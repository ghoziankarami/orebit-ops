#!/bin/bash
# Stop the autosync daemon
DAEMON_PID="/tmp/obsidian-inbox-autosync.pid"
DAEMON_LOCK="/tmp/obsidian-inbox-autosync.lock"
DAEMON_STATUS="/tmp/obsidian-inbox-autosync.status"

if [[ ! -f "$DAEMON_PID" ]]; then
    echo "No PID file found, daemon not running?"
    exit 0
fi

pid=$(cat "$DAEMON_PID")
if kill -0 "$pid" 2>/dev/null; then
    echo "Stopping daemon PID $pid..."
    kill "$pid" && sleep 1 && echo "Stopped."
else
    echo "PID $pid not running, cleaning up."
fi

rm -f "$DAEMON_PID" "$DAEMON_LOCK" "$DAEMON_STATUS"
