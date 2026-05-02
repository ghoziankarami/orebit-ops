#!/bin/bash
# ===========================================================
# CLOUDFLARED HEALTH CHECK & RESTART (Cron Job Friendly)
# ===========================================================

CLOUDFLARED_BIN="/usr/local/bin/cloudflared"
WRAPPER_SCRIPT="/app/working/workspaces/default/orebit-ops/cloudflared-wrapper.sh"
API_URL="http://127.0.0.1:3004/api/rag/health"
TUNNEL_PID_FILE="/tmp/cloudflared-wrapper.pid"
RESTART_LOG="/tmp/cloudflared-restart.log"

echo "[$(date)] Starting cloudflared health check..." >> "$RESTART_LOG"

# Check if wrapper script is running
if [ -f "$TUNNEL_PID_FILE" ]; then
    WRAPPER_PID=$(cat "$TUNNEL_PID_FILE")
    if ps -p "$WRAPPER_PID" > /dev/null 2>&1; then
        echo "[$(date)] Wrapper running (PID $WRAPPER_PID)" >> "$RESTART_LOG"
    else
        echo "[$(date)] Wrapper PID file exists but process not running" >> "$RESTART_LOG"
        rm -f "$TUNNEL_PID_FILE"
    fi
else
    echo "[$(date)] No wrapper PID file found" >> "$RESTART_LOG"
fi

# Check wrapper process by name
WRAPPER_PS=$(ps aux | grep "cloudflared-wrapper" | grep -v grep | wc -l)
if [ "$WRAPPER_PS" -eq 0 ]; then
    echo "[$(date)] ❌ Wrapper not running, starting..." >> "$RESTART_LOG"
    nohup bash "$WRAPPER_SCRIPT" > /dev/null 2>&1 &
    echo "[$(date)] ✅ Wrapper started" >> "$RESTART_LOG"
    exit 0
fi

# Check if cloudflared process is running
CLOUDFLARED_PS=$(ps aux | grep "cloudflared tunnel" | grep -v grep | wc -l)
if [ "$CLOUDFLARED_PS" -eq 0 ]; then
    echo "[$(date)] ❌ Cloudflared not running, checking API..." >> "$RESTART_LOG"
else
    echo "[$(date)] ✅ Cloudflared running ($CLOUDFLARED_PS process(es))" >> "$RESTART_LOG"
fi

# Test API endpoint
API_STATUS=$(curl -s "$API_URL" 2>&1)
if echo "$API_STATUS" | grep -q "healthy"; then
    echo "[$(date)] ✅ API healthy" >> "$RESTART_LOG"
else
    echo "[$(date)] ❌ API not healthy, restarting wrapper..." >> "$RESTART_LOG"
    pkill -f "cloudflared-wrapper" 2>/dev/null
    sleep 2
    nohup bash "$WRAPPER_SCRIPT" > /dev/null 2>&1 &
    echo "[$(date)] ✅ Wrapper restarted" >> "$RESTART_LOG"
fi

echo "[$(date)] Health check complete" >> "$RESTART_LOG"
echo "---" >> "$RESTART_LOG"
