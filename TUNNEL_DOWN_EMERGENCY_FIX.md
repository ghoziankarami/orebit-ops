# Emergency Fix - Cloudflare Tunnel Down & New Tunnel URL

## ⚠️ CRITICAL ISSUE IDENTIFIED

### Error 1016 - Cloudflare Connection Lost

**Symptom:** Error 1016 Ray ID when accessing https://rag.orebit.id/api/*
**Root Cause:** Cloudflare tunnel disconnected, Error 1016 (Origin DNS error)

## Problem Analysis

### What Happened:
1. ✅ API wrapper is working locally (http://127.0.0.1:3004)
2. ❌ Cloudflare tunnel disconnected from Cloudflare edge servers
3. ❌ Old tunnel URL: https://opposite-fountain-corrected-organized.trycloudflare.com (DOWN)
4. ✅ New tunnel URL: https://reader-measuring-romance-rarely.trycloudflare.com (ACTIVE)

### Why This Happens:
- "Quick tunnels" (trycloudflare.com) have no uptime guarantee
- Tunnels can disconnect and need to be restarted
- Each restart generates a NEW URL (this is a limitation)

## 🚨 IMMEDIATE ACTION REQUIRED

### Update VPS Nginx Configuration:

```bash
# On VPS:
sudo nano /etc/nginx/sites-enabled/rag-orebit-id
```

**Find and REPLACE:**
```nginx
# OLD URL (not working)
proxy_pass https://opposite-fountain-corrected-organized.trycloudflare.com;

# NEW URL (working)
proxy_pass https://reader-measuring-romance-rarely.trycloudflare.com;
```

**Also update server_name directive if referencing tunnel:**
```nginx
# If Cloudflare tunnel uses custom Host header
proxy_set_header Host reader-measuring-romance-rarely.trycloudflare.com;
```

**Save and exit** (Ctrl+O, Enter, Ctrl+X)

**Restart Nginx:**
```bash
sudo systemctl restart nginx
```

**Test:**
```bash
curl https://rag.orebit.id/api/rag/health
# Should now return: {"status": "healthy", "indexed_papers": 351}
```

---

## 🎯 About "Old UI" - Clarification

### There Was No Previous UI at rag.orebit.id

**User Question:** "Terus mana UI rag.orebit.id yang lama???"

**Clarification:**

**QwenPaw has TWO components:**
1. **Port 3004:** RAG API Wrapper (API only, NO UI)
   - This is what we exposed through the tunnel
   - Pure REST API endpoints
   - No HTML interface

2. **Port 8088:** QwenPaw Console (Full Admin UI)
   - This has a HTML interface
   - Agent management, chat interface, full control panel
   - BUT: We NEVER exposed this through the tunnel

**Why No UI at rag.orebit.id:**
- RAG system was designed as API-only initially
- We created a **landing page** to show system status
- Landing page shows: URL, endpoints, and usage instructions
- No interactive RAG search interface was ever implemented

### What We Have Now:

```
rag.orebit.id/
├─ / (landing page - shows status and API info)
└─ /api/rag/* (REST API endpoints)
    ├─ /api/rag/health (health check)
    └─ /api/rag/query (query RAG)
```

### If You Want a UI:

**Options:**
1. **Build a simple RAG query interface** (HTML form → POST to /api/rag/query)
2. **Expose QwenPaw Console** (tunnel port 8088 in addition to 3004)
3. **Create a dedicated RAG search UI** (similar to ChatGPT interface)

---

## 🔧 Troubleshooting Quick Reference

### If You See Error 1016:

**Cause:** Cloudflare tunnel URL changed or disconnected

**Solution:**
```bash
# 1. Check QwenPaw tunnel status
ps aux | grep cloudflared | grep -v grep

# 2. Get new tunnel URL
tail -50 /tmp/cloudflared-tunnel-new.log | grep "trycloudflare.com"

# 3. Update VPS Nginx config to new URL
sudo nano /etc/nginx/sites-enabled/rag-orebit-id

# 4. Restart Nginx
sudo systemctl restart nginx

# 5. Test
curl https://rag.orebit.id/api/rag/health
```

### Current Tunnel URLs:

| Status | Tunnel URL |
|--------|------------|
| ❌ OLD | opposite-fountain-corrected-organized.trycloudflare.com |
| ✅ NEW | reader-measuring-romance-rarely.trycloudflare.com |

---

## 💡 Permanent Solution: Named Tunnel

**Problem:** Quick tunnels change URL every restart

**Solution:** Create a named Cloudflare tunnel (persistent URL)

```bash
# On QwenPaw:
cloudflared tunnel login
cloudflared tunnel create qwenpaw-rag

# Get tunnel ID and configure
# Update VPS to use stable URL like: qwenpaw-rag.trycloudflare.com
```

**Benefits:**
- URL never changes
- Domain control via Cloudflare DNS
- Better monitoring and analytics
- More suitable for production

---

## 📊 Current System Status

### Working:
- ✅ API wrapper (http://127.0.0.1:3004)
- ✅ ChromaDB (351 indexed papers)
- ✅ Cloudflare tunnel (new URL)

### Not Working (Needs Fix):
- ❌ VPS Nginx configuration (still pointing to OLD tunnel URL)

### Next Steps:
1. ⏳ Update VPS Nginx to new tunnel URL
2. ⏳ Test API endpoints
3. ⏳ Apply landing page fix (if not done)
4. ✅ System fully operational

---

## ❓ Common Questions

### Q: Why Error 1016?
A: Cloudflare tunnel disconnected, needs restart. New URL generated.

### Q: Will this happen again?
A: Yes, with quick tunnels. Restart = new URL.

### Q: How to prevent this?
A: Use named tunnel (persistent URL) - requires Cloudflare account.

### Q: Where is the RAG search UI?
A: Never implemented. Currently API-only. Landing page provides API info.

### Q: Can I build a RAG UI?
A: Yes! POST to /api/rag/query with natural language questions.

---

## 🚨 IMMEDIATE ACTION PLAN

### Step 1 (Critical - On VPS):
```bash
sudo nano /etc/nginx/sites-enabled/rag-orebit-id
# Update proxy_pass to: reader-measuring-romance-rarely.trycloudflare.com
sudo systemctl restart nginx
curl https://rag.orebit.id/api/rag/health
```

### Step 2 (Optional - On QwenPaw):
```bash
# Consider creating named tunnel for persistent URL
# See "Permanent Solution" section above
```

### Step 3 (Optional - On VPS):
```bash
# Apply landing page fix for stats
bash /app/working/workspaces/default/orebit-ops/update-landing-page.sh
```

---

## 🎯 Summary

**Current Issue:**
- ❌ Cloudflare tunnel URL changed → Error 1016
- ❌ VPS Nginx still pointing to OLD URL
- ✅ Tunnel restarted with NEW URL

**Fix:**
1. Update VPS Nginx to NEW tunnel URL
2. Restart Nginx
3. Test API endpoints

**Status:**
- 🟡 Waiting for VPS Nginx update
- 🟢 QwenPaw: All systems operational
- 🟢 API: Working (351 papers)

**No Previous UI:**
- RAG system is API-only (no search interface ever built)
- Landing page shows API usage
- QwenPaw Console exists but not exposed (port 8088)

---

**Apply the Nginx update on VPS to restore API functionality!** 🚀
