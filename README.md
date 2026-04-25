# Orebit Canonical Workspace

Canonical repository for the Orebit stack that is currently being operated through QwenPaw.

This repo is not only a deployment bundle. It is the canonical home for three connected workflows:

- Orebit RAG full workflow
- Obsidian PARA / second-brain capture workflow
- QwenPaw-facing runtime and operator workflow for this stack

## What this repo owns

| Area | Purpose | Canonical location |
|---|---|---|
| Public RAG UI | Public frontend for `rag.orebit.id` | `rag-public/` |
| Local RAG runtime | API wrapper, local data, fallback dashboard | `rag-system/` |
| Second brain | PARA vault structure and capture model | `obsidian-system/` |
| Research data | Research and paper workspace layout | `research-data/` |
| Bootstrap and deploy | Installation, validation, deploy helpers | root docs + `infra-template/` |
| QwenPaw bridge | Applied runtime notes and workflow docs | `docs/qwenpaw/` |
| Canonical workflows | RAG and second-brain operational docs | `docs/workflows/` |

## Canonical boundaries

Use this repo as the source of truth for:

- bootstrap and deployment
- RAG workflow
- second-brain/PARA workflow
- QwenPaw-facing operational notes that are verified and relevant to this stack

Do not use this repo as a dumping ground for every historical OpenClaw document.
Only migrate material that is active, verified, and useful.

## Read this first

### Core docs

- `BOOTSTRAP.md`
- `DEPLOYMENT.md`
- `RAG_PUBLIC_DEPLOYMENT.md`
- `docs/CANONICAL_AUDIT_2026-04-25.md`
- `docs/setup/RCLONE_SETUP.md`

### Canonical workflows

- `docs/workflows/RAG_FULL_WORKFLOW.md`
- `docs/workflows/RAG_OBSIDIAN_REMOTE_CACHE_VERIFIED.md`
- `docs/workflows/RAG_RUNTIME_RELOAD_AND_LLM.md`
- `docs/workflows/SECOND_BRAIN_CAPTURE_WORKFLOW.md`
- `docs/qwenpaw/QWENPAW_NEW_SYSTEM.md`

### Applied-state references

- `docs/QWENPAW_RUNTIME_APPLIED.md`
- `docs/QWENPAW_CRON_APPLIED.md`
- `docs/MIGRATION_QWENPAW_CANONICAL_GAP.md`

## Runtime map

### Public surfaces

- public UI: `https://rag.orebit.id`
- public API path: `https://rag.orebit.id/api/rag/*`

### Local runtime

- local API: `http://127.0.0.1:3004`
- local fallback dashboard: `http://127.0.0.1:8503`
- local 9router: `http://127.0.0.1:20128/v1`

### Main live paths

- repo source: `/workspace/orebit-rag-deploy`
- live vault root: `/workspace/obsidian-system`
- live research-data root: `/workspace/research-data`
- QwenPaw runtime root: `/app/working`

## Quick start

### 1. Clone

```bash
git clone https://github.com/ghoziankarami/orebit-rag-deploy.git
cd orebit-rag-deploy
```

### 2. Prepare env

```bash
cp infra-template/.env.template .env
# Fill real values
```

### 3. Bootstrap

```bash
bash infra-template/install.sh
```

### 4. Verify local runtime

```bash
curl -sS http://127.0.0.1:3004/api/rag/health
curl -sS http://127.0.0.1:8503/_stcore/health
```

### 5. Deploy public UI

```bash
bash scripts_deploy_rag_public_vercel.sh
```

## Verification habits

- verify live runtime before claiming docs are correct
- keep secrets and runtime databases out of Git
- treat fallback local surfaces as fallback, not as public canonical targets
- prefer repo-documented workflows over stale chat memory

## Current migration stance

`openclaw-workspace` is now a migration source, not the canonical home for this stack.
This repo should be kept smaller, cleaner, and more trustworthy.

## What is not in Git

- production secrets
- runtime databases
- vault content backups
- research PDFs and large datasets
- generated caches and logs
