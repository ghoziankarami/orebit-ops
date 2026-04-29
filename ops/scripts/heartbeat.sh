#!/bin/bash
# Orebit Runtime Heartbeat - NO LLM
# Checks system health every 15 minutes via OS crontab

LOG="/tmp/orebit-heartbeat.log"

echo "=== $(date -Iseconds) ===" >> "$LOG"

# QwenPaw health
QwenPaw=$(curl -s --max-time 3 http://127.0.0.1:8088/ | head -c 50)
echo "QwenPaw: $QwenPaw" >> "$LOG"

# Embedding server health
Embedding=$(curl -s --max-time 3 http://127.0.0.1:3005/health | head -c 120)
echo "Embedding: $Embedding" >> "$LOG"

# RAG API health
Wrapper=$(curl -s --max-time 3 http://127.0.0.1:3004/api/rag/health | head -c 120)
echo "Wrapper: $Wrapper" >> "$LOG"

# rclone OAuth status
RcloneOAuth=$(rclone about gdrive-obsidian-oauth: 2>&1 | head -c 50 || echo "ERROR")
echo "rcloneOAuth: $RcloneOAuth" >> "$LOG"

echo "OK" >> "$LOG"
echo "---" >> "$LOG"
