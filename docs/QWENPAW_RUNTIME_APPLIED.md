# QwenPaw Runtime Applied

> Last verified: 2026-04-26

## Workspace Path

- `/app/working/workspaces/default/`

## System Prompt Files (enabled)

- `AGENTS.md`, `SOUL.md`, `PROFILE.md`, `OREBIT_RUNTIME.md`
- `HEARTBEAT.md` and `MEMORY.md` loaded natively by QwenPaw

## Verified Active Services

| Service | Port | Status | Notes |
|---------|------|--------|-------|
| QwenPaw | 8088 | ✅ | Main runtime |
| 9router | 20128 | ✅ | LLM + embedding, OpenRouter-compatible |
| RAG API | 3004 | ❌ | Not running — Docker blocked in SumoDok |

## QwenPaw Model Config

- **Active model:** `sumopod` / `MiniMax-M2.7-highspeed`
- **llm_routing.local:** Empty — 9router not wired yet
- **embedding_cache/:** Exists but no backend configured

## What Is NOT True (Stale Claims Removed)

- ❌ "RAG API active at port 3004" — RAG is not running
- ❌ "ChromaDB persistent storage active" — lost in container reset
- ❌ "9router fully integrated with QwenPaw" — pending Phase 2
- ❌ "qwenpaw.orebit.id domain" — needs re-verification

## Phase 2: Wire 9router

See `docs/operations/OPERATIONAL_STATUS.md` → "Open Gaps"
