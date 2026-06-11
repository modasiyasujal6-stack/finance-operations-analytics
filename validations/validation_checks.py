from sqlalchemy import text
from db.connection import get_engine

engine = get_engine()

def run_validations():
    checks = {
        "customers_count": "SELECT COUNT(*) FROM finance_ops.customers;",
        "vendors_count": "SELECT COUNT(*) FROM finance_ops.vendors;",
        "sales_count": "SELECT COUNT(*) FROM finance_ops.sales_transactions;",
        "receivables_count": "SELECT COUNT(*) FROM finance_ops.receivables;",
        "expenses_count": "SELECT COUNT(*) FROM finance_ops.expense_entries;",
        "payables_count": "SELECT COUNT(*) FROM finance_ops.payables;",
        "bank_txn_count": "SELECT COUNT(*) FROM finance_ops.bank_transactions;",
        "invalid_receivables": """
            SELECT COUNT(*)
            FROM finance_ops.receivables
            WHERE amount_received > amount_due;
        """,
        "invalid_payables": """
            SELECT COUNT(*)
            FROM finance_ops.payables
            WHERE amount_paid > amount_due;
        """,
        "missing_sales_receivable_links": """
            SELECT COUNT(*)
            FROM finance_ops.sales_transactions s
            LEFT JOIN finance_ops.receivables r
              ON s.sale_id = r.sale_id
            WHERE r.sale_id IS NULL;
        """,
        "missing_expense_payable_links": """
            SELECT COUNT(*)
            FROM finance_ops.expense_entries e
            LEFT JOIN finance_ops.payables p
              ON e.expense_id = p.expense_id
            WHERE p.expense_id IS NULL;
        """
    }

    with engine.connect() as conn:
        for check_name, sql in checks.items():
            result = conn.execute(text(sql)).scalar()
            print(f"{check_name}: {result}")