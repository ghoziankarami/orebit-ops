#!/bin/bash
# extract-youtube.sh — One-shot YouTube transcript extractor
# Usage: bash extract-youtube.sh <youtube-url> [lang]
# Example: bash extract-youtube.sh https://youtu.be/DbEfS9O5Aq4 id
#
# Flow:
#   1. Ensure yt-dlp is installed
#   2. Download auto-caption (default: id, fallback en)
#   3. Clean + deduplicate VTT → plain text
#   4. Save transcript to vault _resources/
#   5. Print summary (does NOT create Obsidian note — do that manually)

set -euo pipefail

VAULT="/app/working/workspaces/default/obsidian-system/vault"
RES_DIR="$VAULT/3. Resources/Research Notes/_resources"
TMPDIR="/tmp/yt-extract"

URL="${1:-}"
LANG="${2:-id,en}"

if [ -z "$URL" ]; then
    echo "Usage: bash extract-youtube.sh <youtube-url> [lang]"
    echo "Example: bash extract-youtube.sh https://youtu.be/DbEfS9O5Aq4 id"
    exit 1
fi

# Step 1: Ensure yt-dlp
if ! command -v yt-dlp &>/dev/null; then
    echo "[yt-extract] Installing yt-dlp..."
    pip install -q yt-dlp
fi
echo "[yt-extract] yt-dlp $(yt-dlp --version 2>/dev/null) OK"

# Step 2: Setup temp dir
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR" "$RES_DIR"

# Step 3: Get video info
echo "[yt-extract] Getting video info..."
TITLE=$(yt-dlp --print title "$URL" 2>/dev/null || echo "untitled")
VIDEO_ID=$(yt-dlp --print id "$URL" 2>/dev/null || echo "unknown")
echo "  Title: $TITLE"
echo "  ID: $VIDEO_ID"

# Step 4: Download auto-caption
echo "[yt-extract] Downloading subtitle (lang: $LANG)..."
yt-dlp --write-auto-sub --sub-lang "$LANG" --sub-format vtt \
       --skip-download --output "$TMPDIR/%(id)s.%(ext)s" "$URL" 2>&1 | grep -v "^$\|WARNING:\|ERROR: Unable to download video subtitles"

# Find the VTT file
VTT_FILE=$(ls "$TMPDIR"/*.vtt 2>/dev/null | head -1)
if [ -z "$VTT_FILE" ]; then
    echo "[yt-extract] ERROR: No subtitle downloaded. Fallback not available."
    exit 1
fi
echo "[yt-extract] Subtitle saved: $(basename "$VTT_FILE") ($(du -h "$VTT_FILE" | cut -f1))"

# Step 5: Clean transcript
SAFE_TITLE=$(echo "$TITLE" | sed 's/[\/:*?"<>|]/_/g')
OUT_FILE="$RES_DIR/$SAFE_TITLE - Full Transcript.txt"

python3 -c "
from pathlib import Path
import re

vtt = Path('$VTT_FILE').read_text()
lines = vtt.strip().split('\n')

header_done = False
parts = []
for line in lines:
    if not header_done:
        if line.startswith('WEBVTT'): continue
        if line.strip() == '': header_done = True; continue
        continue
    line = line.strip()
    if re.match(r'^\d{2}:\d{2}:\d{2}\.\d+.*-->', line): continue
    if re.match(r'^\d+$', line): continue
    if not line: continue
    cleaned = re.sub(r'<[^>]+>', '', line).strip()
    if cleaned: parts.append(cleaned)

# Deduplicate
seen = set()
unique = [p for p in parts if not (p in seen or seen.add(p))]
full = re.sub(r'\s+', ' ', ' '.join(unique)).strip()

Path('$OUT_FILE').write_text(full)
print(f'Transcript: {len(full):,} chars, ~{len(full.split()):,} words')
"

echo "[yt-extract] Transcript saved to vault:"
echo "  $OUT_FILE"

# Step 6: Clean up temp
rm -rf "$TMPDIR"

echo ""
echo "[yt-extract] Done! Next step: buat Obsidian note dari transcript ini."
echo "  Suggested path: 3. Resources/Research Notes/Video Analysis - $SAFE_TITLE.md"
