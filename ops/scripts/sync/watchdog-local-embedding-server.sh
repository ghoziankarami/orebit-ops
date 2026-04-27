#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-/app/working/workspaces/default/orebit-ops}"
STATUS_SCRIPT="$REPO_ROOT/ops/scripts/sync/status-local-embedding-server.sh"
START_SCRIPT="$REPO_ROOT/ops/scripts/sync/start-local-embedding-server.sh"
STATUS_DIR="${STATUS_DIR:-/app/working/workspaces/default/runtime-status}"
STATUS_FILE="$STATUS_DIR/local-embedding-server.status"
LOG_FILE="$STATUS_DIR/local-embedding-server.watchdog.log"

mkdir -p "$STATUS_DIR"

timestamp() {
  date -Iseconds
}

if "$STATUS_SCRIPT" >/tmp/local-embedding-server.status.$$ 2>/tmp/local-embedding-server.err.$$; then
  {
    echo "[$(timestamp)] STATUS: healthy"
    cat /tmp/local-embedding-server.status.$$
  } >"$STATUS_FILE"
  {
    echo "[$(timestamp)] healthy"
    cat /tmp/local-embedding-server.status.$$
  } >>"$LOG_FILE"
  rm -f /tmp/local-embedding-server.status.$$ /tmp/local-embedding-server.err.$$
  exit 0
fi

"$START_SCRIPT" >/tmp/local-embedding-server.start.$$ 2>/tmp/local-embedding-server.start.err.$$ || true

if "$STATUS_SCRIPT" >/tmp/local-embedding-server.status.$$ 2>/tmp/local-embedding-server.err.$$; then
  {
    echo "[$(timestamp)] STATUS: restarted-ok"
    cat /tmp/local-embedding-server.status.$$
  } >"$STATUS_FILE"
  {
    echo "[$(timestamp)] restarted-ok"
    cat /tmp/local-embedding-server.start.$$
    cat /tmp/local-embedding-server.status.$$
  } >>"$LOG_FILE"
  rm -f /tmp/local-embedding-server.status.$$ /tmp/local-embedding-server.err.$$ /tmp/local-embedding-server.start.$$ /tmp/local-embedding-server.start.err.$$
  exit 0
fi

{
  echo "[$(timestamp)] STATUS: failed"
  echo "Could not start local embedding server"
  cat /tmp/local-embedding-server.start.err.$$ 2>/dev/null || true
  cat /tmp/local-embedding-server.err.$$ 2>/dev/null || true
} >"$STATUS_FILE"

{
  echo "[$(timestamp)] failed"
  cat /tmp/local-embedding-server.start.err.$$ 2>/dev/null || true
  cat /tmp/local-embedding-server.err.$$ 2>/dev/null || true
} >>"$LOG_FILE"

rm -f /tmp/local-embedding-server.status.$$ /tmp/local-embedding-server.err.$$ /tmp/local-embedding-server.start.$$ /tmp/local-embedding-server.start.err.$$
exit 1
