#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
uv run --with pymysql --with pandas --with python-dotenv j2_extract.py "$@"
uv run --with pandas --with altair --with vl-convert-python --with Pillow j2_viz_altair.py "$@"
