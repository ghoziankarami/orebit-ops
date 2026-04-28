#!/bin/bash
# ensure-yt-dlp.sh — Auto-install yt-dlp if missing
# Run before any YouTube extract task

if ! command -v yt-dlp &>/dev/null; then
    echo "[ensure-yt-dlp] yt-dlp not found. Installing..."
    pip install yt-dlp 2>&1 | tail -1
    echo "[ensure-yt-dlp] Done."
else
    echo "[ensure-yt-dlp] yt-dlp $(yt-dlp --version 2>/dev/null) already available at $(which yt-dlp)"
fi
