# UI 404 Issue - Solution Options

## Current Status:

✅ **Working:**
- https://rag.orebit.id/api/rag/health → 351 papers (OK)
- https://rag.orebit.id/api/rag/* → All API endpoints working

❌ **404 Error:**
- https://rag.orebit.id/ → Returns 404

## Root Cause:

QwenPaw API wrapper (port 3004) is a **pure API server**, not a web app.
It ONLY serves `/api/*` endpoints, no UI at root (`/`).

## QwenPaw Components:

```
Port 3004: RAG API Wrapper (API only, no UI)
  - /api/rag/health
  - /api/rag/query
  - All RAG endpoints

Port 8088: QwenPaw Console (Full admin UI)
  - Has HTML interface
  - Agent management
  - Chat interface
  - Full QwenPaw control panel
```

---

## Solution Options:

### Option 1: Create Landing Page (RECOMMENDED)

**Architecture:**
```
rag.orebit.id/
├─ / (landing page with API info + links)
├─ /api/rag/* (RAG API - proxy to QwenPaw:3004)
```

**VPS Nginx configuration:**
```nginx
server {
    listen 443 ssl http2;
    server_name rag.orebit.id;

    # SSL config...

    # Root: Serve landing page
    location = / {
        root /var/www/rag.orebit.id;
        index index.html;
        try_files $uri /index.html;
    }

    # RAG API endpoints
    location /api/ {
        proxy_pass https://opposite-fountain-corrected-organized.trycloudflare.com;
        proxy_set_header Host $host;
        # ... other proxy settings
    }
}
```

**Landing page content:**
```
RAG API Service
--------------
Status: ✅ Healthy (351 indexed papers)

Endpoints:
  • Health Check: /api/rag/health
  • Query API: /api/rag/query

Documentation: [API Docs](https://github.com/ghoziankarami/orebit-ops)

QwenPaw Console: [Admin Dashboard](https://console.orebit.id) (setup needed)
```

---

### Option 2: Path-Based Routing

**Architecture:**
```
rag.orebit.id/
├─ /api/* (RAG API - proxy to QwenPaw:3004)
├─ /console/* (QwenPaw Console - proxy to QwenPaw:8088)
```

**Requirements:**
- Setup cloudflared tunnel for port 8088
- Update Nginx with location blocks

---

### Option 3: Separate Domain for Console

**Architecture:**
```
rag.orebit.id      → RAG API (port 3004)
console.orebit.id  → QwenPaw Console (port 8088)
```

**Requirements:**
- Create DNS: console.orebit.id → 43.157.201.50
- Get SSL certificate: certbot
- Setup separate Nginx site
- Setup cloudflared tunnel for port 8088

---

### Option 4: Status Quo (API-Only)

**Keep current setup:**
- rag.orebit.id serves API only
- Consumers use /api/rag/* endpoints
- Root 404 is acceptable for public API

---

## 🎯 RECOMMENDATION: Option 1

**Why:**
- ✅ Simple to implement
- ✅ Provides useful information at domain root
- ✅ Links to API docs and console
- ✅ Professional look
- ✅ No additional infrastructure needed

---

## 🔧 IMPLEMENTATION - Option 1 (Landing Page)

### Step 1: Create Landing Page (on VPS)

```bash
# On VPS:
sudo mkdir -p /var/www/rag.orebit.id
sudo nano /var/www/rag.orebit.id/index.html
```

**Paste this content:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Orebit RAG API Service</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            line-height: 1.6;
            color: #333;
        }
        h1 { color: #2c3e50; }
        .status { font-size: 24px; margin: 20px 0; }
        .healthy { color: #27ae60; }
        .endpoint { background: #f8f9fa; padding: 10px; margin: 10px 0; border-radius: 4px; }
        code { background: #ecf0f1; padding: 2px 6px; border-radius: 3px; }
    </style>
</head>
<body>
    <h1>🚀 Orebit RAG API Service</h1>

    <div class="status">
        Status: <span class="healthy">✅ Healthy</span>
    </div>

    <h2>API Health</h2>
    <div class="endpoint">
        <strong>351</strong> indexed papers available
    </div>

    <h2>API Endpoints</h2>
    <div class="endpoint">
        <code>GET /api/rag/health</code><br>
        Check API status and corpus information
    </div>

    <div class="endpoint">
        <code>POST /api/rag/query</code><br>
        Query the RAG system with questions
    </div>

    <h2>Documentation</h2>
    <p>
        <a href="https://github.com/ghoziankarami/orebit-ops">GitHub Repository</a>
    </p>

    <h2>Quick Test</h2>
    <div class="endpoint">
        <code>curl https://rag.orebit.id/api/rag/health</code>
    </div>

    <hr>
    <footer>
        <p>Orebit RAG System • QwenPaw powered</p>
    </footer>
</body>
</html>
```

**Save and exit** (Ctrl+O, Enter, Ctrl+X)

### Step 2: Update Nginx Configuration (on VPS)

```bash
# On VPS:
sudo nano /etc/nginx/sites-enabled/rag-orebit-id
```

**Add/update location block for root:**
```nginx
server {
    listen 443 ssl http2;
    server_name rag.orebit.id;

    # SSL config... (keep existing)

    # NEW: Root landing page
    location = / {
        root /var/www/rag.orebit.id;
        index index.html;
        try_files $uri /index.html;
    }

    # API endpoints (keep existing)
    location / {
        proxy_pass https://opposite-fountain-corrected-organized.trycloudflare.com;
        # ... keep existing proxy settings
    }
}
```

**Save and exit**

### Step 3: Test and Restart

```bash
# On VPS:
# Test Nginx config
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Test
curl https://rag.orebit.id/
curl https://rag.orebit.id/api/rag/health
```

---

## ✅ RESULT:

After implementing Option 1:
- ✅ https://rag.orebit.id/ → Landing page with API info
- ✅ https://rag.orebit.id/api/rag/health → 351 papers
- ✅ Clean, professional looking at domain root
- ✅ Easy to test and verify API status
- ✅ Links to documentation

---

**Would you like me to generate the complete setup script for Option 1?** 🛠️
