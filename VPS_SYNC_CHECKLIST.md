# VPS Sync Checklist

## 📋 OVERVIEW

**Objective:** Keep VPS (orebit-sumopod) synchronized with latest updates from QwenPaw

**Current Status:** ⚠️ **NEEDS SYNC** - UI updates available

---

## ✅ YES, YOU'RE RIGHT!

**Problem Identified:**
- RAG Public UI has latest features (May 2, 2026)
- VPS has older UI (unknown version)
- UI in rag.orebit.id is **NOT** the latest version

---

## 🔍 WHAT NEEDS SYNC?

### **Category 1: React UI Updates (MEDIUM FREQUENCY)**

| Component | Last Updated | VPS Status | Action Needed |
|-----------|--------------|------------|---------------|
| **React UI** | May 2, 2026 | ⚠️ OLD | ✅ Deploy Now |
| **Features** | Latest | ❌ Missing | ✅ Deploy Now |

**UI Features to Deploy:**
- ✅ Surface corpus trust metrics
- ✅ Show Obsidian paper summaries in UI
- ✅ Strip JATS tags from source snippets
- ✅ Improve library card readability
- ✅ Hero density improvements
- ✅ Typography matches Orebit showcase

**How Often:** When rag-public has new commits

---

### **Category 2: Configuration Updates (LOW FREQUENCY)**

| Config | VPS Status | When to Update |
|--------|------------|----------------|
| **Tunnel URL** | venture-stud-gale-fuji... | When tunnel changes |
| **Nginx Config** | Configured | When adding new routes |
| **API Key** | Set | When changing API key |

**How Often:** Rarely (manual triggers)

---

### **Category 3: Data Updates (SYNCED AUTOMATICALLY)**

| Data | Location | Sync Method | Frequency |
|------|----------|-------------|-----------|
| **ChromaDB** | QwenPaw local | Cloudflare Tunnel | Real-time |
| **Papers** | QwenPaw local | Cloudflare Tunnel | Real-time |
| **Embeddings** | QwenPaw local | Cloudflare Tunnel | Real-time |

**How Often:** Automatic via Cloudflare Tunnel (NO action needed)

---

## 🚀 IMMEDIATE ACTION REQUIRED

### **DEPLOY LATEST UI TO VPS**

**Step 1: Prepare UI Package**
```bash
cd /app/working/workspaces/default/orebit-ops
bash vps-prepare-ui-update.sh
```

**What it does:**
- Builds latest React UI from rag-public
- Creates deployment package with version info
- Generates deployment script for VPS

**Step 2: Deploy to VPS (AUTOMATED)**

If SSH keys configured:
```bash
bash vps-deploy-ui-automated.sh
```

If SSH not configured (MANUAL):
```bash
# Transfer package to VPS
scp vps-ui-package-* root@43.157.201.50:/tmp/

# SSH to VPS
ssh root@43.157.201.50

# Extract and deploy
cd /tmp
tar -xzf rag-ui-package-*.tar.gz
cd vps-ui-package
bash deploy-to-vps.sh
```

**Step 3: Verify Deployment**
```bash
# Test UI
curl -I https://rag.orebit.id/

# Check version
ssh root@43.157.201.50 "cat /var/www/rag-ui/VERSION.txt"
```

---

## 📊 SYNC FREQUENCY GUIDE

### **HIGH PRIORITY (Sync Immediately)**

| Item | Trigger | Sync Method | Time to Deploy |
|------|---------|-------------|----------------|
| **UI Updates** | New rag-public commit | Package + Deploy | 5-10 min |
| **Critical Bug Fix** | Security issue | Patch + Deploy | 2-5 min |
| **Tunnel URL Change** | Tunnel restarted | Update Nginx | 2 min |

### **MEDIUM PRIORITY (Sync When Needed)**

| Item | Trigger | Sync Method | Time to Deploy |
|------|---------|-------------|----------------|
| **Nginx Config** | New route needed | Edit config | 5 min |
| **SSL Update** | Certificate expiry | Let's Encrypt | Auto-renew |

### **LOW PRIORITY (Rare)**

| Item | Trigger | Sync Method | Time to Deploy |
|------|---------|-------------|----------------|
| **API Key** | Change auth key | Update env var | 1 min |
| **Backup/Restore** | System failure | Manual restore | Manual |

---

## 🔧 AUTOMATION OPTIONS

### **Option 1: Automated Deployment (Preferred)**

**Prerequisites:**
- SSH keys configured between QwenPaw and VPS
- User has sudo access on VPS

**How to Setup SSH Keys:**
```bash
# On QwenPaw
ssh-keygen -t rsa -b 4096 -f ~/.ssh/vps_deploy

# Copy public key to VPS
ssh-copy-id -i ~/.ssh/vps_deploy.pub root@43.157.201.50

# Test connection
ssh -i ~/.ssh/vps_deploy root@43.157.201.50 "echo 'SSH OK'"

# In vps-deploy-ui-automated.sh, add:
# export SSH_KEY="-i /root/.ssh/vps_deploy"
```

