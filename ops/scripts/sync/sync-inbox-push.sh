#!/bin/bash
# Push local Inbox captures TO Google Drive
# PARA rule: only 0. Inbox is synced
# Use --update to never overwrite newer files on Drive (protect Windows edits)

set -euo pipefail

LOCAL_INBOX="/app/working/workspaces/default/obsidian-system/vault/0. Inbox"
DRIVE_INBOX="gdrive-obsidian-oauth:/0. Inbox"
LOG_FILE="/tmp/rclone-sync.log"
LOCK_FILE="/tmp/rclone-sync.lock"

# Prevent concurrent runs
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "Sync already running (PID $PID)"
        exit 0
    fi
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

echo "$(date '+%Y-%m-%d %H:%M:%S'): PUSH Inbox to Google Drive..." | tee -a "$LOG_FILE"

# Push local to Drive
# --update = skip files that are newer on Drive (protect Windows edits)
rclone sync "$LOCAL_INBOX" "$DRIVE_INBOX" \
  --update \
  --progress \
  --log-file="$LOG_FILE" \
  --log-level=INFO \
  --exclude ".git/**" \
  --exclude ".obsidian/**" \
  --exclude ".locks/**" \
  --exclude "node_modules/**" \
  --exclude ".trash/**"

echo "$(date '+%Y-%m-%d %H:%M:%S'): PUSH complete" | tee -a "$LOG_FILE"
