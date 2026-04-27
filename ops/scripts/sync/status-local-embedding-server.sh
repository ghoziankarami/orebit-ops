#!/usr/bin/env bash
set -euo pipefail

PID_FILE="${PID_FILE:-/app/working/workspaces/default/run/local-embedding-server.pid}"
HEALTH_URL="${HEALTH_URL:-http://127.0.0.1:3005/health}"

if [[ -f "$PID_FILE" ]]; then
  pid="$(cat "$PID_FILE" 2>/dev/null || true)"
else
  pid=""
fi

if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
  echo "PID: $pid"
else
  echo "PID: not-running"
fi

if curl -fsS "$HEALTH_URL"; then
  exit 0
fi

echo
exit 1
