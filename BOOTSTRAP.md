# Bootstrap Guide

This repo is the source of truth for the Orebit RAG workspace bootstrap.

## What this repo owns

Commit and review these here:

- deployment docs
- install scripts
- validation scripts
- Docker and compose files
- sanitized env templates
- small README files that explain each runtime tree

Do not rely on chat history as the source of truth. If a future agent or operator needs to know how the system works, they should read this repo first.

## Runtime paths managed by this repo

- `/workspace/orebit-rag-deploy` - source repo
- `/workspace/obsidian-system` - live second-brain vault
- `/workspace/rag-system` - live RAG services and volumes
- `/workspace/research-data` - live research data trees

## Bootstrap flow

1. Clone the repo to `/workspace/orebit-rag-deploy`.
2. Copy `infra-template/.env.template` to `.env` and fill required secrets locally.
3. Run `python3 scripts_preflight_validate.py`.
4. Run `bash infra-template/install.sh`.
5. Run `python3 scripts_postflight_verify.py`.
6. If needed, restore data backups and rerun the postflight check.

## Required manual items

- real API keys in `.env`
- optional Google Drive `rclone` config in `~/.config/rclone/rclone.conf`
- optional Google Drive mount at `/mnt/gdrive/AI_Knowledge`

## Agent/operator checklist

Before changing runtime behavior, check these files:

- `README.md`
- `DEPLOYMENT.md`
- `BOOTSTRAP.md`
- `infra-template/README.md`
- `infra-template/install.sh`
- `rag-system/install.sh`
- `rag-system/docker-compose.yml`
- `obsidian-system/install.sh`
- `research-data/install.sh`
- `scripts_preflight_validate.py`
- `scripts_postflight_verify.py`

## Current expectations

- RAG API listens on `3004`
- RAG dashboard listens on `8503`
- Obsidian vault uses PARA folders
- research data includes `nala`, `orebit`, and `papers-index`
