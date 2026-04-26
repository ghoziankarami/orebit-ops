# PARA Capture — Runbook

## Overview
Capture links (YouTube, GitHub, articles, generic) into Obsidian vault using PARA method. Files go to `0. Inbox` first, then reviewed before promotion.

## Capture Command
```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/capture/capture-link.sh "URL" --context "optional context"
```

## Routing Rules
| Type | Target Folder | Index File |
|------|-------------|------------|
| YouTube | `0. Inbox/YouTube to Watch/` | `0. Inbox/YouTube to Watch.md` |
| GitHub | `0. Inbox/GitHub Follow-up/` | `0. Inbox/GitHub Follow-up.md` |
| Article/Blog | `0. Inbox/Reading Inbox/` | `0. Inbox/Reading Inbox.md` |
| Generic link | `0. Inbox/Links/` | `0. Inbox/Links.md` |
| Task | `0. Inbox/Task Staging.md` | — |

## YouTube Enrichment
Uses `yt-dlp` to fetch metadata: title, channel, duration, description.
Falls back to URL + timestamp if yt-dlp unavailable.

## Sync After Capture
After capture, push-only sync to Google Drive:
```bash
bash ops/scripts/sync/push-obsidian-inbox-copy-only.sh
```
This avoids pulling Drive→local which could overwrite fresh index entries.

## Rebuild Indexes
```bash
cd /app/working/workspaces/default/orebit-rag-deploy
python3 ops/scripts/obsidian/rebuild_link_indexes.py
```
Rebuilds all link index files from scratch based on actual files in vault.

## Batch Capture
```bash
bash ops/scripts/capture/capture-link-batch.sh file_with_urls.txt
```

## Safety Rules
1. Always capture to `0. Inbox` first — never directly to Projects/Areas/Resources
2. Review before promoting to permanent locations
3. After capture → push-only sync → rebuild index (never pull-before-push)
4. Use `--context` flag to add personal notes to capture
