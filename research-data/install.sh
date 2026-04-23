#!/usr/bin/env bash
set -euo pipefail

echo "=== Research Data Setup ==="

NALA_DIR="/workspace/research-data/nala"
OREBIT_DIR="/workspace/research-data/orebit"
PAPERS_DIR="/workspace/research-data/papers-index"

# Verify structure
for dir in "$NALA_DIR" "$OREBIT_DIR" "$PAPERS_DIR"; do
    if [ -d "$dir" ]; then
        echo "OK: $dir"
    else
        echo "MISSING: $dir"
        exit 1
    fi
done

# Check rclone mount
if mount | grep -q gdrive; then
    echo "OK: rclone gdrive mount active"
else
    echo "WARN: rclone gdrive mount not found"
    echo "Run: rclone mount gdrive:AI_Knowledge /mnt/gdrive/AI_Knowledge --daemon"
fi

echo "Research data structure ready"
echo "To restore data content, extract your backup:"
echo "  tar xzf research-backup.tar.gz -C /workspace/"
