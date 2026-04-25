# RAG Full Workflow

This is the canonical workflow for the Orebit RAG stack in this repository.

## Scope

This workflow covers:

- research input and paper intake
- local RAG runtime structure
- API wrapper behavior
- indexing expectations
- local verification
- public deployment boundary

## Canonical runtime ownership

### Repo-owned source

- `rag-public/` - canonical public UI source
- `rag-system/` - local RAG runtime source and support files
- `research-data/` - expected research-data layout
- `obsidian-system/` - vault structure and second-brain integration support

### Live runtime targets

- local API: `http://127.0.0.1:3004`
- local fallback dashboard: `http://127.0.0.1:8503`
- public UI: `https://rag.orebit.id`

## Workflow stages

### 1. Prepare runtime inputs

Ensure these runtime trees exist:

- `/workspace/orebit-rag-deploy`
- `/workspace/research-data`
- `/workspace/obsidian-system`
- `/workspace/rag-system`

Bootstrap from the repo:

```bash
bash infra-template/install.sh
```

## 2. Prepare secrets and env

- copy `infra-template/.env.template` to `.env`
- fill the required runtime values
- keep deploy secrets outside Git

Optional shared secret source:

- `~/.orebit/secrets.env`

## 3. Start or verify local RAG API

Canonical health target:

```bash
curl -sS http://127.0.0.1:3004/api/rag/health
```

Minimal query test:

```bash
curl -sS -X POST http://127.0.0.1:3004/api/rag/query \
  -H 'Content-Type: application/json' \
  -d '{"query":"test","top_k":1}'
```

## 4. Data and knowledge flow

The repo is designed around this high-level path:

1. research inputs and papers enter the system
2. research data is organized under `research-data/`
3. vault-facing notes and summaries connect through `obsidian-system/`
4. local RAG services expose retrieval through the API wrapper
5. public UI uses the canonical deployed surface at `rag.orebit.id`

In the current verified runtime, use the remote+cache model:

- sync Obsidian from `gdrive-obsidian:` into `/workspace/obsidian-system/vault`
- sync RAG papers from `gdrive-research:` into `/workspace/research-data/papers-cache`
- ingest from local cache into `/workspace/orebit-rag-deploy/rag-system/chroma`
- query through `http://127.0.0.1:3004`

See `docs/workflows/RAG_OBSIDIAN_REMOTE_CACHE_VERIFIED.md` for the verified non-mount workflow.

## 5. Public deployment boundary

Use `rag-public/` for the public domain.
Do not treat local Streamlit on `8503` as the canonical public target.

Public deploy path:

```bash
bash scripts_deploy_rag_public_vercel.sh
```

Verify:

```bash
curl -sk https://rag.orebit.id | head
curl -sk https://rag.orebit.id/api/rag/health
```

## 6. Best-practice rules

- keep repo docs aligned with the live runtime
- keep runtime data and secrets out of Git
- validate local API before claiming the public stack is healthy
- do not confuse the fallback local dashboard with the canonical public surface
- use repo scripts and docs as the source of truth, not stale chat context

## 7. Current limitations

- some historical RAG docs in `openclaw-workspace` are broader than this repo and should be mined selectively, not copied whole
- host Docker/network state may still block some local fallback flows even when repo config is correct
- end-to-end query validation should be repeated after each major runtime or data change

## Related docs

- `README.md`
- `DEPLOYMENT.md`
- `RAG_PUBLIC_DEPLOYMENT.md`
- `docs/workflows/SECOND_BRAIN_CAPTURE_WORKFLOW.md`
- `docs/qwenpaw/QWENPAW_NEW_SYSTEM.md`
