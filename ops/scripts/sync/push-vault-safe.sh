#!/bin/bash
set -euo pipefail

LOCAL_VAULT="/app/working/workspaces/default/obsidian-system/vault"
REMOTE="gdrive-obsidian-oauth:"
LOG_FILE="/tmp/rclone-vault-push.log"
LOCK_FILE="/tmp/rclone-vault-push.lock"

if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "Vault push already running (PID $PID)"
        exit 0
    fi
fi

echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

echo "$(date '+%Y-%m-%d %H:%M:%S'): PUSH full vault to Google Drive (safe copy/update)..." | tee -a "$LOG_FILE"

rclone copy "$LOCAL_VAULT" "$REMOTE" \
  --update \
  --progress \
  --log-file="$LOG_FILE" \
  --log-level=INFO \
  --exclude ".git/**" \
  --exclude ".obsidian/**" \
  --exclude ".locks/**" \
  --exclude ".trash/**" \
  --exclude "node_modules/**" \
  --exclude ".DS_Store"

echo "$(date '+%Y-%m-%d %H:%M:%S'): PUSH full vault complete" | tee -a "$LOG_FILE"
