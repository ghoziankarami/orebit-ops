# Obsidian Sync Backup and Recovery

## Purpose

This runbook documents the minimum recovery surface for Obsidian inbox sync so the setup can be rebuilt without repeating trial-and-error.

## Current model

- `gdrive-obsidian` is the service-account read remote
- `gdrive-obsidian-oauth` is the OAuth write remote
- autosync is limited to `0. Inbox`
- local vault path is `/app/working/workspaces/default/obsidian-system/vault`
- Drive root folder is `1a33hipwORSMZh3pKOMvB4PjMQzvvJFGI`

## Important live config

Sensitive live config is stored outside the repo in:
- `/root/.config/rclone/rclone.conf`
- `/root/.config/rclone/service-account.json`

Do not commit those raw files to Git.

## Automatic backups

The backup script is:
- `ops/scripts/backup/backup-obsidian-sync-state.sh`

It writes timestamped backups under:
- `/app/working/workspaces/default/backups/obsidian-sync/`

Each backup contains:
- sanitized `rclone.conf`
- remote list and remote connectivity checks
- autosync daemon status
- QwenPaw cron job list
- compressed local `0. Inbox` snapshot
- metadata with vault path, remotes, and folder ID

The script keeps the latest 14 backup directories.

## Related operational scripts

- `ops/scripts/sync/push-vault-safe.sh` for guarded full-vault local-to-Drive copy/update
- `ops/scripts/capture/capture-task-note.sh` for writing chat-derived task notes into `0. Inbox/Task Notes/`
- `rag-system/pdf_to_paper_note.py` for PDF text ingest into local RAG plus a draft note in `0. Inbox/Papers/`

## Manual backup command

```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/backup/backup-obsidian-sync-state.sh
```

## Recovery checklist

1. Verify the repo is present at `/app/working/workspaces/default/orebit-ops`
2. Verify the local vault is present at `/app/working/workspaces/default/obsidian-system/vault`
3. Restore or recreate `/root/.config/rclone/rclone.conf`
4. Restore or recreate `/root/.config/rclone/service-account.json`
5. Verify read remote:
   - `rclone lsd gdrive-obsidian:`
6. Verify write remote:
   - `rclone lsd gdrive-obsidian-oauth:`
7. Verify autosync daemon:
   - `bash ops/scripts/sync/status-obsidian-inbox-autosync.sh`
8. Restart autosync if needed:
   - `bash ops/scripts/sync/start-obsidian-inbox-autosync.sh`
9. Run one backup immediately after recovery:
   - `bash ops/scripts/backup/backup-obsidian-sync-state.sh`

## Important scope rule

Only `0. Inbox` is automatically synchronized to Drive.
Changes elsewhere in the vault are outside the daemon boundary and are only pushed when an explicit guarded workflow is used.

Current non-inbox rule:
- use `ops/scripts/sync/push-vault-safe.sh` for deliberate local-to-Drive promotion
- this path uses `rclone copy --update`
- it does not delete remote files
- it does not overwrite newer remote files
- it should be treated as conservative push, not as full bidirectional merge
