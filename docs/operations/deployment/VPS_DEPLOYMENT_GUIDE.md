# RAG.orebit.id — VPS Deployment Guide

> **VPS:** orebit-sumopod (43.157.201.50)  
> **SSH:** ubuntu@43.157.201.50  
> **Status:** Ready to Deploy  
> **Last updated:** 2026-05-01

---

## Overview

Deploy the RAG API system to a new VPS with Docker, Nginx, and SSL certificates.

### Architecture

```
Internet → Nginx (443 HTTPS) → rag.orebit.id / api.orebit.id
                                    ↓
                            RAG API Wrapper
                            (Node.js, port 3004)
                                    ↓
                   ┌────────────────┴────────────────┐
                   ↓                                  ↓
            Embedding Server                   ChromaDB
            (all-MiniLM-L6-v2)                  (350 papers)
            (port 8000)                         (port 8001)
```

---

## Prerequisites

### VPS Information
- **Provider:** Sumopod
- **IP Address:** 43.157.201.50
- **OS:** Ubuntu
- **User:** ubuntu
- **SSH:** `ssh ubuntu@43.157.201.50`

### Domain Requirements
- **rag.orebit.id** - Primary domain
- **api.orebit.id** - API endpoint domain
- **DNS Provider:** Access to manage DNS records

### Software Stack
- Docker & Docker Compose
- Nginx (reverse proxy)
- Certbot (SSL certificates)
- UFW (firewall)

---

## DNS Configuration Checklist

### ⚠️ CRITICAL: Set up DNS records FIRST

Before running the setup script, ensure the following DNS records are configured:

### DNS Records to Create/Verify

| Type | Name | Value | TTL | Notes |
|---|---|---|---|---|
| A | rag.orebit.id | 43.157.201.50 | 300 | Primary domain |
| A | api.orebit.id | 43.157.201.50 | 300 | API endpoint |
| A | @ | 43.157.201.50 | 300 | Root domain (optional) |
| CNAME | www | rag.orebit.id | 300 | WWW redirect (optional) |

### How to Verify DNS Records

```bash
# Check rag.orebit.id
dig rag.orebit.id

# Check api.orebit.id
dig api.orebit.id

# Check with nslookup
nslookup rag.orebit.id
nslookup api.orebit.id
```

Expected output should show `43.157.201.50` as the answer.

### DNS Propagation Time

- **Minimum:** 5 minutes
- **Recommended:** 10-15 minutes
- **Maximum:** 24 hours (rare)

