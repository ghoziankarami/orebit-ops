# Orebit Operational Status

> **Last verified:** 2026-04-26 — Source: live runtime + `qwenpaw cron list`
> **Canonical:** This is the single source of truth for Orebit runtime state.
> Reset by: clone repo → read this file → run setup.

---

## Storage Policy

| Location | Safe? | Notes |
|----------|-------|-------|
| GitHub (`ghoziankarami/orebit-ops`) | ✅ | Permanent |
| `/app/working/workspaces/default/` | ✅ | Persistent with container |
| `/workspace/` | ❌ | Volatile — lost on container restart |

**Rule:** Commit all important files to GitHub before restarting anything.

---

## Verified Services

| Service | Port | Reachable from container | Status | Notes |
|---------|------|--------------------------|--------|-------|
| QwenPaw | 8088 | ✅ Yes | ✅ Healthy | Main agent runtime |
| 9router (ninerouter) | 20128 | ✅ Yes | ✅ Running | 459 models, includes embedding |
| RAG API | 3004 | ❌ No | ❌ Not running | Needs Docker (blocked in SumoDok) |
| Streamlit | 8503 | ❌ No | ❌ Not running | Was on host, lost after reset |

> **9router is the key service** — it runs inside the container and provides LLM + embedding via OpenRouter-compatible API.

---

## Orebit Repo

- **Repo:** https://github.com/ghoziankarami/orebit-ops
- **Branch:** `feat/bootstrap-secondbrain-sync`
- **Local:** `/app/working/workspaces/default/orebit-ops/`
- **Reset procedure:** `cd /app/working/workspaces/default && rm -rf orebit-ops && git clone -b feat/bootstrap-secondbrain-sync https://github.com/ghoziankarami/orebit-ops`

---

## QwenPaw Cron Jobs (4 active)

All silent — write to files only, no Telegram messages.

| Name | ID | Schedule | Status | Channel |
|------|----|----------|--------|---------|
| ArsariCore PR Checker | `0c608158-...` | `0 */6 * * *` | ❌ Disabled (budget) | telegram |
| Orebit Autosync Watchdog | `f54e6ef2-...` | `*/5 * * * *` | ✅ Active | none |
| Orebit Runtime Heartbeat | `4ef3ddcf-...` | `*/15 * * * *` | ✅ Active | none |
| Orebit Runtime Audit | `8e998c92-...` | `0 */6 * * *` | ✅ Active | none |

> Watchdog writes status to `docs/operations/OBSIDIAN_INBOX_AUTOSYNC_STATUS.md`

---

## Autosync Daemon

- **Script:** `ops/scripts/sync/autosync-obsidian-inbox-copy-merge.sh`
- **Scope:** `0. Inbox/` only (PARA discipline — only inbox is synced)
- **Interval:** 300s
- **Hardened:** All other folders permanently blocked from sync
- **Status file:** `/tmp/obsidian-inbox-autosync.status`
- **Lock file:** `/tmp/obsidian-inbox-autosync.lock`
- **⚠️ Requires:** rclone OAuth configured (`gdrive-obsidian:` remote)

---

## GitHub Automation

### ArsariCore- Repo
- **Repo:** https://github.com/ghoziankarami/ArsariCore-
- **Main branch:** `master`
- **CI:** ✅ All green on master
- **Last verified:** PR #47 merged — `fix(geology): correct Resource/Reserve tonnage formula`

---

## QwenPaw ↔ 9router Integration

| Aspect | Status | Notes |
|--------|--------|-------|
| 9router running | ✅ | `http://127.0.0.1:20128/v1` |
| 9router models available | ✅ | 459 models including embeddings |
| QwenPaw active model | ⚠️ | `sumopod/MiniMax-M2.7-highspeed` (not 9router) |
| QwenPaw llm_routing.local | ❌ | Empty — not wired to 9router |
| QwenPaw embedding backend | ❌ | Not configured |

**→ See: Phase 2 (wire 9router to QwenPaw)**

---

## Open Gaps (Prioritized)

| Priority | Gap | Blocker |
|----------|-----|---------|
| 🔴 HIGH | Wire 9router to QwenPaw | None — service is running |
| 🔴 HIGH | RAG rebuild (no Docker) | Need design decision |
| 🟡 MED | rclone Google Drive OAuth | Needs browser (headless limitation) |
| 🟡 MED | Full vault bisync | Needs rclone OAuth |
| 🟢 LOW | QwenPaw memory search | Needs embedding backend |
| 🟢 LOW | ArsariCore PR cron | Disabled — re-enable on request |

---

## Quick Reset Checklist

If you clone this repo fresh:

- [ ] Verify `qwenpaw cron list` shows 3 silent jobs
- [ ] Verify `curl http://127.0.0.1:20128/v1/models` returns model list
- [ ] Configure rclone OAuth (needs browser)
- [ ] Wire 9router to QwenPaw (agent.json edit)
- [ ] Rebuild RAG without Docker dependency
