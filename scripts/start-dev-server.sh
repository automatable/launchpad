#!/bin/bash
#
# Start Django dev server if not already running
# Used by Claude Code SessionStart hook
#

PORT=8000
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Check if something is already listening on the port
if lsof -i :$PORT -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Django dev server already running on port $PORT"
    exit 0
fi

# Start Django in background
cd "$PROJECT_DIR"
DEBUG=True nohup .venv/bin/python manage.py runserver $PORT > /tmp/django-dev-server.log 2>&1 &

# Wait briefly and verify it started
sleep 2
if lsof -i :$PORT -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Started Django dev server on port $PORT"
else
    echo "Failed to start Django dev server - check /tmp/django-dev-server.log"
    exit 1
fi
