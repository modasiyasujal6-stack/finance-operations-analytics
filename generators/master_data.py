import random
from faker import Faker
from sqlalchemy import text

from db.connection import get_engine
from config.config import NUM_CUSTOMERS, NUM_VENDORS, DEPARTMENTS, VENDOR_CATEGORIES, INDUSTRIES
from utils.logger import logger

fake = Faker("en_IN")
engine = get_engine()

def insert_accounts():
    records = [
        {"account_name": "Main Bank Account", "account_type": "bank", "currency": "INR"},
        {"account_name": "Payroll Bank Account", "account_type": "bank", "currency": "INR"},
        {"account_name": "Petty Cash", "account_type": "cash", "currency": "INR"},
        {"account_name": "Corporate Credit Card", "account_type": "credit", "currency": "INR"},
        {"account_name": "Collections Account", "account_type": "bank", "currency": "INR"},
    ]

    query = text("""
        INSERT INTO finance_ops.accounts_master (account_name, account_type, currency)
        VALUES (:account_name, :account_type, :currency)
    """)

    with engine.begin() as conn:
        conn.execute(query, records)

    logger.info("Inserted accounts_master")

def insert_customers(n=NUM_CUSTOMERS):
    records = []
    for _ in range(n):
        records.append({
            "customer_name": fake.company(),
            "industry": random.choice(INDUSTRIES),
            "credit_limit": round(random.uniform(50000, 500000), 2)
        })

    query = text("""
        INSERT INTO finance_ops.customers (customer_name, industry, credit_limit)
        VALUES (:customer_name, :industry, :credit_limit)
    """)

    with engine.begin() as conn:
        conn.execute(query, records)

    logger.info(f"Inserted {n} customers")

def insert_vendors(n=NUM_VENDORS):
    records = []
    for _ in range(n):
        records.append({
            "vendor_name": fake.company(),
            "category": random.choice(VENDOR_CATEGORIES),
            "payment_terms": random.choice([7, 15, 30, 45])
        })

    query = text("""
        INSERT INTO finance_ops.vendors (vendor_name, category, payment_terms)
        VALUES (:vendor_name, :category, :payment_terms)
    """)

    with engine.begin() as conn:
        conn.execute(query, records)

    logger.info(f"Inserted {n} vendors")

def insert_budget():
    records = []
    for year in [2024, 2025]:
        for month in range(1, 13):
            for dept in DEPARTMENTS:
                records.append({
                    "department": dept,
                    "month": f"{year}-{month:02d}-01",
                    "budget_amount": round(random.uniform(200000, 1500000), 2)
                })

    query = text("""
        INSERT INTO finance_ops.budget (department, month, budget_amount)
        VALUES (:department, :month, :budget_amount)
    """)

    with engine.begin() as conn:
        conn.execute(query, records)

    logger.info("Inserted budget rows")

def load_master_data():
    insert_accounts()
    insert_customers()
    insert_vendors()
    insert_budget()