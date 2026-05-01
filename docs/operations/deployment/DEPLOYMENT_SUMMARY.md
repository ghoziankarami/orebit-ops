# VPS Deployment Package - rag.orebit.id & api.orebit.id

> **Date:** 2026-05-01  
> **VPS:** orebit-sumopod (43.157.201.50)  
> **Status:** Ready to Deploy

---

## 📦 Deployment Package Contents

This package contains everything needed to deploy the RAG system to the new VPS.

### Files Included

| File | Purpose | Location |
|---|---|---|
| vps-setup-script.sh | Automated setup script | `/tmp/vps-setup-script.sh` |
| vps-docker-compose.yml | VPS-optimized Docker Compose | `/tmp/vps-docker-compose.yml` |
| VPS_DEPLOYMENT_GUIDE.md | Complete deployment guide | `/tmp/VPS_DEPLOYMENT_GUIDE.md` |
| DNS_CHECKLIST.md | DNS configuration checklist | `/tmp/DNS_CHECKLIST.md` |

---

## 🎯 Overview

What we're deploying:
- RAG API Wrapper (Node.js, port 3004)
- Embedding Server (Python, port 8000)
- ChromaDB (port 8001, with 350 indexed papers)
- Nginx reverse proxy (ports 80/443)
- SSL certificates (auto-renewal)

Where we're deploying:
- VPS: orebit-sumopod
- IP: 43.157.201.50
- User: ubuntu
- Domains: rag.orebit.id, api.orebit.id

---

## 🚀 Quick Start

### Step 1: Configure DNS (CRITICAL - Do This First!)

Read and follow: **DNS_CHECKLIST.md**

Tasks:
- [ ] Add A record: rag.orebit.id → 43.157.201.50
- [ ] Add A record: api.orebit.id → 43.157.201.50
- [ ] Wait for DNS propagation (10-15 minutes)
- [ ] Verify: `dig rag.orebit.id`

**Don't proceed until DNS is configured!**

---

### Step 2: Connect to VPS

```bash
ssh ubuntu@43.157.201.50

# Password: falcon-73@-panda
```

---

### Step 3: Run Setup Script

**Option A: Full Automated Setup (Recommended)**

```bash
# Create setup directory
mkdir -p ~/orebit-deploy
cd ~/orebit-deploy

# Copy the setup script from local to VPS (use SCP or nano)
# Method 1: Using SCP (from local machine)
scp /tmp/vps-setup-script.sh ubuntu@43.157.201.50:~/orebit-deploy/

# Method 2: Using nano (on VPS)
nano ~/orebit-deploy/setup-vps.sh
# Paste the script content from /tmp/vps-setup-script.sh
# Save: Ctrl+O, Enter, Ctrl+X

# Make executable and run
chmod +x setup-vps.sh
sudo bash setup-vps.sh
```

**Option B: Manual Setup**

Follow the detailed instructions in VPS_DEPLOYMENT_GUIDE.md

---

### Step 4: Configure SSL (During Setup)

When prompted, enter `yes` (only after DNS is propagated):

```
Are DNS records (rag.orebit.id, api.orebit.id) pointing to 43.157.201.50? (yes/no):
yes
```

Certbot will:
1. Verify domain ownership
2. Issue SSL certificates
3. Configure Nginx for HTTPS
4. Setup auto-renewal

---

### Step 5: Verify Deployment

```bash
# Check services
cd /opt/orebit-rag/orebit-ops/rag-system
sudo docker-compose ps

# Test API health
curl https://rag.orebit.id/api/rag/health
curl https://api.orebit.id/api/rag/health

# Expected response:
{
  "status": "healthy",
  "service": "rag-api-wrapper",
  "version": "2.0.0",
  "mode": "public_read_only",
  "corpus": {
    "indexed_papers": 350,
    "summary_count": 342,
    "collection_count": 93
  }
}
```

---

## 📋 DNS Configuration Summary

### Required DNS Records

| Record | Type | Name | Value | TTL |
|---|:---:|:---:|---|:---:|
| 1 | A | rag | 43.157.201.50 | 300 |
| 2 | A | api | 43.157.201.50 | 300 |

### Optional DNS Records

| Record | Type | Name | Value | TTL |
|---|---|:---:|---|:---:|
| 3 | A | @ | 43.157.201.50 | 300 |
| 4 | CNAME | www | rag.orebit.id | 300 |

