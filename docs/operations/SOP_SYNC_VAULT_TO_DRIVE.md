# SOP: Sync Obsidian Vault to Google Drive

## 🚀 QUICK START

### What To Say:
- "sync to Drive"
- "push to Google Drive"
- "sync Obsidian"
- "backup to Drive"

### What Happens:
1. Agent syncs all folders to Google Drive (~18 seconds)
2. Refresh Obsidian to see all folders

---

## 📚 BEST PRACTICE SYNC STRATEGY

### Inbox (Auto - Already Running):
```
0. Inbox/  ←→  Google Drive/0. Inbox/
- Auto-syncs every 5 minutes
- Two-way sync (safe)
- No manual action needed
```

### PARA Folders (Manual - Safe Push):
```
1. Projects/   → Google Drive/1. Projects/
2. Areas/      → Google Drive/2. Areas/
3. Resources/  → Google Drive/3. Resources/
4. Archive/    → Google Drive/4. Archive/
Attachments/   → Google Drive/Attachments/
Templates/     → Google Drive/Templates/
Root files     → Google Drive/
```
- Push-only (LOCAL → Drive)
- ~18 seconds to sync all folders
- Safe, won't delete local files

---

## 🎯 USAGE PATTERNS

### Pattern 1: Sync All (Most Common)

**User says:** "sync to Drive"

**Agent does:**
```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/sync-all-safe.sh
```

**Agent responds:**
```
✅ Sync complete! Folders synced to Google Drive:
   - 1. Projects: 21 files
   - 2. Areas: 12 files
   - 3. Resources: 780 files
   - 4. Archive: synced
   - Attachments: synced
   - Templates: synced
   - Root: 1,231 files

Next: Refresh your Obsidian (Google Drive plugin) to see all folders!
```

### Pattern 2: Sync Specific Folder

**User says:** "sync 3.Resources to Drive"

**Agent does:**
```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/sync-all-safe.sh

# If user specifically wants one folder:
# bash ops/scripts/sync/manual-sync-folder.sh "3.Resources" "local-to-drive"
```

**Note:** Typically just sync all folders, it's only ~18 seconds.

### Pattern 3: Sync Status Check

**User says:** "check sync status"

**Agent does:**
```bash
# Check inbox daemon
cat /tmp/obsidian-inbox-autosync.pid
ps -p $(cat /tmp/obsidian-inbox-autosync.pid)

# Check test file
rclone ls gdrive-obsidian-oauth:"0. Inbox/SYNC-TEST-2026-05-01.md"

# Check last sync
tail -3 /tmp/obsidian-inbox-autosync-daemon.log
```

**Agent responds:**
```
✅ Sync Status:
   🐕 Inbox daemon: RUNNING (PID 3303172)
   ✅ Test file: EXISTS on Google Drive
   👀 Last sync: 13:05:54 UTC
   📋 PARA folders: Currently only available locally
```

---

## 📋 DAILY WORKFLOW SOP

### Morning Routine
**User starts work:**

If user worked on Obsidian from another device:
```
User: "pull from Drive" OR "sync from Obsidian"
Agent: Syncs Drive → Local for requested folders
```

Otherwise:
```
User starts working normally
Agent: Nothing needed (PARA folders are local)
```

### During Day Routine
**User working:**

User creates files in `0. Inbox`:
```
Agent: Automatically syncs to Drive (every 5 min)
User: Files visible in Obsidian after refresh
```

User works in PARA folders:
```
Agent: Sync stays local (no automatic sync yet)
User: Focus on work, no interruption
```

### Evening/Bedtime Routine
**User prepares to stop work:**

Before going offline:
```
User: "sync to Drive"
Agent:
  1. Runs sync-all-safe.sh (~18 seconds)
  2. Reports which folders synced
  3. Reminds user to refresh Obsidian
```

Why this timing:
- ✅ Ensures latest work on Drive
- ✅ Safe to go offline
- ✅ Obsidian has latest changes

