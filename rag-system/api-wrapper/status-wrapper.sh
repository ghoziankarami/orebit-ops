#!/usr/bin/env bash
set -euo pipefail

HOST="${RAG_WRAPPER_HOST:-127.0.0.1}"
WRAPPER_PORT="${RAG_WRAPPER_PORT:-3004}"
PID_FILE="${RAG_WRAPPER_PID_FILE:-/app/working/workspaces/default/run/rag-api-wrapper.pid}"
HEALTH_URL="http://${HOST}:${WRAPPER_PORT}/api/rag/health"

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
