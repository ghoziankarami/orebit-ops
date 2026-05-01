#!/bin/bash
#===========================================================
# start-obsidian-full-vault-autosync.sh
# Starts the full vault autosync daemon
#===========================================================

DAEMON_PID_FILE="/tmp/obsidian-full-vault-autosync.pid"

cd /app/working/workspaces/default/orebit-ops

# Check if daemon already running
if [[ -f "$DAEMON_PID_FILE" ]]; then
    PID=$(cat "$DAEMON_PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Daemon already running (PID $PID)"
        exit 0
    fi
    echo "Removing stale PID file..."
    rm -f "$DAEMON_PID_FILE"
fi

# Start daemon
echo "Starting Obsidian Full Vault autosync daemon..."
nohup bash ops/scripts/sync/run-obsidian-full-vault-autosync-daemon.sh > /tmp/obsidian-full-vault-autosync-daemon.log 2>&1 &

# Wait a bit and check if started
sleep 3
if [[ -f "$DAEMON_PID_FILE" ]]; then
    NEW_PID=$(cat "$DAEMON_PID_FILE")
    echo "Daemon started successfully (PID $NEW_PID)"
else
    echo "Failed to start daemon (no PID file)"
    exit 1
fi
