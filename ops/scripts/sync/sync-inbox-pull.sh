#!/bin/bash
# Pull Inbox FROM Google Drive (source of truth) TO local vault
# PARA rule: only 0. Inbox is synced — other folders are local-only
# Run this to get latest captures from Windows/other devices

set -euo pipefail

LOCAL_INBOX="/app/working/workspaces/default/obsidian-system/vault/0. Inbox"
DRIVE_INBOX="gdrive-obsidian:/0. Inbox"
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

echo "$(date '+%Y-%m-%d %H:%M:%S'): PULL Inbox from Google Drive..." | tee -a "$LOG_FILE"

# Pull from Drive (source of truth) to local
# --update = skip files that are newer on local (protect local captures)
rclone sync "$DRIVE_INBOX" "$LOCAL_INBOX" \
  --update \
  --progress \
  --log-file="$LOG_FILE" \
  --log-level=INFO \
  --exclude ".git/**" \
  --exclude ".obsidian/**" \
  --exclude ".locks/**" \
  --exclude "node_modules/**" \
  --exclude ".trash/**"

echo "$(date '+%Y-%m-%d %H:%M:%S'): PULL complete" | tee -a "$LOG_FILE"
