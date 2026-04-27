# Orebit — Open Gaps & Todo

## Status: ACTIVE

Last updated: 2026-04-26

---

## Completed

### Runtime and providers
- [x] 9router restored and pruned to 8 reliable models
- [x] opencode_go configured and pruned to 5 reliable models
- [x] OpenRouter free models reviewed and pruned to 12 retained models
- [x] Active QwenPaw model set to `opencode_go/kimi-k2.6`

### RAG and memory
- [x] Rebuilt RAG without Docker
- [x] Installed local ChromaDB persistence
- [x] Installed local embedding server on port `3005`
- [x] Pointed QwenPaw embedding config to local embedding server
- [x] Validated QwenPaw memory search end-to-end against the local embedding backend

### Obsidian and PARA
- [x] Verified canonical PARA layout from runbooks and older docs
- [x] Established working vault at `/app/working/workspaces/default/obsidian-system/vault`
- [x] Confirmed Google Drive `Obsidian` folder is the intended source of truth
- [x] Added inbox pull/push and initial pull sync scripts

---

## In Progress

- [ ] Complete one clean full-vault sync verification against Google Drive
- [ ] Continue local vault curation for research, fleeting notes, and legacy knowledge promotion
- [ ] Add concrete example notes that exercise the new QwenPaw research-playground templates
- [ ] Wire `rag.orebit.id` to a reproducible Orebit-controlled backend/API deployment path using `rag-public/` and `rag-system/api-wrapper/`
- [ ] Simplify and clean up `rag-system/api-wrapper/rag_public_data.py` now that canonical local corpus wiring has been restored
- [ ] Update canonical docs and runbooks to reflect the new knowledge architecture and capture workflow

---

## Blocked / Deferred

- [ ] rclone write access through service account is blocked by Google Drive quota rules
- [ ] OAuth-based rclone write setup is deferred until user wants to resume it
- [ ] Full bidirectional vault sync should not be enabled until write path is trusted

---

## Key Rules

- Use `/app/working/workspaces/default/` as the only persistent workspace root.
- Do not depend on `/workspace/` for anything important.
- Treat `docs/operations/OPERATIONAL_STATUS.md` as canonical runtime truth.
- Treat `0. Inbox/` as the only default automation write surface.
- Keep embeddings local unless 9router embedding credentials are explicitly fixed.
- Treat QwenPaw chat as an exploration surface and Obsidian notes as the durable artifact surface.
- Promote valuable chat outputs into typed notes instead of keeping them only as transcript history.

---

## Key Paths

- Repo: `/app/working/workspaces/default/orebit-ops`
- Vault: `/app/working/workspaces/default/obsidian-system/vault`
- Chroma store: `/app/working/workspaces/default/file_store/chroma`
- Embedding server: `/app/working/workspaces/default/orebit-ops/rag-system/embedding_server.py`
- RAG script: `/app/working/workspaces/default/orebit-ops/rag-system/rag_no_docker.py`
- Sync scripts: `/app/working/workspaces/default/orebit-ops/ops/scripts/sync`