**Full Domains:**
- rag.orebit.id → 43.157.201.50
- api.orebit.id → 43.157.201.50
- (optional) orebit.id → 43.157.201.50
- (optional) www.orebit.id → rag.orebit.id

---

## 🔍 Verification Commands

### DNS Verification

```bash
# Check rag.orebit.id
dig rag.orebit.id

# Check api.orebit.id
dig api.orebit.id

# Simple test
ping rag.orebit.id
ping api.orebit.id
```

### Service Verification

```bash
# All Docker services
cd /opt/orebit-rag/orebit-ops/rag-system
sudo docker-compose ps

# API health
curl http://localhost:3004/api/rag/health

# Via domain (after SSL)
curl https://rag.orebit.id/api/rag/health
```

### SSL Certificate Verification

```bash
# Check certificates
sudo certbot certificates

# Test SSL
openssl s_client -connect rag.orebit.id:443 -servername rag.orebit.id
```

---

## 📊 System Resources

### VPS Specs
- **CPU:** 2 vCPU
- **RAM:** 2 GB
- **Storage:** 40 GB
- **Cost:** 60,000 IDR/month (~$3.80 USD)

### Services & Resources

| Service | CPU | RAM | Disk | Notes |
|---|---|---|---|---|
| API Wrapper | Low | 100-200 MB | Low | Fast startup |
| Embedding Server | Medium | 500-800 MB | Medium | Model caching |
| ChromaDB | Low | 500-800 MB | High | Indexed papers |
| Nginx | Very Low | 20-30 MB | Low | Reverse proxy |
| Ubuntu | Low | 200-300 MB | Low | System overhead |
| **Total** | **Medium** | **~1.5 GB** | **~5-10 GB** | **Within specs** |

---

## 🔐 Security Configuration

### Firewall (UFW) Status

```bash
sudo ufw status
```

Expected:
```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
3004/tcp                   ALLOW       Anywhere
8000/tcp                   ALLOW       Anywhere
8001/tcp                   ALLOW       Anywhere
```

### Security Checklist

- [ ] Ubuntu password changed (default: falcon-73@-panda)
- [ ] SSH key authentication configured (recommended)
- [ ] UFW firewall enabled
- [ ] SSL certificates installed
- [ ] Auto-renewal configured for SSL
- [ ] Services running as non-root where possible
- [ ] Regular backups configured

---

## 🔄 Maintenance

### Update Application

```bash
cd /opt/orebit-rag/orebit-ops
git pull origin main
cd rag-system
sudo docker-compose down
sudo docker-compose up --build -d
```

### Check Logs

```bash
cd /opt/orebit-rag/orebit-ops/rag-system

# All logs
sudo docker-compose logs -f

# Specific service
sudo docker-compose logs -f api-wrapper
sudo docker-compose logs -f embedding-server
sudo docker-compose logs -f chromadb
```

### Restart Services

```bash
# All services
sudo docker-compose restart

# Individual service
sudo docker-compose restart api-wrapper
```

### Backup

```bash
# ChromaDB data backup
cd /opt/orebit-rag
mkdir -p backups
tar -czf backups/chroma-$(date +%Y%m%d).tar.gz \
  /opt/orebit-rag/orebit-ops/rag-system/chroma-data
```

---

## 🚨 Troubleshooting

### Issue: DNS Not Propagating

**Solution:**
```bash
# Wait 10-15 minutes
dig rag.orebit.id
dig api.orebit.id

# Check with online tool
# https://dnschecker.org/
```

### Issue: Services Won't Start

**Solution:**
```bash
# Check logs
cd /opt/orebit-rag/orebit-ops/rag-system
sudo docker-compose logs

# Restart
sudo docker-compose restart

# Rebuild
sudo docker-compose down
sudo docker-compose up --build -d
```

### Issue: SSL Certificate Failed

**Solution:**
```bash
# Check DNS first
dig rag.orebit.id

# Check Nginx
sudo nginx -t

# Re-request certificate
sudo certbot --nginx -d rag.orebit.id -d api.orebit.id
```

### Issue: API Not Responding

**Solution:**
```bash
# Check services
sudo docker-compose ps

# Check locally
curl http://localhost:3004/api/rag/health

# Check Nginx
sudo systemctl status nginx
```

---

## 📚 Documentation Files

| File | Description |
|---|---|
| **VPS_DEPLOYMENT_GUIDE.md** | Complete VPS deployment guide |
| **DNS_CHECKLIST.md** | DNS configuration checklist |
| **vps-setup-script.sh** | Automated setup script |
| **vps-docker-compose.yml** | Docker Compose configuration |
| **DEPLOYMENT_SUMMARY.md** | This file - quick reference |

