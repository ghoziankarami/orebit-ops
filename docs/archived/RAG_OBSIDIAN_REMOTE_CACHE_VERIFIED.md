# RAG Obsidian Remote Cache Verified

This document records the verified runtime pattern that works in the current Orebit environment.

## Why this exists

The current runtime does not support FUSE mount inside the active container environment.
Because of that, the canonical workflow for now is not "mount Google Drive and read files directly".
The verified workflow is:

- Google Drive remote as source of truth
- local cache and local vault as working state
- RAG API reading from repo-local Chroma data

## Canonical source mapping

Windows source mapping confirmed by the operator:

- Obsidian source: `D:\Drive\Obsidian`
- RAG paper source: `D:\Drive\AI_Knowledge`

Server-side `rclone` mapping:

- `gdrive-obsidian:` -> `gdrive:Obsidian`
- `gdrive-research:` -> `gdrive:AI_Knowledge`

## Canonical local working paths

- local Obsidian vault: `/workspace/obsidian-system/vault`
- local research cache: `/workspace/research-data/papers-cache`
- repo-local RAG Chroma path: `/workspace/orebit-rag-deploy/rag-system/chroma`
- local RAG API: `http://127.0.0.1:3004`

## Verified commands

### Verify remotes

```bash
rclone about gdrive:
rclone lsd gdrive-obsidian:
rclone lsd gdrive-research:
```

### Sync Obsidian and paper samples

```bash
bash scripts_sync_drive_to_local.sh sample
bash scripts_sync_sample_papers.sh 8
```

### Verify research-data bootstrap

```bash
bash research-data/install.sh
```

### Ingest cached paper samples into repo-local Chroma

```bash
python3 rag-system/ingest_sample_papers.py
```

### Verify RAG stats and query

```bash
python3 rag-system/api-wrapper/rag_public_data.py stats
curl -sS -X POST http://127.0.0.1:3004/api/rag/query \
  -H 'Content-Type: application/json' \
  -d '{"query":"BenAvraham","top_k":5}'
```

## Verified outcomes

### Obsidian

- `Home.md` synced successfully into `/workspace/obsidian-system/vault`
- inbox and `.obsidian` files synced successfully into the local vault
- local PARA/capture surfaces remain usable without Drive mount

### Research cache

- sample PDFs synced successfully into `/workspace/research-data/papers-cache`
- verified sample set included eight papers during this validation pass

### RAG

- repo-local `research_papers` collection was populated with eight sample records
- stats after ingest showed:
  - `indexed_papers: 8`
  - `paper_count: 8`
  - `fulltext_papers: 8`
  - `collection_count: 8`
- API query returned real results for synced paper names such as `BenAvraham`

## Current limitation

### No FUSE mount in container runtime

`rclone mount` is not the canonical path here because `/dev/fuse` is not available in the active runtime.
Use remote+cache instead.

### LLM answer path not fully active in running API service

The `.env` file contains `OPENROUTER_API_KEY`, but the running API service did not inherit that key during validation.
As a result:

- retrieval works
- `/api/rag/answer` works in fallback mode
- `llm_used` remains `false` in the current running service

This should be fixed at the service launcher level, not by changing the canonical workflow.

## Best-practice rule

Until the runtime changes, treat this as the canonical Orebit workflow:

1. sync from Drive remotes
2. work from local vault and local cache
3. ingest into repo-local Chroma
4. query the local API
