#!/bin/bash
# push-obsidian-inbox-copy-only.sh
# Push-only sync: local 0. Inbox → Google Drive (no pull)
# SAFE: only touches 0. Inbox, all other folders blocked
set -euo pipefail

REMOTE="gdrive-obsidian"
LOCAL_VAULT="${VAULT_PATH:-/app/working/workspaces/default/obsidian-system/vault}"
INBOX_DIR="0. Inbox"
LOG_DIR="/app/working/workspaces/default/orebit-ops/docs/audits/sync"

mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/obsidian-inbox-push-$(date +%Y%m%dT%H%M%SZ).log"

log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG_FILE"; }

log "PUSH-ONLY: ${LOCAL_VAULT}/${INBOX_DIR} → ${REMOTE}:/${INBOX_DIR}"

rclone copy "${LOCAL_VAULT}/${INBOX_DIR}" "${REMOTE}:/${INBOX_DIR}" \
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
    2>&1 | tee -a "$LOG_FILE"

log "PUSH-ONLY complete."
