# RAG system

This folder contains the local RAG runtime pieces used by the repo:

- `api-wrapper/` for the VPS/public API backend on port `3004`
- local Chroma data
- fallback local Streamlit dashboard on port `8503`

Important:

- the canonical public frontend for `rag.orebit.id` is in `../rag-public/`
- `8503` is not the canonical public deployment target
- use `../RAG_PUBLIC_DEPLOYMENT.md` for the final public deployment path
