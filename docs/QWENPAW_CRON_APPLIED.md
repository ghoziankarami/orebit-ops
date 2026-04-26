# QwenPaw Cron Applied

> Last verified: 2026-04-27 — Source: `qwenpaw cron list --agent-id default`

## All Cron Jobs (7 total)

### 1. ArsariCore PR Checker
- **ID:** `0c608158-265f-430e-816f-0c3192a856e0`
- **Schedule:** `0 */6 * * *` (every 6 hours)
- **Status:** ❌ **Disabled** (budget)
- **Session:** `telegram:187945281`
- **Task:** Review open PRs, mark ready if safe, merge if possible

### 2. Orebit Autosync Watchdog
- **ID:** `f54e6ef2-e289-4bca-89cf-782c4af36745`
- **Schedule:** `*/5 * * * *` (every 5 min)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` (silent — no Telegram)
- **Task:** Check obsidian sync daemon, restart if dead, write status to file

### 3. Orebit Runtime Heartbeat
- **ID:** `4ef3ddcf-7293-4bb4-9bf4-abf4b50c754d`
- **Schedule:** `*/15 * * * *` (every 15 min)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` (silent — no Telegram)
- **Task:** Write runtime state to file

### 4. Orebit Runtime Audit
- **ID:** `8e998c92-...`
- **Schedule:** `0 */6 * * *` (every 6 hours)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` (silent — no Telegram)
- **Task:** Audit all Orebit systems

### 5. Orebit Obsidian Sync Backup
- **ID:** `8c0c034c-9437-45f2-b075-ce17066f9d6a`
- **Schedule:** `30 */6 * * *` (every 6 hours at minute 30)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` (silent — no Telegram)
- **Task:** Run `ops/scripts/backup/backup-obsidian-sync-state.sh` and write backup artifacts only

### 6. Orebit Vault Safe Push
- **ID:** `0b237f7e-3a90-42d3-a3c6-0ab1b0875e54`
- **Schedule:** `15 */6 * * *` (every 6 hours at minute 15)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` (silent — no Telegram)
- **Task:** Run `ops/scripts/sync/push-vault-safe.sh` to push local vault changes to Drive

### 7. Orebit PDF Paper Intake
- **ID:** `c7d39d39-4747-4f7a-a44b-82d3a127e31a`
- **Schedule:** `45 */6 * * *` (every 6 hours at minute 45)
- **Status:** ✅ Active
- **Session:** `cron:orebit-silent` (silent — no Telegram)
- **Task:** Ingest vault PDFs into local RAG, write draft notes to `0. Inbox/Papers/`, then push vault changes to Drive

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

**User preference:** All cron jobs must be silent. Telegram output only on explicit request.
