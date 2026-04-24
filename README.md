# Orebit Workspace Deployment

Single source of truth for deploying Orebit RAG, PARA second-brain, and the public `rag.orebit.id` surface from one repo.

## What this repo owns

| Component | Purpose | Canonical deploy method |
|---|---|---|
| `rag-public/` | Public frontend for `rag.orebit.id` | Vercel via `bash scripts_deploy_rag_public_vercel.sh` |
| `rag-system/api-wrapper/` | Public RAG API wrapper | VPS service / local process on port `3004` |
| `rag-system/` | Local RAG data, Chroma, fallback dashboard | local bootstrap / fallback runtime |
| `obsidian-system/` | PARA vault + capture workflow | local bootstrap |
| `research-data/` | Research structure and second-brain feed | local bootstrap |
| `infra-template/` | Bootstrap helpers and env templates | `bash infra-template/install.sh` |

## Canonical rule

For the public showcase domain:

- `rag.orebit.id` is the Vercel-hosted UI from `rag-public/`
- `rag.orebit.id/api/rag/*` is served by the API wrapper
- local Streamlit on `8503` is fallback/local only

If you want the final public surface, do not treat `8503` as the canonical deployment target.

## Quick start

### 1. Clone

```bash
git clone https://github.com/ghoziankarami/orebit-rag-deploy.git
cd orebit-rag-deploy
```

### 2. Configure local env

```bash
cp infra-template/.env.template .env
# Edit .env with your actual values
```

### 3. Bootstrap local/runtime pieces

```bash
bash infra-template/install.sh
```

### 4. Deploy the public frontend

```bash
bash scripts_deploy_rag_public_vercel.sh
```

## Verification

### Public surface

```bash
curl -sk https://rag.orebit.id | head
curl -sk https://rag.orebit.id/api/rag/health
```

### Local API

```bash
curl -sS http://127.0.0.1:3004/api/rag/health
curl -sS -X POST http://127.0.0.1:3004/api/rag/query \
  -H 'Content-Type: application/json' \
  -d '{"query":"test","top_k":1}'
```

### Local fallback dashboard

```bash
curl -sS http://127.0.0.1:8503/_stcore/health
```

## Important docs

- `RAG_PUBLIC_DEPLOYMENT.md` - canonical public deployment for `rag.orebit.id`
- `DEPLOYMENT.md` - end-to-end deployment overview for this repo
- `BOOTSTRAP.md` - bootstrap guidance
- `DOCKER_HOST_FIX.md` - host Docker troubleshooting for optional local container flows

## Repo structure

```text
orebit-rag-deploy/
├── rag-public/                       # canonical public UI source for rag.orebit.id
├── rag-system/
│   ├── api-wrapper/                  # API wrapper source
│   ├── rag_dashboard_local.py        # fallback local dashboard
│   └── run_dashboard_local.sh        # fallback dashboard runner
├── obsidian-system/                  # PARA vault structure
├── research-data/                    # research and second-brain data layout
├── infra-template/                   # bootstrap helpers
├── scripts_deploy_rag_public_vercel.sh
├── RAG_PUBLIC_DEPLOYMENT.md
└── DEPLOYMENT.md
```

## What is not in Git

- real secrets
- production `.env`
- Vercel token
- Chroma runtime data backups
- vault content backups
- research PDFs and large datasets
- `node_modules/`, logs, and generated caches

## Deployment summary

- Public UI: `rag-public/` -> Vercel -> `rag.orebit.id`
- Public API: `rag-system/api-wrapper/` -> port `3004`
- Fallback local dashboard: Streamlit -> port `8503`
- PARA/research/bootstrap: local filesystem + scripts
