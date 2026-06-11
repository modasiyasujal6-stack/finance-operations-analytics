-- ============================================
-- FINANCE OPS ANALYSIS LAYER
-- ============================================

-- 1. Receivables Aging View
CREATE OR REPLACE VIEW finance_ops.vw_receivables_aging AS
SELECT
    r.receivable_id,
    r.sale_id,
    r.customer_id,
    c.customer_name,
    r.invoice_date,
    r.due_date,
    r.amount_due,
    r.amount_received,
    (r.amount_due - r.amount_received) AS outstanding_amount,
    CASE
        WHEN (r.amount_due - r.amount_received) <= 0 THEN 'Closed'
        WHEN CURRENT_DATE <= r.due_date THEN 'Not Due'
        WHEN CURRENT_DATE - r.due_date BETWEEN 1 AND 30 THEN '1-30 Days'
        WHEN CURRENT_DATE - r.due_date BETWEEN 31 AND 60 THEN '31-60 Days'
        WHEN CURRENT_DATE - r.due_date BETWEEN 61 AND 90 THEN '61-90 Days'
        ELSE '90+ Days'
    END AS aging_bucket
FROM finance_ops.receivables r
JOIN finance_ops.customers c
    ON r.customer_id = c.customer_id;


-- 2. Payables Aging View
CREATE OR REPLACE VIEW finance_ops.vw_payables_aging AS
SELECT
    p.payable_id,
    p.expense_id,
    p.vendor_id,
    v.vendor_name,
    p.bill_date,
    p.due_date,
    p.amount_due,
    p.amount_paid,
    (p.amount_due - p.amount_paid) AS outstanding_amount,
    CASE
        WHEN (p.amount_due - p.amount_paid) <= 0 THEN 'Closed'
        WHEN CURRENT_DATE <= p.due_date THEN 'Not Due'
        WHEN CURRENT_DATE - p.due_date BETWEEN 1 AND 30 THEN '1-30 Days'
        WHEN CURRENT_DATE - p.due_date BETWEEN 31 AND 60 THEN '31-60 Days'
        WHEN CURRENT_DATE - p.due_date BETWEEN 61 AND 90 THEN '61-90 Days'
        ELSE '90+ Days'
    END AS aging_bucket
FROM finance_ops.payables p
JOIN finance_ops.vendors v
    ON p.vendor_id = v.vendor_id;


-- 3. Monthly Revenue Summary
CREATE OR REPLACE VIEW finance_ops.vw_monthly_revenue AS
SELECT
    DATE_TRUNC('month', sale_date)::date AS month,
    SUM(invoice_amount) AS invoice_amount,
    SUM(tax_amount) AS tax_amount,
    SUM(total_amount) AS total_revenue
FROM finance_ops.sales_transactions
GROUP BY 1;


-- 4. Monthly Expense Summary
CREATE OR REPLACE VIEW finance_ops.vw_monthly_expenses AS
SELECT
    DATE_TRUNC('month', expense_date)::date AS month,
    department,
    SUM(expense_amount) AS total_expense
FROM finance_ops.expense_entries
GROUP BY 1, 2;


-- 5. Monthly Closing Summary
CREATE OR REPLACE VIEW finance_ops.vw_monthly_closing_summary AS
WITH sales_monthly AS (
    SELECT
        DATE_TRUNC('month', sale_date)::date AS month,
        SUM(total_amount) AS total_revenue
    FROM finance_ops.sales_transactions
    GROUP BY 1
),
expense_monthly AS (
    SELECT
        DATE_TRUNC('month', expense_date)::date AS month,
        SUM(expense_amount) AS total_expense
    FROM finance_ops.expense_entries
    GROUP BY 1
)
SELECT
    COALESCE(s.month, e.month) AS month,
    COALESCE(s.total_revenue, 0) AS total_revenue,
    COALESCE(e.total_expense, 0) AS total_expense,
    COALESCE(s.total_revenue, 0) - COALESCE(e.total_expense, 0) AS net_profit
FROM sales_monthly s
FULL OUTER JOIN expense_monthly e
    ON s.month = e.month
ORDER BY month;


-- 6. Budget vs Actual
CREATE OR REPLACE VIEW finance_ops.vw_budget_vs_actual AS
WITH actuals AS (
    SELECT
        DATE_TRUNC('month', expense_date)::date AS month,
        department,
        SUM(expense_amount) AS actual_amount
    FROM finance_ops.expense_entries
    GROUP BY 1, 2
)
SELECT
    b.month::date AS month,
    b.department,
    b.budget_amount,
    COALESCE(a.actual_amount, 0) AS actual_amount,
    COALESCE(a.actual_amount, 0) - b.budget_amount AS variance_amount,
    CASE
        WHEN b.budget_amount = 0 THEN NULL
        ELSE ROUND(((COALESCE(a.actual_amount, 0) - b.budget_amount) / b.budget_amount) * 100, 2)
    END AS variance_pct
FROM finance_ops.budget b
LEFT JOIN actuals a
    ON b.month::date = a.month
   AND b.department = a.department
ORDER BY month, department;


-- 7. Cash Flow View
CREATE OR REPLACE VIEW finance_ops.vw_cash_flow AS
SELECT
    transaction_id,
    account_id,
    transaction_date,
    transaction_type,
    reference_type,
    reference_id,
    amount,
    description,
    CASE
        WHEN transaction_type = 'inflow' THEN amount
        ELSE 0
    END AS cash_in,
    CASE
        WHEN transaction_type = 'outflow' THEN amount
        ELSE 0
    END AS cash_out
