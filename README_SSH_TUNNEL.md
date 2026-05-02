# Problem FIXED: Connection Refused → SSH Tunnel

## What Happened

**Original Problem:**
```
curl http://103.139.244.177:3004/api/rag/health
Result: Connection refused
```

**Root Cause:**
QwenPaw network blocking incoming connections on port 3004

---

## Solution: SSH Tunnel

**Quick Fix (Run on VPS):**
```bash
git clone https://github.com/ghoziankarami/orebit-ops.git
cd orebit-ops
bash vps-ssh-tunnel-setup.sh
```

**That's it!** The script will:
✅ Create SSH tunnel VPS→QwenPaw
✅ Update Nginx to use localhost:3004
✅ Setup auto-restart service
✅ Test full deployment

---

## Architecture

**Before (Failed):**
```
https://rag.orebit.id → 103.139.244.177:3004 ❌ (connection refused)
```

**After (Working):**
```
https://rag.orebit.id → localhost:3004 → SSH tunnel → QwenPaw:3004 ✅
```

---

## Quick Commands

```bash
# Deploy VPS (one command)
git clone https://github.com/ghoziankarami/orebit-ops.git && cd orebit-ops && bash vps-ssh-tunnel-setup.sh

# Check status
curl https://rag.orebit.id/health

# Monitor tunnel
sudo systemctl status qwenpaw-tunnel.service

# Restart if needed
sudo systemctl restart qwenpaw-tunnel.service
```

---

## Files Available on GitHub

After `git clone`, you'll have:

1. **vps-ssh-tunnel-setup.sh** ⭐ **RUN THIS!**
2. **DEPLOYMENT_SSH_TUNNEL_INSTRUCTIONS.md** - Detailed guide
3. **TROUBLESHOOTING_DIRECT_CONNECTION.md** - Troubleshooting
4. **CORRECT_ARCHITECTURE_DEPLOYMENT.md** - Architecture docs

---

## Success Check

Deployment successful when:

✅ `curl https://rag.orebit.id/health` works
✅ Returns: `{"status": "healthy", "indexed_papers": 351}`
✅ Accessible in browser: https://rag.orebit.id
✅ Tunnel systemd service running

---

**Repository:** https://github.com/ghoziankarami/orebit-ops
**Latest:** Main branch
**Status:** ✅ Ready to deploy

---

**Just run: `bash vps-ssh-tunnel-setup.sh` on VPS!** 🚀
