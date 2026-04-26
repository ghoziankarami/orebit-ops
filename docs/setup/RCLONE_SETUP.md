# Rclone Setup

Use this runbook to understand the current rclone and Google Drive position for Orebit.

## Current canonical state

The current system treats Google Drive as the intended cross-device source of truth for the Obsidian vault, but not yet as a fully trusted write path from this runtime.

What is true now:
- `rclone` read access to the shared `Obsidian` folder works
- the connected folder is the real existing Google Drive `Obsidian` vault
- local vault work happens at `/app/working/workspaces/default/obsidian-system/vault`
- service-account write is still blocked in practice
- OAuth-based write finalization is still pending

## Current remote expectation

The important operational remote is:
- `gdrive-obsidian`

It should point at the real shared Google Drive `Obsidian` folder using the configured `root_folder_id`.

## Current success criteria

Read-path success means:
- `rclone lsd gdrive-obsidian:` works
- the real vault structure is visible
- inbox or full-vault pull scripts can read from the remote

Write-path success is not yet assumed.

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

## Canonical interpretation

- Google Drive is the intended long-term source of truth across devices
- this runtime currently trusts Drive read more than Drive write
- local vault cleanup can proceed without assuming write-back is ready
- inbox-first automation remains the safest default sync model