---

## ✅ Post-Deployment Checklist

### DNS Configuration
- [ ] rag.orebit.id A record created
- [ ] api.orebit.id A record created
- [ ] DNS propagated (verified with dig)
- [ ] All DNS providers updated

### VPS Setup
- [ ] Connected to VPS successfully
- [ ] Setup script completed
- [ ] Docker installed and running
- [ ] Services started (3 containers)

### SSL & Security
- [ ] SSL certificates installed
- [ ] HTTPS working (test in browser)
- [ ] Firewall configured (UFW)
- [ ] Default password changed

### Application
- [ ] API health check passing
- [ ] Search functionality working
- [ ] ChromaDB data persisted
- [ ] All domains accessible

### Monitoring & Maintenance
- [ ] Auto-renewal configured for SSL
- [ ] Systemd auto-start enabled
- [ ] Monitoring setup
- [ ] Backup strategy configured

---

## 🎯 Next Steps After Deployment

### 1. Test in Browser
Visit these URLs:
- https://rag.orebit.id/api/rag/health
- https://api.orebit.id/api/rag/health

### 2. Test API Functionality

```bash
# Search papers
curl -X POST https://rag.orebit.id/api/rag/search \
  -H "Content-Type: application/json" \
  -d '{"query": "machine learning", "top_k": 5}'

# Ask question
curl -X POST https://rag.orebit.id/api/rag/answer \
  -H "Content-Type: application/json" \
  -d '{"query": "What is RAG?", "top_k": 3}'
```

### 3. Set Up Monitoring

```bash
# Check resource usage
htop

# Docker stats
sudo docker stats

# Nginx logs
sudo tail -f /var/log/nginx/access.log
```

### 4. Setup Backups

```bash
# Create backup directory
mkdir -p /opt/orebit-rag/backups

# Add to crontab for daily backups
crontab -e
# Add:
  0 2 * * * tar -czf /opt/orebit-rag/backups/chroma-$(date +\%Y\%m\%d).tar.gz /opt/orebit-rag/orebit-ops/rag-system/chroma-data
```

---

## 📞 Support & Resources

### Documentation Location
Once deployed, docs will be at:
- `/opt/orebit-rag/orebit-ops/docs/operations/VPS_DEPLOYMENT.md`
- `/opt/orebit-rag/orebit-ops/docs/operations/DNS_CHECKLIST.md`

### Support Commands

```bash
# Quick status check
cd /opt/orebit-rag/orebit-ops/rag-system
sudo docker-compose ps && sudo docker-compose logs --tail=50

# Full system status
echo "=== Docker Services ===" && sudo docker-compose ps && \
echo "" && echo "=== Nginx Status ===" && sudo systemctl status nginx --no-pager && \
echo "" && echo "=== UFW Status ===" && sudo ufw status
```

### External Resources

- **Docker Documentation:** https://docs.docker.com/
- **Nginx Documentation:** https://nginx.org/en/docs/
- **Certbot Documentation:** https://certbot.eff.org/
- **UFW Documentation:** https://help.ubuntu.com/community/UFW

---

## 🎉 Deployment Complete!

When all steps are complete, the RAG system will be live at:

- **Main Interface:** https://rag.orebit.id
- **API Endpoint:** https://api.orebit.id
- **Health Check:** https://rag.orebit.id/api/rag/health

Both domains will have:
- ✅ SSL certificates (auto-renewing)
- ✅ HTTPS enabled
- ✅ Nginx reverse proxy
- ✅ 3 Docker services running
- ✅ ChromaDB with 350 indexed papers

---

**Deployment Package Created:** 2026-05-01  
**VPS:** orebit-sumopod (43.157.201.50)  
**Documentation:** Complete and ready to use  
**Status:** Ready for deployment (after DNS configuration)

---

## 📋 Quick Reference Card

```
SSH:              ssh ubuntu@43.157.201.50
Project Dir:      /opt/orebit-rag/orebit-ops/rag-system
Main Domain:      https://rag.orebit.id
API Domain:       https://api.orebit.id
Health Check:     https://rag.orebit.id/api/rag/health

Commands:
  sudo docker-compose ps              # Check services
  sudo docker-compose logs -f         # View logs
  sudo docker-compose restart         # Restart services
  sudo systemctl restart nginx        # Restart nginx
  sudo certbot renew                  # Renew SSL
