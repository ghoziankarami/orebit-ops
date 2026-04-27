# RAG system

This folder contains the active local RAG runtime pieces used by `orebit-ops`.

## Canonical components

- `rag_no_docker.py` - local ChromaDB + local-embedding RAG path with curated vault indexing and query reranking
- `embedding_server.py` - local OpenAI-compatible embedding server on port `3005`
- `../ops/scripts/sync/start-local-embedding-server.sh` - managed start helper for the embedding service
- `../ops/scripts/sync/status-local-embedding-server.sh` - health/status helper for the embedding service
- `api-wrapper/` - older wrapper-related code retained only as supporting legacy context

## Current rule

The canonical active path is local-first and no-Docker.
Do not treat the old Docker dashboard/API path as the main runtime unless it is deliberately revived.

The canonical vault index is intentionally curated for operational second-brain retrieval:
- include the active PARA/workflow knowledge surfaces
- exclude archive/template/daily-note noise
- prioritize inbox, SOP, and operating-system notes for workflow-style queries

## Canonical paths

- Vault: `/app/working/workspaces/default/obsidian-system/vault`
- Chroma store: `/app/working/workspaces/default/file_store/chroma`

## Notes

- `3005` is the active embedding service port.
- The old `3004` wrapper path is not the primary runtime anymore.
- Keep this folder focused on operational RAG pieces that support QwenPaw memory and vault retrieval.
