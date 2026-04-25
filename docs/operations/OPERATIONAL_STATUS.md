# Orebit — Operational Status

## ⚠️ CONTAINER RESET NOTE
**`/workspace/` mount detached after container reset (2026-04-25).**
Repo re-cloned to: `/app/working/workspaces/default/orebit-ops/`
All scripts and configs are being rebuilt here.

## Services (running on host)
| Service | Port | Status |
|---------|------|--------|
| RAG API | 3004 | ⚠️ need verification |
| QwenPaw | 8088 | ⚠️ need verification |
| ninerouter | 20128 | ⚠️ need verification |
| Streamlit | 8503 | ⚠️ need verification |

## Autosync (Obsidian Inbox ↔ Google Drive)
- Status: 🔴 Need to restart daemon
- Script: `ops/scripts/sync/autosync-obsidian-inbox-copy-merge.sh`
- Daemon: `ops/scripts/sync/run-obsidian-inbox-autosync-daemon.sh`
- Run: `bash ops/scripts/sync/start-obsidian-inbox-autosync.sh`

## PARA Capture
- Script: `ops/scripts/capture/capture-link.sh`
- Status: ✅ Ready to use (rebuilt after reset)

## GitHub
- Repo: `https://github.com/ghoziankarami/orebit-rag-deploy`
- Branch: `feat/bootstrap-secondbrain-sync`
- Last commit: `787a1c8` (docs+ops: verify remote-cache RAG and Obsidian workflow)

## Google Drive
- Remote: `gdrive-obsidian`
- Vault path: `/workspace/obsidian-system/vault`
- Only `0. Inbox` is synced (HARDENED)

## ⚠️ PENDING ACTIONS
1. Restart autosync daemon on host
2. Verify all services are running on host
3. Verify `gh` auth on host
4. Commit all rebuilt files to GitHub
