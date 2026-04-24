#!/usr/bin/env bash
set -euo pipefail

echo "=== Obsidian System Setup ==="

VAULT_DIR="/workspace/obsidian-system/vault"
OBSIDIAN_DIR="/workspace/obsidian-system/.obsidian"

# Create vault structure explicitly to avoid shell-specific brace bugs
mkdir -p "$VAULT_DIR/0. Inbox"
mkdir -p "$VAULT_DIR/1. Projects"
mkdir -p "$VAULT_DIR/2. Areas"
mkdir -p "$VAULT_DIR/3. Resources"
mkdir -p "$VAULT_DIR/4. Archive"
mkdir -p "$VAULT_DIR/.obsidian"

# Keep a predictable top-level .obsidian symlink if it does not already exist
if [ ! -e "$OBSIDIAN_DIR" ]; then
    ln -s "$VAULT_DIR/.obsidian" "$OBSIDIAN_DIR"
fi

echo "Obsidian vault structure ready at $VAULT_DIR"
echo "To restore vault content, extract your backup:"
echo "  tar xzf obsidian-backup.tar.gz -C /workspace/obsidian-system/"
