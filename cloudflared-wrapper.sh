#!/bin/bash
# ===========================================================
# CLOUDFLARED WRAPPER - Auto-restart without systemd
# ===========================================================

CLOUDFLARED_BIN="${CLOUDFLARED_BIN:-/usr/local/bin/cloudflared}"
TUNNEL_URL="${TUNNEL_URL:-http://127.0.0.1:3004}"
WRAPPER_PID_FILE="${WRAPPER_PID_FILE:-/tmp/cloudflared-wrapper.pid}"
CHILD_PID_FILE="${CHILD_PID_FILE:-/tmp/cloudflared.pid}"
LOG_FILE="${LOG_FILE:-/tmp/cloudflared-wrapper.log}"
MAX_RESTARTS="${MAX_RESTARTS:-100}"
RESTART_DELAY="${RESTART_DELAY:-10}"

mkdir -p "$(dirname "$LOG_FILE")"
echo $$ > "$WRAPPER_PID_FILE"

cleanup() {
    echo "[$(date)] Stopping Cloudflare Tunnel wrapper..." | tee -a "$LOG_FILE"
    if [ -f "$CHILD_PID_FILE" ]; then
        CHILD_PID="$(cat "$CHILD_PID_FILE")"
        kill "$CHILD_PID" 2>/dev/null || true
        rm -f "$CHILD_PID_FILE"
    fi
    rm -f "$WRAPPER_PID_FILE"
}
trap cleanup INT TERM EXIT

echo "[$(date)] Starting Cloudflare Tunnel wrapper (PID $$)..." | tee -a "$LOG_FILE"
echo "[$(date)] Tunnel target: $TUNNEL_URL" | tee -a "$LOG_FILE"

restart_count=0

while [ "$restart_count" -lt "$MAX_RESTARTS" ]; do
    echo "[$(date)] Starting cloudflared (attempt $((restart_count + 1)))" | tee -a "$LOG_FILE"

    "$CLOUDFLARED_BIN" tunnel --url "$TUNNEL_URL" >> "$LOG_FILE" 2>&1 &
    CHILD_PID=$!
    echo "$CHILD_PID" > "$CHILD_PID_FILE"

    echo "[$(date)] Cloudflare Tunnel started with PID $CHILD_PID" | tee -a "$LOG_FILE"

    wait "$CHILD_PID"
    EXIT_CODE=$?
    rm -f "$CHILD_PID_FILE"

    echo "[$(date)] Cloudflare Tunnel stopped with exit code $EXIT_CODE" | tee -a "$LOG_FILE"

    if [ "$EXIT_CODE" -eq 0 ]; then
        echo "[$(date)] Cloudflare Tunnel exited normally, not restarting" | tee -a "$LOG_FILE"
        break
    fi

    restart_count=$((restart_count + 1))

    if [ "$restart_count" -ge "$MAX_RESTARTS" ]; then
        echo "[$(date)] Reached max restarts ($MAX_RESTARTS), stopping" | tee -a "$LOG_FILE"
        break
    fi

    echo "[$(date)] Restarting in ${RESTART_DELAY}s..." | tee -a "$LOG_FILE"
    sleep "$RESTART_DELAY"
done

echo "[$(date)] Cloudflare Tunnel wrapper stopped" | tee -a "$LOG_FILE"
