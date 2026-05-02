#!/bin/bash
# ===========================================================
# CLOUDFLARED WRAPPER - Auto-restart without systemd
# ===========================================================

CLOUDFLARED_BIN="/usr/local/bin/cloudflared"
TUNNEL_URL="http://127.0.0.1:3004"
PID_FILE="/tmp/cloudflared-wrapper.pid"
LOG_FILE="/tmp/cloudflared-wrapper.log"
MAX_RESTARTS=100
RESTART_DELAY=10

echo "[$(date)] Starting Cloudflare Tunnel wrapper..." | tee -a "$LOG_FILE"
echo "[$(date)] Tunnel URL: $TUNNEL_URL" | tee -a "$LOG_FILE"

restart_count=0

while [ $restart_count -lt $MAX_RESTARTS ]; do
    echo "[$(date)] Starting cloudflared (attempt $((restart_count + 1)))" | tee -a "$LOG_FILE"
    
    # Start cloudflared
    $CLOUDFLARED_BIN tunnel --url "$TUNNEL_URL" >> "$LOG_FILE" 2>&1 &
    PID=$!
    echo $PID > "$PID_FILE"
    
    echo "[$(date)] Cloudflare Tunnel started with PID $PID" | tee -a "$LOG_FILE"
    
    # Wait for process to finish
    wait $PID
    EXIT_CODE=$?
    
    echo "[$(date)] Cloudflare Tunnel stopped with exit code $EXIT_CODE" | tee -a "$LOG_FILE"
    
    # Check if we should restart
    if [ $EXIT_CODE -eq 0 ]; then
        echo "[$(date)] Cloudflare Tunnel exited normally, not restarting" | tee -a "$LOG_FILE"
        break
    fi
    
    restart_count=$((restart_count + 1))
    
    if [ $restart_count -ge $MAX_RESTARTS ]; then
        echo "[$(date)] Reached max restarts ($MAX_RESTARTS), stopping" | tee -a "$LOG_FILE"
        break
    fi
    
    echo "[$(date)] Restarting in ${RESTART_DELAY}s..." | tee -a "$LOG_FILE"
    sleep $RESTART_DELAY
done

echo "[$(date)] Cloudflare Tunnel wrapper stopped" | tee -a "$LOG_FILE"
