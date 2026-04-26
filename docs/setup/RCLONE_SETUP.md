# Rclone Setup

Use this runbook to understand the current rclone and Google Drive position for Orebit.

## Current canonical state

The current system treats Google Drive as the intended cross-device source of truth for the Obsidian vault.

What is true now:
- `rclone` read access to the shared `Obsidian` folder works
- the connected folder is the real existing Google Drive `Obsidian` vault
- local vault work happens at `/app/working/workspaces/default/obsidian-system/vault`
- service-account write is still blocked in practice
- OAuth-based write is now configured and verified for inbox push

## Current remote expectation

The important operational remotes are:
- `gdrive-obsidian` for service-account read access
- `gdrive-obsidian-oauth` for OAuth-backed write access

Both should point at the real shared Google Drive `Obsidian` folder using the configured `root_folder_id`.

## Current success criteria

Read-path success means:
- `rclone lsd gdrive-obsidian:` works
- the real vault structure is visible
- inbox or full-vault pull scripts can read from the remote

Write-path success means:
- `rclone lsd gdrive-obsidian-oauth:` works
- a small test write/delete succeeds on the OAuth remote
- inbox push uses the OAuth remote, not the service-account remote

## Important caution

Do not assume service-account write is safe just because read works.
The service-account path previously failed with Google Drive quota/storage behavior.

## Check current status

```bash
rclone listremotes
rclone lsd gdrive-obsidian:
rclone size gdrive-obsidian:
```

## Working local path

Use this as the persistent local mirror path:

```bash
/app/working/workspaces/default/obsidian-system/vault
```

Do not use:

```bash
/workspace/obsidian-system/vault
```

## Canonical scripts

Use the active scripts in:

```bash
ops/scripts/sync/
```

Important scripts include:
- `setup-rclone-service-account.sh`
- `sync-vault-initial-pull.sh`
- `sync-inbox-pull.sh`
- `sync-inbox-push.sh`
- `autosync-obsidian-inbox-copy-merge.sh`
- `backup-obsidian-sync-state.sh`

## Canonical interpretation

- Google Drive is the intended long-term source of truth across devices
- this runtime uses split remotes: service-account read plus OAuth write
- local vault cleanup can proceed without opening full-vault write automation
- inbox-first automation remains the default sync model

## Recovery notes

If auth breaks again, recover in this order:
- verify `/root/.config/rclone/rclone.conf` still contains both `gdrive-obsidian` and `gdrive-obsidian-oauth`
- verify both remotes still point at `root_folder_id = 1a33hipwORSMZh3pKOMvB4PjMQzvvJFGI`
- test read with `rclone lsd gdrive-obsidian:`
- test write with `rclone lsd gdrive-obsidian-oauth:`
- if OAuth expired or was lost, recreate it with `rclone authorize` using the Google OAuth web client and paste the token back into `rclone.conf`
- keep `sync-inbox-pull.sh` on the read remote and `sync-inbox-push.sh` on the OAuth remote
