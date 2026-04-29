#!/bin/bash
# rclone Google Drive OAuth Token Watchdog
# Ensures OAuth token stays valid by periodically triggering rclone operations
# Runs every 30 minutes via OS crontab (not qwenpaw cron = no LLM calls)

LOG_FILE="/tmp/rclone-token-watchdog.log"
CONFIG_FILE="/root/.config/rclone/rclone.conf"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check token expiry from rclone.conf
get_token_expiry() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "NO_CONFIG"
        return
    fi
    local expiry=$(grep -A1 '\[gdrive-obsidian-oauth\]' "$CONFIG_FILE" | grep expiry | sed 's/.*"expiry":"\([^"]*\)".*/\1/')
    echo "$expiry"
}

# Force token refresh by running a simple rclone operation
trigger_refresh() {
    log "Triggering token refresh..."
    local result=$(rclone about gdrive-obsidian-oauth: 2>&1)
    if [[ $? -eq 0 ]]; then
        log "✅ Token still valid, rclone about OK"
        return 0
    else
        log "❌ Token refresh failed: $result"
        return 1
    fi
}

# Test write capability (lightweight test)
test_write() {
    local test_file="/tmp/rclone-token-test-$(date +%s).tmp"
    echo "watchdog $(date)" > "$test_file"
    local dest="gdrive-obsidian-oauth:0. Inbox/.watchdog-token-test"
    if rclone copy "$test_file" "$dest" 2>/dev/null; then
        rclone delete "$dest" 2>/dev/null
        rm -f "$test_file"
        log "✅ Write test PASSED"
        return 0
    else
        rm -f "$test_file"
        log "❌ Write test FAILED - token may be expired"
        return 1
    fi
}

# Main
log "=== Token watchdog started ==="
expiry=$(get_token_expiry)
log "Current token expiry: $expiry"

# Always trigger a refresh to keep token alive
if trigger_refresh; then
    test_write
else
    log "⚠️ Token refresh issue detected!"
fi

log "=== Token watchdog finished ==="
