# Orebit Canonical Workspace

> **Start here:** `docs/operations/OPERATIONAL_STATUS.md`
> Everything else is a detail doc. OPERATIONAL_STATUS is the source of truth.

---

## This Repo Lives At

```
/app/working/workspaces/default/orebit-ops/
```
Cloned from: `https://github.com/ghoziankarami/orebit-ops`
Branch: `feat/bootstrap-secondbrain-sync`

---

## Active Ops Structure

```
orebit-ops/
├── ops/
│   ├── scripts/
│   │   ├── sync/           # Autosync daemon + scripts
│   │   └── capture/        # PARA link capture (url_ingest.py)
│   └── runbooks/
│       ├── OBSIDIAN_INBOX_AUTOSYNC.md
│       └── PARA_CAPTURE.md
├── docs/
│   ├── operations/         # ← Start here
│   │   ├── OPERATIONAL_STATUS.md   ← Canonical truth
│   │   ├── OPEN_GAPS.md
│   │   ├── QWENPAW_WORKSPACE_BRIDGE.md
│   │   └── OBSIDIAN_INBOX_AUTOSYNC_STATUS.md
│   ├── workflows/
│   │   └── SECOND_BRAIN_CAPTURE_WORKFLOW.md
│   ├── setup/
│   │   └── RCLONE_SETUP.md
│   └── archived/           # Stale docs (do not use)
└── .github/               # CI/CD governance
```

---

## Three Active Workflows

| Workflow | Status | Runbook |
|----------|--------|---------|
| PARA link capture | ✅ Scripts ready | `ops/runbooks/PARA_CAPTURE.md` |
| Obsidian inbox autosync | ✅ Daemon ready, needs rclone OAuth | `ops/runbooks/OBSIDIAN_INBOX_AUTOSYNC.md` |
| RAG (no Docker) | ❌ Needs rebuild | See OPERATIONAL_STATUS.md |

---

## Storage Rules

| Safe | Unsafe |
|------|--------|
| GitHub | `/workspace/` |
| `/app/working/workspaces/default/` | |

**Commit before restart. Clone to reset.**

---

## Quick Links

- [OPERATIONAL_STATUS.md](docs/operations/OPERATIONAL_STATUS.md) — live state
- [OPEN_GAPS.md](docs/operations/OPEN_GAPS.md) — what needs doing
- [PARA_CAPTURE.md](ops/runbooks/PARA_CAPTURE.md) — capture workflow
- [OBSIDIAN_INBOX_AUTOSYNC.md](ops/runbooks/OBSIDIAN_INBOX_AUTOSYNC.md) — sync workflow
