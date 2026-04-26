# Canonical Audit - 2026-04-25

This audit defines what `orebit-rag-deploy` should own as the canonical repo right now.

## Goal

Make this repo clean, trustworthy, and focused on three active workflows:

- full RAG workflow
- full Obsidian / PARA / second-brain capture workflow
- QwenPaw runtime and operator workflow that is actually in use

## Audit conclusion

`orebit-rag-deploy` should become the canonical source for:

- deployment and verification of the Orebit RAG stack
- runtime ownership of the local RAG + vault + research layout
- the applied PARA capture and second-brain workflow relevant to this stack
- the verified QwenPaw-facing operational model used to run it

It should not become a dump of all historical OpenClaw governance docs.

## What is already good

The repo already has useful docs for:

- bootstrap
- deployment
- public UI deployment
- local RAG runtime layout
- research-data structure
- vault structure baseline

## Main gaps

### Root positioning gap

The old root `README.md` was still deployment-first.
The repo needs a clearer identity as the canonical home for the Orebit RAG + second-brain + QwenPaw-operated workflow.

### Workflow gap

The repo did not yet have a clean canonical set for:

- end-to-end RAG workflow
- end-to-end PARA capture workflow
- QwenPaw system/runtime workflow

### Legacy contamination risk

The old `openclaw-workspace` docs contain useful knowledge, but also a lot of:

- machine-specific cron inventory
- legacy OpenClaw governance
- Hermes/OpenClaw transition notes
- broad operator docs not specific to this repo

These should not be copied wholesale.

## Migration principles

Only migrate docs that are:

- relevant to the current Orebit repo scope
- verified from live runtime or active repo state
- useful to the next operator without requiring chat history
- small and opinionated enough to stay maintainable

## Chosen canonical docs for phase 2

- `docs/workflows/RAG_FULL_WORKFLOW.md`
- `docs/workflows/SECOND_BRAIN_CAPTURE_WORKFLOW.md`
- `docs/qwenpaw/QWENPAW_NEW_SYSTEM.md`
- `docs/QWENPAW_RUNTIME_APPLIED.md`
- `docs/QWENPAW_CRON_APPLIED.md`
- `docs/MIGRATION_QWENPAW_CANONICAL_GAP.md`

## Deferred items

Do not migrate these as canonical yet:

- full cron registry from `openclaw-workspace`
- full SOP registry from `openclaw-workspace`
- broad `WORKSPACE.md` from the legacy workspace
- large Hermes/OpenClaw transition docs that are not repo-specific

## Next practical steps

1. finish tightening the root docs around these three workflows
2. verify Google Drive/rclone path and mount behavior for this repo
3. test the RAG workflow end to end
4. test the PARA capture workflow end to end
5. only then promote more SOP extracts if they are truly active and useful
