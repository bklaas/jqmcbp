
import lib.db as db
from lib.models import (
    Filter,
    Games,
    LastUpdated,
    Picks,
    PlayerInfo,
    Scores,
    SimilarityIndex,
    Teams,
)
from flask import Flask, request
from flask_restful import Resource, Api
from sqlalchemy import create_engine, text, desc
import json

app = Flask(__name__)
api = Api(app)

# XXX Change to johnnyquest
DB = "jq_2023"



class DBHealth(Resource):
    def test(self):
        with db.get_engine(DB) as session:
            ret = []
            step = session.query(Scores).order_by(desc(Scores.step)).first()
            result = (
                session.query(Scores)
                .filter(Scores.step == step.step, Scores.man_or_chimp == "man")
                .order_by(desc(Scores.score))
            )
            for r in result:
                ret.append({"name": r.name, "score": r.score})
        return ret


class Leaderboard(Resource):
    def leaderboard(self):
        with db.get_engine(DB) as session:
            ret = []
            step = session.query(Scores).order_by(desc(Scores.step)).first()
            result = (
                session.query(Scores)
                .filter(Scores.step == step.step, Scores.man_or_chimp == "man")
                .order_by(desc(Scores.score))
            )
            for r in result:
                ret.append(
                    {
                        "name": r.name,
                        "score": r.score,
                        "candybar": r.player_info_obj.candybar,
                        "champion": r.player_info_obj.champion,
                    }
                )
        return ret

class HelloWorld(Resource):
    def get(self):
        return {'api_up': True}

api.add_resource(HelloWorld, '/')
api.add_resource(Leaderboard, '/leaderboard')
api.add_resource(DBHealth, '/test')

if __name__ == '__main__':
    app.run(debug=True)