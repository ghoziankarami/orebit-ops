#!/usr/bin/env bash
set -euo pipefail

echo "=== Research Data Setup ==="

RUNTIME_ROOT="/workspace/research-data"
NALA_DIR="$RUNTIME_ROOT/nala"
OREBIT_DIR="$RUNTIME_ROOT/orebit"
PAPERS_DIR="$RUNTIME_ROOT/papers-index"
PAPERS_MOUNT="/mnt/gdrive/AI_Knowledge"
OBSIDIAN_PAPERS_DIR="/data/obsidian/3. Resources/Papers"

mkdir -p "$NALA_DIR" "$OREBIT_DIR" "$PAPERS_DIR"
mkdir -p "$OBSIDIAN_PAPERS_DIR"

for dir in "$NALA_DIR" "$OREBIT_DIR" "$PAPERS_DIR"; do
  if [ -d "$dir" ]; then
    echo "OK: $dir"
  else
    echo "ERROR: missing $dir"
    exit 1
  fi
done

if command -v mountpoint >/dev/null 2>&1 && mountpoint -q "$PAPERS_MOUNT"; then
  echo "OK: rclone gdrive mount active at $PAPERS_MOUNT"
elif [ -d "$PAPERS_MOUNT" ]; then
  echo "WARN: $PAPERS_MOUNT exists but is not a confirmed mountpoint"
else
  echo "WARN: rclone gdrive mount not found"
  echo "Run: rclone mount gdrive:AI_Knowledge /mnt/gdrive/AI_Knowledge --daemon"
fi

echo "Research data structure ready"
echo "To restore data content, extract your backup:"
echo "  tar xzf research-backup.tar.gz -C /workspace/"
