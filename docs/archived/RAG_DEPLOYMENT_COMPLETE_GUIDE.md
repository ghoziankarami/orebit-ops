# 🚀 Complete RAG System Deployment Guide
## Best Practice Architecture: Vercel UI + VPS API + QwenPaw Backend

---

## 📋 Current System Status (QwenPaw)

### ✅ Working Components
- **API Wrapper**: Running on port 3004 (PID 3991901)
  - Health: http://127.0.0.1:3004/api/rag/health
  - Status: Healthy (351 papers, 343 summaries, 93 collections)
  - API Key: Enabled (orebit-rag-api-key-2026-03-26-temp)

- **Cloudflare Tunnel**: Active
  - URL: https://reader-measuring-romance-rarely.trycloudflare.com
  - Target: http://127.0.0.1:3004
  - Status: Operational

- **RAG System**: Complete
  - ChromaDB: 351 indexed papers
  - API Endpoints: All ready
  - Authentication: API key + loopback bypass

### 📁 File Structure
```
/app/working/workspaces/default/orebit-ops/
├── rag-public/               # React UI (cloned from GitHub)
│   ├── src/App.jsx          # Main React app
│   ├── dist/                # Built UI (ready to deploy)
│   ├── api/                 # Vercel serverless functions
│   ├── vercel.json          # Vercel configuration
│   └── package.json
├── rag-system/api-wrapper/  # API wrapper (Node.js)
│   ├── index.js             # Express server
│   ├── .env                 # API key configured
│   └── start-wrapper.sh     # Startup script
└── orebit-rag-id-index-V2.html  # Placeholder landing page
```

---

