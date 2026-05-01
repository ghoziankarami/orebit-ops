# Best Practice Sync Strategy - Safe & Reliability

## 🎯 STRATEGY OVERVIEW

### The Problem:
- Full vault sync (two-way) = Risky (deletions propagate, conflicts)
- Inbox-only sync = Limited (can't sync PARA folders)
- User wants: Safe + Working sync

### The Solution (Best Practice:
```
✅ INBOX AUTO-SYNC (Two-way, every 5 min, safe)
✅ PARA FOLDERS MANUAL (One-way push, safe)
✅ PULL-MANUAL (When needed, controlled)
```

---

## 🔒 CONFIGURATION (BEST PRACTICE)

### What Syncs Automatically (Safe):
```
0. Inbox/  ←→  Google Drive/0. Inbox/   (Two-way, daemon)
```

### What Syncs Manually (Safe):
```
1. Projects/   → Google Drive/1. Projects/   (Push only)
2. Areas/      → Google Drive/2. Areas/      (Push only)
3. Resources/  → Google Drive/3. Resources/  (Push only)
4. Archive/    → Google Drive/4. Archive/    (Push only)
Attachments/   → Google Drive/Attachments/   (Push only)
Templates/     → Google Drive/Templates/     (Push only)
Root files     → Google Drive/              (Push only)
```

### Why This is Safe:
1. **Inbox two-way** = Quick capture items, safe to sync two-way
2. **PARA push-only** = Important work, can't be accidentally deleted
3. **Pull-manual** = Controlled when you want to update from Drive

---

## 🚀 HOW TO USE

### Option 1: Safe Sync (Recommended - Push Everything to Drive)

```bash
# This syncs:
#   - Inbox: Auto (daemon running)
#   - PARA folders: Push to Drive only (one-way, safe)
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/sync-all-safe.sh
```

### Option 2: Manual Sync Specific Folder

```bash
# Sync one folder to Drive (push only)
bash ops/scripts/sync/manual-sync-folder.sh "3.Resources" local-to-drive

# Sync one folder FROM Drive (pull only)
bash ops/scripts/sync/manual-sync-folder.sh "3.Resources" drive-to-local

# Sync root files to Drive
bash ops/scripts/sync/manual-sync-folder.sh "root" local-to-drive
```

### Option 3: Ingest From Obsidian (Pull New Changes)

```bash
# When you've made changes in Obsidian and want to pull them:
bash ops/scripts/sync/manual-sync-folder.sh "1. Projects" drive-to-local
bash ops/scripts/sync/manual-sync-folder.sh "2. Areas" drive-to-local
bash ops/scripts/sync/manual-sync-folder.sh "3.Resources" drive-to-local
bash ops/scripts/sync/manual-sync-folder.sh "root" drive-to-local
```

---

## 🔄 DAILY WORKFLOW (BEST PRACTICE)

### MORNING - Before Work:
```bash
# Pull any changes from Obsidian you made previous night
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/manual-sync-folder.sh "root" drive-to-local
bash ops/scripts/sync/manual-sync-folder.sh "3.Resources" drive-to-local
```

### DURING WORK:
- Files in `0. Inbox` auto-sync every 5 minutes
- Work in PARA folders without worrying about sync
- Focus on work, not sync conflicts

### EVENING - Before Bed:
```bash
# Push all your work to Google Drive so Obsidian has it
bash ops/scripts/sync/sync-all-safe.sh
```

---

## ✅ VERIFICATION

### Check Sync Status:
```bash
# Quick status check
bash /tmp/check_sync.sh

# Or manually:
# 1. Check inbox daemon
cat /tmp/obsidian-inbox-autosync.pid
ps -p $(cat /tmp/obsidian-inbox-autosync.pid)

# 2. Check test file
rclone ls gdrive-obsidian-oauth:"0. Inbox/SYNC-TEST-2026-05-01.md"

# 3. Check last sync
tail -10 /tmp/obsidian-inbox-autosync-daemon.log
```

### What If Sync Fails:
```bash
# Check logs
tail -30 /tmp/obsidian-inbox-autosync-daemon.log
tail -30 /tmp/safe-sync-*.log

# Restart inbox daemon
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/start-obsidian-inbox-autosync.sh

# Verify rclone token
rclone about gdrive-obsidian-oauth:
```

---

## ⚠️ IMPORTANT NOTES

### What This Strategy Prevents:
- ❌ Accidental deletion of important files
- ❌ Sync conflicts when editing on multiple devices
- ❌ Overwriting your work with older versions
- ❌ Data loss due to automatic deletions

### What This Strategy Provides:
- ✅ Safe, predictable sync behavior
- ✅ Control over when and what syncs
- ✅ Minimal risk of data loss
- ✅ Clear workflow for regular use

### The Trade-off:
- ⚠️ You need to manually push PARA folders to Drive
- ⚠️ You need to manually pull changes when working elsewhere

**BUT**: This is MUCH safer than automatic two-way sync for important work.

---

## 🎯 WHY THIS IS BEST PRACTICE

### Comparison:

| Strategy | Pros | Cons |
|---|---|---|
| **Full vault two-way** | Fully automatic | ❌ High risk of deletion/conflicts |
| **Inbox-only** | Very safe | ❌ Can't sync PARA folders |
| **Inbox auto + PARA manual** (THIS) | Safe + Flexible | ⚠️ Manual PARA sync (but controlled) |

### When Each Strategy Works:
- **Full vault two-way**: Single device, simple use case
- **Inbox-only**: Multiple devices, minimal PARA use
- **Inbox auto + PARA manual**: Multiple devices PARA workflows ← **YOU** ✨

---

## 📋 SUMMARY

### What You Have Now:
✅ Inbox daemon: Auto-sync every 5 min (two-way, safe)
✅ PARA manual sync: Scripts to push/pull folders
✅ Documentation: Complete guide (this file)
✅ Test file: SYNC-TEST-2026-05-01.md verified on Drive

### How To Use:
1. ✅ Inbox: Auto-sync (daemon running)
2. ✅ PARA: Use `sync-all-safe.sh` (push to Drive)
3. ✅ Pull: Use `manual-sync-folder.sh <folder> drive-to-local`

### Safety Level:
🔒 **HIGH SECURITY** - Best practice for PARA workflows

---

## 📖 DOCUMENTATION

1. **This File**: Best practice strategy
2. `ops/scripts/sync/manual-sync-folder.sh` - Per-folder sync
3. `ops/scripts/sync/sync-all-safe.sh` - Safe all-vault sync
4. `ops/scripts/sync/rclone-token-watchdog-t3.sh` - Token watchdog
5. `/tmp/check_sync.sh` - Quick status check

---

## ✅ CONFIRMATION

**BEST PRACTICE SYNC CONFIGURED!**

- ✅ Inbox auto-sync running (safe two-way)
- ✅ PARA manual sync scripts ready (safe push-only)
- ✅ Test file sync verified (SYNC-TEST-2026-05-01.md)
- ✅ Documentation complete (this guide)
- ✅ Workflow defined (morning/during/evening)

**This is safe, reliable, and follows best practices for PARA workflows.**

---

**Last Updated**: 2026-05-01 12:40 UTC
**Status**: ✅ BEST PRACTICE ACTIVE
