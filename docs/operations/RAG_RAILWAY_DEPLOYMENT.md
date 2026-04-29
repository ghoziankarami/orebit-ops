# RAG.orebit.id — Railway Deployment Guide

> **Status:** Ready to Deploy  
> **Last updated:** 2026-04-29  
> **Deployment target:** Railway.app  

---

## Overview

This guide deploys the RAG API (rag.orebit.id) to Railway for production use.

### Architecture

```
Internet → Railway (Auto-SSL) → rag.orebit.id
                                     ↓
                              RAG API Wrapper
                              (Node.js, port 3004)
                                     ↓
                         ┌───────────┴───────────┐
                         ↓                       ↓
                  Embedding Server         ChromaDB
                  (all-MiniLM-L6-v2)       (350 papers indexed)
                  (port 8000)               (port 8001)
```

---

## Prerequisites

1. **Railway account** — Sign up at [railway.app](https://railway.app) (free tier available)
2. **GitHub account** — Code is in `ghoziankarami/orebit-ops`
3. **Domain** — `rag.orebit.id` DNS access

---

## Deployment Steps

### Step 1: Fork or Link Repository

1. Go to [railway.app](https://railway.app)
2. Click **"New Project"** → **"Deploy from GitHub repo"**
3. Select `ghoziankarami/orebit-ops` repository
4. Branch: `main`

### Step 2: Configure Service

1. Railway will auto-detect Dockerfile
2. **Override root directory** to: `rag-system/api-wrapper`
3. Set environment variables:

```bash
# Required
PORT=3004
RAG_API_HOST=0.0.0.0
OREBIT_EMBEDDING_API_URL=http://localhost:8000/v1/embeddings

# Optional (for stats)
RAG_API_KEY=your-secret-api-key
RAG_STATS_TTL_MS=60000
RAG_RESPONSE_CACHE_TTL_MS=300000
```

### Step 3: Add Persistent Storage

1. In Railway dashboard, click on the service
2. Go to **"Settings"** → **"Add Persistent Disk"**
3. Allocate **1GB** (ChromaDB data)
4. Mount at: `/data`

> ⚠️ **IMPORTANT:** ChromaDB data needs persistent storage for the 350 indexed papers.

### Step 4: Configure Domain

1. In Railway dashboard, go to **"Settings"** → **"Networking"**
2. Click **"Generate Domain"**
3. Railway will generate a domain like: `rag-api.railway.app`
4. **OR** add custom domain:
   - Click **"Add Custom Domain"**
   - Enter: `rag.orebit.id`
   - Railway will show DNS verification record
   - Add CNAME record in your DNS provider

### DNS Configuration for rag.orebit.id

```
Type: CNAME
Name: rag
Value: rag-api.railway.app  (or your Railway generated domain)
TTL: 300
```

Wait 5-10 minutes for DNS propagation.

### Step 5: Verify Deployment

```bash
# Check health
curl https://rag.orebit.id/api/rag/health

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

## Health Check

Railway uses `/api/rag/health` for health checks.

If health check fails:
1. Check Railway logs: `railway logs`
2. Common issues:
   - Port mismatch (set PORT=3004)
   - Missing environment variables
   - Out of memory (add RAM in settings)

---

## Troubleshooting

### Issue: Health check failing

```bash
# Check if service is running
railway logs

# Check environment variables
railway variables

# Restart service
railway up --detach
```

### Issue: 502 Bad Gateway

The API wrapper is starting but not responding. Check:
1. Environment variable `PORT=3004` is set
2. Health check endpoint `/api/rag/health` returns 200

### Issue: ChromaDB data missing

1. Check persistent disk is attached
2. Verify disk mount path matches ChromaDB config
3. May need to rebuild index from source

---

## Monitoring

### Railway Dashboard

- **Logs:** Real-time logs at `railway logs -f`
- **Metrics:** CPU, RAM, Network usage in dashboard
- **Deployments:** Auto-redeploy on GitHub push

### Alert Setup (Optional)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Add Discord/Slack notifications
railway notifications add discord --webhook-url=<your-webhook>
```

---

## Cost Estimate

| Resource | Free Tier | Paid |
|----------|-----------|------|
| Compute | 500 hours/month | ~$5/month |
| RAM | 1GB | $10/GB |
| Disk | 1GB | $0.15/GB |
| Bandwidth | 100GB/month | $0.10/GB |

**Estimated cost for moderate use:** $0-5/month

---

## Backup Strategy

### ChromaDB Backup

```bash
# Connect to Railway container
railway connect chromadb

# Export data
rclone copy railway-chroma:/chroma backup:orebit-rag/chroma-$(date +%Y%m%d)
```

---

## Local Development

### Test Docker Compose Locally

```bash
cd /app/working/workspaces/default/orebit-ops/rag-system

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f api-wrapper

# Test API
curl http://localhost:3004/api/rag/health

# Stop
docker-compose down
```

---

## Quick Reference

```bash
# Railway CLI commands
railway login              # Login to Railway
railway init              # Initialize project
railway up                # Deploy
railway up --detach       # Deploy in background
railway logs              # View logs
railway logs -f           # Follow logs
railway variables         # List variables
railway connect <service> # Connect to service
railway status           # Check deployment status

# API endpoints
GET  /api/rag/health      # Health check
GET  /api/rag/stats       # Stats
POST /api/rag/search      # Search
POST /api/rag/answer      # Ask question
```

---

## Post-Deployment Checklist

- [ ] DNS propagated (`dig rag.orebit.id`)
- [ ] Health check passing
- [ ] Can search papers
- [ ] Can ask questions
- [ ] ChromaDB data persisted
- [ ] Backup configured
- [ ] Monitoring alerts set up

---

**Maintained by:** QwenPaw Agent  
**Repository:** https://github.com/ghoziankarami/orebit-ops
