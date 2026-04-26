# Orebit Operational Status

> **Last verified:** 2026-04-26 — Source: live runtime, repo audit, and active config review
> **Canonical:** This is the single source of truth for Orebit runtime state.
> Reset by: clone repo -> read this file -> run setup.
>
> **Primary stack:** QwenPaw + local-first RAG + Obsidian PARA + optional Google Drive inbox sync

---

## Storage Policy

| Location | Safe? | Notes |
|----------|-------|-------|
| GitHub (`ghoziankarami/orebit-ops`) | ✅ | Permanent canonical repo |
| `/app/working/workspaces/default/` | ✅ | Persistent workspace path |
| `/workspace/` | ❌ | Volatile — do not use for active runtime |

**Rule:** commit important operational changes to GitHub before resets or runtime changes.

---

## Verified Services

| Service | Port | Reachable from container | Status | Notes |
|---------|------|--------------------------|--------|-------|
| QwenPaw | 8088 | ✅ Yes | ✅ Healthy | Main agent runtime |
| 9router (ninerouter) | 20128 | ✅ Yes | ✅ Running | 8 retained models tested working |
| OpenRouter (via QwenPaw) | 443 | ✅ Yes | ✅ Configured | 12 retained free models; some upstream rate-limited |
| opencode_go | 443 | ✅ Yes | ✅ Tested | 5 retained models tested working |
| Local Embedding Server | 3005 | ✅ Yes | ✅ Running | `all-MiniLM-L6-v2`, OpenAI-compatible `/v1/embeddings` |
| Local RAG | — | ✅ Yes | ✅ Working | ChromaDB + sentence-transformers, no Docker |
| Obsidian Vault | — | ✅ Yes | ✅ Present | `/app/working/workspaces/default/obsidian-system/vault` |
| Google Drive read access | — | ✅ Yes | ✅ Healthy | Folder is visible through rclone service-account remote |
| Google Drive inbox write access | — | ✅ Yes | ✅ Healthy | OAuth remote tested with small write/delete and used for inbox push |
| RAG API (old Docker) | 3004 | ❌ No | ❌ Deprecated | Replaced by local no-Docker stack |
| Streamlit | 8503 | ❌ No | ❌ Not running | Old host-era service, not canonical |

> **Important:** the active embedding path is the local embedding server on port `3005`, not 9router embeddings.

---

## Orebit Repo

- **Repo:** `https://github.com/ghoziankarami/orebit-ops`
- **Branch:** `main`
- **Local path:** `/app/working/workspaces/default/orebit-ops`
- **Reset procedure:** `cd /app/working/workspaces/default && rm -rf orebit-ops && git clone https://github.com/ghoziankarami/orebit-ops`

---

## QwenPaw Runtime

| Aspect | Status | Notes |
|--------|--------|-------|
| Active model | ✅ | `opencode_go/kimi-k2.6` |
| `llm_routing.local` | ✅ | `opencode_go/kimi-k2.6` |
| Local embedding backend | ✅ | `http://127.0.0.1:3005/v1` |
| Embedding model | ✅ | `all-MiniLM-L6-v2` |
| Embedding dimensions | ✅ | `384` |
| 9router chat path | ✅ | Working for retained models |
| 9router embeddings | ❌ | Not usable; upstream OpenAI credential issue |

**Current recommendation:** keep 9router for strong paid chat models, but keep embeddings local.

---

## QwenPaw Cron Jobs (4 configured)

All silent — write to files only, no Telegram messages.

| Name | ID | Schedule | Status | Channel |
|------|----|----------|--------|---------|
| ArsariCore PR Checker | `0c608158-...` | `0 */6 * * *` | ❌ Disabled (budget) | telegram |
| Orebit Autosync Watchdog | `f54e6ef2-...` | `*/5 * * * *` | ✅ Active | none |
| Orebit Runtime Heartbeat | `4ef3ddcf-...` | `*/15 * * * *` | ✅ Active | none |
| Orebit Runtime Audit | `8e998c92-...` | `0 */6 * * *` | ✅ Active | none |

> The autosync watchdog cron is active and the inbox push path now uses the OAuth write remote.

---

## QwenPaw ↔ Provider Integration

| Aspect | Status | Notes |
|--------|--------|-------|
| 9router running | ✅ | `http://127.0.0.1:20128/v1` |
| 9router retained models | ✅ | 8 tested working |
| OpenRouter free models | ✅ | 12 retained; several hit upstream `429` |
| opencode_go models | ✅ | 5 tested working |
| QwenPaw active provider | ✅ | `opencode_go` |
| QwenPaw local chat routing | ✅ | `opencode_go/kimi-k2.6` |
| QwenPaw local embeddings | ✅ | local embedding server on port `3005` |

---

## Verified Model Inventory

> Last tested: 2026-04-26. Inventory pruned to reliable/working models only.

### 9router — 8 Working Models

| Model | Status | Use Case |
|-------|--------|----------|
| `cx/gpt-5.5` | ✅ | Best overall reasoning and agentic work |
| `cx/gpt-5.4` | ✅ | Strong reliable default |
| `cx/gpt-5.3-codex` | ✅ | Standard coding path |
| `cx/gpt-5.3-codex-xhigh` | ✅ | Maximum reasoning depth |
| `cx/gpt-5.3-codex-high` | ✅ | High reasoning |
| `cx/gpt-5.3-codex-low` | ✅ | Faster coding |
| `cx/gpt-5.3-codex-none` | ✅ | Minimal reasoning overhead |
| `cx/gpt-5.2` | ✅ | Stable fallback |

### opencode_go — 5 Working Models

