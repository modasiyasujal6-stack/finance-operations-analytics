from datetime import date

DB_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"

# Master data
NUM_ACCOUNTS = 5
NUM_CUSTOMERS = 200
NUM_VENDORS = 100

# Transaction data
NUM_SALES = 5000
NUM_EXPENSES = 3000

# Date range
START_DATE = date(2024,1,1)
END_DATE   = date(2026,12,31)

# Dimensions
DEPARTMENTS = ["Finance", "HR", "Operations", "Marketing", "Sales", "IT"]
VENDOR_CATEGORIES = ["Utilities", "Logistics", "Software", "Office Supplies", "Consulting", "Maintenance"]
INDUSTRIES = ["Retail", "Manufacturing", "Healthcare", "Technology", "Education", "FMCG"]
CURRENCIES = ["INR"]