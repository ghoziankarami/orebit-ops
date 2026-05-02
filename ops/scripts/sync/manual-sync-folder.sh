#!/bin/bash
#===========================================================
# manual-sync-folder.sh
# Manual sync specific folder to/from Google Drive
#===========================================================

set -euo pipefail

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <folder-name> <direction>"
    echo "  folder-name: 1.Projects, 2.Areas, 3.Resources, 4.Archive, Attachments, Templates, or root (for .md files in vault root)"
    echo "  direction:   drive-to-local, local-to-drive, or two-way"
    echo ""
    echo "Examples:"
    echo "  $0 3.Resources local-to-drive"
    echo "  $0 2.Areas drive-to-local"
    echo "  $0 root two-way"
    exit 1
fi

FOLDER=$1
DIRECTION=$2
LOCAL_VAULT="/app/working/workspaces/default/obsidian-system/vault"
READ_REMOTE="gdrive-obsidian"
WRITE_REMOTE="gdrive-obsidian-oauth"
LOG_DIR="/app/working/workspaces/default/orebit-ops/docs/audits/sync"
LOG_FILE="${LOG_DIR}/manual-sync-${FOLDER//\//-}-$(date +%Y%m%dT%H%M%SZ).log"

mkdir -p "$LOG_DIR"

log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG_FILE"; }

# Resolve folder path
case $FOLDER in
    root)
        SRC_LOCAL="${LOCAL_VAULT}/*.md"
        SRC_DRIVE="${WRITE_REMOTE}:/"
        FILTER="*.md"
        ;;
    *)
        SRC_LOCAL="${LOCAL_VAULT}/${FOLDER}"
        SRC_DRIVE="${WRITE_REMOTE}:${FOLDER}"
        FILTER=""
        ;;
esac

log "=== MANUAL SYNC: $FOLDER ($DIRECTION) ==="
log "Local: $SRC_LOCAL"
log "Drive: $SRC_DRIVE"

case $DIRECTION in
    drive-to-local)
        log "Syncing Drive → Local (one-way)"
        if [ "$FOLDER" = "root" ]; then
            rclone copy "${READ_REMOTE}:/" "$LOCAL_VAULT" --include "*.md" --exclude ".git/**" --exclude ".trash/**" --exclude ".obsidian/**" -v 2>&1 | tee -a "$LOG_FILE"
        else
            rclone copy "${READ_REMOTE}:${FOLDER}" "${LOCAL_VAULT}/${FOLDER}" --exclude ".git/**" --exclude ".trash/**" --exclude ".obsidian/**" -v 2>&1 | tee -a "$LOG_FILE"
        fi
        ;;
    local-to-drive)
        log "Syncing Local → Drive (one-way)"
        if [ "$FOLDER" = "root" ]; then
            rclone copy "$LOCAL_VAULT" "$WRITE_REMOTE":/ --include "*.md" --exclude ".git/**" --exclude ".trash/**" --exclude ".obsidian/**" -v 2>&1 | tee -a "$LOG_FILE"
        else
            rclone copy "$LOCAL_VAULT/${FOLDER}" "$WRITE_REMOTE}:${FOLDER}" --exclude ".git/**" --exclude ".trash/**" --exclude ".obsidian/**" -v 2>&1 | tee -a "$LOG_FILE"
        fi
        ;;
    two-way)
        log "Syncing Local ↔ Drive (two-way, dangerous!)"
        read -p "⚠️ Are you sure? This may delete files. Type 'yes' to continue: " confirm
        if [ "$confirm" != "yes" ]; then
            log "Aborted by user"
            exit 0
        fi
        if [ "$FOLDER" = "root" ]; then
            rclone sync "$LOCAL_VAULT" "$WRITE_REMOTE":/ --include "*.md" --exclude ".git/**" --exclude ".trash/**" --exclude ".obsidian/**" -v 2>&1 | tee -a "$LOG_FILE"
        else
            rclone sync "$LOCAL_VAULT}/${FOLDER}" "$WRITE_REMOTE:${FOLDER}" --exclude ".git/**" --exclude ".trash/**" --exclude ".obsidian/**" -v 2>&1 | tee -a "$LOG_FILE"
        fi
        ;;
    *)
        log "ERROR: Invalid direction: $DIRECTION"
        log "Valid directions: drive-to-local, local-to-drive, two-way"
        exit 1
        ;;
esac

log "=== SYNC COMPLETE ==="
log "Log: $LOG_FILE"
