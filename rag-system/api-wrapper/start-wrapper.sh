#!/usr/bin/env bash
set -euo pipefail

WRAPPER_ROOT="${WRAPPER_ROOT:-/app/working/workspaces/default/orebit-ops/rag-system/api-wrapper}"
HOST="${RAG_WRAPPER_HOST:-127.0.0.1}"
WRAPPER_PORT="${RAG_WRAPPER_PORT:-3004}"
PID_FILE="${RAG_WRAPPER_PID_FILE:-/app/working/workspaces/default/run/rag-api-wrapper.pid}"
LOG_DIR="${RAG_WRAPPER_LOG_DIR:-/app/working/workspaces/default/logs}"
LOG_FILE="${RAG_WRAPPER_LOG_FILE:-$LOG_DIR/rag-api-wrapper.log}"
HEALTH_URL="http://${HOST}:${WRAPPER_PORT}/api/rag/health"

mkdir -p "$LOG_DIR" "$(dirname "$PID_FILE")"

if [[ -f "$PID_FILE" ]]; then
  pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    echo "RAG wrapper already running (PID $pid)"
    exit 0
  fi
fi

cd "$WRAPPER_ROOT"
nohup env PORT="$WRAPPER_PORT" RAG_API_HOST="$HOST" node index.js >"$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
sleep 3

if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
  echo "RAG wrapper started (PID $(cat "$PID_FILE"))"
  exit 0
fi

echo "RAG wrapper failed to start" >&2
exit 1
