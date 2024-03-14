import lib.db as db
from flask import Flask, request
from app_service import AppService
import json

app = Flask(__name__)
appService = AppService();


@app.route('/')
def home():
    return """
*********************
JQ-API UP!!! 
*********************
"""

def dbconnect():
    return db.get_engine().connect()

@app.route('/api/dbhealth')
def dbhealth():
    # XXX this import not working
    with db.get_engine().connect() as dbc:
        result = dbc.execute(text("SELECT * from player_info"))
        return result.fetchone()

@app.route('/api/tasks')
def tasks():
    return appService.get_tasks()

@app.route('/api/task', methods=['POST'])
def create_task():
    request_data = request.get_json()
    task = request_data['task']
    return appService.create_task(task)


@app.route('/api/task', methods=['PUT'])
def update_task():
    request_data = request.get_json()
    return appService.update_task(request_data['task'])


@app.route('/api/task/<int:id>', methods=['DELETE'])
def delete_task(id):
    return appService.delete_task(id)

