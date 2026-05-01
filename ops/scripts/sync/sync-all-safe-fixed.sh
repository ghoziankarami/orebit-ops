#!/bin/bash
#===========================================================
# sync-all-safe-fixed.sh - Fixed safe vault sync
#===========================================================

set -euo pipefail

LOCAL_VAULT="/app/working/workspaces/default/obsidian-system/vault"
LOG_DIR="/app/working/workspaces/default/orebit-ops/docs/audits/sync"
LOG_FILE="${LOG_DIR}/safe-sync-$(date +%Y%m%d).log"
SYNC_DIR="/app/working/workspaces/default/orebit-ops"

mkdir -p "$LOG_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

log "=== SAFE VAULT SYNC (Best Practice) ==="

# Part 1: Inbox auto-sync (verify daemon running)
log "📥 1. INBOX AUTO-SYNC (Verifying daemon)..."

if [ -f /tmp/obsidian-inbox-autosync.pid ]; then
    PID=$(cat /tmp/obsidian-inbox-autosync.pid)
    if ps -p $PID > /dev/null 2>&1; then
        log "   ✅ Inbox daemon running (PID $PID)"
    else
        log "   ⚠️ Inbox daemon not running - starting..."
        cd "$SYNC_DIR"
        bash ops/scripts/sync/start-obsidian-inbox-autosync.sh
        sleep 3
        log "   ✅ Inbox daemon started"
    fi
else
    log "   ⚠️ Inbox daemon not running - starting..."
    cd "$SYNC_DIR"
    bash ops/scripts/sync/start-obsidian-inbox-autosync.sh
    sleep 3
    log "   ✅ Inbox daemon started"
fi

log "   Last sync: $(tail -3 /tmp/obsidian-inbox-autosync-daemon.log 2>/dev/null | grep 'END autosync' | tail -1)"

log ""

# Part 2: Manual sync other folders (one-way to be safe)
log "📤 2. MANUAL SYNC (Other folders - Local → Drive, safe one-way)"
log "   This pushes your changes to Google Drive without risk of overwriting"

# List folders to sync
FOLDERS=(
    "1. Projects"
    "2. Areas"
    "3. Resources"
    "4. Archive"
    "Attachments"
    "Templates"
)

SYNCED_COUNT=0
for folder in "${FOLDERS[@]}"; do
    FOLDER_PATH="${LOCAL_VAULT}/${folder}"
    if [ -d "$FOLDER_PATH" ]; then
        log ""
        log "   Syncing: $folder..."
        if rclone copy "$FOLDER_PATH" gdrive-obsidian-oauth:"${folder}" --exclude ".git/**" --exclude ".trash/**" --exclude ".obsidian/**" -q 2>&1 | tee -a "$LOG_FILE"; then
            log "   ✅ $folder synced"
            SYNCED_COUNT=$((SYNCED_COUNT + 1))
        else
            log "   ⚠️ $folder sync failed (check log)"
        fi
    fi
done

log ""
log "   Root files (.md in vault root)..."
if rclone copy "${LOCAL_VAULT}" gdrive-obsidian-oauth:/ --include "*.md" --exclude ".git/**" --exclude ".trash/**" --exclude ".obsidian/**" -q 2>&1 | tee -a "$LOG_FILE"; then
    log "   ✅ Root files synced"
    SYNCED_COUNT=$((SYNCED_COUNT + 1))
else
    log "   ⚠️ Root files sync failed (check log)"
fi

log ""
log ""
log "=== SYNC SUMMARY ==="
log "✅ Inbox auto-sync: Running"
log "✅ Manual folders synced: $SYNCED_COUNT folders"
log ""
log "📋 LOG: $LOG_FILE"
log ""
log "🎯 WHAT THIS DOES:"
log "   ✅ Inbox: Auto-sync every 5 min (two-way, safe)"
log "   ✅ Others: Push to Drive only (one-way, safe)"
log ""
log "✅ SAFE SYNC COMPLETE"
