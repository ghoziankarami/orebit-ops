#!/bin/bash
# Runs the autosync daemon loop (internal use, called by start script)
set -euo pipefail

DAEMON_LOCK="/tmp/obsidian-inbox-autosync.lock"
DAEMON_PID="/tmp/obsidian-inbox-autosync.pid"
DAEMON_STATUS="/tmp/obsidian-inbox-autosync.status"
INTERVAL="${AUTOSYNC_INTERVAL:-300}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOSYNC_SCRIPT="${SCRIPT_DIR}/autosync-obsidian-inbox-copy-merge.sh"

acquire_lock() {
    if [[ -f "$DAEMON_LOCK" ]]; then
        old_pid=$(cat "$DAEMON_LOCK" 2>/dev/null || echo "")
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            echo "[DAEMON] Already running PID $old_pid, exiting."
            exit 0
        fi
    fi
    echo $$ > "$DAEMON_LOCK"
    echo $$ > "$DAEMON_PID"
}

release_lock() {
    rm -f "$DAEMON_LOCK" "$DAEMON_PID"
}

echo "[DAEMON] Starting Obsidian Inbox autosync daemon (PID $$), interval=${INTERVAL}s"
acquire_lock
trap release_lock EXIT

while true; do
    echo "[DAEMON $(date -Iseconds)] Running sync cycle..."
    bash "$AUTOSYNC_SCRIPT"
    echo "[DAEMON $(date -Iseconds)] Sleeping ${INTERVAL}s..."
    sleep "$INTERVAL"
done