| Model | Status | Use Case |
|-------|--------|----------|
| `kimi-k2.6` | ✅ | Default active model |
| `kimi-k2.5` | ✅ | Reliable coding |
| `glm-5.1` | ✅ | Long-session reasoning |
| `glm-5` | ✅ | Fallback |
| `qwen3.6-plus` | ✅ | Balanced general use |

### OpenRouter Free — 12 Retained Models

| Model | Status | Use Case |
|-------|--------|----------|
| `openai/gpt-oss-120b:free` | ✅ | Strong open-weight reasoning |
| `openai/gpt-oss-20b:free` | ✅ | Smaller fast fallback |
| `nvidia/nemotron-3-super-120b-a12b:free` | ✅ | Big-context OSS option |
| `minimax/minimax-m2.5:free` | ✅ | Good general/coding fallback |
| `inclusionai/ling-2.6-1t:free` | ✅ | Fast reasoning |
| `tencent/hy3-preview:free` | ✅ | General-purpose fallback |
| `inclusionai/ling-2.6-flash:free` | ✅ | Fast/cheap |
| `google/gemma-4-31b-it:free` | ⏳ | Upstream rate-limited |
| `google/gemma-4-26b-a4b-it:free` | ⏳ | Upstream rate-limited |
| `qwen/qwen3-coder:free` | ⏳ | Upstream rate-limited |
| `meta-llama/llama-3.3-70b-instruct:free` | ⏳ | Upstream rate-limited |
| `qwen/qwen3-next-80b-a3b-instruct:free` | ⏳ | Upstream rate-limited |

---

## RAG + Obsidian Architecture

### Canonical paths

- **Vault:** `/app/working/workspaces/default/obsidian-system/vault`
- **Chroma store:** `/app/working/workspaces/default/file_store/chroma`
- **Embedding server:** `/app/working/workspaces/default/orebit-ops/rag-system/embedding_server.py`
- **RAG script:** `/app/working/workspaces/default/orebit-ops/rag-system/rag_no_docker.py`

### Actual behavior

- Obsidian is the human system of record.
- Google Drive `Obsidian` is the intended cross-device source of truth.
- Local container vault is the working mirror used for indexing and automation.
- RAG indexing is local-only and does not require Docker.
- Embeddings are generated locally with `all-MiniLM-L6-v2`.
- QwenPaw chat should be treated as an exploration surface; durable outputs should be promoted into typed vault notes.

### Knowledge architecture

Important current lanes include:
- `0. Inbox/Research/`
- `0. Inbox/AI Sessions/`
- `1. Projects/Research Programs/`
- `1. Projects/Product Studio/`
- `3. Resources/Research Notes/`
- `3. Resources/Literature Notes/`
- `3. Resources/Mining Systems/`
- `3. Resources/Offshore Operations/`
- `3. Resources/Exploration Methods/`
- `3. Resources/SOPs/`
- `3. Resources/Visual Concepts/`
- `3. Resources/Operating Systems/`

### PARA rule

- Automation should write to `0. Inbox/` first.
- Promotion into `1. Projects/`, `2. Areas/`, `3. Resources/`, or `4. Archive/` is deliberate.
- Inbox automation is the only sync lane that should be automated by default.

---

## Google Drive / rclone Status

| Aspect | Status | Notes |
|--------|--------|-------|
| Remote folder discovery | ✅ | Existing `Obsidian` folder visible via `root_folder_id` |
| Read access | ✅ | `rclone lsd gdrive-obsidian:` works |
| Write access | ✅ | OAuth remote works; service-account writes still fail with `storageQuotaExceeded` |
| OAuth finalization | ✅ | Separate OAuth write remote configured and tested |
| Full vault pull completeness | 🟡 | Partial local mirror present; full clean sync still pending |

**Canonical interpretation:** rclone now uses a split-remote model: service account for read and OAuth for inbox write.

---

## Open Gaps (Prioritized)

| Priority | Gap | Blocker |
|----------|-----|---------|
| 🟡 MED | Clean full vault sync verification | Need one non-overlapping final sync/check |
| 🟡 MED | QwenPaw memory search end-to-end validation | Embedding server is working, full workflow still needs explicit test |
| 🟡 MED | Full vault sync verification | Need one non-overlapping final sync/check |
| 🟡 MED | Example typed captures for geology/exploration/offshore/SOP/image requests | Workflow exists, examples still need to be populated |
| 🟢 LOW | GitHub CLI `gh` authentication | `gh` is installed, but not yet logged in |
| 🟢 LOW | ArsariCore PR cron | Disabled by budget choice |

**Completed:**
- ✅ 9router restored and pruned to working models
- ✅ opencode_go configured and tested
- ✅ OpenRouter free set pruned and validated
- ✅ Local RAG rebuilt without Docker
- ✅ Local embedding server installed and running
- ✅ Obsidian PARA vault mirror established locally

---

## Main Read-First Doc

If you only want to read one document to understand the current Obsidian knowledge system, start with:
- `docs/workflows/OBSIDIAN_SYSTEM_SOP.md`

## Quick Reset Checklist

If you clone this repo fresh:

- [ ] Read this file first
- [ ] Verify `curl http://127.0.0.1:20128/v1/models` returns 9router models
- [ ] Verify `curl http://127.0.0.1:3005/health` returns local embedding server health
- [ ] Verify QwenPaw active provider/model in `/app/working/workspaces/default/agent.json`
- [ ] Verify vault exists at `/app/working/workspaces/default/obsidian-system/vault`
- [ ] Rebuild or re-run local RAG ingest if needed
- [ ] Verify both rclone remotes: `gdrive-obsidian` for read and `gdrive-obsidian-oauth` for write if Drive sync is needed
