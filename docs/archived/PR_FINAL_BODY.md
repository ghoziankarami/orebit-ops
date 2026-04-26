# Title

Bootstrap RAG + second-brain sync for `orebit-rag-deploy`

# Summary

This PR makes `orebit-rag-deploy` a much clearer bootstrap/source-of-truth repository for the live Orebit runtime.

It adds:
- clearer bootstrap and repo guidance
- preflight and postflight validation
- a real `rag-system` installer path
- safer repo sync tooling
- minimal second-brain PARA helpers for task staging and research publishing
- a Docker host troubleshooting runbook for the remaining dashboard blocker

# What changed

## Bootstrap and docs
- add `BOOTSTRAP.md`
- add repo-level `AGENTS.md`
- align `README.md` and `DEPLOYMENT.md` with the actual bootstrap flow
- add `PR_SUMMARY.md`
- add `DOCKER_HOST_FIX.md`

## Validation and install flow
- add `scripts_preflight_validate.py`
- add `scripts_postflight_verify.py`
- improve `infra-template/install.sh`
- add `rag-system/install.sh`

## Second-brain PARA support
- add `docs_secondbrain_PARA.md`
- add `secondbrain_task_staging.py`
- add `secondbrain_publish_research.sh`
- fix `obsidian-system/install.sh` to create PARA folders explicitly

## Research bootstrap
- improve `research-data/install.sh`
- improve `research-data/README.md`

## Git helper
- add `scripts_git_safe_sync.sh`

# Verified locally
- `.env` main runtime keys are present locally
- RAG API health endpoint returns `200`
- `GET /api/rag/query` returns `405` as expected
- PARA task staging writes to `/workspace/obsidian-system/vault/0. Inbox/Task Staging.md`
- research publish writes to `/workspace/obsidian-system/vault/0. Inbox/Research/`
- broken legacy vault folders were removed from the live vault
- runtime research directories exist under `/workspace/research-data`

# Known limitation
The remaining blocker is host Docker runtime stability, not missing repo files.

Current status:
- application bootstrap/config side is prepared
- RAG API is reachable
- dashboard on port `8503` is not yet healthy because Docker daemon startup/networking is unstable on the host

See `DOCKER_HOST_FIX.md` for the host-level runbook.

# Review checklist
- [ ] Review bootstrap docs and repo guidance
- [ ] Review validation/install flow changes
- [ ] Review second-brain PARA wrappers
- [ ] Review `scripts_git_safe_sync.sh` branch safety behavior
- [ ] Fix host Docker runtime
- [ ] Re-run `bash rag-system/install.sh`
- [ ] Re-run `python3 scripts_postflight_verify.py`
- [ ] Verify dashboard `8503` returns healthy status

# Suggested merge note
This PR is safe to merge for bootstrap/documentation/tooling value, but full runtime success for the dashboard still depends on host Docker fixes.