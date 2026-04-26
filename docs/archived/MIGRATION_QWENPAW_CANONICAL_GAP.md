# QwenPaw Canonical Migration Gap

This document tracks which parts of the old `openclaw-workspace` should move into `orebit-rag-deploy` as canonical documentation.

## Scope rule

Migrate only material that is both:

- relevant to the Orebit + QwenPaw runtime now in use, and
- verified as applied in the live environment

Do not bulk-copy historical OpenClaw docs, stale registries, or operator notes that are not proven live.

## Verified live sources checked

The current migration baseline was verified against:

- `/app/working/config.json`
- `/app/working/HEARTBEAT.md`
- `/app/working/workspaces/default/AGENTS.md`
- `/app/working/workspaces/default/BOOTSTRAP.md`
- `/app/working/workspaces/default/MEMORY.md`
- `qwenpaw cron list --agent-id default`

These are treated as higher-confidence runtime truth than legacy files under `openclaw-workspace/`.

## What is already covered in this repo

`orebit-rag-deploy` already has a good baseline for:

- public RAG deployment
- bootstrap flow
- local runtime verification
- public UI deploy path
- local RAG/Obsidian/research structure

That is why this migration should focus on QwenPaw-facing operational truth, not duplicate deploy docs that already exist.

## Gaps found

### Needed now

- a concise QwenPaw runtime note for this repo
- a verified cron note for jobs that are actually active in QwenPaw
- a migration policy explaining what not to copy from `openclaw-workspace`

### Not safe to migrate blindly

- full `docs/CRON_REGISTRY.md` from `openclaw-workspace`
  - reason: it reflects a larger local machine automation estate, not just QwenPaw-applied jobs
- full `docs/SOP_REGISTRY.md` from `openclaw-workspace`
  - reason: it mixes active, transitional, legacy, Hermes, OpenClaw, and unrelated workspace governance docs
- `WORKSPACE.md` as-is from `openclaw-workspace`
  - reason: much of it is broader than Orebit RAG deploy and includes legacy operational boundaries
- `docs/SYSTEM_MAP.md` pointer from `openclaw-workspace`
  - reason: it points back to old canonical paths rather than this repo

## Migration policy

Use this order when deciding whether something should move here:

1. Is it active in the live QwenPaw/Orebit runtime?
2. Is it specific enough to this repo's scope?
3. Does it improve operator trust without importing legacy baggage?
4. Can it be verified from runtime, repo, or dashboard state?

If the answer to any of these is no, do not migrate it yet.

## Phase 1 deliverables

- `docs/QWENPAW_RUNTIME_APPLIED.md`
- `docs/QWENPAW_CRON_APPLIED.md`
- this gap document

## Next likely phase

After more runtime verification, add only the minimal canonical docs for:

- QwenPaw + 9router integration once end-to-end is proven
- RAG runtime ownership once dashboard/control path is stable
- selected SOP extracts only after they are proven active in live operations
