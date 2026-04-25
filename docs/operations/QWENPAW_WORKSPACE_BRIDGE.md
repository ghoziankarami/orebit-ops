# QwenPaw Workspace Bridge

## Purpose
Bridge between QwenPaw container runtime and Orebit operational repo.

## Storage Policy (POST-RESET)
⚠️ **`/workspace/` is NOT reliable for permanent storage.**
Container resets can detach `/workspace/` mount.

**Safe locations:**
- **GitHub**: all files committed here (permanent)
- **`/app/working/workspaces/default/`**: persistent with container

## Repo Location
```
/app/working/workspaces/default/orebit-rag-deploy/
```
(Cloned from GitHub: `https://github.com/ghoziankarami/orebit-rag-deploy`)
(Branch: `feat/bootstrap-secondbrain-sync`)

## Key Files in QwenPaw Workspace
- `OREBIT_RUNTIME.md` — runtime bridge (in workspace root)
- `agent.json` — agent config with system_prompt_files

## Ops Files in Repo
```
orebit-rag-deploy/
├── ops/
│   ├── scripts/
│   │   ├── sync/          # Autosync daemon + scripts
│   │   ├── capture/       # PARA link capture
│   │   └── obsidian/      # Index rebuild
│   └── runbooks/          # Runbook docs
├── docs/
│   └── operations/        # Operational docs
└── .github/               # GitHub governance
```

## Cron Jobs (QwenPaw)
- **Autosync Watchdog**: every 5 min (SILENT — no chat messages)
- All Orebit cron jobs run SILENT (write to files only, no chat output)

## Service Endpoints
- RAG API: `http://127.0.0.1:3004`
- QwenPaw: `http://127.0.0.1:8088`
- ninerouter: `http://127.0.0.1:20128`
- Streamlit: `http://127.0.0.1:8503`

## Best Practices
1. **Commit to GitHub immediately** after creating important files
2. **Never rely on `/workspace/`** for permanent storage
3. **Test sync scripts** before deploying
4. **All automation SILENT** — no chat messages
5. **Keep OREBIT_RUNTIME.md updated** in workspace
