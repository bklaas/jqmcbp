#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
uv run --with pymysql --with pandas --with python-dotenv extras_extract.py "$@"
uv run --with pandas --with altair --with vl-convert-python extras_viz_altair.py "$@"
