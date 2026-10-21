#!/data/data/com.termux/files/usr/bin/bash
set -e
cd "$(dirname "$0")/.."
echo "Starting temporary Cloudflare Tunnel..."
echo "Make sure Gunicorn is already listening on 127.0.0.1:8080"
exec cloudflared tunnel --url http://127.0.0.1:8080
