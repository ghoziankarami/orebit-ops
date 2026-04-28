#!/bin/bash
# pull-vault-from-drive.sh — Pull Drive edits back to local vault (SAFE)
# 
# Use this when you've edited files directly on Google Drive
# and want those changes reflected in the local Obsidian vault.
#
# Safety: uses --update (only newer files), --dry-run first, then confirm.
#
# Usage:
#   bash pull-vault-from-drive.sh              # preview + confirm
#   bash pull-vault-from-drive.sh --force       # skip confirm

set -euo pipefail

LOCAL_VAULT="/app/working/workspaces/default/obsidian-system/vault"
REMOTE="gdrive-obsidian-oauth:"
LOG_FILE="/tmp/rclone-drive-pull.log"
LOCK_FILE="/tmp/rclone-drive-pull.lock"
FORCE="${2:-}"

echo "============================================"
echo "  DRIVE → LOCAL PULL"
echo "============================================"
echo "Source: Drive ($REMOTE)"
echo "Dest:   $LOCAL_VAULT"
echo "============================================"

# Check lock
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "Pull already running (PID $PID). Abort."
        exit 1
    fi
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# Step 1: Dry-run — show what would change
echo ""
echo "=== DRY RUN: Files that would be updated ==="
DRY_OUTPUT=$(rclone copy "$REMOTE" "$LOCAL_VAULT" \
  --update \
  --dry-run \
  --log-file="$LOG_FILE" \
  --log-level=INFO \
  --exclude ".git/**" \
  --exclude ".obsidian/**" \
  --exclude ".locks/**" \
  --exclude ".trash/**" \
  --exclude "node_modules/**" \
  --exclude ".DS_Store" \
  2>&1 | grep -v "^$" || true)

if [ -z "$DRY_OUTPUT" ]; then
    echo "  (no differences — local is already up to date with Drive)"
    echo ""
    echo "Done."
    exit 0
fi

echo "$DRY_OUTPUT"
echo ""

# Count changes
CHANGE_COUNT=$(echo "$DRY_OUTPUT" | wc -l)
echo "Total changes detected: $CHANGE_COUNT"

# Step 2: Ask confirm (unless --force)
if [ "$FORCE" != "--force" ]; then
    echo ""
    echo "⚠️  WARNING: This will OVERWRITE local files with Drive versions."
    echo "   If there are local changes that haven't been pushed to Drive,"
    echo "   they will be LOST."
    echo ""
    echo "   Safe practice:"
    echo "   1) Push local → Drive FIRST:  bash push-vault-safe.sh"
    echo "   2) THEN pull Drive → local:   bash pull-vault-from-drive.sh"
    echo ""
    read -p "Proceed with pull? (y/N): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Step 3: Real pull
echo ""
echo "=== PULLING Drive → Local ==="
rclone copy "$REMOTE" "$LOCAL_VAULT" \
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

echo ""
echo "=== PULL COMPLETE ==="
echo "Log: $LOG_FILE"
echo ""
echo "Next step: check git status for any vault files tracked in repo"
echo "  git -C /app/working/workspaces/default/orebit-ops status"
