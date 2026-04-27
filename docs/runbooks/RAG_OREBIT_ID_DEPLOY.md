# rag.orebit.id Deploy Runbook

## Purpose

Rebuild `rag.orebit.id` from `orebit-ops` while preserving the restored legacy frontend and using an Orebit-controlled backend wrapper.

## Scope

This runbook covers:
- the frontend in `rag-public/`
- the backend wrapper in `rag-system/api-wrapper/`
- the environment-variable contract between them
- a minimum smoke-test path

It does not assume the old Docker RAG API is revived.
The canonical direction remains the local-first `rag-system/` stack documented in this repo.

## Components

### Frontend

- Path: `rag-public/`
- Type: Vite + React + Vercel serverless proxy
- Browser production path: `/api/rag`

### Backend wrapper

- Path: `rag-system/api-wrapper/`
- Type: Node + Express
- Default bind: `127.0.0.1:3004`
- Health endpoint: `GET /api/rag/health`

## Environment contract

### Backend wrapper env

Required:
- `RAG_API_KEY` - shared secret expected in `X-API-Key` for non-loopback requests

Optional:
- `PORT` - defaults to `3004`
- `RAG_API_HOST` - defaults to `127.0.0.1`
- `RAG_STATS_TTL_MS`
- `RAG_RESPONSE_CACHE_TTL_MS`
- `OREBIT_WORKSPACE_ROOT`
- `OREBIT_VAULT_ROOT`
- `OREBIT_CHROMA_ROOT`
- `OREBIT_OBSIDIAN_PAPERS_DIR`
- `OREBIT_PAPERS_COLLECTION`
- `OREBIT_PAPERS_COLLECTION_FALLBACKS`
- `OREBIT_SUMMARIES_COLLECTION`
- `OREBIT_SUMMARIES_COLLECTION_FALLBACKS`

Default canonical runtime values point at the current Orebit workspace:
- workspace root: `/app/working/workspaces/default`
- vault root: `/app/working/workspaces/default/obsidian-system/vault`
- chroma root: `/app/working/workspaces/default/file_store/chroma`
- papers dir: `/app/working/workspaces/default/obsidian-system/vault/3. Resources/Papers`
- papers collection: `paper_docs`

### Frontend Vercel env

Required:
- `RAG_API_BASE` - public base URL ending with `/api/rag`
- `RAG_API_KEY` - same shared secret used by the backend wrapper

## Local verification

### 1. Build the frontend

```bash
cd /app/working/workspaces/default/orebit-ops/rag-public
env -u NODE_ENV npm install --include=dev
env -u NODE_ENV npm run build
```

### 2. Install backend wrapper dependencies

```bash
cd /app/working/workspaces/default/orebit-ops/rag-system/api-wrapper
npm install
```

If `node index.js` fails with `Cannot find module 'dotenv'` or similar, dependencies were not installed in the current runtime yet.

### 3. Start the backend wrapper locally

```bash
cd /app/working/workspaces/default/orebit-ops/rag-system/api-wrapper
export RAG_API_KEY='replace-with-real-secret'
node index.js
```

Expected:
- wrapper listens on `http://127.0.0.1:3004`
- health route responds on `http://127.0.0.1:3004/api/rag/health`

### 4. Smoke-test the wrapper locally

Loopback requests do not require API key:

```bash
curl http://127.0.0.1:3004/api/rag/health
curl http://127.0.0.1:3004/api/rag/stats
```

Example search:

```bash
curl -X POST http://127.0.0.1:3004/api/rag/search \
  -H 'Content-Type: application/json' \
  -d '{"query":"tin exploration bangka","top_k":3}'
```

## Production deployment shape

### Backend host

Run `rag-system/api-wrapper/` on an Orebit-controlled machine or service that can reach its data provider locally.
Recommended baseline requirements:
- Node.js available
- Python 3 available
- access to the local data provider path used by `rag_public_data.py`
- HTTPS reverse proxy or public gateway in front of the wrapper

### Frontend host

Deploy `rag-public/` to Vercel.
The browser should only talk to same-origin `/api/rag`; Vercel forwards to the wrapper with the configured secret.

## Vercel setup

From `rag-public/`:

```bash
cd /app/working/workspaces/default/orebit-ops/rag-public
vercel
```

Set env vars in Vercel:
- `RAG_API_BASE=https://api.orebit.id/api/rag`
- `RAG_API_KEY=<same-secret-as-wrapper>`

Then redeploy after env changes.

## Production smoke test

Do not call the deploy green until all checks below pass.

After deploy:

### 0. Backend preflight
- run `bash rag-system/api-wrapper/preflight.sh`
- verify local embedding health: `curl http://127.0.0.1:3005/health`
- verify wrapper health: `curl http://127.0.0.1:3004/api/rag/health`
- verify wrapper stats: `curl http://127.0.0.1:3004/api/rag/stats`
- only proceed if these are healthy

### 1. Frontend loads
- open `rag.orebit.id`
- verify main UI renders without blank-screen errors

### 2. Proxy health path works
- request `https://rag.orebit.id/api/rag/health`
- expect `status` response from wrapper

### 3. Browse works
- request `https://rag.orebit.id/api/rag/browse?page=1&limit=5`
- expect JSON response with records or empty-but-valid structure

### 4. Search works
- submit a known search from UI or proxy endpoint
- verify response is non-500 and shape matches frontend expectation

## Rollback rule

If a new deploy breaks production:
- keep the restored `rag-public/` baseline as the rollback target
- do not replace the UI with a new design during recovery
- revert only the failing frontend or wrapper change, not the whole repo state

## Current limitation

This runbook documents the reproducible contract and local validation path.
The final production host/process-manager specifics for `rag-system/api-wrapper/` still need to be fixed to one canonical Orebit runtime surface.
