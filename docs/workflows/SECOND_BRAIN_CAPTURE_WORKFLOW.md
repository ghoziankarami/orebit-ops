# Second Brain Capture Workflow

This is the canonical second-brain and PARA capture workflow for the Orebit stack represented by this repository.

## Scope

This workflow covers:

- Obsidian PARA layout
- safe capture surfaces
- link and task intake rules
- promotion boundaries
- second-brain compatibility with the RAG workflow

## Canonical vault layout

The working PARA layout is:

- `0. Inbox/`
- `1. Projects/`
- `2. Areas/`
- `3. Resources/`
- `4. Archive/`

Important intake surfaces:

- `0. Inbox/Task Staging.md`
- `0. Inbox/Master Task List.md`
- `0. Inbox/Task Notes/`
- `0. Inbox/Links/`
- `0. Inbox/Reading Inbox/`
- `0. Inbox/GitHub Follow-up/`
- `0. Inbox/YouTube to Watch/`
- `0. Inbox/Papers/`

## Core operating rule

Automation writes to low-conflict capture surfaces first.
Humans or controlled review flows promote into more durable surfaces later.

## Task workflow

### Default automation lane

Write new tasks into:

- `0. Inbox/Task Staging.md`

Canonical staging format:

```text
- [ ] Task text 📅 YYYY-MM-DD #priority/medium #task-staging
```

### Reviewed task lane

The reviewed/manual canonical task surface is:

- `0. Inbox/Master Task List.md`

Do not treat `Master Task List.md` as the default automation append target.

## Link workflow

Use source-aware routing:

- generic links -> `0. Inbox/Links/`
- articles/blogs -> `0. Inbox/Reading Inbox/`
- GitHub links -> `0. Inbox/GitHub Follow-up/`
- YouTube links -> `0. Inbox/YouTube to Watch/`

Best-practice behavior:

- 1 URL should produce 1 detail note plus the relevant index update
- preserve light metadata and a short summary
- keep visible properties lean for inbox triage

## Paper workflow

Stage first under:

- `0. Inbox/Papers/`

Promote approved literature into a durable resource lane later.

This keeps the capture workflow compatible with both human review and RAG indexing.

## Note and idea workflow

- notes -> `0. Inbox/`
- ideas -> `0. Inbox/Ideas/`
- promote deliberately after review

## QwenPaw / operator interpretation

In the current runtime model:

- QwenPaw is the active operator surface
- capture should feel direct and low-friction
- routine capture should not depend on stale OpenClaw-specific assumptions
- the canonical idea is still wrapper-first and staging-first behavior

## Best-practice rules

- capture fast, promote deliberately
- keep automation in low-conflict areas by default
- do not claim something was saved unless the write really succeeded
- keep capture notes granular so RAG can index them cleanly
- do not route raw scratch output directly into durable resource zones

## Relationship to RAG

This workflow supports the RAG system by ensuring:

- capture notes are granular and indexable
- staged paper intake remains traceable
- stable resource notes can later become durable retrieval material

## Related docs

- `obsidian-system/vault/README.md`
- `docs/workflows/RAG_FULL_WORKFLOW.md`
- `docs/qwenpaw/QWENPAW_NEW_SYSTEM.md`
