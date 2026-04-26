# rag.orebit.id Deployment Target

## Current truth

`orebit-ops` now contains the canonical local RAG and Obsidian-operating runtime, but it does not yet contain a live Vercel frontend app for `rag.orebit.id`.

What is already in place:
- QwenPaw is the runtime orchestrator
- local embedding service is active on `3005`
- local Chroma-based RAG is active in `rag-system/`
- PDF intake can write draft paper notes into Obsidian
- QwenPaw cron is the active scheduler for autosync, backup, vault push, and paper intake

## Required end state

The target state for `rag.orebit.id` should be:
- a Vercel-hosted frontend surface
- backed by Orebit-controlled retrieval logic, not a separate ad-hoc manual stack
- operationally documented in this repo
- restartable by cloning `orebit-ops`, restoring secrets, and redeploying

## Current gap

This repo no longer contains the old `rag-public/` frontend because it was removed during cleanup of stale bootstrap surfaces.
That means `rag.orebit.id` is not yet independently redeployable from the current `main` branch alone.

## Canonical requirement going forward

To make `rag.orebit.id` fully independent with QwenPaw and Vercel, the repo must gain:
- a deployable frontend app directory for Vercel
- a documented environment-variable contract
- a documented retrieval/API boundary
- a runbook for production deploy, rollback, and smoke test

## Decision

Treat the current local RAG + QwenPaw + Obsidian system as the canonical backend/runtime foundation.
Treat the public `rag.orebit.id` deployment surface as a missing but planned layer that must be rebuilt intentionally on top of this repo, not inferred from archived docs.

## Near-term recommendation

1. Keep local RAG and Obsidian workflows canonical in `orebit-ops`
2. Rebuild a minimal Vercel frontend in-repo
3. Point that frontend at a documented Orebit-controlled retrieval endpoint
4. Document deploy and smoke test inside this repo
