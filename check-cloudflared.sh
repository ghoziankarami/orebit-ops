#!/bin/bash
# ===========================================================
# CLOUDFLARED HEALTH CHECK & RESTART (Cron Job Friendly)
# ===========================================================

CLOUDFLARED_BIN="${CLOUDFLARED_BIN:-/usr/local/bin/cloudflared}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER_SCRIPT="${WRAPPER_SCRIPT:-${SCRIPT_DIR}/cloudflared-wrapper.sh}"
API_URL="${API_URL:-http://127.0.0.1:3004/api/rag/health}"
WRAPPER_PID_FILE="${WRAPPER_PID_FILE:-/tmp/cloudflared-wrapper.pid}"
CHILD_PID_FILE="${CHILD_PID_FILE:-/tmp/cloudflared.pid}"
RESTART_LOG="${RESTART_LOG:-/tmp/cloudflared-restart.log}"

echo "[$(date)] Starting cloudflared health check..." >> "$RESTART_LOG"

# Check if wrapper script is running
WRAPPER_RUNNING=0
if [ -f "$WRAPPER_PID_FILE" ]; then
    WRAPPER_PID=$(cat "$WRAPPER_PID_FILE")
    if ps -p "$WRAPPER_PID" > /dev/null 2>&1; then
        WRAPPER_RUNNING=1
        echo "[$(date)] ✅ Wrapper running (PID $WRAPPER_PID)" >> "$RESTART_LOG"
    else
        echo "[$(date)] Wrapper PID file exists but process not running" >> "$RESTART_LOG"
        rm -f "$WRAPPER_PID_FILE"
    fi
else
    echo "[$(date)] No wrapper PID file found" >> "$RESTART_LOG"
fi

# Fallback: check wrapper process by name
if [ "$WRAPPER_RUNNING" -eq 0 ]; then
    WRAPPER_PS=$(pgrep -f "bash .*cloudflared-wrapper.sh|/cloudflared-wrapper.sh" | wc -l)
    if [ "$WRAPPER_PS" -eq 0 ]; then
        echo "[$(date)] ❌ Wrapper not running, starting..." >> "$RESTART_LOG"
        nohup bash "$WRAPPER_SCRIPT" > /dev/null 2>&1 &
        echo "[$(date)] ✅ Wrapper started" >> "$RESTART_LOG"
        exit 0
    fi
fi

# Check if cloudflared process is running
CLOUDFLARED_PS=$(pgrep -f "cloudflared tunnel --url" | wc -l)
if [ "$CLOUDFLARED_PS" -eq 0 ]; then
    echo "[$(date)] ❌ Cloudflared not running, restarting wrapper..." >> "$RESTART_LOG"
    pkill -f "cloudflared-wrapper.sh" 2>/dev/null || true
    rm -f "$WRAPPER_PID_FILE" "$CHILD_PID_FILE"
    sleep 2
    nohup bash "$WRAPPER_SCRIPT" > /dev/null 2>&1 &
    echo "[$(date)] ✅ Wrapper restarted" >> "$RESTART_LOG"
    exit 0
else
    echo "[$(date)] ✅ Cloudflared running ($CLOUDFLARED_PS process(es))" >> "$RESTART_LOG"
fi

# Test API endpoint
API_STATUS=$(curl -s "$API_URL" 2>&1)
if echo "$API_STATUS" | grep -q "healthy"; then
    echo "[$(date)] ✅ API healthy" >> "$RESTART_LOG"
else
    echo "[$(date)] ❌ API not healthy, restarting wrapper..." >> "$RESTART_LOG"
    pkill -f "cloudflared-wrapper.sh" 2>/dev/null || true
    pkill -f "cloudflared tunnel --url" 2>/dev/null || true
    rm -f "$WRAPPER_PID_FILE" "$CHILD_PID_FILE"
    sleep 2
    nohup bash "$WRAPPER_SCRIPT" > /dev/null 2>&1 &
    echo "[$(date)] ✅ Wrapper restarted" >> "$RESTART_LOG"
fi

echo "[$(date)] Health check complete" >> "$RESTART_LOG"
echo "---" >> "$RESTART_LOG"
