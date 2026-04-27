# Obsidian Inbox Autosync — Runbook

## Overview

Automated inbox sync is limited to `0. Inbox` only.
This is now a guarded but working workflow using split remotes: service account for read and OAuth for write.

## Hardening rule

Only `0. Inbox` is sync-eligible by default.
All other folders are treated as manual-only.

Blocked by policy:

- `1. Projects`
- `2. Areas`
- `3. Resources`
- `4. Archive`
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

## Remote roles

- `gdrive-obsidian` = service-account read remote
- `gdrive-obsidian-oauth` = OAuth write remote
- the autosync daemon pulls from the read remote and pushes to the write remote

## Scheduling model

This runtime currently uses QwenPaw cron plus the local autosync daemon, not OS `crontab`.
The active cron job is the watchdog that restarts the daemon if it dies.

## Current caution

Inbox-only remains the automation boundary.
Do not broaden autosync beyond `0. Inbox` unless the operational docs are updated first.

## Files

- Daemon lock: `/tmp/obsidian-inbox-autosync.lock`
- Daemon PID: `/tmp/obsidian-inbox-autosync.pid`
- Status file: `/tmp/obsidian-inbox-autosync.status`
- Watchdog log: `/tmp/obsidian-inbox-autosync-watchdog.status`
- Audit logs: `docs/audits/sync/obsidian-inbox-autosync-*.log`
