---
tags:
  - guide
  - vault
  - para
  - sync-safety
  - canonical
---

# Ghozian's Second Brain

Canonical root guide for how this Obsidian vault is organized, how chat/automation capture works, and how sync-safe behavior should be interpreted.

---

## 1. Role of This File

This `README.md` is the single root guide for:
- vault structure
- capture and promotion flow
- sync-safe write rules
- chat command reference
- operational notes for Siro/OpenClaw behavior in the vault

Root-level `COMMANDS.md` and `WORKSPACE.md` are now merged into this file conceptually.
This file should be treated as the root-readable summary.

---

## 2. Core Structure

### PARA folders
- `0. Inbox/` -> capture, staging, and automation-safe intake
- `1. Projects/` -> active project execution
- `2. Areas/` -> ongoing responsibilities
- `3. Resources/` -> promoted, durable, and read-mostly knowledge
- `4. Archive/` -> inactive historical material

### Important workflow locations
- `0. Inbox/Task Staging.md`
- `0. Inbox/Master Task List.md`
- `0. Inbox/Task Notes/`
- `0. Inbox/Automation Inbox/`
- `0. Inbox/Review Queue.md`
- `0. Inbox/Ideas/`
- `0. Inbox/Links/`
- `0. Inbox/Reading Inbox/`
- `0. Inbox/GitHub Follow-up/`
- `0. Inbox/YouTube to Watch/`
- `0. Inbox/Papers/`
- `3. Resources/Literature Notes/`
- `3. Resources/Evergreen/`
- `3. Resources/Tutorials/`
- `3. Resources/Reference Links/` *(canonical promoted link lane; use this instead of the old `Web Link` lane)*

---

## 3. Sync-Safe Operating Model

This vault is moving toward a safer dual-entry model:
- **Human entry** via desktop/mobile Obsidian synced through Google Drive
- **Automation entry** via Siro/OpenClaw on VPS

### Write-safety rule
- Automation should write by default to low-conflict capture/staging surfaces
- Humans review/promote to more stable/final surfaces
- Critical singleton files should not receive uncontrolled automation writes

### Most important rule
- `0. Inbox/Master Task List.md` is **not** the default automation append target
- `Master Task List.md` is the **reviewed/manual canonical task surface**

### Default automation-safe zones
- `0. Inbox/Task Staging.md`
- `0. Inbox/Ideas/`
- `0. Inbox/Links/`
- `0. Inbox/Reading Inbox/`
- `0. Inbox/GitHub Follow-up/`
- `0. Inbox/YouTube to Watch/`
- `0. Inbox/Papers/`
- `0. Inbox/Automation Inbox/`

---

## 4. Capture Rules

### Tasks
- Default automation intake -> `0. Inbox/Task Staging.md`
- Approved/manual task surface -> `0. Inbox/Master Task List.md`
- Supporting detailed context -> `0. Inbox/Task Notes/`

**Task staging format:**
```markdown
- [ ] Task text 📅 YYYY-MM-DD #priority/medium #task-staging
```

### Notes and ideas
- Note -> `0. Inbox/`
- Idea -> `0. Inbox/Ideas/`
- Paper -> `0. Inbox/Papers/`
- Journal -> `0. Inbox/Journal/`

### Links
- Generic links -> `0. Inbox/Links/`
- Reading/article links -> `0. Inbox/Reading Inbox/`
- GitHub links -> `0. Inbox/GitHub Follow-up/`
- YouTube links -> `0. Inbox/YouTube to Watch/`
- URL capture remains source-aware via canonical URL routing

### Fallback
- Generic automation output with no clean destination -> `0. Inbox/Automation Inbox/`

---

## 5. Approval and Promotion Model

### Task model
- capture first into `Task Staging.md`
- malam: review task staging
- review/approve manually
- then move into `Master Task List.md`
- pagi: execution focus comes from `Master Task List.md`

### Paper model
- `0. Inbox/Papers/` -> approve paper -> `3. Resources/Literature Notes/`

### Idea model
- `0. Inbox/Ideas/` -> promote idea -> promoted knowledge target after review

### Evergreen model
- candidate/reviewed note -> promote evergreen -> `3. Resources/Evergreen/`

### General principle
- capture fast
- review intentionally
- promote deliberately
- archive old material instead of deleting quickly

---

## 6. Chat Command Cheat Sheet

### Capture
- `/task <text> @YYYY-MM-DD !high|medium|low`
- `/todo <text>`
- `/note <text>`
- `/idea <text>`
- `/paper <text>`
- `/journal <text>`
- `/link <url>`
- `/video <url>`
- `/readlater <url>`

Natural-language patterns still valid:
- `task: <text>`
- `note: <text>`
- `idea: <text>`
- `add link <url>`
- `save link <url>`
- `read later <url>`
- raw URL

### Approval / promotion
- `/approve paper <slug|file>`
- `/approve note <slug|file>`
- `/promote idea <slug|file>`
- `/promote evergreen <slug|file>`

### Controls
- `/status`
- `/cancel`
- `/help`
- `/commands`

---

## 7. RAG / Paper Compatibility

The current RAG-friendly direction should be preserved:
- prefer granular markdown notes
- keep paper notes staged first, promoted later
- avoid routing raw scratch output directly into stable resource zones
- stable knowledge should live mainly in:
  - `3. Resources/Literature Notes/`
  - `3. Resources/Evergreen/`

Singleton control files should not become the center of RAG knowledge.
Granular note structure is safer both for sync and for indexing.

---

## 8. Documentation Map

### Root-level
- `README.md` -> root vault guide
- `Home.md` -> daily command center

### Folder READMEs
- `0. Inbox/README.md`
- `1. Projects/README.md`
- `2. Areas/README.md`
- `3. Resources/README.md`
- `4. Archive/README.md`

### Compatibility note
- Legacy folders may still remain during transition
- root interpretation should converge toward this README

---

## 9. Policy Highlights

- Default language for durable knowledge notes: **English**
- Cleanup policy: **archive-first**
- Automation should prefer low-conflict staging surfaces
- Do not casually let automation write directly into `Master Task List.md`
- Staging due tasks may appear in reports, but must be labeled as not yet approved
- Keep docs aligned with live behavior

---

Last updated: 2026-04-05
