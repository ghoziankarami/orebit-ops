#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-/app/working/workspaces/default/orebit-ops}"
LOG_DIR="${LOG_DIR:-/app/working/workspaces/default/logs}"
PID_FILE="${PID_FILE:-/app/working/workspaces/default/run/local-embedding-server.pid}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/local-embedding-server.log}"

mkdir -p "$LOG_DIR" "$(dirname "$PID_FILE")"

if [[ -f "$PID_FILE" ]]; then
  pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    echo "Embedding server already running (PID $pid)"
    exit 0
  fi
fi

cd "$REPO_ROOT"
nohup python3 rag-system/embedding_server.py >"$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
sleep 2

if curl -fsS http://127.0.0.1:3005/health >/dev/null 2>&1; then
  echo "Embedding server started (PID $(cat "$PID_FILE"))"
  exit 0
fi

echo "Embedding server failed to start" >&2
exit 1
