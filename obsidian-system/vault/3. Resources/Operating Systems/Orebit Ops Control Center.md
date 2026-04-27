---
tags:
  - orebit-ops
  - operations
  - control-center
  - workflow
---

# Orebit Ops Control Center

This note is the readable control panel for day-to-day operation.
It does not replace the repo docs.
It helps you navigate them from inside Obsidian.

## Daily use

### If you are capturing
- use `0. Inbox/Task Staging.md` for tasks
- use `0. Inbox/Ideas/` for ideas
- use `0. Inbox/Research/` for research questions and drafts
- use `0. Inbox/Papers/` for paper-note intake
- use `0. Inbox/Automation Inbox/` for staged automation output

### If you are reviewing
- open `0. Inbox/Review Queue.md`
- open `0. Inbox/Automation Inbox/Automation Review Queue.md`
- promote only the notes that remain useful after one reread

### If you are operating the system
Read these repo docs when you need exact technical truth:
- `docs/operations/OPERATIONAL_STATUS.md`
- `docs/operations/OPEN_GAPS.md`
- `docs/setup/RCLONE_SETUP.md`
- `docs/runbooks/CHAT_AUTOMATION_REVIEW.md`
- `docs/runbooks/RAG_OREBIT_ID_DEPLOY.md`

## Operating SOPs mirrored in the vault

- [[3. Resources/Operating Systems/Obsidian System SOP]]
- [[3. Resources/SOPs/SOP - Turning QwenPaw Sessions into Durable Notes]]
- [[3. Resources/Operating Systems/QwenPaw Capture and Review Workflow]]
- [[3. Resources/SOPs/SOP - Automation Inbox Review]]
- [[0. Inbox/Automation Inbox/README]]

## Current system rule

- GitHub repo holds canonical technical docs.
- Obsidian holds selective readable mirrors and working navigation notes.
- Durable insights should leave chat and become notes.
- Low-confidence automation should stage first, not autopromote.

## When in doubt

Ask:
- is this a capture?
- is this a review item?
- is this a durable knowledge note?
- is this a technical runtime doc that should stay canonical in Git?

If it is mainly technical/runtime truth, keep the source in the repo.
If it is something you want to read often while operating, mirror a readable version in the vault.
