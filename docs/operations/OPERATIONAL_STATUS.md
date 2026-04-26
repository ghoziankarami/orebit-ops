# Orebit Operational Status

> Last updated: 2026-04-26

## Services

| Service | Port | Status | Endpoint |
|---------|------|--------|----------|
| QwenPaw | 8088 | ✅ Healthy | http://localhost:8088 |
| RAG API | 3004 | ⚠️ Unknown (port not reachable from container) | http://10.0.1.154:3004 |
| ninerouter | 20128 | ⚠️ Unknown (port not reachable from container) | http://10.0.1.154:20128 |
| Streamlit | 8503 | ⚠️ Unknown (port not reachable from container) | http://10.0.1.154:8503 |

> Services RAG/ninerouter/Streamlit berjalan di host Orebit (10.0.1.154), tidak reachable dari dalam SumoDok container ini karena network namespace berbeda.

## Orebit Repo

- **Repo**: https://github.com/ghoziankarami/orebit-ops
- **Branch**: `feat/bootstrap-secondbrain-sync`
- **Local path**: `/app/working/workspaces/default/orebit-ops/`
- **Last audit**: 2026-04-26

## GitHub Automation

### ArsariCore Repository
- **Repo**: https://github.com/ghoziankarami/ArsariCore-
- **Main branch**: `master`
- **Cron job**: `ArsariCore PR Checker` (every 6 hours)
- **Latest**: PR #47 merged — fix(health): graceful DatabaseHealthCheck + static HTML smoke gate fixes
- **CI**: ✅ All green on master

### ArsariCore- CI Fixes Applied
PR #47 (`fix/geology-resource-tonnage-formula`) fixed:
1. **HTML smoke gate tests** — missing space before "Reference", "All Types" → "All"
2. **DatabaseHealthCheck** — graceful handling of missing relational provider (CI/test environments), null-safe logger, `InvalidOperationException` → `Unhealthy` (not skip)
3. **Whitespace formatting** — removed trailing whitespace, consistent 12-space catch indent

## Autosync Daemon

- **PID**: 432343 (may have died; use `status-autosync.sh` to check)
- **Scope**: `0. Inbox` ↔ `gdrive-obsidian:0. Inbox`
- **Interval**: 300s
- **Mode**: copy-merge, no deletes (safe side)
- **Lock file**: `/tmp/obsidian-inbox-autosync.lock`
- **Log**: `docs/audits/sync/obsidian-inbox-autosync-YYYYMMDD-HHMMSS.log`

## QwenPaw Cron Jobs

| Name | Schedule | Session | Status |
|------|----------|---------|--------|
| ArsariCore PR Checker | `0 */6 * * *` | telegram | ✅ Active |
| Orebit Autosync Watchdog | `*/5 * * * *` | silent | ✅ Active |
| Orebit Runtime Heartbeat | `*/15 * * * *` | silent | ✅ Active |
| Orebit Runtime Audit | `0 */6 * * *` | silent | ✅ Active |

## Critical Gaps

- ❌ Docker unavailable in SumoDok container — cannot install Docker-based services
- ❌ `/workspace/` is volatile — file apa pun di sana akan hilang saat container restart
- ❌ Google Drive OAuth belum configured — rclone perlu browser untuk otorisasi
- ❌ rclone Google Drive remote `gdrive-obsidian` belum tested dengan OAuth
- ❌ Auto Memory Search embedding backend belum valid
- ❌ 9router installed but not configured (need OpenRouter/API key)
- ⚠️ Full-vault bisync perlu manual review dulu sebelum apply
