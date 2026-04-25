# Obsidian Inbox Autosync — Runbook

## Overview
Automated bidirectional sync between local Obsidian vault `0. Inbox` and Google Drive `gdrive-obsidian:0. Inbox`. Uses copy-merge strategy (no deletes).

## HARDENING RULE
**ONLY `0. Inbox` is synced. All other folders are permanently blocked:**
- `1. Projects` — BLOCKED
- `2. Areas` — BLOCKED
- `3. Resources` — BLOCKED
- `4. Archive` / `4. Archives` — BLOCKED
- `Attachments` — BLOCKED
- `Templates` — BLOCKED
- `.obsidian` — BLOCKED

This is enforced at the rclone level (--exclude flags).

## Architecture
```
autosync-daemon (runs every 300s)
  └── autosync-obsidian-inbox-copy-merge.sh
        ├── rclone copy gdrive-obsidian:0. Inbox → local 0. Inbox
        └── rclone copy local 0. Inbox → gdrive-obsidian:0. Inbox
```

## Commands

### Start daemon
```bash
cd /app/working/workspaces/default/orebit-rag-deploy
bash ops/scripts/sync/start-obsidian-inbox-autosync.sh
```

### Stop daemon
```bash
bash ops/scripts/sync/stop-obsidian-inbox-autosync.sh
```

### Check status
```bash
bash ops/scripts/sync/status-obsidian-inbox-autosync.sh
```

### Run once manually (no daemon)
```bash
bash ops/scripts/sync/autosync-obsidian-inbox-copy-merge.sh
```

### Run watchdog (auto-restart if dead)
```bash
bash ops/scripts/sync/watchdog-obsidian-inbox-autosync.sh
```

## Files
- Daemon lock: `/tmp/obsidian-inbox-autosync.lock`
- Daemon PID: `/tmp/obsidian-inbox-autosync.pid`
- Status file: `/tmp/obsidian-inbox-autosync.status`
- Watchdog log: `/tmp/obsidian-inbox-autosync-watchdog.status`
- Audit logs: `docs/audits/sync/obsidian-inbox-autosync-*.log`

## Cron watchdog (recommended)
```bash
*/5 * * * * cd /app/working/workspaces/default/orebit-rag-deploy && bash ops/scripts/sync/watchdog-obsidian-inbox-autosync.sh
```

## Troubleshooting
- **Daemon not running**: `bash ops/scripts/sync/start-obsidian-inbox-autosync.sh`
- **Sync stuck**: `bash ops/scripts/sync/stop-obsidian-inbox-autosync.sh && bash ops/scripts/sync/start-obsidian-inbox-autosync.sh`
- **rclone not found**: Ensure rclone is in PATH or use full path
- **Permission denied**: Check vault path `/workspace/obsidian-system/vault`
