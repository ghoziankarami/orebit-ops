# Quick Reference: Sync to Google Drive

## 🚀 Agent Commands

### When User Says: "sync to Drive"
```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/sync-all-safe.sh
```

### What to Say to User:
```
✅ Syncing all folders to Google Drive...
[show progress]
✅ Complete! 7 folders synced.

Refresh your Obsidian to see all folders.
```

---

## 📋 Synced Folders

1. **1. Projects** → Google Drive/1. Projects/
2. **2. Areas** → Google Drive/2. Areas/
3. **3. Resources** → Google Drive/3. Resources/
4. **4. Archive** → Google Drive/4. Archive/
5. **Attachments** → Google Drive/Attachments/
6. **Templates** → Google Drive/Templates/
7. **Root files** → Google Drive/

**Time:** ~18 seconds
**Method:** Push-only (LOCAL → Drive)
**Safety:** HIGH (won't delete local files)

---

## ✅ Sync Complete Message

```
✅ Sync complete! Folders synced to Google Drive:
   - 1. Projects: [X] files
   - 2. Areas: [X] files
   - 3. Resources: [X] files
   - 4. Archive: synced
   - Attachments: synced
   - Templates: synced
   - Root: [X] files

Next: Refresh your Obsidian (Google Drive plugin) to see all folders!
```

---

## 🔍 Quick Status Check

```bash
# Inbox daemon
ps -p $(cat /tmp/obsidian-inbox-autosync.pid)

# Test file on Drive
rclone ls gdrive-obsidian-oauth:"0. Inbox/SYNC-TEST-2026-05-01.md"

# Last sync
tail -3 /tmp/obsidian-inbox-autosync-daemon.log
```

---

## 📖 Documentation

- Full SOP: `docs/operations/SOP_SYNC_VAULT_TO_DRIVE.md`
- Best Practice: `ops/scripts/sync/BEST_PRACTICE_SYNC.md`
- Execution Log: `ops/scripts/sync/EXECUTION_COMPLETE.md`
