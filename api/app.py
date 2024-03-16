import lib.db as db
from lib.models import (
    Filter, Games, LastUpdated, Picks, PlayerInfo, Scores, SimilarityIndex, Teams, 
)
from flask import Flask, request
from sqlalchemy import create_engine, text, desc
from app_service import AppService
import json

app = Flask(__name__)
appService = AppService();

# XXX Change to johnnyquest
DB = "jq_2023"

@app.route('/')
def home():
    return """
*********************
JQ-API UP!!! 
*********************
"""

@app.route('/api/test')
def test():
    with db.get_engine(DB) as session:
        ret = []
        step = session.query(Scores).order_by(desc(Scores.step)).first()
        result = session.query(Scores).filter(Scores.step == step.step, Scores.man_or_chimp == 'man').order_by(desc(Scores.score))
        for r in result:
            ret.append({"name": r.name, "score": r.score})
    return json.dumps(ret)

