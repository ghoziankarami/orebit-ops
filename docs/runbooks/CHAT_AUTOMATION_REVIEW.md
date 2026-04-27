# Chat Automation Review

## Purpose

Stage likely high-value chat outputs from `dialog/*.jsonl` into `0. Inbox/Automation Inbox/` without directly promoting noisy transcript content into durable knowledge lanes.

## Principles

- Prefer under-capture over vault spam.
- Stage first, promote later.
- Keep one predictable queue note for review.
- Do not treat all assistant replies as worth saving.

## Script

- `ops/scripts/capture/review-chat-candidates.py`

## Inputs

- Dialog files: `/app/working/workspaces/default/dialog/*.jsonl`
- Vault target: `/app/working/workspaces/default/obsidian-system/vault/0. Inbox/Automation Inbox/`

## Outputs

- Candidate notes under `0. Inbox/Automation Inbox/Chat Review Candidates/<date>/`
- Queue note: `0. Inbox/Automation Inbox/Automation Review Queue.md`
- State file: `0. Inbox/Automation Inbox/.chat-review-state.json`

## Default behavior

The reviewer only stages assistant messages that look structured or reusable enough to matter later.
Short replies now need stronger reuse signals; meta progress/status answers are intentionally filtered out even when they mention real work.
Examples of positive signals:
- clear headings
- enumerated steps
- workflow/SOP/research language
- explicit review/procedure/decision structure
- longer synthesis rather than tiny chat fragments

Examples of negative signals:
- tool-progress chatter
- meta progress updates like `sudah saya...` or `yang saya update...`
- stacktrace fragments or error-line snippets without synthesis
- tiny acknowledgements
- low-context conversational fragments

## Dry run

```bash
cd /app/working/workspaces/default/orebit-ops
python3 ops/scripts/capture/review-chat-candidates.py --dry-run
```

## Real run

```bash
cd /app/working/workspaces/default/orebit-ops
python3 ops/scripts/capture/review-chat-candidates.py
```

## Review rule

Candidates in Automation Inbox are not durable knowledge yet.
They must be reviewed, rewritten, promoted, archived, or discarded.

## Safe next step

After confidence is acceptable, this script can be scheduled by QwenPaw cron to refresh the staged queue on a regular cadence.
