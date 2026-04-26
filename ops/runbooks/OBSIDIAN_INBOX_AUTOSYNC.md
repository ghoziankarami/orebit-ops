# Obsidian Inbox Autosync — Runbook

## Overview

Automated inbox sync is limited to `0. Inbox` only.
This remains a guarded workflow until OAuth-based rclone write access is finalized.

## Hardening rule

Only `0. Inbox` is sync-eligible by default.
All other folders are treated as manual-only.

Blocked by policy:

- `1. Projects`
- `2. Areas`
- `3. Resources`
- `4. Archive`
- `4. Archives`
- `Attachments`
- `Templates`
- `.obsidian`

## Canonical scripts

- Pull from Drive: `ops/scripts/sync/sync-inbox-pull.sh`
- Push to Drive: `ops/scripts/sync/sync-inbox-push.sh`
- Full initial pull: `ops/scripts/sync/sync-vault-initial-pull.sh`
- Autosync daemon: `ops/scripts/sync/autosync-obsidian-inbox-copy-merge.sh`

## Commands

### Pull inbox manually

```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/sync-inbox-pull.sh
```

### Push inbox manually

```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/sync-inbox-push.sh
```

### Start daemon

```bash
cd /app/working/workspaces/default/orebit-ops
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

### Run watchdog

```bash
bash ops/scripts/sync/watchdog-obsidian-inbox-autosync.sh
```

## Current caution

Do not assume push is safe until rclone write auth is explicitly verified.
Read-side pull and structure verification are the currently trusted paths.

## Files

- Daemon lock: `/tmp/obsidian-inbox-autosync.lock`
- Daemon PID: `/tmp/obsidian-inbox-autosync.pid`
- Status file: `/tmp/obsidian-inbox-autosync.status`
- Watchdog log: `/tmp/obsidian-inbox-autosync-watchdog.status`
- Audit logs: `docs/audits/sync/obsidian-inbox-autosync-*.log`
