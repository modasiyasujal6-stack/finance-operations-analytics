import logging
import os

LOG_FILE = "pipeline.log"

os.makedirs("logs", exist_ok=True)

logging.basicConfig(
    filename=os.path.join("logs", LOG_FILE),
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

logger = logging.getLogger(__name__)