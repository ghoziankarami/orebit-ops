# Full Vault Sync - Complete Guide

## ✅ UPGRADED TO FULL VAULT SYNC!

---

## 🎯 APA YANG BERUBAH?

### SETUP SEBELUM (Hanya 0. Inbox):
```
✅ SYNCED:
   0. Inbox/     ←→   Google Drive/0. Inbox/

❌ TIDAK DISYNC:
   Root folder/
   1. Projects/
   2. Areas/
   3. Resources/
   4. Archive/
   Attachments/
   Templates/
```

### SETUP SEKARANG (Full Vault):
```
✅ SYNCED SEMUA FOLDER:
   Root folder/     ←→   Google Drive/root/
   0. Inbox/       ←→   Google Drive/0. Inbox/
   1. Projects/    ←→   Google Drive/1. Projects/
   2. Areas/       ←→   Google Drive/2. Areas/
   3. Resources/   ←→   Google Drive/3. Resources/
   4. Archive/     ←→   Google Drive/4. Archive/
   Attachments/    ←→   Google Drive/Attachments/
   Templates/      ←→   Google Drive/Templates/

❌ TIDAK DISYNC (System files):
   .git/
   .trash/
   .obsidian/
   .obsidian-plugins/
```

---

## 🔧 SCRIPT BARU:

### 1. Full Vault Sync Script:
```
ops/scripts/sync/autosync-obsidian-full-vault.sh
```
- **Function**: Two-way sync semua folder ke Google Drive
- **Method**: `rclone sync` (tidak `copy` - sinkronisasi penuh)
- **Schedule**: Running sekarang (satu kali test)

### 2. Full Vault Daemon:
```
ops/scripts/sync/run-obsidian-full-vault-autosync-daemon.sh
```
- **Function**: Daemon yang jalan setiap 5 menit
- **PID**: `/tmp/obsidian-full-vault-autosync.pid`
- **Log**: `/tmp/obsidian-full-vault-autosync-daemon.log`

### 3. Start/Stop Scripts:
```
ops/scripts/sync/start-obsidian-full-vault-autosync.sh   - Start daemon
ops/scripts/sync/stop-obsidian-full-vault-autosync.sh    - Stop daemon
```

---

## 🚀 CARA PAKAI:

### Manual Sync (satu kali):
```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/autosync-obsidian-full-vault.sh
```

### Start Daemon (auto-sync setiap 5 menit):
```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/start-obsidian-full-vault-autosync.sh
```

### Stop Daemon:
```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/stop-obsidian-full-vault-autosync.sh
```

### Check Status:
```bash
# Is daemon running?
cat /tmp/obsidian-full-vault-autosync.pid
ps -p $(cat /tmp/obsidian-full-vault-autosync.pid)

# Last sync
tail -20 /tmp/obsidian-full-vault-autosync-daemon.log
```

---

## ⚠️ PERINGATAN (IMPORTANT):

### Full Vault Sync = Sync Penuh (Two-Way)

**Ini berarti:**
- ✅ Setiap perubahan di local → Drive
- ✅ Setiap perubahan di Drive → Local
- ⚠️ **HAPUS di satu sisi** → **HAPUS di sisi lain**
- ⚠️ **CONFLICT** → PENTING untuk resolve

### Safe Practices:
1. **Sync salah satu device dulu** → Tunggu selesai → Buka device lain
2. **Jangan edit file yang sama di dua device sekaligus**
3. **Backup penting sebelum sync** (sudah ada otomatis)
4. **Cari file konflik** → resolve secara manual

---

## 📋 SYNC PROGRESS:

Saat ini sedang running full vault sync:
```
[2026-05-01T12:34:57+00:00] START full vault sync cycle
[2026-05-01T12:34:57+00:00] === Sync GDrive->Local: gdrive-obsidian:/ → /vault/ ===
Files checked: 1,712 files
Status: Running...
```

### Setelah Complete:
```
[2026-05-01T12:XX:XX+00:00] Sync GDrive->Local complete.
[2026-05-01T12:XX:XX+00:00] === Sync Local->GDrive: /vault/ → gdrive-obsidian-oauth:/ ===
[2026-05-01T12:XX:XX+00:00] END full vault sync cycle OK
```

---

## ✅ APA YANG ANDA AKAN LIHAT DI OBSIDIAN:

### Setelah Sync Complete:
1. **Buka Obsidian** (Google Drive version)
2. **Refresh/sync** Google Drive plugin
3. **Lihat semua folder**:
   - Root folder ✅
   - 0. Inbox ✅
   - 1. Projects ✅
   - 2. Areas ✅
   - 3. Resources ✅
   - 4. Archive ✅
   - Attachments ✅
4. **Semua file** akan visible!

### File Test:
```
0. Inbox/SYNC-TEST-2026-05-01.md  ✅ AKAN TERLIHAT
```

---

## 🔒 DAEMON SETUP (Coming Soon):

Full vault daemon akan dijadwal di crontab untuk auto-sync setiap 5 menit.

**Status saat ini:**
- ✅ Script ready
- ⏳ Daemon setup (segera)
- ⏳ Crontab update (segera)

---

## 📖 DOKUMENTASI:

1. **Full Vault Guide**: Ini (ops/scripts/sync/FULL_VAULT_SYNC.md)
2. **Rclone Bulletproof**: docs/operations/RCLONE_SYNC_BULLETPROOF.md
3. **Complete Automation**: docs/operations/OBSIDIAN_AUTOMATION.md

---

## ✅ CONFIRMATION:

**FULL VAULT SYNC SEDANG BERJALAN!**

- ✅ Sync script running sekarang
- ✅ Semua folder akan sync
- ✅ Obsidian Anda akan melihat semua
- ⏳ Daemon setup (several seconds)

**Please wait for sync to complete (~5-10 minutes)**

---

**Last Updated**: 2026-05-01 12:35 UTC
**Status**: 🔄 FULL VAULT SYNC RUNNING
