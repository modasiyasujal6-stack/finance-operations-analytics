import time

from generators.master_data import load_master_data
from generators.sales_generator import generate_sales_and_receivables
from generators.expense_generator import generate_expenses_and_payables
from validations.validation_checks import run_validations
from utils.logger import logger
from utils.reset_data import reset_finance_ops_data

def run_pipeline(reset=False):
    start_time = time.time()

    logger.info("Pipeline started")
    print("Pipeline started...")

    if reset:
        reset_finance_ops_data()

    load_master_data()
    generate_sales_and_receivables()
    generate_expenses_and_payables()

    print("\nRunning validation checks...\n")
    run_validations()

    end_time = time.time()
    total_time = round(end_time - start_time, 2)

    logger.info(f"Pipeline completed in {total_time} seconds")
    print(f"\nPipeline completed in {total_time} seconds")

if __name__ == "__main__":
    run_pipeline(reset=False)