#!/bin/bash
# Start the autosync daemon
DAEMON_PID="/tmp/obsidian-inbox-autosync.pid"
DAEMON_STATUS="/tmp/obsidian-inbox-autosync.status"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$DAEMON_PID" ]]; then
    pid=$(cat "$DAEMON_PID")
    if kill -0 "$pid" 2>/dev/null; then
        echo "Daemon already running (PID $pid)"
        exit 0
    fi
fi

echo "Starting autosync daemon..."
nohup bash "${SCRIPT_DIR}/run-obsidian-inbox-autosync-daemon.sh" \
    >> /tmp/obsidian-inbox-autosync-daemon.log 2>&1 &
new_pid=$!
echo $new_pid > "$DAEMON_PID"
sleep 2
if kill -0 "$new_pid" 2>/dev/null; then
    echo "Daemon started (PID $new_pid)"
    echo "OK|$(date -Iseconds)|$new_pid" > "$DAEMON_STATUS"
else
    echo "ERROR: Daemon failed to start"
    exit 1
fi
