# PARA Capture — Runbook

## Overview

Capture links into the Obsidian vault using PARA discipline.
Everything lands in `0. Inbox` first, then gets reviewed before promotion.

## Capture command

```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/capture/capture-link.sh "URL" --context "optional context"
```

## Routing rules

| Type | Target Folder | Index File |
|------|---------------|------------|
| YouTube | `0. Inbox/YouTube to Watch/` | `0. Inbox/YouTube to Watch.md` |
| GitHub | `0. Inbox/GitHub Follow-up/` | `0. Inbox/GitHub Follow-up.md` |
| Article/Blog | `0. Inbox/Reading Inbox/` | `0. Inbox/Reading Inbox.md` |
| Generic link | `0. Inbox/Links/` | `0. Inbox/Links.md` |
| Task | `0. Inbox/Task Staging.md` | — |

## YouTube enrichment

Uses `yt-dlp` when available to fetch title, channel, duration, and description.
Falls back to URL + timestamp if `yt-dlp` is unavailable.

## Sync after capture

If a trusted Drive write path is available later, use the canonical push script:

```bash
bash ops/scripts/sync/sync-inbox-push.sh
```

Until OAuth-based rclone write access is finalized, treat remote push as optional.

## Safety rules

1. Always capture to `0. Inbox` first.
2. Never write automation output directly into `Projects`, `Areas`, or `Resources`.
3. Review before promoting to durable folders.
4. Use `--context` to preserve why a link matters.
5. Do not claim a sync succeeded unless the write really succeeded.
