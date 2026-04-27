# Orebit Canonical Workspace

> Start here: `docs/START_HERE.md`
> Then read `docs/operations/OPERATIONAL_STATUS.md` for runtime truth.

---

## Repo purpose

This repo is the canonical operational base for:

- QwenPaw runtime and provider configuration
- local-first RAG with local embeddings
- Obsidian PARA workflow and capture rules
- Google Drive sync for the vault orchestrated by QwenPaw-managed scripts and cron jobs
- product-digital operating workflows

---

## This repo lives at

- Local: `/app/working/workspaces/default/orebit-ops`
- Branch: `main`
- Remote: `https://github.com/ghoziankarami/orebit-ops`

---

## Active structure

```text
orebit-ops/
├── docs/
│   ├── operations/
│   │   ├── OPERATIONAL_STATUS.md
│   │   ├── OPEN_GAPS.md
│   │   └── QWENPAW_WORKSPACE_BRIDGE.md
│   ├── workflows/
│   │   ├── SECOND_BRAIN_CAPTURE_WORKFLOW.md
│   │   ├── PRODUCT_DIGITAL_BLUEPRINT.md
│   │   ├── QWENPAW_RESEARCH_PLAYGROUND.md
│   │   ├── OBSIDIAN_KNOWLEDGE_ARCHITECTURE.md
│   │   └── LEGACY_RESEARCH_BRIDGE.md
│   ├── setup/
│   │   └── RCLONE_SETUP.md
│   └── archived/
├── ops/
│   ├── runbooks/
│   └── scripts/
├── obsidian-system/
├── rag-system/
└── .github/
```

---

## Current canonical architecture

### Runtime
- QwenPaw is the main operator surface
- `opencode_go/kimi-k2.6` is the active default model
- 9router remains available for GPT-5 family chat models
- `git` access to GitHub works in this runtime; `gh` is installed and authenticated

### Memory and RAG
- local embedding server on port `3005`
- local embedding model `all-MiniLM-L6-v2`
- local ChromaDB persistence
- no Docker required for the active RAG path

### Obsidian
- persistent vault path: `/app/working/workspaces/default/obsidian-system/vault`
- Google Drive `Obsidian` is the intended source of truth across devices
- automation should write to `0. Inbox/` first
- QwenPaw chat outputs should be promoted into typed notes instead of left only in transcript history

---

## Read these first

- `docs/operations/OPERATIONAL_STATUS.md`
- `docs/workflows/OBSIDIAN_SYSTEM_SOP.md`
- `docs/workflows/SECOND_BRAIN_CAPTURE_WORKFLOW.md`
- `docs/workflows/PRODUCT_DIGITAL_BLUEPRINT.md`
- `docs/workflows/QWENPAW_RESEARCH_PLAYGROUND.md`
- `docs/workflows/OBSIDIAN_KNOWLEDGE_ARCHITECTURE.md`
- `docs/workflows/OBSIDIAN_SYSTEM_BLUEPRINT.md`
- `docs/workflows/OBSIDIAN_FOLDER_MAP.md`
- `docs/workflows/OBSIDIAN_TEMPLATE_SYSTEM.md`
- `docs/workflows/LEGACY_RESEARCH_BRIDGE.md`
- `docs/setup/RCLONE_SETUP.md`
- `docs/workflows/RAG_OREBIT_ID_DEPLOYMENT_TARGET.md`
- `docs/runbooks/RAG_OREBIT_ID_DEPLOY.md`
- `docs/workflows/INBOX_CURATION_PLAN.md`
- `docs/runbooks/CHAT_AUTOMATION_REVIEW.md`

---

## Important rule

Do not trust stale docs in `docs/archived/` for runtime decisions.
Use `docs/operations/OPERATIONAL_STATUS.md` as the source of truth.
