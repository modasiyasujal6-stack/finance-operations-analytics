from sqlalchemy import create_engine
from config.config import DB_URL

engine = create_engine(DB_URL, future=True)

def get_engine():
    return engine