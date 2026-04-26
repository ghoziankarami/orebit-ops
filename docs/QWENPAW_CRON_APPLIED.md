# QwenPaw Cron Applied

> Last verified: 2026-04-26 — Source: `qwenpaw cron list --agent-id default`

## All Cron Jobs (4 total)

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

## Summary

| Job | Silent? | Telegram? |
|-----|---------|-----------|
| ArsariCore PR Checker | ❌ | ✅ (but disabled) |
| Autosync Watchdog | ✅ | ❌ |
| Runtime Heartbeat | ✅ | ❌ |
| Runtime Audit | ✅ | ❌ |

**User preference:** All cron jobs must be silent. Telegram output only on explicit request.
