# Bootstrap Guide

This repo is the source of truth for deploying and bootstrapping the Orebit public RAG surface plus the supporting local runtime.

## Scope of this repo

This repo intentionally combines:

- the canonical public frontend source for `rag.orebit.id`
- the RAG API wrapper/runtime support
- local bootstrap/install scripts
- PARA second-brain support
- research-data structure and helpers
- validation, runbooks, and operator docs

So although the folder name is `orebit-rag-deploy`, the repo now covers more than a single Docker-style deploy path.
It should be read as the bootstrap/deploy source-of-truth for the Orebit RAG stack and its supporting workspace pieces.

## What this repo owns

Commit and review these here:

- deployment docs
- install scripts
- validation scripts
- Vercel deploy helpers
- Docker and compose files where still relevant
- sanitized env templates
- small README files that explain each runtime tree
- the canonical public `rag-public/` frontend source

Do not rely on chat history as the source of truth. If a future agent or operator needs to know how the system works, they should read this repo first.

## Runtime and deploy surfaces managed by this repo

- `/workspace/orebit-rag-deploy` - source repo
- `/workspace/orebit-rag-deploy/rag-public` - canonical public UI for `rag.orebit.id`
- `/workspace/obsidian-system` - live second-brain vault
- `/workspace/rag-system` - live RAG services and local fallback dashboard
- `/workspace/research-data` - live research data trees

## Canonical deployment map

- public `rag.orebit.id` -> `rag-public/` -> Vercel
- public API path `/api/rag/*` -> API wrapper on `3004`
- local `8503` -> fallback/local dashboard only

Do not treat port `8503` as the canonical public deployment target.

## Bootstrap flow

1. Clone the repo to `/workspace/orebit-rag-deploy`.
2. Copy `infra-template/.env.template` to `.env` and fill required local/runtime secrets.
3. Copy `secrets.env.template` to `~/.openclaw/secrets.env` and fill deploy secrets for Vercel and public API access.
4. Run `python3 scripts_preflight_validate.py`.
5. Run `bash infra-template/install.sh`.
6. Run `python3 scripts_postflight_verify.py`.
7. Deploy the public UI with `bash scripts_deploy_rag_public_vercel.sh`.
8. Verify `https://rag.orebit.id` and `https://rag.orebit.id/api/rag/health`.

## Required manual items

- real API keys in `.env`
- deploy secrets in `~/.openclaw/secrets.env`
- optional Google Drive `rclone` config in `~/.config/rclone/rclone.conf`
- optional Google Drive mount at `/mnt/gdrive/AI_Knowledge`
- Vercel CLI availability or deploy token when shipping the public UI

## Agent/operator checklist

Before changing runtime behavior, check these files:

- `README.md`
- `DEPLOYMENT.md`
- `RAG_PUBLIC_DEPLOYMENT.md`
- `BOOTSTRAP.md`
- `infra-template/install.sh`
- `scripts_deploy_rag_public_vercel.sh`
- `rag-system/install.sh`
- `rag-system/docker-compose.yml`
- `obsidian-system/install.sh`
- `research-data/install.sh`
- `scripts_preflight_validate.py`
- `scripts_postflight_verify.py`

## Current expectations

- public frontend source is `rag-public/`
- RAG API listens on `3004`
- local fallback dashboard listens on `8503`
- Obsidian vault uses PARA folders
- research data includes `nala`, `orebit`, and `papers-index`
