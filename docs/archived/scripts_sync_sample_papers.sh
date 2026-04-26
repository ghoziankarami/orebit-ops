#!/usr/bin/env bash
set -euo pipefail

REMOTE="gdrive-research:"
LOCAL_DIR="/workspace/research-data/papers-cache"
LIMIT="${1:-12}"

mkdir -p "$LOCAL_DIR"

mapfile -t FILES < <(rclone lsf "$REMOTE" --files-only --include '*.pdf' | sed -n "1,${LIMIT}p")

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No PDF files found in $REMOTE"
  exit 1
fi

for file in "${FILES[@]}"; do
  echo "Copying: $file"
  rclone copyto "${REMOTE}${file}" "$LOCAL_DIR/$file"
done
