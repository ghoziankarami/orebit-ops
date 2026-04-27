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

## High-value chat output capture

For brainstorming, strategy, image concepts, workflow drafts, decision logs, deck briefs, and similar outputs that should not remain only in chat, use:

```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/capture/capture-chat-output.sh \
  --type idea|research|decision|workflow|sop|image-concept|deck-brief|video-brief \
  --title "Title" \
  --content "Captured output" \
  --context "Why it matters / source chat context"
```

Routing rules:
- `idea` -> `0. Inbox/Ideas/`
- `research` -> `0. Inbox/Research/`
- `decision` -> `0. Inbox/Task Notes/`
- `workflow` -> `3. Resources/Operating Systems/`
- `sop` -> `3. Resources/SOPs/`
- `image-concept` -> `3. Resources/Visual Concepts/`
- `deck-brief` -> `0. Inbox/Task Notes/`
- `video-brief` -> `0. Inbox/Task Notes/`

## Safety rules

1. Capture any high-value chat output that is likely to matter later.
2. Use `0. Inbox/` for raw or review-needed items.
3. Write directly to durable `Resources` lanes only for already-shaped reusable outputs such as SOP drafts, workflow drafts, and image concepts.
4. Review before promoting unfinished captures to more stable lanes.
5. Use `--context` to preserve why a result matters.
6. Do not claim a sync succeeded unless the write really succeeded.

## Automation review flow

For method-2/method-3 staged capture from saved chat history, use:

```bash
cd /app/working/workspaces/default/orebit-ops
python3 ops/scripts/capture/review-chat-candidates.py --dry-run
python3 ops/scripts/capture/review-chat-candidates.py
```

Behavior:
- scans `dialog/*.jsonl`
- stages only conservative high-value candidates into `0. Inbox/Automation Inbox/Chat Review Candidates/`
- updates `0. Inbox/Automation Inbox/Automation Review Queue.md`
- tracks already-staged items in `.chat-review-state.json` to reduce duplicates
