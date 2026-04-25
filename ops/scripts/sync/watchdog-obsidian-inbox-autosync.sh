#!/bin/bash
# Watchdog: checks if autosync daemon is alive, restarts if dead
# SILENT: only writes to status file, NO chat messages
set -euo pipefail

DAEMON_PID="/tmp/obsidian-inbox-autosync.pid"
DAEMON_STATUS="/tmp/obsidian-inbox-autosync.status"
WD_STATUS="/tmp/obsidian-inbox-autosync-watchdog.status"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "[$(date -Iseconds)] [WATCHDOG] $*" | tee -a "$WD_STATUS"; }

check() {
    if [[ ! -f "$DAEMON_PID" ]]; then
        log "DEAD: no PID file, starting daemon..."
        bash "${SCRIPT_DIR}/start-obsidian-inbox-autosync.sh"
        log "STARTED: daemon started"
        return
    fi

    pid=$(cat "$DAEMON_PID")
    if ! kill -0 "$pid" 2>/dev/null; then
        log "DEAD: PID $pid not running, restarting..."
        bash "${SCRIPT_DIR}/start-obsidian-inbox-autosync.sh"
        log "RESTARTED: daemon restarted"
    else
        log "ALIVE: daemon PID $pid running"
    fi
}

check
echo "Watchdog check OK|$(date -Iseconds)" >> "$WD_STATUS"
