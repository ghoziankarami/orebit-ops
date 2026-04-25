# QwenPaw Runtime Applied

This document captures only the QwenPaw-related runtime state that has been verified as active and relevant to this repository.

## Purpose

Use this as the repo-local runtime bridge between:

- Orebit RAG deployment assets in this repository
- the live QwenPaw workspace/runtime on the server

This is not a full dump of old OpenClaw workspace documentation.

## Verified active runtime facts

The following items were verified from the live environment.

### QwenPaw workspace

- active workspace path: `/app/working/workspaces/default`
- active runtime config root: `/app/working`
- workspace docs present: `AGENTS.md`, `BOOTSTRAP.md`, `MEMORY.md`, `HEARTBEAT.md`, `agent.json`

### Current operator patterns in runtime

- `AGENTS.md` emphasizes safety, heartbeat discipline, and workspace-local operation
- `BOOTSTRAP.md` is the first-run identity ritual for a workspace, not a deploy runbook
- `MEMORY.md` confirms current durable runtime state such as 9router, the RAG API, and user preferences around exact verified changes
- `HEARTBEAT.md` currently contains an applied PR-checker task for ArsariCore

### Known verified services

- 9router is active at `http://127.0.0.1:20128/v1`
- RAG API is active at `http://127.0.0.1:3004`
- QwenPaw custom routing intent points toward 9router, but end-to-end QwenPaw chat validation is still not fully closed here

## Boundaries

What belongs here:

- runtime facts that matter for operating the Orebit stack from QwenPaw
- verified bridges between this repo and the live server setup
- verified scheduled tasks relevant to this repo

What does not belong here:

- every legacy OpenClaw governance doc
- historical rollout notes that are not active anymore
- speculative config that has not been proven in the live runtime

## Current migration stance

For now, treat `orebit-rag-deploy` as the canonical repo for:

- deploy/bootstrap flow
- public RAG surface
- local Orebit RAG runtime layout
- verified QwenPaw-facing operational notes that are specific to this stack

Treat `openclaw-workspace` as a migration source, not as the canonical source for this repo.
