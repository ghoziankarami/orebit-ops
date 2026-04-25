#!/bin/bash
# Check autosync daemon status
DAEMON_PID="/tmp/obsidian-inbox-autosync.pid"
DAEMON_STATUS="/tmp/obsidian-inbox-autosync.status"
DAEMON_LOG="/tmp/obsidian-inbox-autosync-daemon.log"

echo "=== Obsidian Inbox Autosync Status ==="
if [[ ! -f "$DAEMON_PID" ]]; then
    echo "Status: NOT RUNNING (no PID file)"
    exit 1
fi

pid=$(cat "$DAEMON_PID")
if kill -0 "$pid" 2>/dev/null; then
    echo "Status: RUNNING"
    echo "PID: $pid"
    if [[ -f "$DAEMON_STATUS" ]]; then
        echo "Last cycle: $(cat "$DAEMON_STATUS")"
    fi
    echo "Cmd: $(ps -p "$pid" -o cmd= 2>/dev/null || echo 'unknown')"
else
    echo "Status: DEAD (PID file exists but process not running)"
fi

echo ""
echo "Recent daemon log:"
tail -5 "$DAEMON_LOG" 2>/dev/null || echo "(no log)"
