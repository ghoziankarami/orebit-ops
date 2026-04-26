# PR Summary

## Branch

- `feat/bootstrap-secondbrain-sync`

## Purpose

Make `orebit-rag-deploy` a clearer bootstrap/source-of-truth repo for Orebit RAG + Obsidian second-brain runtime, while adding basic validation and PARA helper wrappers.

## What changed

### Bootstrap and repo guidance

- add `BOOTSTRAP.md`
- add repo-focused `AGENTS.md`
- align `README.md` and `DEPLOYMENT.md` with the actual bootstrap flow

### Validation and verification

- add `scripts_preflight_validate.py`
- add `scripts_postflight_verify.py`
- add safer `infra-template/install.sh`

### RAG setup

- add `rag-system/install.sh`
- keep `rag-system/docker-compose.yml` as the stack definition
- keep `rag-system/chroma_integration.py` in repo as source/helper code

### Second-brain / PARA helpers

- add `docs_secondbrain_PARA.md`
- add `secondbrain_task_staging.py`
- add `secondbrain_publish_research.sh`
- fix `obsidian-system/install.sh` so it creates PARA folders explicitly

### Research bootstrap

- improve `research-data/install.sh`
- improve `research-data/README.md`

### Git helper

- add `scripts_git_safe_sync.sh` for safer branch-based repo sync

## Verified outcomes

- `.env` main keys were populated locally for runtime use
- RAG API health endpoint responds with `200`
- PARA task staging writes to `/workspace/obsidian-system/vault/0. Inbox/Task Staging.md`
- research publish writes to `/workspace/obsidian-system/vault/0. Inbox/Research/`
- broken legacy vault folders were removed from `/workspace/obsidian-system/vault`

## Known gaps

- Docker host is still unstable for full dashboard/container startup
- dashboard health on port `8503` is not yet verified healthy
- Google Drive mount is still optional/missing in current runtime

## Merge checklist

- [ ] Review `BOOTSTRAP.md`
- [ ] Review `AGENTS.md`
- [ ] Review `DOCKER_HOST_FIX.md`
- [ ] Confirm `scripts_preflight_validate.py` matches desired required env policy
- [ ] Confirm `scripts_git_safe_sync.sh` branch protection behavior is desired
- [ ] Fix host Docker runtime
- [ ] Verify `rag-system/install.sh` can bring up dashboard `8503`
- [ ] Run `python3 scripts_postflight_verify.py`
- [ ] Optionally open PR from `feat/bootstrap-secondbrain-sync` to `main`

## Suggested PR description

This PR turns `orebit-rag-deploy` into a more reliable bootstrap repo for the live Orebit runtime. It adds preflight/postflight validation, clearer bootstrap docs, a real `rag-system` installer, and minimal second-brain PARA wrappers for task staging and research publishing. It also fixes the Obsidian PARA folder creation path and improves research-data bootstrap checks. Application-side bootstrap is now much clearer; the remaining blocker for full dashboard startup is host Docker runtime stability.
