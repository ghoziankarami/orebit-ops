---
tags:
  - workflow
  - qwenpaw
  - capture
  - review
---

# QwenPaw Capture and Review Workflow

## Purpose

Describe the practical working loop for turning useful chat output into durable notes without flooding the vault.

## Working loop

1. Explore in QwenPaw.
2. Capture obvious high-value output immediately.
3. Stage uncertain outputs in inbox/review surfaces.
4. Promote only after a second read.

## Direct capture

Use direct capture when the result is already clearly useful.
Examples:
- image concepts
- SOP drafts
- workflow drafts
- decision logs
- research notes with clear reuse value

## Staged capture

Use staged capture when the result might be useful but is not yet clean enough to promote.
Examples:
- mixed brainstorm outputs
- partial strategic notes
- promising but noisy chat summaries
- automation-selected candidates from transcript review

These belong in:
- `0. Inbox/Automation Inbox/`
- `0. Inbox/Review Queue.md`
- `0. Inbox/Automation Inbox/Automation Review Queue.md`

## Repo-side automation

The technical reviewer automation lives in the repo:
- `ops/scripts/capture/review-chat-candidates.py`
- `docs/runbooks/CHAT_AUTOMATION_REVIEW.md`

## Rule

Do not use transcript history itself as the knowledge base.
Use it as raw material for capture, review, and promotion.
