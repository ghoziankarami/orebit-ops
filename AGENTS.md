# Repo Instructions

Read this repo before making deployment or runtime decisions.

## Source of truth

Use this repository as the primary source for:

- deployment flow
- validation flow
- runtime layout
- env template expectations
- RAG and second-brain verification steps

Do not guess from stale chat context when the repo already documents the answer.

## Files to read first

- `BOOTSTRAP.md`
- `README.md`
- `DEPLOYMENT.md`
- `infra-template/README.md`
- `infra-template/install.sh`
- `rag-system/install.sh`
- `rag-system/docker-compose.yml`
- `obsidian-system/install.sh`
- `research-data/install.sh`
- `scripts_preflight_validate.py`
- `scripts_postflight_verify.py`

## Rules

- Keep secrets out of Git.
- Keep runtime databases and mounts out of Git.
- Validate before install.
- Verify after install.
- If runtime and repo disagree, update the repo docs and scripts so the next operator can trust the repo.
