#!/usr/bin/env bash
set -euo pipefail

WRAPPER_ROOT="${WRAPPER_ROOT:-/app/working/workspaces/default/orebit-ops/rag-system/api-wrapper}"
STATUS_SCRIPT="$WRAPPER_ROOT/status-wrapper.sh"
START_SCRIPT="$WRAPPER_ROOT/start-wrapper.sh"
STATUS_DIR="${STATUS_DIR:-/app/working/workspaces/default/runtime-status}"
STATUS_FILE="$STATUS_DIR/rag-api-wrapper.status"
LOG_FILE="$STATUS_DIR/rag-api-wrapper.watchdog.log"

mkdir -p "$STATUS_DIR"

timestamp() {
  date -Iseconds
}

if "$STATUS_SCRIPT" >/tmp/rag-wrapper.status.$$ 2>/tmp/rag-wrapper.err.$$; then
  {
    echo "[$(timestamp)] STATUS: healthy"
    cat /tmp/rag-wrapper.status.$$
  } >"$STATUS_FILE"
  {
    echo "[$(timestamp)] healthy"
    cat /tmp/rag-wrapper.status.$$
  } >>"$LOG_FILE"
  rm -f /tmp/rag-wrapper.status.$$ /tmp/rag-wrapper.err.$$
  exit 0
fi

"$START_SCRIPT" >/tmp/rag-wrapper.start.$$ 2>/tmp/rag-wrapper.start.err.$$ || true

if "$STATUS_SCRIPT" >/tmp/rag-wrapper.status.$$ 2>/tmp/rag-wrapper.err.$$; then
  {
    echo "[$(timestamp)] STATUS: restarted-ok"
    cat /tmp/rag-wrapper.status.$$
  } >"$STATUS_FILE"
  {
    echo "[$(timestamp)] restarted-ok"
    cat /tmp/rag-wrapper.start.$$ 2>/dev/null || true
    cat /tmp/rag-wrapper.status.$$
  } >>"$LOG_FILE"
  rm -f /tmp/rag-wrapper.status.$$ /tmp/rag-wrapper.err.$$ /tmp/rag-wrapper.start.$$ /tmp/rag-wrapper.start.err.$$
  exit 0
fi

{
  echo "[$(timestamp)] STATUS: failed"
  echo "Could not start RAG API wrapper"
  cat /tmp/rag-wrapper.start.err.$$ 2>/dev/null || true
  cat /tmp/rag-wrapper.err.$$ 2>/dev/null || true
} >"$STATUS_FILE"

{
  echo "[$(timestamp)] failed"
  cat /tmp/rag-wrapper.start.err.$$ 2>/dev/null || true
  cat /tmp/rag-wrapper.err.$$ 2>/dev/null || true
} >>"$LOG_FILE"

rm -f /tmp/rag-wrapper.status.$$ /tmp/rag-wrapper.err.$$ /tmp/rag-wrapper.start.$$ /tmp/rag-wrapper.start.err.$$
exit 1