FROM finance_ops.bank_transactions;


-- 8. Running Cash Balance
CREATE OR REPLACE VIEW finance_ops.vw_running_cash_balance AS
SELECT
    transaction_date,
    transaction_id,
    transaction_type,
    reference_type,
    reference_id,
    amount,
    SUM(
        CASE
            WHEN transaction_type = 'inflow' THEN amount
            WHEN transaction_type = 'outflow' THEN -amount
            ELSE 0
        END
    ) OVER (
        ORDER BY transaction_date, transaction_id
    ) AS running_balance
FROM finance_ops.bank_transactions;


-- 9. Daily Cash Summary
CREATE OR REPLACE VIEW finance_ops.vw_daily_cash_summary AS
SELECT
    transaction_date,
    SUM(CASE WHEN transaction_type = 'inflow' THEN amount ELSE 0 END) AS total_inflow,
    SUM(CASE WHEN transaction_type = 'outflow' THEN amount ELSE 0 END) AS total_outflow,
    SUM(
        CASE
            WHEN transaction_type = 'inflow' THEN amount
            WHEN transaction_type = 'outflow' THEN -amount
            ELSE 0
        END
    ) AS net_cash_flow
FROM finance_ops.bank_transactions
GROUP BY transaction_date
ORDER BY transaction_date;


-- 10. Cash Forecast - Next 30 Days
CREATE OR REPLACE VIEW finance_ops.vw_cash_forecast_30_days AS
WITH expected_inflows AS (
    SELECT
        due_date AS forecast_date,
        SUM(amount_due - amount_received) AS expected_inflow
    FROM finance_ops.receivables
    WHERE (amount_due - amount_received) > 0
      AND due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
    GROUP BY due_date
),
expected_outflows AS (
    SELECT
        due_date AS forecast_date,
        SUM(amount_due - amount_paid) AS expected_outflow
    FROM finance_ops.payables
    WHERE (amount_due - amount_paid) > 0
      AND due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
    GROUP BY due_date
)
SELECT
    COALESCE(i.forecast_date, o.forecast_date) AS forecast_date,
    COALESCE(i.expected_inflow, 0) AS expected_inflow,
    COALESCE(o.expected_outflow, 0) AS expected_outflow,
    COALESCE(i.expected_inflow, 0) - COALESCE(o.expected_outflow, 0) AS net_expected_cash_flow
FROM expected_inflows i
FULL OUTER JOIN expected_outflows o
    ON i.forecast_date = o.forecast_date
ORDER BY forecast_date;


-- 11. DSO KPI
CREATE OR REPLACE VIEW finance_ops.vw_dso AS
WITH revenue_data AS (
    SELECT
        DATE_TRUNC('month', sale_date)::date AS month,
        SUM(total_amount) AS total_credit_sales
    FROM finance_ops.sales_transactions
    GROUP BY 1
),
receivable_data AS (
    SELECT
        DATE_TRUNC('month', invoice_date)::date AS month,
        AVG(amount_due - amount_received) AS avg_receivable
    FROM finance_ops.receivables
    GROUP BY 1
)
SELECT
    r.month,
    r.avg_receivable,
    d.total_credit_sales,
    CASE
        WHEN d.total_credit_sales = 0 THEN NULL
        ELSE ROUND((r.avg_receivable / d.total_credit_sales) * 30, 2)
    END AS dso
FROM receivable_data r
JOIN revenue_data d
    ON r.month = d.month
ORDER BY r.month;


-- 12. DPO KPI
CREATE OR REPLACE VIEW finance_ops.vw_dpo AS
WITH expense_data AS (
    SELECT
        DATE_TRUNC('month', expense_date)::date AS month,
        SUM(expense_amount) AS total_purchases
    FROM finance_ops.expense_entries
    GROUP BY 1
),
payable_data AS (
    SELECT
        DATE_TRUNC('month', bill_date)::date AS month,
        AVG(amount_due - amount_paid) AS avg_payable
    FROM finance_ops.payables
    GROUP BY 1
)
SELECT
    p.month,
    p.avg_payable,
    e.total_purchases,
    CASE
        WHEN e.total_purchases = 0 THEN NULL
        ELSE ROUND((p.avg_payable / e.total_purchases) * 30, 2)
    END AS dpo
FROM payable_data p
JOIN expense_data e
    ON p.month = e.month
ORDER BY p.month;


-- 13. Top Overdue Customers
CREATE OR REPLACE VIEW finance_ops.vw_top_overdue_customers AS
SELECT
    customer_name,
    SUM(outstanding_amount) AS total_overdue
FROM finance_ops.vw_receivables_aging
WHERE aging_bucket IN ('1-30 Days', '31-60 Days', '61-90 Days', '90+ Days')
GROUP BY customer_name
ORDER BY total_overdue DESC;


-- 14. Top Outstanding Vendors
CREATE OR REPLACE VIEW finance_ops.vw_top_outstanding_vendors AS
SELECT
    vendor_name,
    SUM(outstanding_amount) AS total_outstanding
FROM finance_ops.vw_payables_aging
WHERE aging_bucket IN ('1-30 Days', '31-60 Days', '61-90 Days', '90+ Days')
GROUP BY vendor_name
ORDER BY total_outstanding DESC;