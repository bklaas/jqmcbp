#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
uv run --with pymysql --with pandas --with plotly --with kaleido --with python-dotenv choropleth.py "$@"
uv run --with pymysql --with pandas --with plotly --with kaleido --with python-dotenv --with pillow choropleth_over_time.py "$@"
