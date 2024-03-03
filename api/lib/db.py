import os
from typing import Optional
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError


# Create the engine
#engine = create_engine('mysql+pymysql://root:hoopoe@localhost/johnnyquest')
#engine = create_engine(f'mysql+pymysql://{USER}:{PWD}@localhost/johnnyquest')

def get_engine(DB: Optional[str]="johnnyquest"):
    USER = os.getenv("JQMCBP_DB_USER")
    PWD = os.getenv("JQMCBP_DB_PASS")
    HOST = os.getenv("JQMCBP_DB_HOST")
    db_str = "mysql+pymysql"
    return create_engine(f'{db_str}://{USER}:{PWD}@{HOST}/{DB}')
    
try:
    with get_engine().connect() as connection:
        result = connection.execute(text("SELECT * from player_info"))
        value = result.fetchone()
        print(value)
except SQLAlchemyError as e:
    print(f"Error: {e}")


