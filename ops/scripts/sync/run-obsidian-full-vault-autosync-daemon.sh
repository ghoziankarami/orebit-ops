#!/bin/bash
#===========================================================
# run-obsidian-full-vault-autosync-daemon.sh
# Runs the full vault autosync daemon loop
#===========================================================

set -euo pipefail

DAEMON_LOCK="/tmp/obsidian-full-vault-autosync.lock"
DAEMON_PID="/tmp/obsidian-full-vault-autosync.pid"
INTERVAL="${AUTOSYNC_INTERVAL:-300}"  # 5 minutes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOSYNC_SCRIPT="${SCRIPT_DIR}/autosync-obsidian-full-vault.sh"

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

echo "[DAEMON] Starting Obsidian Full Vault autosync daemon (PID $$), interval=${INTERVAL}s"
acquire_lock
trap release_lock EXIT

while true; do
    echo "[DAEMON $(date -Iseconds)] Running full vault sync cycle..."
    bash "$AUTOSYNC_SCRIPT"

    # Check if daemon stopped
    if [[ ! -f "$DAEMON_LOCK" ]]; then
        echo "[DAEMON] Lock file removed, stopping daemon."
        exit 0
    fi

    echo "[DAEMON $(date -Iseconds)] Sleeping ${INTERVAL}s..."
    sleep "$INTERVAL"
done
