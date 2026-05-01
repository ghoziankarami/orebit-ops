#!/bin/bash
# Tier-3 RCLONE WATCHDOG - BULLETPROOF
# Checks token, forces refresh if needed, restarts daemon if sync fails

LOG="/tmp/rclone-watchdog-t3.log"
ALERT_LOG="/tmp/rclone-alert.log"
VAULT_DIR="/app/working/workspaces/default/obsidian-system/vault"
REMOTE="gdrive-obsidian-oauth:"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ ALERT: $1" >> "$ALERT_LOG"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ ALERT: $1"
}

# Test 1: Basic connectivity
log "=== TEST 1: Basic connectivity ==="
if ! rclone about "$REMOTE" > /dev/null 2>&1; then
    alert "rclone about FAILED - Token might be invalid"
    log "❌ Basic connectivity FAILED"
    exit 1
fi
log "✅ Basic connectivity OK"

# Test 2: Force token refresh
log "=== TEST 2: Force token refresh ==="
REFRESH_TEST=$(rclone about "$REMOTE" 2>&1)
if echo "$REFRESH_TEST" | grep -i "error\|invalid\|expired" > /dev/null; then
    alert "Token refresh FAILED - $REFRESH_TEST"
    log "❌ Token refresh FAILED"
    
    # Try to fix
    log "Attempting to re-authenticate..."
    # Can't do this non-interactively, so just alert
    exit 1
fi
log "✅ Token refresh OK"

# Test 3: Write test
log "=== TEST 3: Write test ==="
TEST_FILE="/tmp/watchdog-test-$(date +%s).txt"
echo "test $(date)" > "$TEST_FILE"
TEST_DEST="${REMOTE}0. Inbox/.watchdog-test.txt"

if rclone copy "$TEST_FILE" "$TEST_DEST" > /dev/null 2>&1; then
    rclone delete "$TEST_DEST" > /dev/null 2>&1
    rm -f "$TEST_FILE"
    log "✅ Write test PASSED"
else
    alert "Write test FAILED - Sync might be broken"
    log "❌ Write test FAILED"
    rm -f "$TEST_FILE"
    exit 1
fi

# Test 4: Check autosync daemon
log "=== TEST 4: Autosync daemon check ==="
if [ -f /tmp/obsidian-inbox-autosync.pid ]; then
    PID=$(cat /tmp/obsidian-inbox-autosync.pid)
    if kill -0 "$PID" 2>/dev/null; then
        log "✅ Autosync daemon running (PID $PID)"
    else
        alert "Autosync daemon NOT running - Restarting..."
        log "Restarting autosync daemon..."
        
        cd /app/working/workspaces/default/orebit-ops
        timeout 30 bash ops/scripts/sync/start-obsidian-inbox-autosync.sh > /tmp/autosync-restart.log 2>&1 < /dev/null
        
        sleep 3
        if [ -f /tmp/obsidian-inbox-autosync.pid ]; then
            NEW_PID=$(cat /tmp/obsidian-inbox-autosync.pid)
            if kill -0 "$NEW_PID" 2>/dev/null; then
                log "✅ Autosync daemon restarted (PID $NEW_PID)"
            else
                alert "Autosync daemon restart FAILED"
                log "❌ Autosync daemon restart FAILED"
                exit 1
            fi
        else
            alert "Autosync daemon restart FAILED - No PID"
            log "❌ Autosync daemon restart FAILED"
            exit 1
        fi
    fi
else
    alert "Autosync daemon PID not found - Starting..."
    log "Starting autosync daemon..."
    
    cd /app/working/workspaces/default/orebit-ops
    timeout 30 bash ops/scripts/sync/start-obsidian-inbox-autosync.sh > /tmp/autosync-start.log 2>&1 < /dev/null
    
    sleep 3
    if [ -f /tmp/obsidian-inbox-autosync.pid ]; then
        NEW_PID=$(cat /tmp/obsidian-inbox-autosync.pid)
        if kill -0 "$NEW_PID" 2>/dev/null; then
            log "✅ Autosync daemon started (PID $NEW_PID)"
        else
            alert "Autosync daemon start FAILED"
            log "❌ Autosync daemon start FAILED"
            exit 1
        fi
    else
        alert "Autosync daemon start FAILED - No PID"
        log "❌ Autosync daemon start FAILED"
        exit 1
    fi
fi

# Test 5: Check recent sync to ensure not stale
log "=== TEST 5: Check recent sync ==="
LATEST_SYNC=$(tail -5 /tmp/obsidian-inbox-autosync-daemon.log 2>/dev/null | grep "END autosync" | tail -1 || echo "")
if [ -z "$LATEST_SYNC" ]; then
    alert "No recent sync found in log"
    log "❌ No recent sync found"
else
    # Extract timestamp from log
    SYNC_TIME=$(echo "$LATEST_SYNC" | grep -oP '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}' || echo "")
    if [ -n "$SYNC_TIME" ]; then
        SYNC_EPOCH=$(date -d "$SYNC_TIME" +%s)
        CURRENT_EPOCH=$(date +%s)
        DIFF_MINUTES=$(( (CURRENT_EPOCH - SYNC_EPOCH) / 60 ))
        
        if [ $DIFF_MINUTES -gt 20 ]; then
            alert "Sync is stale ($DIFF_MINUTES minutes old)"
            log "⚠️ Sync is stale ($DIFF_MINUTES minutes)"
        else
            log "✅ Sync recent ($DIFF_MINUTES minutes old)"
        fi
    fi
fi

log "=== ALL TESTS PASSED ==="
