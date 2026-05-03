# SSH Tunnel Deployment Instructions

## Problem Solved

**Original Issue:** Direct connection from VPS to QwenPaw failing

```
curl http://103.139.244.177:3004/api/rag/health
Result: Connection refused
```

**Root Cause:** QwenPaw network blocking incoming connections on port 3004

---

## Solution: SSH Tunnel

**Architecture:**
```
https://rag.orebit.id → Nginx (VPS) → localhost:3004 → SSH tunnel → QwenPaw:3004
```

**Why SSH Tunnel Works:**
- ✅ Works around network blocking
- ✅ Encrypted connection
- ✅ Standard SSH protocol
- ✅ Auto-restart capability

---

## Quick Start (One Command)

### On VPS, run:

```bash
git clone https://github.com/ghoziankarami/orebit-ops.git
cd orebit-ops
bash vps-ssh-tunnel-setup.sh
```

**That's it! The script handles everything.**

---

## What the Script Does

1. **Verify SSH connectivity** to QwenPaw
2. **Create SSH tunnel** (port 3004:127.0.0.1:3004)
3. **Verify tunnel** is working
4. **Update Nginx** to proxy to `localhost:3004`
5. **Restart Nginx** with new configuration
6. **Test deployment** via https://rag.orebit.id
7. **Setup systemd service** for auto-restart

---

## Manual Setup (If Automated Script Fails)

### STEP 1: Create SSH Tunnel

```bash
# Kill existing tunnels
pkill -f "ssh.*3004"

# SSH tunnel from VPS to QwenPaw
nohup ssh -N -R 3004:127.0.0.1:3004 root@103.139.244.177 > /tmp/qwenpaw-tunnel.log 2>&1 &

# Save tunnel PID
echo $! > /tmp/qwenpaw-tunnel.pid

# Wait for tunnel
sleep 5

# Verify tunnel
ps aux | grep ssh | grep 3004
```

### STEP 2: Test Tunnel

```bash
# Test forwarded connection
curl http://localhost:3004/api/rag/health

# Should return:
{
  "status": "healthy",
  "indexed_papers": 351
}
```

### STEP 3: Update Nginx

```bash
# Edit Nginx config
sudo nano /etc/nginx/sites-available/rag.orebit.id

# Change proxy_pass:
# OLD: proxy_pass http://103.139.244.177:3004;
# NEW: proxy_pass http://localhost:3004;

# Reload Nginx
sudo systemctl restart nginx
```

### STEP 4: Test Full Deployment

```bash
# Test via domain
curl https://rag.orebit.id/health

# Access in browser
https://rag.orebit.id
```

---

## Systemd Service (Auto-Restart)

### Create Service:

```bash
sudo tee /etc/systemd/system/qwenpaw-tunnel.service > /dev/null << 'EOF'
[Unit]
Description=SSH Tunnel to QwenPaw
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/ssh -N -R 3004:127.0.0.1:3004 root@103.139.244.177
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
```

### Enable and Start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable qwenpaw-tunnel.service
sudo systemctl start qwenpaw-tunnel.service
sudo systemctl status qwenpaw-tunnel.service
```

---

## Monitoring

### Check Tunnel Status:

```bash
# Tunnel process
ps aux | grep ssh | grep 3004

# Tunnel systemd service
sudo systemctl status qwenpaw-tunnel.service

# Port listening
netstat -tlnp | grep :3004

# Tunnel logs
tail -f /tmp/qwenpaw-tunnel.log
```

### Restart Tunnel:

```bash
# Via systemd (recommended)
sudo systemctl restart qwenpaw-tunnel.service

# Manual method
pkill -f "ssh.*3004"
nohup ssh -N -R 3004:127.0.0.1:3004 root@103.139.244.177 > /tmp/qwenpaw-tunnel.log 2>&1 &
```

---

## Success Criteria

Deployment successful when:

✅ SSH tunnel establishes successfully
✅ `curl http://localhost:3004/api/rag/health` works on VPS
✅ Nginx proxies to `localhost:3004`
✅ `curl https://rag.orebit.id/health` returns JSON
✅ Accessible from browser: https://rag.orebit.id
✅ Health check shows `indexed_papers: 351`
✅ Tunnel auto-restarts (systemd service)

---

## Troubleshooting

### Issue: SSH connection refused
**Fix:** Check SSH service and port 22 on QwenPaw

```bash
# On QwenPaw:
systemctl status ssh
netstat -tlnp | grep :22
```

### Issue: Tunnel not working
**Fix:** Check tunnel logs

```bash
tail -f /tmp/qwenpaw-tunnel.log
```

### Issue: Nginx still using old proxy
**Fix:** Verify Nginx config

```bash
cat /etc/nginx/sites-enabled/rag.orebit.id | grep proxy_pass
# Should show: proxy_pass http://localhost:3004;
```

### Issue: Tunnel drops frequently
**Fix:** Use systemd service (auto-restart) or autossh

---

## Architecture Summary

**Before (Failed):**
```
https://rag.orebit.id → Nginx → 103.139.244.177:3004 (connection refused)
```

**After (Working):**
```
https://rag.orebit.id → Nginx → localhost:3004 → SSH tunnel → QwenPaw:3004
```

**Benefits:**
- ✅ Works around network blocking
- ✅ Encrypted SSH connection
- ✅ Auto-restart capability
- ✅ Monitoring and logging

---

## Files in Repository

After `git clone` from GitHub:

1. **vps-ssh-tunnel-setup.sh** - Automated setup script (MAIN)
2. **TROUBLESHOOTING_DIRECT_CONNECTION.md** - Detailed troubleshooting
3. **CORRECT_ARCHITECTURE_DEPLOYMENT.md** - Architecture documentation

---

## Quick Commands

```bash
# Clone and install
git clone https://github.com/ghoziankarami/orebit-ops.git
cd orebit-ops
bash vps-ssh-tunnel-setup.sh

# Check status
sudo systemctl status qwenpaw-tunnel.service
curl https://rag.orebit.id/health

# Restart if needed
sudo systemctl restart qwenpaw-tunnel.service
```

---

**Last Updated:** 2026-05-02
**Repository:** https://github.com/ghoziankarami/orebit-ops
**Status:** ✅ Ready for deployment
