import os
from typing import Optional
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import SQLAlchemyError

def get_engine(DB: Optional[str]="johnnyquest"):
    USER = os.getenv("JQMCBP_DB_USER")
    PWD = os.getenv("JQMCBP_DB_PASS")
    HOST = os.getenv("JQMCBP_DB_HOST")
    db_str = f"mysql+pymysql://{USER}:{PWD}@{HOST}/{DB}"
    engine = create_engine(db_str, echo=True)
    Session = sessionmaker(bind=engine)
    return Session()

