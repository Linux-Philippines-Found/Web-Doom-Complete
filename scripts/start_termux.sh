#!/data/data/com.termux/files/usr/bin/bash
set -e
cd "$(dirname "$0")/.."
if [ -d .venv ]; then . .venv/bin/activate; fi
exec gunicorn --workers 1 --bind 0.0.0.0:8080 app:app
