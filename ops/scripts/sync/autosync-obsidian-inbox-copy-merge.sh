#!/bin/bash
#===========================================================
# autosync-obsidian-inbox-copy-merge.sh
# HARDENED: ONLY touches 0. Inbox. All other folders BLOCKED.
#===========================================================

set -euo pipefail

READ_REMOTE="gdrive-obsidian"
WRITE_REMOTE="gdrive-obsidian-oauth"
LOCAL_VAULT="/app/working/workspaces/default/obsidian-system/vault"
INBOX_DIR="0. Inbox"
SYNC_LOCK="/tmp/obsidian-inbox-autosync.sync.lock"
DAEMON_STATUS="/tmp/obsidian-inbox-autosync.status"
LOG_DIR="/app/working/workspaces/default/orebit-ops/docs/audits/sync"
LOG_FILE="${LOG_DIR}/obsidian-inbox-autosync-$(date +%Y%m%dT%H%M%SZ).log"

mkdir -p "$LOG_DIR"

log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG_FILE"; }

# HARDENING: Always check we're only syncing 0. Inbox
check_scope() {
    if [[ "$LOCAL_VAULT" != *"/obsidian-system/vault"* ]]; then
        log "FATAL: Vault path not recognized: $LOCAL_VAULT"
        exit 1
    fi
    log "SCOPE VERIFIED: Only syncing '$INBOX_DIR'"
}

# Lock to prevent overlapping sync cycles while allowing the daemon to stay alive.
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

# HARDENING filter: EXPLICITLY block all folders except 0. Inbox
do_sync() {
    local src=$1; local dst=$2; local label=$3

    log "=== Sync $label: $src → $dst ==="

    # HARDENED: Only pass 0. Inbox, explicitly exclude everything else
    rclone copy "$src" "$dst" \
        --verbose \
        --fast-list \
        --exclude ".git/**" \
        --exclude ".trash/**" \
        --exclude "*.tmp" \
        --exclude "*.swp" \
        --exclude "/1. Projects/**" \
        --exclude "/2. Areas/**" \
        --exclude "/3. Resources/**" \
        --exclude "/4. Archive/**" \
        --exclude "/4. Archives/**" \
        --exclude "/Attachments/**" \
        --exclude "/Templates/**" \
        --exclude ".obsidian/**" \
        --progress 2>&1 | tee -a "$LOG_FILE"

    log "Sync $label complete."
}

run() {
    check_scope
    acquire_lock

    trap release_lock EXIT

    log "START autosync cycle (PID $$)"

    # Sync: Drive -> Local uses the service-account remote for reliable reads.
    do_sync "${READ_REMOTE}:/${INBOX_DIR}" "${LOCAL_VAULT}/${INBOX_DIR}" "GDrive->Local"

    # Sync: Local -> Drive uses the OAuth remote for write capability.
    do_sync "${LOCAL_VAULT}/${INBOX_DIR}" "${WRITE_REMOTE}:/${INBOX_DIR}" "Local->GDrive"

    log "END autosync cycle OK"

    # Write status
    echo "OK|$(date -Iseconds)|$$" > "$DAEMON_STATUS"
}

# Run once (used by daemon loop)
run