**Benefits:**
- One-command deployment
- Automated backups
- Rollback capability
- Zero downtime

---

### **Option 2: Manual Deployment (Current)**

**Prerequisites:**
- Manual file transfer via scp/sftp
- SSH access to VPS
- Manual Nginx restart

**Process:**
```bash
# 1. Prepare package
bash vps-prepare-ui-update.sh

# 2. Transfer files
scp -r vps-ui-package/* root@43.157.201.50:/tmp/

# 3. SSH to VPS
ssh root@43.157.201.50

# 4. Deploy on VPS
cd /tmp/vps-ui-package
bash deploy-to-vps.sh
```

**Benefits:**
- No SSH key setup required
- Works from anywhere
- Good for one-time deployments

---

## 📋 CHECKLIST FOR VPS SYNC

### **Before Sync:**
- [ ] Check rag-public for new commits
- [ ] Review changelog for breaking changes
- [ ] Test UI locally (if possible)
- [ ] Backup current VPS UI (automatic)

### **During Sync:**
- [ ] Prepare UI package
- [ ] Transfer files to VPS
- [ ] Stop Nginx on VPS
- [ ] Backup old UI files
- [ ] Deploy new UI files
- [ ] Set permissions (www-data:www-data)
- [ ] Start Nginx on VPS

### **After Sync:**
- [ ] Verify Nginx status (running)
- [ ] Test UI (https://rag.orebit.id/)
- [ ] Test API (https://api.orebit.id/api/rag/health)
- [ ] Check version info
- [ ] Monitor for errors

---

## 🆘 ROLLBACK PROCEDURE

### **If UI Deployment Fails:**

```bash
# SSH to VPS
ssh root@43.157.201.50

# Stop Nginx
sudo systemctl stop nginx

# Restore backup
sudo mv /var/www/rag-ui.backup.YYYYMMDD-HHMMSS /var/www/rag-ui

# Start Nginx
sudo systemctl start nginx

# Verify
curl -I https://rag.orebit.id/
```

### **If API Stops Working:**

```bash
# Check Cloudflare tunnel
ps aux | grep cloudflared | grep -v grep

# Check API wrapper
ps aux | grep "node.*index.js" | grep -v grep

# Restart if needed
kill <PID> && nohup node index.py > /tmp/rag-wrapper.log 2>&1 &
```

---

## 📚 DOCUMENTATION FOR VPS

| Document | Purpose | Location |
|----------|---------|----------|
| **VPS_SYNC_GUIDE.md** | VPS sync overview | QwenPaw |
| **VPS_SYNC_CHECKLIST.md** | This checklist | QwenPaw |
| **vps-prepare-ui-update.sh** | Prepare UI package | QwenPaw |
| **vps-deploy-ui-automated.sh** | Automated deployment | QwenPaw |
| **vps-deploy-rag.sh** | Full RAG deployment | VPS |
| **vps-update-tunnel-url.sh** | Update tunnel URL | VPS |
| **PRODUCTION_DEPLOYMENT_STATUS.md** | Production status | QwenPaw |

---

## 🎯 RECOMMENDED WORKFLOW

### **For UI Updates:**

1. **Weekly Check:**
   ```bash
   cd /app/working/workspaces/default/orebit-ops/rag-public
   git fetch
   git log HEAD..origin/main --oneline
   ```

2. **If Updates Available:**
   ```bash
   bash vps-prepare-ui-update.sh
   bash vps-deploy-ui-automated.sh  # or manual deploy
   ```

3. **Verify:**
   ```bash
   curl -I https://rag.orebit.id/
   ```

### **For System Updates:**

1. **Check Changelog:** Review features/bugs
2. **Test Locally:** If possible
3. **Deploy to VPS:** Use scripts
4. **Monitor:** Check logs and uptime

---

## ✅ SUMMARY

**Q: Perlu sync ke VPS?**
**A: YES, UI perlu di-update sekarang!**

**What to sync:**
- ✅ React UI (immediate)
- ⚠️ Tunnel URL (only if changes)
- ⚠️ Nginx config (only if needed)

**What syncs automatically:**
- ✅ ChromaDB (via Cloudflare tunnel)
- ✅ Papers (via Cloudflare tunnel)
- ✅ API responses (via Cloudflare tunnel)

**Next steps:**
1. Run: `bash vps-prepare-ui-update.sh`
2. Deploy: `bash vps-deploy-ui-automated.sh` (or manual)
3. Verify: `curl -I https://rag.orebit.id/`

---

**Created:** 2026-05-03
**Last Updated:** 2026-05-03
**For:** VPS sync and UI deployment updates
