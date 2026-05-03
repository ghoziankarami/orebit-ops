# Troubleshooting: Direct Connection Failed

## Problem

VPS deployment successful but cannot connect to QwenPaw:

```
curl http://103.139.244.177:3004/api/rag/health
Result: Connection refused
```

## Root Cause Analysis

### QwenPaw Status:
✅ API wrapper running and healthy
✅ Listening on 0.0.0.0:3004 (all interfaces)
✅ Successfully responds to localhost: `curl http://127.0.0.1:3004/api/rag/health`

### Connection Issue:
❌ Cannot access from public IP (103.139.244.177:3004)
❌ VPS cannot connect to QwenPaw API
❌ Network blocking incoming connections

---

## Solution: SSH Tunnel Deployment

Since direct connection is not working, we'll use SSH tunnel.

### Why SSH Tunnel?
- ✅ Works without public IP access
- ✅ Secure (SSH encrypted)
- ✅ Proven technology
- ✅ Standard networking
- ❌ Requires SSH access from VPS to QwenPaw

---

## Step-by-Step SSH Tunnel Setup

### STEP 1: Verify SSH Connectivity

#### On VPS, test SSH connection to QwenPaw:
```bash
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@103.139.244.177 "echo 'SSH connection successful'"
```

#### If this works, proceed to Step 2.
#### If this fails, check:
- SSH service running on QwenPaw
- SSH port (22) accessible from VPS
- Authentication method (password/key)

---

### STEP 2: Create SSH Tunnel on VPS

#### On VPS, create persistent SSH tunnel:
```bash
# Create SSH tunnel in background
nohup ssh -N -R 3004:127.0.0.1:3004 root@103.139.244.177 > /tmp/qwenpaw-tunnel.log 2>&1 &

# Save tunnel PID for monitoring
echo $! > /tmp/qwenpaw-tunnel.pid

# Display PID
echo "Tunnel started with PID: $(cat /tmp/qwenpaw-tunnel.pid)"

# Wait 5 seconds for tunnel to establish
sleep 5

# Check if tunnel process is running
ps -p $(cat /tmp/qwenpaw-tunnel.pid) > /dev/null && echo "✓ Tunnel running" || echo "✗ Tunnel failed"
```

#### Verify tunnel is working:
```bash
# Check if local port 3004 is forwarding
netstat -tlnp | grep :3004

# Should show:
# LISTEN 0      ...    127.0.0.1:3004
```

---

### STEP 3: Test Tunnel Connection

#### On VPS, test if tunnel works:
```bash
# Test forwarded localhost connection
curl http://localhost:3004/api/rag/health

# Should return:
{
  "status": "healthy",
  "corpus": {
    "indexed_papers": 351
  }
}
```

#### If this works, proceed to Step 4.

---

### STEP 4: Update Nginx Configuration

#### On VPS, update Nginx to use tunnel:

```bash
# Current proxy target is http://103.139.244.177:3004 (not working)
# Change to http://localhost:3004 (via SSH tunnel)

sudo nano /etc/nginx/sites-available/rag.orebit.id
```

#### Change this line:
```nginx
# OLD (not working):
proxy_pass http://103.139.244.177:3004;

# NEW (via SSH tunnel):
proxy_pass http://localhost:3004;
```

#### Save and exit (Ctrl+X, Y, Enter)

---

### STEP 5: Restart Nginx

```bash
# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Check Nginx status
sudo systemctl status nginx
```

---

### STEP 6: Test Full Deployment

#### Test from VPS:
```bash
curl https://rag.orebit.id/health
```

#### Test from browser:
```
https://rag.orebit.id
```

#### Should return:
```json
{
  "status": "healthy",
  "service": "rag-api-wrapper",
  "corpus": {
    "indexed_papers": 351
  }
}
```

---

### STEP 7: Setup Tunnel Auto-Restart (Optional but Recommended)

#### Create systemd service for SSH tunnel:

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

# Reload systemd
sudo systemctl daemon-reload

# Enable service (auto-start on boot)
sudo systemctl enable qwenpaw-tunnel.service

# Start service
sudo systemctl start qwenpaw-tunnel.service

# Check status
sudo systemctl status qwenpaw-tunnel.service
```

---

## Alternative: SSH Tunnel with Auto-Maintain Connection

### If SSH connection drops frequently:

#### Install autossh:
```bash
sudo apt-get install autossh
```

#### Use autossh for tunnel:
```bash
# Kill existing tunnel
pkill -f "ssh.*3004"

# Start autossh tunnel
nohup autossh -N -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -R 3004:127.0.0.1:3004 root@103.139.244.177 > /tmp/qwenpaw-autossh.log 2>&1 &
echo $! > /tmp/qwenpaw-autossh.pid
```

---

## Troubleshooting

### Issue 1: SSH connection refused
**Check:**
```bash
# On QwenPaw, check SSH service
systemctl status ssh

# Check SSH port
netstat -tlnp | grep :22

# Check firewall
iptables -L INPUT -n
```

### Issue 2: Tunnel established but no traffic
**Check:**
```bash
# On VPS, check tunnel logs
tail -f /tmp/qwenpaw-tunnel.log

# Check if port 3004 is listening locally
netstat -tlnp | grep :3004

# Test local connection
curl http://localhost:3004/api/rag/health
```

### Issue 3: Tunnel drops frequently
**Solution:**
- Use autossh (above)
- Add ServerAliveInterval options
- Check network stability

### Issue 4: Nginx still showing old proxy target
**Check:**
```bash
# Check actual Nginx config
cat /etc/nginx/sites-enabled/rag.orebit.id | grep proxy_pass

# Should show: proxy_pass http://localhost:3004;
```

---

## Success Criteria

Deployment successful when:

✅ SSH tunnel establishes successfully
✅ `curl http://localhost:3004/api/rag/health` works on VPS
✅ Nginx configured to proxy to `localhost:3004`
✅ `curl https://rag.orebit.id/health` returns JSON
✅ Can access RAG system from browser via https://rag.orebit.id
✅ Health check shows `indexed_papers: 351`
✅ Tunnel auto-restarts (if systemd service configured)

---

## After Deployment: Monitor Tunnel

### Check tunnel status:
```bash
# Check if tunnel process running
ps aux | grep ssh | grep 3004

# Check if port 3004 listening
netstat -tlnp | grep :3004

# Check tunnel logs
tail -f /tmp/qwenpaw-tunnel.log
```

### Check systemd service (if configured):
```bash
sudo systemctl status qwenpaw-tunnel.service

# Restart if needed
sudo systemctl restart qwenpaw-tunnel.service

# Check logs
sudo journalctl -u qwenpaw-tunnel -f
```

---

## Summary

**Problem:** Direct connection from VPS to QwenPaw not working
**Root Cause:** Network firewall blocking incoming connections
**Solution:** SSH tunnel from VPS to QwenPaw
**Result:** VPS accesses QwenPaw via encrypted SSH tunnel
**Final Config:** Nginx proxies https://rag.orebit.id → localhost:3004 → SSH tunnel → QwenPaw:3004

---

**Next Steps:**
1. Verify SSH connectivity from VPS to QwenPaw
2. Setup SSH tunnel on VPS
3. Update Nginx configuration to use localhost:3004
4. Test full deployment
5. Setup tunnel auto-restart (systemd service)

**All set!** 🚀
