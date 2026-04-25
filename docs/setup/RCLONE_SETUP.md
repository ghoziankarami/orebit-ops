# Rclone Setup

Use this runbook to make Google Drive usable for the Orebit workspace.

This repo expects two separate concepts:

1. a working `rclone` Google Drive remote for backup and restore
2. an active mount at `/mnt/gdrive/AI_Knowledge` for paper-processing workflows

Do not treat a placeholder `rclone.conf` as a valid setup.

## Required remotes

The current workspace expects these remote names:

- `gdrive`
- `gdrive-obsidian`
- `gdrive-research`

Recommended meaning:

- `gdrive` = primary Google Drive remote
- `gdrive-obsidian` = alias to `gdrive:Obsidian`
- `gdrive-research` = alias to `gdrive:AI_Knowledge`

## Current failure mode to recognize

If `rclone` returns `invalid_grant`, the stored OAuth token is stale or invalid.
That remote is not usable until it is reconnected.

## Check current status

```bash
rclone config show
rclone listremotes
rclone about gdrive:
rclone lsd gdrive:
rclone lsd gdrive-research:
mountpoint -q /mnt/gdrive/AI_Knowledge && echo mounted || echo not-mounted
```

## Reconnect the primary Google Drive remote

If `gdrive` already exists but fails auth, reconnect it:

```bash
rclone config reconnect gdrive:
```

If the remote does not exist yet, create it:

```bash
rclone config
```

Recommended base remote:

- name: `gdrive`
- type: `drive`
- scope: `drive`

After reconnect or creation, verify:

```bash
rclone about gdrive:
rclone lsd gdrive:
```

## Create or repair aliases

Use aliases so scripts can keep stable names:

```bash
rclone config create gdrive-obsidian alias remote gdrive:Obsidian
rclone config create gdrive-research alias remote gdrive:AI_Knowledge
```

Verify:

```bash
rclone lsd gdrive-obsidian:
rclone lsd gdrive-research:
```

## Activate the paper mount

Create the mountpoint if needed:

```bash
mkdir -p /mnt/gdrive/AI_Knowledge
```

Mount the research folder:

```bash
rclone mount gdrive:AI_Knowledge /mnt/gdrive/AI_Knowledge --daemon
```

Verify:

```bash
mountpoint -q /mnt/gdrive/AI_Knowledge && echo mount-ok
ls -la /mnt/gdrive/AI_Knowledge | sed -n '1,40p'
```

## Backup and restore usage

The backup helper uses the `gdrive` remote, not the mounted path:

```bash
bash infra-template/sync-to-gdrive.sh --dry-run
bash infra-template/sync-to-gdrive.sh
bash infra-template/sync-to-gdrive.sh --restore
```

## Workflow mapping

- `gdrive` is for backup and restore
- `gdrive-research` points to the research paper source folder
- `/mnt/gdrive/AI_Knowledge` is the live mounted paper source used by paper scripts
- `gdrive-obsidian` is the optional alias for Obsidian folder operations

## Success criteria

Primary success in the current runtime is:

- `rclone about gdrive:` works
- `rclone lsd gdrive-research:` works
- `bash research-data/install.sh` accepts the remote+cache path
- `scripts_sync_drive_to_local.sh` and `scripts_sync_sample_papers.sh` can populate local working paths

Optional mount success is only required on hosts that actually support FUSE.
