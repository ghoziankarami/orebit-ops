# VPS Deployment Quick Start

## 🚀 One-Command VPS Deployment

Deploy VPS as public frontend only with this single command:

```bash
git clone https://github.com/ghoziankarami/orebit-ops.git
cd orebit-ops
bash deploy-vps-frontend.sh
```

That's it! The script will handle everything.

---

## 📋 Prerequisites

- Ubuntu 20.04+ (VPS)
- Domain name (e.g., rag.orebit.id) pointing to VPS IP
- Domain DNS configured (A record)
- sudo access on VPS

---

## 🎯 What This Script Does

1. **Clone Repository** - Pulls architecture docs from GitHub
2. **Install Dependencies** - Nginx, Certbot, etc.
3. **Setup SSL** - Automatic Let's Encrypt certificates
4. **Configure Nginx** - Reverse proxy to QwenPaw
5. **Deploy Frontend** - Public HTTPS access setup

---

## 🔧 Deployment Options

The script supports 3 deployment modes:

### **Option 1: ngrok Tunnel (RECOMMENDED) - Easiest**

**Requirements:**
- QwenPaw runs ngrok tunnel
- No public IP needed

**Setup on QwenPaw:**
```bash
# Install ngrok (if not installed)
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# Start ngrok tunnel
nohup ngrok http 3004 > /tmp/ngrok.log 2>&1 &

# Get ngrok URL
cat /tmp/ngrok.log | grep -oP 'https://[a-z0-9-]+\.ngrok(-free)?\.app'
```

**Setup on VPS:**
```bash
bash deploy-vps-frontend.sh
# Choose option 1 (ngrok)
# Paste ngrok URL from QwenPaw
```

---

### **Option 2: Direct Connection - Best Performance**

**Requirements:**
- QwenPaw has public IP
- API wrapper listens on 0.0.0.0:3004

**Setup on QwenPaw:**
```bash
# Ensure API wrapper listens on 0.0.0.0
cd /app/working/workspaces/default/orebit-ops/rag-system/api-wrapper
pkill -f "node index.js"
nohup npm start > /tmp/api.log 2>&1 &

# Verify API accessible from outside
# Test from another machine:
curl http://QWENPAW_PUBLIC_IP:3004/api/rag/health
```

**Setup on VPS:**
```bash
bash deploy-vps-frontend.sh
# Choose option 2 (direct)
# Paste QwenPaw public IP
```

---

### **Option 3: SSH Tunnel - Flexible**

**Requirements:**
- SSH access from VPS to QwenPaw
- QwenPaw SSH reachable

**Setup on VPS:**
```bash
bash deploy-vps-frontend.sh
# Choose option 3 (SSH)
# Enter QwenPaw user@IP (e.g., ubuntu@192.168.1.100)
```

---

## ✅ After Deployment

### **Test deployment:**

```bash
# Test health check
curl https://rag.orebit.id/health

# Test API query
curl -X POST https://rag.orebit.id/api/rag/query \
  -H 'Content-Type: application/json' \
  -d '{"query":"test"}'
```

### **Access from browser:**

- **Public UI:** https://rag.orebit.id
- **API Endpoint:** https://rag.orebit.id/api/rag/query
- **Health Check:** https://rag.orebit.id/health

---

## 🔍 Monitoring

### **Check Nginx logs:**
```bash
sudo journalctl -u nginx -f
```

### **Check SSL certificates:**
```bash
sudo certbot certificates
```

### **Check Nginx configuration:**
```bash
sudo nginx -t
```

### **Restart Nginx:**
```bash
sudo systemctl restart nginx
```

---

## 🎯 Architecture Verification

After deployment, verify:

### **VPS is Frontend Only:**
```bash
# Check memory usage (should be low)
free -h

# Check running processes (should only have Nginx + SSH)
ps aux | grep nginx
ps aux | grep sshd

# Should NOT have:
# - ChromaDB process
# - Python processes (except Nginx)
# - Node.js processes (except optional)
```

### **QwenPaw is Central System:**
```bash
# Verify ChromaDB running
curl http://localhost:3004/api/rag/health

# Should show:
# {
#   "status": "healthy",
#   "indexed_papers": 350
# }
```

---

## 📚 Documentation Available

After `git clone`, you'll have:

- **CORRECT_ARCHITECTURE_DEPLOYMENT.md** - Detailed architecture guide
- **SYSTEM_ARCHITECTURE_ANALYSIS.md** - Complete system analysis
- **ARCHITECTURE_QUICK_REF.md** - Quick reference
- **ARCHITECTURE_SUMMARY.txt** - ASCII art summary
- **VPS_SYNC_COMPLETE.md** - Complete sync guide (alternative approach)

---

## 🚨 Troubleshooting

### **Common Issues:**

#### **1. Domain not resolving**
```bash
# Check DNS propagation
nslookup rag.orebit.id
dig rag.orebit.id

# Check if A record points to VPS IP
```

#### **2. SSL certificate error**
```bash
# Renew manually
sudo certbot renew

# Force renewal
sudo certbot renew --force-renewal
```

#### **3. Can't connect to QwenPaw**
```bash
# Test ngrok URL
curl https://your-ngrok-url.ngrok-free.app/api/rag/health

# Test direct IP
curl http://QWENPAW_IP:3004/api/rag/health

# Check firewall/UFW rules
sudo ufw status
```

#### **4. Nginx not starting**
```bash
# Check Nginx status
sudo systemctl status nginx

# Test configuration
sudo nginx -t

# Check error logs
sudo tail -f /var/log/nginx/error.log
```

---

## 🎉 Success Criteria

Deployment successful when:

✅ Nginx running on VPS (only proxy + SSL)
✅ SSL certificate active (Let's Encrypt)
✅ Domain resolves to HTTPS
✅ Health check endpoint returns JSON
✅ API queries work via HTTPS
✅ VPS memory usage < 500MB (no ChromaDB)
✅ No rclone on VPS
✅ No papers on VPS

---

## 📞 Next Steps

1. ✅ VPS deployed as frontend only
2. Test public access via browser
3. Monitor system performance
4. Setup monitoring/alerts (optional)
5. Document deployment details

---

**Last Updated:** 2026-05-02
**Deployment Script:** deploy-vps-frontend.sh
**Repository:** https://github.com/ghoziankarami/orebit-ops
