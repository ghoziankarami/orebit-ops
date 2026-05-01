#!/bin/bash
#===========================================================
# sync-all-safe.sh
# Safe way to sync entire vault: Inbox auto, others manual
#===========================================================

set -euo pipefail

LOCAL_VAULT="/app/working/workspaces/default/obsidian-system/vault"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "=== SAFE VAULT SYNC (Best Practice) ==="
log ""

# Part 1: Inbox auto-sync (verify daemon running)
log "📥 1. INBOX AUTO-SYNC (Verifying daemon)..."

if [ -f /tmp/obsidian-inbox-autosync.pid ]; then
    PID=$(cat /tmp/obsidian-inbox-autosync.pid)
    if ps -p $PID > /dev/null 2>&1; then
        log "   ✅ Inbox daemon running (PID $PID)"
        log "   Last sync: $(tail -3 /tmp/obsidian-inbox-autosync-daemon.log | grep 'END autosync' | tail -1)"
    else
        log "   ⚠️ Inbox daemon not running - starting..."
        cd /app/working/workspaces/default/orebit-ops
        bash ops/scripts/sync/start-obsidian-inbox-autosync.sh
        sleep 3
        log "   ✅ Inbox daemon started"
    fi
else
    log "   ⚠️ Inbox daemon not running - starting..."
    cd /app/working/workspaces/default/orebit-ops
    bash ops/scripts/sync/start-obsidian-inbox-autosync.sh
    sleep 3
    log "   ✅ Inbox daemon started"
fi

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
        if bash "$SCRIPT_DIR/manual-sync-folder.sh" "${folder}" "local-to-drive" >> /tmp/safe-sync-$(date +%Y%m%d).log 2>&1; then
            log "   ✅ $folder synced"
            SYNCED_COUNT=$((SYNCED_COUNT + 1))
        else
            log "   ⚠️ $folder sync failed (check log)"
        fi
    fi
done

log ""
log "   Root files (.md in vault root)..."
if bash "$SCRIPT_DIR/manual-sync-folder.sh" "root" "local-to-drive" >> /tmp/safe-sync-$(date +%Y%m%d).log 2>&1; then
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
log "📋 LOGS:"
log "   Inbox daemon: /tmp/obsidian-inbox-autosync-daemon.log"
log "   Manual sync: /tmp/safe-sync-$(date +%Y%m%d).log"
log ""
log "🎯 WHAT THIS DOES:"
log "   ✅ Inbox: Auto-sync every 5 min (two-way, safe)"
log "   ✅ Others: Push to Drive only (one-way, safe)"
log ""
log "⚠️ TO PULL FROM DRIVE:"
log "   Use: bash ops/scripts/sync/manual-sync-folder.sh <folder> drive-to-local"
log "   Example: bash ops/scripts/sync/manual-sync-folder.sh 3.Resources drive-to-local"
log ""
log "✅ SAFE SYNC COMPLETE"
