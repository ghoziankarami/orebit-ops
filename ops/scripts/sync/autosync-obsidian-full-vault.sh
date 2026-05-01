#!/bin/bash
#===========================================================
# autosync-obsidian-full-vault.sh
# FULL VAULT SYNC: All folders two-way (root + PARA structure)
#===========================================================

set -euo pipefail

READ_REMOTE="gdrive-obsidian"
WRITE_REMOTE="gdrive-obsidian-oauth"
LOCAL_VAULT="/app/working/workspaces/default/obsidian-system/vault"
SYNC_LOCK="/tmp/obsidian-full-vault-sync.lock"
DAEMON_STATUS="/tmp/obsidian-full-vault-sync.status"
LOG_DIR="/app/working/workspaces/default/orebit-ops/docs/audits/sync"
LOG_FILE="${LOG_DIR}/obsidian-full-vault-sync-$(date +%Y%m%dT%H%M%SZ).log"

mkdir -p "$LOG_DIR"

log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG_FILE"; }

# Lock to prevent overlapping sync cycles
acquire_lock() {
    if [[ -f "$SYNC_LOCK" ]]; then
        old_pid=$(cat "$SYNC_LOCK" 2>/dev/null || echo "")
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            log "Sync already running (PID $old_pid), skip."
            exit 0
        fi
        log "Stale sync lock found (PID $old_pid), removing."
        rm -f "$SYNC_LOCK"
    fi
    echo $$ > "$SYNC_LOCK"
}

release_lock() {
    rm -f "$SYNC_LOCK"
}

# Full vault sync: all folders except .git, .trash, .obsidian
do_sync() {
    local src=$1; local dst=$2; local label=$3

    log "=== Sync $label: $src → $dst ==="

    # Full vault sync - include all folders
    rclone sync "$src" "$dst" \
        --verbose \
        --fast-list \
        --exclude ".git/**" \
        --exclude ".trash/**" \
        --exclude "*.tmp" \
        --exclude "*.swp" \
        --exclude ".obsidian/**" \
        --exclude ".obsidian-plugins/**" \
        --create-empty-src-dirs \
        --progress 2>&1 | tee -a "$LOG_FILE"

    log "Sync $label complete."
}

run() {
    acquire_lock

    trap release_lock EXIT

    log "START full vault sync cycle (PID $$)"

    # Sync: Drive -> Local (pull changes first)
    do_sync "${READ_REMOTE}:/" "${LOCAL_VAULT}" "GDrive->Local"

    # Sync: Local -> Drive (push changes)
    do_sync "${LOCAL_VAULT}" "${WRITE_REMOTE}:/" "Local->GDrive"

    log "END full vault sync cycle OK"

    # Write status
    echo "OK|$(date -Iseconds)|$$" > "$DAEMON_STATUS"
}

# Run once (used by daemon loop)
run
