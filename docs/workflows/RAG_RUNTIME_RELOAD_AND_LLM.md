# RAG Runtime Reload And LLM

This document explains the remaining runtime gap after the remote+cache workflow was verified.

## What is already true

- `OPENROUTER_API_KEY` exists in repo root `.env`
- `rag-system/api-wrapper/index.js` now loads both local wrapper env and repo root `.env`
- retrieval and fallback answers already work

## What is not yet true automatically

The currently running Node API process may have been started before the env-loading fix.
If so, `OPENROUTER_API_KEY` will still be missing from the live process environment.

Observed during verification:

- process env contained `RAG_API_KEY=local-dev-key`
- process env did not contain `OPENROUTER_API_KEY`
- `/api/rag/answer` returned fallback answers with `llm_used: false`

## Required action after code update

Restart the active RAG API service/process so the new env-loading behavior takes effect.

## Verify process env

```bash
ps aux | grep '[n]ode index.js'
tr '\0' '\n' </proc/<PID>/environ | sort | grep -E 'OPENROUTER|RAG_API|PORT|HOST'
```

## Verify LLM answer path after restart

```bash
curl -sS -X POST http://127.0.0.1:3004/api/rag/answer \
  -H 'Content-Type: application/json' \
  -d '{"query":"BenAvraham","top_k":3}'
```

Success signs:

- `llm_used: true`, or
- answer text no longer says the LLM is inactive

## Important note

This is a service-launch/runtime concern, not a repo-structure concern.
The canonical data workflow remains:

1. sync from `gdrive-obsidian:` and `gdrive-research:`
2. work from local vault and local paper cache
3. ingest into repo-local Chroma
4. query through the local API
