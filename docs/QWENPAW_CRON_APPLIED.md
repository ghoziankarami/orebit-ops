# QwenPaw Cron Applied

> Last verified: 2026-04-27 — Source: `qwenpaw cron list --agent-id default`, `qwenpaw cron state ...`, and manual one-off run checks

## All Cron Jobs (10 total)

### 1. ArsariCore PR Checker
- **ID:** `0c608158-265f-430e-816f-0c3192a856e0`
- **Schedule:** `0 */6 * * *` (every 6 hours)
- **Status:** ❌ **Disabled** (budget)
- **Session:** `telegram:187945281`
- **Task:** Review open PRs, mark ready if safe, merge if possible

### 2. Orebit Autosync Watchdog
- **ID:** `11f98f40-e0e0-49a6-9dac-cba2651ef0ab`
- **Schedule:** `*/5 * * * *` (every 5 min)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` via `console` dispatch (silent — no Telegram)
- **Task:** Check obsidian sync daemon, restart if dead, write status to file

### 3. Orebit Runtime Heartbeat
- **ID:** `d2f0a6fe-a3c6-47bc-9dcd-178a05de7ca0`
- **Schedule:** `*/15 * * * *` (every 15 min)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` via `console` dispatch (silent — no Telegram)
- **Task:** Write runtime state to file

### 4. Orebit Runtime Audit
- **ID:** `7449f8b2-ded4-4682-979e-7825cb649d19`
- **Schedule:** `0 */6 * * *` (every 6 hours)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` via `console` dispatch (silent — no Telegram)
- **Task:** Audit all Orebit systems

### 5. Orebit Obsidian Sync Backup
- **ID:** `96d1a253-1884-4b21-95b5-4d0b51353340`
- **Schedule:** `30 */6 * * *` (every 6 hours at minute 30)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` via `console` dispatch (silent — no Telegram)
- **Task:** Run `ops/scripts/backup/backup-obsidian-sync-state.sh` and write backup artifacts only

### 6. Orebit Vault Safe Push
- **ID:** `66fad5ea-2436-4145-ace5-60cd2bc22841`
- **Schedule:** `15 */6 * * *` (every 6 hours at minute 15)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` via `console` dispatch (silent — no Telegram)
- **Task:** Run `ops/scripts/sync/push-vault-safe.sh` to push local vault changes to Drive

### 7. Orebit PDF Paper Intake
- **ID:** `e61f4651-3b6e-4423-a03c-c1bdc0e4c057`
- **Schedule:** `45 */6 * * *` (every 6 hours at minute 45)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` via `console` dispatch (silent — no Telegram)
- **Task:** Ingest vault PDFs into local RAG, write draft notes to `0. Inbox/Papers/`, then push vault changes to Drive

### 8. Orebit Chat Review Stager
- **ID:** `cf81f82a-d6f0-4d7e-b73f-38ac4f61102c`
- **Schedule:** `10 */6 * * *` (every 6 hours at minute 10)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` via `console` dispatch (silent — no Telegram)
- **Task:** Run `ops/scripts/capture/review-chat-candidates.py` to stage conservative transcript candidates into `0. Inbox/Automation Inbox/`

### 9. Orebit Embedding Server Watchdog
- **ID:** `4ca2c4e3-26ea-4519-bd83-3b75d51cf054`
- **Schedule:** `*/10 * * * *` (every 10 min)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` via `console` dispatch (silent — no Telegram)
- **Task:** Run `ops/scripts/sync/watchdog-local-embedding-server.sh` to keep the local embedding service on `3005` healthy and write runtime status outside the repo tree

### 10. Orebit RAG Wrapper Watchdog
- **ID:** `b09a2f17-6a4b-4af3-80ab-65983f8c855b`
- **Schedule:** `*/10 * * * *` (every 10 min)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` via `console` dispatch (silent — no Telegram)
- **Task:** Run `rag-system/api-wrapper/watchdog-wrapper.sh` to keep the local RAG API wrapper on `3004` healthy and write runtime status outside the repo tree

## Summary

| Job | Silent? | Telegram? |
|-----|---------|-----------|
| ArsariCore PR Checker | ❌ | ✅ (but disabled) |
| Autosync Watchdog | ✅ | ❌ |
| Runtime Heartbeat | ✅ | ❌ |
| Runtime Audit | ✅ | ❌ |
| Obsidian Sync Backup | ✅ | ❌ |
| Vault Safe Push | ✅ | ❌ |
| PDF Paper Intake | ✅ | ❌ |
| Chat Review Stager | ✅ | ❌ |
| Embedding Server Watchdog | ✅ | ❌ |
| RAG Wrapper Watchdog | ✅ | ❌ |

**User preference:** All cron jobs must be silent. Telegram output only on explicit request.
