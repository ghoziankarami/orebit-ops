#!/bin/bash
# Initial sync: Pull entire vault FROM Google Drive (source of truth)
# Run ONCE when setting up new container or after reset
# WARNING: This will overwrite local vault — only run on fresh setup!

set -euo pipefail

LOCAL_VAULT="/app/working/workspaces/default/obsidian-system/vault"
DRIVE_VAULT="gdrive-obsidian:"
LOG_FILE="/tmp/rclone-initial-sync.log"

echo "========================================="
echo "INITIAL VAULT SYNC FROM GOOGLE DRIVE"
echo "Source: Google Drive /Obsidian"
echo "Target: $LOCAL_VAULT"
echo "========================================="
echo ""

# Check if local vault has existing files
if [ -d "$LOCAL_VAULT" ] && [ "$(ls -A "$LOCAL_VAULT" 2>/dev/null | wc -l)" -gt 0 ]; then
    echo "WARNING: Local vault already has files!"
    echo "This will OVERWRITE local files with Drive versions."
    read -p "Continue? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Aborted."
        exit 1
    fi
fi

mkdir -p "$LOCAL_VAULT"

echo "$(date): Starting initial vault pull..."

rclone sync "$DRIVE_VAULT" "$LOCAL_VAULT" \
  --progress \
  --log-file="$LOG_FILE" \
  --log-level=INFO \
  --exclude ".git/**" \
  --exclude ".obsidian/**" \
  --exclude ".locks/**" \
  --exclude "node_modules/**" \
  --exclude ".trash/**"

echo ""
echo "$(date): Initial sync complete!"
echo "Local vault location: $LOCAL_VAULT"
echo ""
echo "Next steps:"
echo "1. Review local vault structure"
echo "2. For ongoing sync, use: sync-inbox-pull.sh (regularly)"
echo "3. For captures, use: sync-inbox-push.sh (after capture)"
