#!/bin/bash
# Runtime Audit - NO LLM
LOG="/tmp/orebit-audit.log"
echo "=== $(date -Iseconds) ===" >> "$LOG"
echo "QwenPaw: $(curl -s --max-time 3 http://127.0.0.1:8088/ | head -c 50)" >> "$LOG"
echo "Embedding: $(curl -s --max-time 3 http://127.0.0.1:3005/health | head -c 120)" >> "$LOG"
echo "Wrapper: $(curl -s --max-time 3 http://127.0.0.1:3004/api/rag/health | head -c 120)" >> "$LOG"
echo "rcloneOAuth: $(rclone about gdrive-obsidian-oauth: 2>&1 | head -c 50)" >> "$LOG"
echo "---" >> "$LOG"
