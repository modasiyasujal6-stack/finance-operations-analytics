from sqlalchemy import text
from db.connection import get_engine

engine = get_engine()

def reset_finance_ops_data():
    queries = [
        "TRUNCATE TABLE finance_ops.bank_transactions RESTART IDENTITY CASCADE;",
        "TRUNCATE TABLE finance_ops.receivables RESTART IDENTITY CASCADE;",
        "TRUNCATE TABLE finance_ops.payables RESTART IDENTITY CASCADE;",
        "TRUNCATE TABLE finance_ops.sales_transactions RESTART IDENTITY CASCADE;",
        "TRUNCATE TABLE finance_ops.expense_entries RESTART IDENTITY CASCADE;",
        "TRUNCATE TABLE finance_ops.budget RESTART IDENTITY CASCADE;",
        "TRUNCATE TABLE finance_ops.customers RESTART IDENTITY CASCADE;",
        "TRUNCATE TABLE finance_ops.vendors RESTART IDENTITY CASCADE;",
        "TRUNCATE TABLE finance_ops.accounts_master RESTART IDENTITY CASCADE;"
    ]

    with engine.begin() as conn:
        for query in queries:
            conn.execute(text(query))

    print("finance_ops tables reset successfully.")