Use [DNS Checker](https://dnschecker.org/) to verify global propagation.

---

## Deployment Steps

### Option 1: Automated Setup (Recommended)

#### Step 1: Connect to VPS

```bash
# SSH into the VPS
ssh ubuntu@43.157.201.50

# When prompted, enter password: falcon-73@-panda
```

#### Step 2: Download & Run Setup Script

```bash
# Create temporary directory
mkdir -p ~/orebit-deploy
cd ~/orebit-deploy

# Download setup script (copy from local and upload, or create manually)
# The script is at /tmp/vps-setup-script.sh on the local machine

# Create the script on VPS
cat > setup-vps.sh << 'EOF'
#!/bin/bash
set -e
# [Full setup script content here]
EOF

# Make executable
chmod +x setup-vps.sh

# Run setup (this will take 15-20 minutes)
sudo bash setup-vps.sh
```

#### Step 3: Configure SSL (Interactive)

During setup, you'll be prompted:

```
Are DNS records (rag.orebit.id, api.orebit.id) pointing to 43.157.201.50? (yes/no):
```

**Answer:** `yes` (only after DNS propagation is complete)

Certbot will then:
1. Verify domain ownership
2. Issue SSL certificates
3. Configure Nginx for HTTPS
4. Set up auto-renewal

---

### Option 2: Manual Setup

#### Step 1: Update System

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

#### Step 2: Install Dependencies

```bash
sudo apt-get install -y curl wget git docker.io docker-compose \
  nginx certbot python3-certbot-nginx ufw htop tree
```

#### Step 3: Setup Docker

```bash
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
```

#### Step 4: Setup Firewall

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3004/tcp  # RAG API
sudo ufw allow 8000/tcp  # Embedding Server
sudo ufw allow 8001/tcp  # ChromaDB
sudo ufw --force enable
```

#### Step 5: Clone Repository

```bash
sudo mkdir -p /opt/orebit-rag
sudo chown ubuntu:ubuntu /opt/orebit-rag
cd /opt/orebit-rag
git clone https://github.com/ghoziankarami/orebit-ops.git
cd orebit-ops
git checkout main
```

#### Step 6: Configure Environment

```bash
cd rag-system
mkdir -p .env
cat > .env << 'EOF'
PORT=3004
RAG_API_HOST=0.0.0.0
OREBIT_EMBEDDING_API_URL=http://embedding-server:8000/v1/embeddings
RAG_API_KEY=orebit-rag-2026-secret-key-change-me
RAG_STATS_TTL_MS=60000
DOMAIN_RAG=rag.orebit.id
DOMAIN_API=api.orebit.id
EOF
```

#### Step 7: Docker Compose

Use the optimized VPS docker-compose file:

```bash
# Copy VPS-optimized docker-compose.yml
cp /tmp/vps-docker-compose.yml docker-compose.yml

# Build and start
sudo docker-compose up --build -d

# Check status
sudo docker-compose ps
```

#### Step 8: Setup Nginx

```bash
sudo tee /etc/nginx/sites-available/rag-orebit-id <<'EOF'
# rag.orebit.id
server {
    listen 80;
    server_name rag.orebit.id;

    location / {
        proxy_pass http://localhost:3004;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# api.orebit.id
server {
    listen 80;
    server_name api.orebit.id;

    location / {
        proxy_pass http://localhost:3004;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/rag-orebit-id /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### Step 9: Setup SSL Certificates

```bash
# IMPORTANT: DNS must be propagated first!
sudo certbot --nginx -d rag.orebit.id -d api.orebit.id \
  --email admin@orebit.id --agree-tos --non-interactive
```

#### Step 10: Setup Auto-Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Add to crontab
crontab -e
# Add this line:
  0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'
```

#### Step 11: Enable Auto-Start

```bash
sudo tee /etc/systemd/system/orebit-rag.service <<'EOF'
[Unit]
Description=Orebit RAG System
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/orebit-rag/orebit-ops/rag-system
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable orebit-rag.service
sudo systemctl daemon-reload
```

---

## Verification

### Step 1: Verify Services

```bash
cd /opt/orebit-rag/orebit-ops/rag-system
sudo docker-compose ps
```

Expected output:
```
NAME                 STATUS          PORTS
rag-api-wrapper      Up              0.0.0.0:3004->3004/tcp
rag-embedding-server Up              0.0.0.0:8000->8000/tcp
rag-chromadb         Up              0.0.0.0:8001->8000/tcp
```

### Step 2: Test API Health

```bash
# Test local
curl http://localhost:3004/api/rag/health

# Test via domain (after SSL)
curl https://rag.orebit.id/api/rag/health
curl https://api.orebit.id/api/rag/health
```

Expected response:
```json
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

### Step 3: Test Search Functionality

```bash
curl -X POST https://rag.orebit.id/api/rag/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "machine learning",
    "top_k": 5
  }'
```

### Step 4: Check SSL Certificate

```bash
# Check certificate
sudo certbot certificates

# Test SSL
openssl s_client -connect rag.orebit.id:443 -servername rag.orebit.id
```

### Step 5: Check Logs

```bash
# All logs
sudo docker-compose logs -f

# Specific service
sudo docker-compose logs -f api-wrapper
sudo docker-compose logs -f embedding-server
sudo docker-compose logs -f chromadb
```

---

## Security Configuration

### UFW Firewall Status

```bash
sudo ufw status
```

Should show:
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

### Change Default Passwords

```bash
# Change ubuntu password
passwd
```

### SSH Key Authentication (Recommended)

```bash
# Generate SSH key (if not exists)
ssh-keygen -t ed25519 -C "ubuntu@orebit-vps"

# Copy to VPS
ssh-copy-id ubuntu@43.157.201.50

# Disable password auth
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
sudo systemctl restart sshd
```

---

## Troubleshooting

### Issue: DNS Not Propagating

Solution:
```bash
# Check DNS propagation
dig rag.orebit.id
dig api.orebit.id

# Use DNS checker
# https://dnschecker.org/
```

Wait 10-15 minutes for DNS to propagate.

### Issue: Docker Services Won't Start

Solution:
```bash
# Check logs
sudo docker-compose logs

# Restart services
sudo docker-compose restart

# Rebuild
sudo docker-compose down
sudo docker-compose up --build -d

# Check disk space
df -h
```

### Issue: SSL Certificate Failed

Solution:
```bash
# Check DNS first (must be propagated!)
dig rag.orebit.id

# Check nginx configuration
sudo nginx -t

# Check ports 80/443 are open
sudo ufw status
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Manually request certificate
sudo certbot --nginx -d rag.orebit.id -d api.orebit.id
```

### Issue: API Not Responding

Solution:
```bash
# Check if services are running
sudo docker-compose ps

# Check API logs
sudo docker-compose logs api-wrapper

# Test locally
curl http://localhost:3004/api/rag/health

# Check nginx
sudo systemctl status nginx
sudo nginx -t
```

### Issue: ChromaDB Data Missing

Solution:
```bash
# Check ChromaDB logs
sudo docker-compose logs chromadb

# Verify volume
sudo docker volume ls
sudo docker volume inspect rag-system_chroma-data

# If needed, re-index from source
cd /opt/orebit-rag/orebit-ops/rag-system
sudo docker-compose exec chromadb python reindex.py
```

---

## Maintenance

### Update System

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

### Update Application

```bash
cd /opt/orebit-rag/orebit-ops
git pull origin main
cd rag-system
sudo docker-compose down
sudo docker-compose up --build -d
```

### Backup Data

```bash
# Backup ChromaDB
sudo docker exec rag-chromadb sh -c \
  'chroma-run-migrations --target-directory /backup'

# Copy backup
sudo docker cp rag-chromadb:/backup ~/chroma-backup-$(date +%Y%m%d)
```

### View Logs

```bash
# Real-time logs
cd /opt/orebit-rag/orebit-ops/rag-system
sudo docker-compose logs -f

# Last 100 lines
sudo docker-compose logs --tail=100
```

### Restart Services

```bash
cd /opt/orebit-rag/orebit-ops/rag-system
sudo docker-compose restart

# Or restart individually
sudo docker-compose restart api-wrapper
sudo docker-compose restart embedding-server
sudo docker-compose restart chromadb
```

---

## Monitoring

### Check Resource Usage

```bash
# CPU, RAM, Disk
htop

# Docker stats
sudo docker stats

# Disk usage
df -h
sudo du -sh /opt/orebit-rag
```

### Check Nginx Logs

```bash
# Access log
sudo tail -f /var/log/nginx/access.log

# Error log
sudo tail -f /var/log/nginx/error.log
```

---

## Cost & Resources

### VPS Specifications
- **CPU:** 2 vCPU
- **RAM:** 2 GB
- **Storage:** 40 GB
- **Cost:** 60,000 IDR/month (~$3.80 USD)

### Resource Requirements

| Service | CPU | RAM | Disk |
|---|---|---|---|
| API Wrapper | Low | Low (100-200 MB) | Low |
| Embedding Server | Medium (during init) | Medium (500-800 MB) | Medium (model cache) |
| ChromaDB | Low | High (500 MB+) | High (indexed papers) |

**Total Recommended:** 2 vCPU, 2 GB RAM, 10 GB disk

---

## Quick Reference

### Common Commands

```bash
# Connect to VPS
ssh ubuntu@43.157.201.50

# Check services
cd /opt/orebit-rag/orebit-ops/rag-system
sudo docker-compose ps

# View logs
sudo docker-compose logs -f

# Restart services
sudo docker-compose restart

# Update application
cd /opt/orebit-rag/orebit-ops
git pull
cd rag-system
sudo docker-compose down && sudo docker-compose up --build -d

# Restart nginx
sudo systemctl restart nginx

# Renew SSL
sudo certbot renew
```

### API Endpoints

```bash
# Health check
curl https://rag.orebit.id/api/rag/health

# Search papers
curl -X POST https://rag.orebit.id/api/rag/search \
  -H "Content-Type: application/json" \
  -d '{"query": "machine learning", "top_k": 5}'

# Ask question
curl -X POST https://rag.orebit.id/api/rag/answer \
  -H "Content-Type: application/json" \
  -d '{"query": "What is RAG?", "top_k": 3}'

# Stats
curl https://rag.orebit.id/api/rag/stats
```

---

## Post-Deployment Checklist

- [ ] DNS records configured and propagated
- [ ] VPS setup script completed
- [ ] SSL certificates installed and auto-renewal configured
- [ ] Docker services running (3 containers)
- [ ] API health check passing
- [ ] Search functionality working
- [ ] Nginx proxy working
- [ ] Firewall configured (UFW)
- [ ] Default password changed
- [ ] Monitoring setup
- [ ] Backup strategy configured
- [ ] Documentation completed

---

## Support & Logs

### Application Logs
```
/opt/orebit-rag/orebit-ops/rag-system/logs/
```

### System Logs
```bash
# Journal logs
sudo journalctl -u nginx -f
sudo journalctl -u docker -f

# Nginx logs
/var/log/nginx/access.log
/var/log/nginx/error.log
```

### For Issues

1. Check logs: `sudo docker-compose logs`
2. Check services: `sudo docker-compose ps`
3. Check DNS: `dig rag.orebit.id`
4. Check firewall: `sudo ufw status`
5. Check SSL: `sudo certbot certificates`

---

**Maintained by:** QwenPaw Agent  
**VPS:** orebit-sumopod (43.157.201.50)  
**GitHub:** https://github.com/ghoziankarami/orebit-ops  
**Documentation:** `/opt/orebit-rag/orebit-ops/docs/operations/VPS_DEPLOYMENT.md`
