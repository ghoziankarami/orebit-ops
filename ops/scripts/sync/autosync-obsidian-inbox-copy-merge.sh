#!/bin/bash
#===========================================================
# autosync-obsidian-inbox-copy-merge.sh
# HARDENED: ONLY touches 0. Inbox. All other folders BLOCKED.
#===========================================================

set -euo pipefail

REMOTE="gdrive-obsidian"
LOCAL_VAULT="/workspace/obsidian-system/vault"
INBOX_DIR="0. Inbox"
DAEMON_LOCK="/tmp/obsidian-inbox-autosync.lock"
DAEMON_PID="/tmp/obsidian-inbox-autosync.pid"
DAEMON_STATUS="/tmp/obsidian-inbox-autosync.status"
LOG_DIR="/app/working/workspaces/default/orebit-rag-deploy/docs/audits/sync"
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

# Lock to prevent concurrent runs
acquire_lock() {
    if [[ -f "$DAEMON_LOCK" ]]; then
        old_pid=$(cat "$DAEMON_LOCK" 2>/dev/null || echo "")
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            log "Already running (PID $old_pid), skip."
            exit 0
        fi
        log "Stale lock found (PID $old_pid), removing."
        rm -f "$DAEMON_LOCK" "$DAEMON_PID"
    fi
    echo $$ > "$DAEMON_LOCK"
    echo $$ > "$DAEMON_PID"
}

release_lock() {
    rm -f "$DAEMON_LOCK" "$DAEMON_PID"
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

    # Sync: Drive → Local
    do_sync "${REMOTE}:/${INBOX_DIR}" "${LOCAL_VAULT}/${INBOX_DIR}" "GDrive→Local"

    # Sync: Local → Drive (copy-merge, no deletes)
    do_sync "${LOCAL_VAULT}/${INBOX_DIR}" "${REMOTE}:/${INBOX_DIR}" "Local→GDrive"

    log "END autosync cycle OK"

    # Write status
    echo "OK|$(date -Iseconds)|$$" > "$DAEMON_STATUS"
}

# Run once (used by daemon loop)
run
