# RAG Public Deployment

This document is the canonical deployment guide in this repo for the public `rag.orebit.id` surface.

## Canonical architecture

`rag.orebit.id` is **not** the local Streamlit dashboard on port `8503`.

The canonical public deployment shape is:

- public frontend source: `rag-public/`
- public frontend runtime: Vercel
- public API backend: `rag-system/api-wrapper/`
- public API host: `https://rag.orebit.id/api/rag`
- local API health: `http://127.0.0.1:3004/api/rag/health`
- local Streamlit on `8503`: fallback/local dashboard only

Production request flow:

- browser -> `https://rag.orebit.id`
- Vercel UI -> same-origin `/api/rag/*`
- Vercel serverless proxy -> VPS wrapper at `https://api.orebit.id/api/rag` or `https://rag.orebit.id/api/rag`
- wrapper -> local Chroma/vector data

## What lives in this repo

- `rag-public/` = canonical public UI source for `rag.orebit.id`
- `rag-system/api-wrapper/` = VPS API wrapper source
- `scripts_deploy_rag_public_vercel.sh` = canonical deploy helper for the public UI
- `rag-system/run_dashboard_local.sh` = local fallback only, not the public domain deployment path

## Required secrets

Store these outside Git:

- `RAG_API_KEY`
- `RAG_API_BASE`
- `VERCEL_TOKEN`

Recommended locations:

- repo `.env` for local/runtime bootstrap as needed
- `$HOME/.openclaw/secrets.env` for deploy automation
- `$HOME/.config/vercel/token` as fallback token location

## Deploy the public UI

```bash
cd /workspace/orebit-rag-deploy
bash scripts_deploy_rag_public_vercel.sh
```

This will:

- ensure Vercel CLI is available
- build `rag-public/`
- sync `RAG_API_BASE` and `RAG_API_KEY` to Vercel when a token is available
- deploy the production frontend

## Local UI development

```bash
cd /workspace/orebit-rag-deploy/rag-public
npm install
npm run dev
```

Local dev runs on Vite, and the app uses:

- `http://127.0.0.1:3004/api/rag` when opened on localhost
- `/api/rag` in production

## Deploy or verify the API wrapper

The public UI depends on the VPS wrapper in `rag-system/api-wrapper/`.

Verify locally:

```bash
curl -sS http://127.0.0.1:3004/api/rag/health
curl -sS -X POST http://127.0.0.1:3004/api/rag/search \
  -H 'Content-Type: application/json' \
  -H "X-API-Key: $RAG_API_KEY" \
  -d '{"query":"tin deposit bangka","top_k":3}'
```

Verify public path after deploy:

```bash
curl -sk https://rag.orebit.id | head
curl -sk https://rag.orebit.id/api/rag/health
```

## DNS and domain notes

`rag.orebit.id` should point to the Vercel project for the public UI.

Do not point `rag.orebit.id` directly to port `8503` if the goal is the canonical public surface.

## Fallback dashboard

The local Streamlit dashboard remains useful for:

- local inspection
- API query smoke tests
- Chroma/PARA/research visibility on the server

Fallback endpoints:

- `http://127.0.0.1:8503`
- `http://127.0.0.1:8503/_stcore/health`

But this fallback is not the canonical `rag.orebit.id` deployment target.
