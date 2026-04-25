# Research data

This repo tracks the expected structure for the live research data tree.

## Live runtime paths

- `/workspace/research-data/nala`
- `/workspace/research-data/orebit`
- `/workspace/research-data/papers-index`
- `/workspace/research-data/papers-cache`

The real data stays outside Git. This repo only documents the required layout and bootstrap checks.

## Source mapping

- Google Drive Obsidian source: `gdrive-obsidian:`
- Google Drive RAG/paper source: `gdrive-research:`
- preferred local paper cache: `/workspace/research-data/papers-cache`

In this runtime, the remote+cache model is the default safe path.
Do not require FUSE mount support for normal operation.

## Verify

```bash
bash research-data/install.sh
```

That script ensures the runtime directories exist, prepares `/data/obsidian/3. Resources/Papers`, and accepts either:

- a live mount at `/mnt/gdrive/AI_Knowledge`, or
- a reachable `gdrive-research:` remote plus local cache at `/workspace/research-data/papers-cache`

For a full `rclone` reconnect and mount runbook, see `docs/setup/RCLONE_SETUP.md`.
