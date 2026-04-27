# Runtime Guardrails

## Purpose

Keep `orebit-ops` clean, reproducible, and operationally honest.
These guardrails exist to prevent three repeat failure modes:
- runtime churn being mistaken for canonical repo changes
- critical local services drifting down silently
- automation being treated as healthy before it has proven successful runs

## Canonical rules

### 1. Canonical state vs runtime churn

Canonical repo state belongs in tracked docs and scripts such as:
- `docs/operations/OPERATIONAL_STATUS.md`
- `docs/QWENPAW_CRON_APPLIED.md`
- `ops/scripts/**`
- `rag-system/**`

Runtime churn does not belong in normal commits unless its structure is being deliberately changed.
Current example:
- `docs/operations/OBSIDIAN_INBOX_AUTOSYNC_STATUS.md`

Rule:
- do not commit runtime status timestamp churn
- if this file is dirty, treat it as expected runtime output first, not as evidence of a real repo change

### 2. Health before commit/push

Before committing or pushing operational changes:
- local embedding health should pass via `ops/scripts/sync/status-local-embedding-server.sh`
- autosync should be reviewed via `ops/scripts/sync/status-obsidian-inbox-autosync.sh`
- repo health should be reviewed via `ops/scripts/git/check-repo-health.sh`

These checks are enforced by:
- `.githooks/pre-commit`
- `.githooks/pre-push`
- `ops/scripts/git/check-runtime-guardrails.sh`

### 3. Proven cron, not assumed cron

A cron job is not considered healthy just because it exists.
It should have live evidence through `qwenpaw cron state <id> --agent-id default`.

Healthy means:
- recent `last_run_at`
- `last_status: success`
- no active dispatch/channel misconfiguration

### 4. Critical local services

The local embedding service on `3005` is a critical dependency for:
- QwenPaw semantic memory
- local RAG retrieval
- PDF intake workflows

Protection layers:
- start helper: `ops/scripts/sync/start-local-embedding-server.sh`
- status helper: `ops/scripts/sync/status-local-embedding-server.sh`
- watchdog: `ops/scripts/sync/watchdog-local-embedding-server.sh`
- cron: `Orebit Embedding Server Watchdog`

The public RAG wrapper on `3004` is a separate runtime surface and should be treated as optional until its dependencies are installed and its preflight passes.

### 5. Review queue quality rule

Chat-review automation should prefer under-capture over noise.
Situational operator help, progress reports, and manual troubleshooting chatter should not be promoted just because they are long or structured.

Primary script:
- `ops/scripts/capture/review-chat-candidates.py`

## Quick checks

```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/git/check-repo-health.sh
bash ops/scripts/git/check-runtime-guardrails.sh
bash ops/scripts/sync/status-local-embedding-server.sh
bash ops/scripts/sync/status-obsidian-inbox-autosync.sh
qwenpaw cron list --agent-id default
```

## Recovery posture

If the repo suddenly appears dirty again:
1. inspect `git status --short`
2. classify runtime churn vs canonical change
3. do not commit runtime churn by default
4. verify health before making new operational claims

## Operating principle

Do not claim green from configuration alone.
Claim green only from verified commands, successful cron state, and healthy local services.
