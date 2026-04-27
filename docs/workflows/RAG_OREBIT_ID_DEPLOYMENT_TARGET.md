# rag.orebit.id Deployment Target

## Current truth

`orebit-ops` now contains both sides of the intended `rag.orebit.id` rebuild surface:
- the preserved public frontend baseline in `rag-public/`
- the backend/API wrapper candidate in `rag-system/api-wrapper/`

What is already in place:
- QwenPaw is the runtime orchestrator
- local embedding service is active on `3005`
- local Chroma-based RAG is active in `rag-system/`
- the legacy `rag-public/` frontend baseline has been restored and builds successfully
- the API wrapper contract exists in `rag-system/api-wrapper/`
- QwenPaw cron is the active scheduler for autosync, backup, vault push, and paper intake

## Required end state

The target state for `rag.orebit.id` is:
- a Vercel-hosted frontend surface based on the restored `rag-public/` UI
- backed by an Orebit-controlled API wrapper, not an ad-hoc manual stack
- operationally documented in this repo
- restartable by cloning `orebit-ops`, restoring secrets, starting the wrapper, and redeploying the frontend

## Current deploy contract

### Frontend

- Path: `rag-public/`
- Production API path used by browser: `/api/rag`
- Vercel proxy implementation:
  - `rag-public/api/_lib/rag-proxy.js`
  - `rag-public/api/rag/index.js`
  - `rag-public/api/rag/[...path].js`
- Server-side env vars expected by the Vercel proxy:
  - `RAG_API_BASE`
  - `RAG_API_KEY`

### Backend wrapper

- Path: `rag-system/api-wrapper/`
- Default host/port: `127.0.0.1:3004`
- Main entrypoint: `rag-system/api-wrapper/index.js`
- Supported endpoints:
  - `POST /api/rag/search`
  - `POST /api/rag/query`
  - `GET /api/rag/browse`
  - `GET /api/rag/stats`
  - `POST /api/rag/answer`
  - `GET /api/rag/health`
- Auth model:
  - loopback requests are allowed without API key
  - non-loopback requests require `X-API-Key` matching `RAG_API_KEY`

## Recommended architecture

### Production shape

1. Deploy `rag-public/` to Vercel
2. Run `rag-system/api-wrapper/` on an Orebit-controlled host
3. Put HTTPS in front of the wrapper with a stable public base URL
4. Set `RAG_API_BASE` in Vercel to that wrapper base URL ending in `/api/rag`
5. Set `RAG_API_KEY` in both places so the Vercel proxy can call the wrapper securely

### Canonical example

- Frontend: `https://rag.orebit.id`
- Wrapper base: `https://api.orebit.id/api/rag`
- Browser flow: browser -> Vercel `/api/rag` -> wrapper -> local data provider

## Remaining gap

The repo now has the right pieces, but the final reproducible production runbook still depends on:
- choosing the actual Orebit-controlled host/process manager for `rag-system/api-wrapper/`
- documenting exact environment variables and startup commands for that host
- adding a smoke-test sequence for deploy and rollback

## Decision

Treat the restored `rag-public/` app as the required UI baseline for `rag.orebit.id`.
Treat `rag-system/api-wrapper/` as the canonical backend boundary to expose local retrieval data safely.
Do not replace the old UI during redeploy unless there is an explicit product decision to do so.

## Next step

Use `docs/runbooks/RAG_OREBIT_ID_DEPLOY.md` as the operational runbook for finishing this deploy path.
