#!/bin/bash
#===========================================================
# stop-obsidian-full-vault-autosync.sh
# Stops the full vault autosync daemon
#===========================================================

DAEMON_PID_FILE="/tmp/obsidian-full-vault-autosync.pid"
DAEMON_LOCK_FILE="/tmp/obsidian-full-vault-autosync.lock"

echo "Stopping Obsidian Full Vault autosync daemon..."

if [[ -f "$DAEMON_PID_FILE" ]]; then
    PID=$(cat "$DAEMON_PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        echo "Daemon stopped (PID $PID)"
    else
        echo "Daemon not running (stale PID file)"
    fi
    rm -f "$DAEMON_PID_FILE"
else
    echo "PID file not found, daemon may not be running"
fi

if [[ -f "$DAEMON_LOCK_FILE" ]]; then
    rm -f "$DAEMON_LOCK_FILE"
fi

echo "Done."