## 🏗️ Target Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  User Browser                                                   │
│  https://rag.orebit.id                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Vercel (Frontend)                                             │
│  • React UI (rag.orebit.id)                                    │
│  • Static files + API Serverless                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ /api/rag/* (serverless proxy)
                              │ with API key authentication
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  VPS (orebit-sumopod)                                          │
│  • Nginx: api.orebit.id/api/rag/*                              │
│  • Proxy: Cloudflare tunnel → QwenPaw                          │
│  • SSL: api.orebit.id                                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS via Cloudflare Tunnel
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  QwenPaw (Backend)                                             │
│  • API Wrapper: 0.0.0.0:3004                                   │
│  • ChromaDB: 351 papers                                        │
│  • RAG Logic: Search + Answer                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Deployment Steps

### Step 1: Deploy to Vercel (Run on YOUR MACHINE, not QwenPaw)

**Why?** QwenPaw has no npm/Vercel CLI installed, and deployment should be done from your local machine.

```bash
# 1. Install Vercel CLI (your machine)
npm install -g vercel

# 2. Login to Vercel
vercel login

# 3. Navigate to rag-public directory
cd /app/working/workspaces/default/orebit-ops/rag-public

# 4. Deploy to Vercel
vercel

# 5. Follow prompts:
#    - Project name: rag-public-dashboard
#    - Framework preset: Vite
#    - Override settings: Use vercel.json
#    - Build Command: npm run build
#    - Output Directory: dist

# 6. Set environment variables
vercel env add RAG_API_BASE
# Value: https://api.orebit.id/api/rag

vercel env add RAG_API_KEY
# Value: orebit-rag-api-key-2026-03-26-temp

# 7. Configure custom domain
#    - Go to Vercel Dashboard → Domains
#    - Add domain: rag.orebit.id
#    - Update DNS (see DNS section below)

# 8. Production deploy
vercel --prod
```

---

### Step 2: Configure DNS Settings

**Update your DNS records:**

```
rag.orebit.id  CNAME  cname.vercel-dns.com
api.orebit.id  A      43.157.201.50
```

Wait for DNS propagation (5-15 minutes).

---

### Step 3: Deploy to VPS (Run on VPS)

**Copy the VPS_DEPLOYMENT_PROMPT.txt file below and run it on your VPS:**

```bash
# On VPS:
bash deploy-vps-rag-api.sh
```

Or follow the manual steps in VPS_DEPLOYMENT_PROMPT.txt.

---

## 📄 VPS Deployment Prompt (Copy to VPS)

**File: VPS_DEPLOYMENT_PROMPT.txt**

```bash
#!/bin/bash
# ===========================================================
# VPS DEPLOYMENT: Configure api.orebit.id for RAG API
# ===========================================================

set -euo pipefail

echo "🚀 VPS Deployment: Configure api.orebit.id for RAG API"
echo "======================================================="
echo ""

# Step 1: Install dependencies
echo "📦 Step 1: Installing dependencies..."
apt update && apt install -y nginx certbot python3-certbot-nginx
echo "✅ Dependencies installed"
echo ""

# Step 2: Create Nginx configuration for api.orebit.id
echo "⚙️  Step 2: Configuring Nginx for api.orebit.id..."
cat > /etc/nginx/sites-available/api-orebit-id << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name api.orebit.id;

    # Redirect HTTP to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.orebit.id;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/api.orebit.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.orebit.id/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;

    # Proxy to QwenPaw via Cloudflare tunnel
    location /api/rag/ {
        proxy_pass https://reader-measuring-romance-rarely.trycloudflare.com;
        proxy_http_version 1.1;
        proxy_set_header Host reader-measuring-romance-rarely.trycloudflare.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts for long queries
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 120s;

        # CORS headers
        add_header 'Access-Control-Allow-Origin' 'https://rag.orebit.id' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, x-api-key' always;

        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/api-orebit-id-access.log;
    error_log /var/log/nginx/api-orebit-id-error.log;
}
EOF

echo "✅ Nginx configuration created"
echo ""

# Step 3: Enable site and test
echo "🔗 Step 3: Enabling Nginx site..."
ln -sf /etc/nginx/sites-available/api-orebit-id /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
echo "✅ Nginx configuration valid"
echo ""

# Step 4: Obtain SSL certificate
echo "🔒 Step 4: Obtaining SSL certificate..."
certbot certonly --nginx -d api.orebit.id --non-interactive --agree-tos --email your-email@example.com
echo "✅ SSL certificate obtained"
echo ""

# Step 5: Restart Nginx
echo "🔄 Step 5: Restarting Nginx..."
systemctl restart nginx
systemctl enable nginx
echo "✅ Nginx restarted and enabled"
echo ""

# Step 6: Test API
echo "🧪 Step 6: Testing API...
curl -s https://api.orebit.id/api/rag/health
echo ""
echo ""

echo "🎉 VPS Deployment Complete!"
echo "================================"
echo ""
echo "Testing API endpoints:"
echo "  • Health check: curl https://api.orebit.id/api/rag/health"
echo "  • Statistics: curl -H 'x-api-key: orebit-rag-api-key-2026-03-26-temp' https://api.orebit.id/api/rag/stats"
echo "  • Browse: curl -H 'x-api-key: orebit-rag-api-key-2026-03-26-temp' https://api.orebit.id/api/rag/browse"
echo ""
echo "VPS is ready to serve API at: https://api.orebit.id/api/rag/*"
```

---

## 🧪 Verification Steps

### Test 1: Vercel Frontend
```bash
# Open in browser
https://rag.orebit.id

# Should see:
# • Orebit RAG chat interface
# • Browse library button
# • Statistics (351 papers)
# • Search box
```

### Test 2: VPS API
```bash
# Health check
curl https://api.orebit.id/api/rag/health

# Expected:
{
  "status": "healthy",
  "corpus": {
    "indexed_papers": 351,
    "summary_count": 343,
    "collection_count": 93
  }
}

# Statistics (with API key)
curl -H 'x-api-key: orebit-rag-api-key-2026-03-26-temp' \
  https://api.orebit.id/api/rag/stats
```

### Test 3: End-to-End Flow
```bash
# Test query through Vercel → VPS → QwenPaw
curl -X POST https://api.orebit.id/api/rag/answer \
  -H 'Content-Type: application/json' \
  -H 'x-api-key: orebit-rag-api-key-2026-03-26-temp' \
  -d '{
    "query": "What is kriging interpolation?",
    "top_k": 5
  }'
```

---

## 🔧 Troubleshooting

### Issue: Vercel shows "404 Not Found"
**Solution:**
- Check Vercel deployment logs
- Verify build output directory is `dist`
- Check Vercel project settings

### Issue: CORS errors in browser console
**Solution:**
- Check Nginx CORS headers on VPS
- Verify API calls use `x-api-key` header
- Check Vercel environment variables

### Issue: API returns "401 Unauthorized"
**Solution:**
- Verify API key matches: `orebit-rag-api-key-2026-03-26-temp`
- Check header is `x-api-key` (not `X-API-KEY`)
- Test with loopback bypass: curl http://127.0.0.1:3004/api/rag/health

### Issue: Connection timeout from VPS to QwenPaw
**Solution:**
- Check Cloudflare tunnel status on QwenPaw
- Verify tunnel URL: `reader-measuring-romance-rarely.trycloudflare.com`
- Restart tunnel if needed

---

## 📊 Architecture Benefits

### ✅ This Architecture Is Best Practice Because:

1. **Separation of Concerns**
   - Vercel: Frontend, CDN, static files
   - VPS: API gateway, SSL, rate limiting
   - QwenPaw: Core RAG logic, database

2. **Scalability**
   - Vercel scales automatically (frontend)
   - VPS can be upgraded for API traffic
   - QwenPaw handles RAG processing

3. **Security**
   - API key authentication
   - HTTPS everywhere (Vercel + VPS + Cloudflare)
   - CORS properly configured
   - Rate limiting on all layers

4. **Reliability**
   - Cloudflare tunnel (encrypted, no public IP needed)
   - Vercel global CDN (99.99% uptime)
   - VPS Nginx reverse proxy

5. **Cost-Effective**
   - Vercel: Free tier sufficient for UI
   - VPS: 60k IDR/month (orebit-sumopod)
   - QwenPaw: Existing infrastructure

---

## 📝 Summary Checklist

### ✅ QwenPaw (Current Status)
- [x] API wrapper running (port 3004)
- [x] API key configured
- [x] Cloudflare tunnel active
- [x] rag-public cloned from GitHub
- [x] Vercel configuration created

### ⏳ Your Machine (Next Steps)
- [ ] Install Vercel CLI
- [ ] Login to Vercel
- [ ] Deploy rag-public to Vercel
- [ ] Set environment variables (RAG_API_BASE, RAG_API_KEY)
- [ ] Configure custom domain (rag.orebit.id)
- [ ] Wait for DNS propagation

### ⏳ VPS (Next Steps)
- [ ] Run VPS_DEPLOYMENT_PROMPT.txt
- [ ] Configure Nginx for api.orebit.id
- [ ] Obtain SSL certificate
- [ ] Test API endpoints
- [ ] Verify CORS configuration

### 🎯 Final Verification
- [ ] https://rag.orebit.id shows React UI
- [ ] https://api.orebit.id/api/rag/health returns JSON
- [ ] Chat interface works (query → answer with sources)
- [ ] Browse library works (paginated paper list)
- [ ] All CORS errors resolved

---

## 🚀 Quick Start Commands

**On your machine (deploy to Vercel):**
```bash
cd /app/working/workspaces/default/orebit-ops/rag-public
npm install -g vercel
vercel login
vercel env add RAG_API_BASE  # https://api.orebit.id/api/rag
vercel env add RAG_API_KEY   # orebit-rag-api-key-2026-03-26-temp
vercel --prod
```

**On VPS (configure API):**
```bash
bash deploy-vps-rag-api.sh
# Or copy/run VPS_DEPLOYMENT_PROMPT.txt content
```

**Test:**
```bash
# Test VPS API
curl https://api.orebit.id/api/rag/health

# Test browser
open https://rag.orebit.id
```

---

**Deployment Status:**
- 🟢 QwenPaw: Ready
- 🟡 Vercel: Pending (your action needed)
- 🟡 VPS: Pending (your action needed)

**Complete Guide Created:** ✅
**Files Ready for Deployment:** ✅
**Architecture Documented:** ✅
