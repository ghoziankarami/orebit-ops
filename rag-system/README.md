# RAG system

This folder contains the active local RAG runtime pieces used by `orebit-ops`.

## Canonical components

- `rag_no_docker.py` - local ChromaDB + sentence-transformers RAG path
- `embedding_server.py` - local OpenAI-compatible embedding server on port `3005`
- `api-wrapper/` - older wrapper-related code retained only as supporting legacy context

## Current rule

The canonical active path is local-first and no-Docker.
Do not treat the old Docker dashboard/API path as the main runtime unless it is deliberately revived.

## Canonical paths

- Vault: `/app/working/workspaces/default/obsidian-system/vault`
- Chroma store: `/app/working/workspaces/default/file_store/chroma`

## Notes

- `3005` is the active embedding service port.
- The old `3004` wrapper path is not the primary runtime anymore.
- Keep this folder focused on operational RAG pieces that support QwenPaw memory and vault retrieval.
