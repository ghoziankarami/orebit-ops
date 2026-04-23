#!/usr/bin/env bash
set -euo pipefail

echo "=== Obsidian System Setup ==="

VAULT_DIR="/workspace/obsidian-system/vault"
OBSIDIAN_DIR="/workspace/obsidian-system/.obsidian"

# Create vault structure if missing
mkdir -p "$VAULT_DIR"/{0.\ Inbox,1.\ Projects,2.\ Areas,3.\ Resources,4.\ Archive}
mkdir -p "$OBSIDIAN_DIR"

# Create symlink for top-level .obsidian access
if [ ! -L "/workspace/obsidian-system/.obsidian" ] && [ ! -d "/workspace/obsidian-system/.obsidian" ]; then
    ln -sf "$VAULT_DIR/.obsidian" "$OBSIDIAN_DIR"
fi

echo "Obsidian vault structure ready at $VAULT_DIR"
echo "To restore vault content, extract your backup:"
echo "  tar xzf obsidian-backup.tar.gz -C /workspace/obsidian-system/"
