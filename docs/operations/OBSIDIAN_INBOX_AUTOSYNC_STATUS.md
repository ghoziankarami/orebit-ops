# Obsidian Inbox Autosync — Status

## Last Update
<!-- auto-updated by watchdog heartbeat -->
Last check: 2026-04-27T03:28:43+00:00

## Daemon Status
- PID: 723138
- Status: RUNNING
- Interval: 300 seconds (5 minutes)
- Scope: ONLY `0. Inbox` (all other folders HARDENED/blocked)

## Sync Direction
- Local ↔ Google Drive (bidirectional copy-merge, no deletes)
- Read remote: `gdrive-obsidian:0. Inbox`
- Write remote: `gdrive-obsidian-oauth:0. Inbox`
- Local: `/app/working/workspaces/default/obsidian-system/vault/0. Inbox`

## HARDENING
All folders except `0. Inbox` are permanently excluded from sync:
- ❌ `1. Projects`
- ❌ `2. Areas`
- ❌ `3. Resources`
- ❌ `4. Archive`
- ❌ `Attachments`
- ❌ `Templates`
- ❌ `.obsidian`

## Commands
```bash
# Start
bash ops/scripts/sync/start-obsidian-inbox-autosync.sh

# Stop
bash ops/scripts/sync/stop-obsidian-inbox-autosync.sh

# Status
bash ops/scripts/sync/status-obsidian-inbox-autosync.sh

# Watchdog (auto-restart)
bash ops/scripts/sync/watchdog-obsidian-inbox-autosync.sh

# Manual sync (one-shot)
bash ops/scripts/sync/autosync-obsidian-inbox-copy-merge.sh
```