---

## 🔒 SAFETY PROTOCOLS

### What's Prevented:
- ❌ Accidental deletion of important files
- ❌ Sync conflicts on multiple devices
- ❌ Overwriting work with older versions
- ❌ Data loss from auto-deletion

### Safety Features:
- ✅ Push-only for PARA (LOCAL → Drive)
- ✅ Control over when sync happens
- ✅ Inbox auto-sync (safe for quick capture)
- ✅ Manual PARA sync (user decides)

### Critical Warnings:
- ⚠️ PARA sync is one-way (won't pull from Drive)
- ⚠️ If edited in Obsidian, need manual pull
- ⚠️ Don't edit same file on two devices simultaneously

---

## 🚨 TROUBLESHOOTING

### Problem: Script Not Found
**Solution:**
```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/sync-all-safe.sh
```

### Problem: Permission Denied
**Solution:**
```bash
chmod +x /app/working/workspaces/default/orebit-ops/ops/scripts/sync/sync-all-safe.sh
```

### Problem: Sync Failed
**Check logs:**
```bash
tail -50 /app/working/workspaces/default/orebit-ops/docs/audits/sync/safe-sync-*.log
```

### Problem: Inbox Daemon Not Running
**Restart daemon:**
```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/start-obsidian-inbox-autosync.sh
```

---

## 📊 VERIFICATION CHECKLIST

### Before Sync:
- [ ] User wants to sync PARA folders to Drive
- [ ] Ready to wait ~18 seconds
- [ ] Understands push-only will happen

### During Sync:
- [ ] Script running
- [ ] Folders being synced (check which)
- [ ] No errors in output

### After Sync:
- [ ] Sync complete message shown
- [ ] User refreshes Obsidian
- [ ] All folders visible in Obsidian

---

## ✅ SUCCESS CRITERIA

### Sync Success:
- ✅ All 7 folders synced
- ✅ Files count matches expectation
- ✅ No errors in logs
- ✅ Obsidian refreshable

### User Success:
- ✅ User understands what happened
- ✅ User refreshes Obsidian
- ✅ User sees all folders
- ✅ User satisfied with sync

---

## 📖 RELATED SOPs

- **Pull from Drive**: For updating local vault from Obsidian
- **Rclone Token Management**: For OAuth token refresh
- **Backups**: Automated backup every 6 hours

---

## 📦 FILES REFERENCE

**Script:**
`orebit-ops/ops/scripts/sync/sync-all-safe.sh`

**Documentation:**
`orebit-ops/ops/scripts/sync/BEST_PRACTICE_SYNC.md`
`orebit-ops/ops/scripts/sync/EXECUTION_COMPLETE.md`

**Logs:**
`orebit-ops/docs/audits/sync/safe-sync-YYYYMMDD.log`

**Daemon:**
`/tmp/obsidian-inbox-autosync.pid`
`/tmp/obsidian-inbox-autosync-daemon.log`

---

## 🎯 AGENT PROMPTS

### When user says "sync to Drive":
```
User wants to sync vault to Google Drive. Action:
1. Run: cd /app/working/workspaces/default/orebit-ops && bash ops/scripts/sync/sync-all-safe.sh
2. Wait for completion (~18 seconds)
3. Report which folders synced
4. Tell user to refresh Obsidian
```

### When user says "sync 3.Resources":
```
User wants to sync specific folder. Action:
1. Run full safe sync (sync-all-safe.sh) - it's fast (~18s) and syncs all PARA folders
2. Report success
3. Tell user folder is on Drive
```

### When user says "check sync":
```
User wants status. Action:
1. Check inbox daemon status
2. Check test file on Drive
3. Check last sync time
4. Report status summary
```

---

## ✅ STATUS

**Production Ready:** YES
**Tested & Verified:** YES
**Last Update:** 2026-05-01
**Execution Time:** ~18 seconds for all folders
**Safety Level:** HIGH (push-only prevents data loss)
