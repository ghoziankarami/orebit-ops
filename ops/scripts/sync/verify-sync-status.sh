#!/bin/bash
# RCLONE SYNC VERIFICATION SCRIPT
# Checks if Google Drive sync is working correctly

LOG="/tmp/rclone-sync-verify.log"
VAULT_DIR="/app/working/workspaces/default/obsidian-system/vault"
REMOTE_OAUTH="gdrive-obsidian-oauth:"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
}

log "=== RCLONE SYNC VERIFICATION START ==="

# Check 1: Token Watchdog Scheduled
log "=== CHECK 1: TOKEN WATCHDOG SCHEDULE ==="
if grep "rclone-token-watchdog" <(crontab -u root -l 2>/dev/null) > /dev/null; then
    log "✅ Token watchdog scheduled in cron"
else
    log "❌ Token watchdog NOT scheduled in cron"
fi

# Check 2: Recent Watchdog Activity
if grep "$(date '+%Y-%m-%d')" /tmp/rclone-token-watchdog.log | grep "PASSED" > /dev/null; then
    log "✅ Token watchdog ran successfully today"
else
    log "⚠️ Token watchdog not executed successfully today"
fi

# Check 3: Autosync Daemon
log "=== CHECK 3: AUTOSYNC DAEMON ==="
if [ -f /tmp/obsidian-inbox-autosync.pid ]; then
    PID=$(cat /tmp/obsidian-inbox-autosync.pid)
    if kill -0 "$PID" 2>/dev/null; then
        log "✅ Autosync daemon running (PID $PID)"
    else
        log "❌ Autosync daemon not running"
    fi
else
    log "❌ Autosync daemon PID not found"
fi

# Check 4: Last Sync
log "=== CHECK 4: LAST SYNC ==="
LAST_SYNC=$(tail -5 /tmp/obsidian-inbox-autosync-daemon.log | grep "END autosync" | tail -1)
log "Last sync: ${LAST_SYNC:0:100}"

# Check 5: Token Validity
log "=== CHECK 5: TOKEN STATUS ==="
TOKEN_STATUS=$(rclone about "$REMOTE_OAUTH" 2>&1 | head -c 50)
log "Token: $TOKEN_STATUS"

# Check 6: File Count
log "=== CHECK 6: FILE COUNT (0 Inbox) ==="
LOCAL_COUNT=$(find "${VAULT_DIR}/0. Inbox" -name "*.md" 2>/dev/null | wc -l)
REMOTE_COUNT=$(rclone ls "${REMOTE_OAUTH}0. Inbox" 2>/dev/null | wc -l)
log "Local: $LOCAL_COUNT, Remote: $REMOTE_COUNT"

# Check 7: Write Test
log "=== CHECK 7: WRITE TEST ==="
TEST_FILE="/tmp/test-$(date +%s).txt"
echo "test" > "$TEST_FILE"
TEST_DEST="${REMOTE_OAUTH}0. Inbox/.test.txt"
if rclone copy "$TEST_FILE" "$TEST_DEST" 2>/dev/null; then
    rclone delete "$TEST_DEST" 2>/dev/null
    log "✅ Write test PASSED"
    rm -f "$TEST_FILE"
else
    log "❌ Write test FAILED"
    rm -f "$TEST_FILE"
fi

log "=== VERIFICATION COMPLETE ==="
