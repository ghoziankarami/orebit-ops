# Orebit Deployment Guide

This repo is the deploy/bootstrap source-of-truth for the canonical public `rag.orebit.id` frontend plus the supporting local Orebit RAG runtime.

## Canonical deployment map

- `rag.orebit.id` -> `rag-public/` -> Vercel
- `rag.orebit.id/api/rag/*` -> API wrapper on port `3004`
- local `8503` -> fallback/local Streamlit dashboard only

If your goal is the public showcase domain, use `rag-public/` and the Vercel deploy path.

## Step 1 - Clone

```bash
git clone https://github.com/ghoziankarami/orebit-rag-deploy.git
cd orebit-rag-deploy
```

## Step 2 - Prepare secrets

Create or update your local secret sources:

```bash
cp infra-template/.env.template .env
# fill RAG_API_KEY and related runtime values
```

Optional deploy secret file for automation:

```bash
mkdir -p ~/.orebit
cat > ~/.orebit/secrets.env <<'EOF'
RAG_API_BASE=https://api.orebit.id/api/rag
RAG_API_KEY=replace-me
VERCEL_TOKEN=replace-me
EOF
# Legacy fallback is still supported at ~/.openclaw/secrets.env during migration
```

## Step 3 - Bootstrap local runtime

```bash
bash infra-template/install.sh
python3 scripts_preflight_validate.py
python3 scripts_postflight_verify.py
```

## Step 4 - Verify local API

```bash
curl -sS http://127.0.0.1:3004/api/rag/health
curl -sS -X POST http://127.0.0.1:3004/api/rag/query \
  -H 'Content-Type: application/json' \
  -d '{"query":"test","top_k":1}'
```

## Step 5 - Deploy public `rag.orebit.id`

```bash
bash scripts_deploy_rag_public_vercel.sh
```

Expected outcome:

- `rag-public/` builds successfully
- Vercel env vars are synced when token is available
- production deploy is created
- custom domain `rag.orebit.id` serves the public UI

## Step 6 - Verify public surface

```bash
curl -sk https://rag.orebit.id | head
curl -sk https://rag.orebit.id/api/rag/health
```

## Local fallback dashboard

Use this only as a local fallback when you need a simple server-side surface:

```bash
/workspace/orebit-rag-deploy/rag-system/run_dashboard_local.sh
curl -sS http://127.0.0.1:8503/_stcore/health
```

This is not the canonical public domain deployment path.

## Data migration

Large runtime data still needs backup/restore outside Git:

- `rag-system/chroma/`
- `obsidian-system/vault/`
- `research-data/`

## Recommended operator order

1. restore data
2. verify local API on `3004`
3. deploy `rag-public/` to Vercel
4. verify `rag.orebit.id`
5. use `8503` only for fallback/local inspection if needed
