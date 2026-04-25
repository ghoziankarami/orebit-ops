# Orebit — Open Gaps & Todo

## Status: IN PROGRESS

Last updated: 2026-04-25

---

## ✅ Completed

### Autosync (Obsidian Inbox)
- [x] Copy-merge bidirectional sync for `0. Inbox` only
- [x] HARDENED: all other folders permanently blocked
- [x] Daemon with start/stop/status scripts
- [x] Watchdog auto-restart
- [x] Audit logs per sync cycle
- [x] Runbook created

### PARA Capture
- [x] Link capture routing (YouTube/GitHub/article/generic/task)
- [x] YouTube metadata enrichment (yt-dlp)
- [x] Push-only after capture (avoid overwrite)
- [x] Index rebuild script
- [x] Runbook created

### GitHub Governance
- [x] CODEOWNERS file
- [x] PR template
- [x] CI workflow (lint, test)
- [x] Workflow files

### QwenPaw Bridge
- [x] OREBIT_RUNTIME.md in workspace
- [x] QWENPAW_WORKSPACE_BRIDGE.md in repo
- [x] system_prompt_files updated

---

## 🔄 In Progress

- [ ] Full-vault bisync review (dry-run showed many planned deletes)
- [ ] GitHub multi-repo PR automation hardening
- [ ] Daily briefing automation
- [ ] Auto Memory Search embedding backend validation
- [ ] Obsidian autopromote verification
- [ ] QwenPaw fresh-session procedure audit
- [ ] GitHub deploy automation full (secrets, branch protection)

---

## ⏳ Blocked

- **Full-vault bisync**: dry-run shows many planned deletes; need manual review
- **Auto Memory Search**: embedding backend `20128`/`cx/gpt-5.5` does not support embeddings; config empty
- **`/workspace/` mount**: lost in container reset; all files stored in `/app/working/workspaces/default/orebit-rag-deploy/` going forward

---

## 📌 Storage Policy
- **AMAN**: GitHub repo, `/app/working/workspaces/default/`
- **TIDAK AMAN**: `/workspace/` (mount can detach)
- **Commit all important files to GitHub immediately**

---

## 🔑 Key Paths
- Repo: `/app/working/workspaces/default/orebit-rag-deploy/` (cloned from GitHub)
- Vault: `/workspace/obsidian-system/vault`
- Obsidian Inbox sync: `ops/scripts/sync/`
- Capture: `ops/scripts/capture/`
- Runbooks: `ops/runbooks/`
- Ops docs: `docs/operations/`
