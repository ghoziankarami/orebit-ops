## Rclone Sync - Quick Health Check

Run this one-liner to check system health:

```bash
echo "=== RCLONE SYNC HEALTH CHECK ===" && echo "" && \
echo "$(date '+%Y-%m-%d %H:%M:%S')" && echo "" && \
echo "--- Alerts (should be empty) ---" && \
tail -5 /tmp/rclone-alert.log 2>/dev/null || echo "No alerts ✅" && echo "" && \
echo "--- Watchdog (last 3 checks) ---" && \
tail -15 /tmp/rclone-watchdog-t3.log | grep -E "TEST|PASSED|ALERT" && echo "" && \
echo "--- Autosync Daemon ---" && \
ps aux | grep -v grep | grep obsidian-inbox-autosync | awk '{print "Running: PID " $2 " ✅"}' || echo "NOT RUNNING ❌" && echo "" && \
echo "--- Last Sync ---" && \
tail -3 /tmp/obsidian-inbox-autosync-daemon.log | grep "END autosync" || echo "No recent sync ❌"
```

### Quick Status Codes

| Status | Meaning | Action |
|---|:---:|---|
| ✅ All GREEN | System healthy | Do nothing |
| ⚠️ Stale sync | Sync >20 min old | Check connectivity |
| ❌ Not running | Daemon down | Manual restart |
| ❌ Token failed | OAuth issue | Re-authenticate |

### Manual Commands

```bash
# Run full Tier-3 test
bash /app/working/workspaces/default/orebit-ops/ops/scripts/sync/rclone-token-watchdog-t3.sh

# Run verification
bash /app/working/workspaces/default/orebit-ops/ops/scripts/sync/verify-sync-status.sh

# Restart daemon
pkill -f run-obsidian-inbox-autosync-daemon
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/start-obsidian-inbox-autosync.sh

# Check rclone status
rclone about gdrive-obsidian-oauth:
```
