# VPS Sync Guide

## ❌ ANSWER: TIDAK PERLU SYNC APA-APA

### Kenapa Tidak Perlu Sync?

**Current Architecture:**
```
VPS (orebit-sumopod, 43.157.201.50)
  ├─ React UI (frontend only)
  ├─ Nginx (reverse proxy)
  └─ Points to Cloudflare Tunnel
      ↓
Cloudflare Tunnel
  (venture-stud-gale-fuji.trycloudflare.com)
      ↓
QwenPaw (Local)
  ├─ ChromaDB (343 papers)
  ├─ Embedding Server (port 3005)
  └─ API Wrapper (port 3004)
```

**Key Point:**
- VPS **GAK simpan data**
- VPS **GAK run ChromaDB**
- VPS **GAK run API Wrapper**
- VPS cuma **proxy** via Cloudflare Tunnel
- Semua data ada di **QwenPaw local**

---

## ✅ SUDAH DEPLOYED DI VPS

| Component | Status | Location |
|-----------|--------|----------|
| **React UI** | ✅ Deployed | `/var/www/rag-ui` |
| **Nginx Config** | ✅ Configured | rag.orebit.id + api.orebit.id |
| **SSL Certificates** | ✅ Valid | Let's Encrypt |
| **Tunnel URL** | ✅ Active | venture-stud-gale-fuji.trycloudflare.com |
| **API Proxy** | ✅ Working | /api/rag/* → Cloudflare Tunnel |

---

## 🔍 APA SAJA YANG ADA DI VPS?

### Di VPS (orebit-sumopod):
```bash
/opt/rag-ui/                    # React UI files (HTML/JS/CSS)
/etc/nginx/sites-enabled/       # Nginx configuration
  ├── rag-orebit-id            # rag.orebit.id config
  └── api-orebit-id            # api.orebit.id config
/etc/letsencrypt/               # SSL certificates
```

### Di QwenPaw (Local):
```bash
/app/working/workspaces/default/orebit-ops/
  ├─ rag-system/
  │   ├─ file_store/chroma/    # ChromaDB (343 papers)
  │   ├─ api-wrapper/           # API wrapper (port 3004)
  │   └─ embedding_server.py   # Embedding server (port 3005)
  └─ rag-public/dist/          # React UI (source)
```

---

## 🚀 KAPAN PERLU UPDATE VPS?

### ❗ HANYA JIKA:

#### 1. **Tunnel URL Berubah**
Cloudflare tunnel quick URLs berubah setiap restart:
- Current: `venture-stud-gale-fuji.trycloudflare.com`
- Next restart: `random-words-abc.trycloudflare.com`

**Cara Update:**
```bash
# Di QwenPaw, dapatkan tunnel URL baru
cat /tmp/cloudflared-tunnel-*.log | grep -oP 'https://[^ ]+\.trycloudflare\.com' | tail -1

# Update di VPS (opsional, ada script)
vps-update-tunnel-url.sh <new-tunnel-url>
```

#### 2. **React UI Butuh Update**
Jika ada update di `rag-public/dist/`:
```bash
# Deploy ulang React UI ke VPS
# Manual: SSH ke VPS, copy files ke /var/www/rag-ui
```

#### 3. **Nginx Config Butuh Perubahan**
Jika butuh tambahan route/security config:
```bash
# SSH ke VPS, edit Nginx config
sudo nano /etc/nginx/sites-enabled/rag-orebit-id
sudo systemctl restart nginx
```

---

## 📋 SEMUA SUDAH OTOMATIS

### ✅ Yang GAK Perlu Sync:

| Data | Lokasi | Butuh Sync? |
|------|--------|------------|
| ChromaDB (343 papers) | QwenPaw local | ❌ NO |
| Embeddings | QwenPaw local | ❌ NO |
| API Wrapper | QwenPaw local | ❌ NO |
| New Papers | QwenPaw local | ❌ NO |
| Obsidian Notes | QwenPaw local | ❌ NO |
| API Key | QwenPaw local | ❌ NO |
| Tunnel URL | QwenPaw local | ❌ NO (auto) |

### ✅ Ada di VPS:

| Component | Lokasi | Butuh Update? |
|-----------|--------|---------------|
| React UI | /var/www/rag-ui | ❌ NO (sudah deploy) |
| Nginx Config | /etc/nginx/ | ❌ NO (sudah configured) |
| SSL Cert | /etc/letsencrypt/ | ❌ NO (auto-renew) |
| Tunnel URL | Nginx config | ⚠️ HANYA jika berubah |

---

## 🔧 TROUBLESHOOTING

### Problem: rag.orebit.id gak bisa query

**Check:**
```bash
# 1. Check tunnel status
ps aux | grep cloudflared | grep -v grep

# 2. Check API wrapper
ps aux | grep "node.*index.js" | grep -v grep

# 3. Check tunnel URL
curl -s http://127.0.0.1:3004/api/rag/health

# 4. If failed, get new tunnel URL
cat /tmp/cloudflared-tunnel-*.log | grep trycloudflare | tail -1
```

**Solution:**
- Jika tunnel berubah → Update Nginx di VPS
- Jika API wrapper down → Restart di QwenPaw
- Jika tunnel down → `bash check-cloudflared.sh` (auto every 5 min)

---

## 📊 CURRENT STATUS

| Component | Status | Location |
|-----------|--------|----------|
| QwenPaw | ✅ Running | Local |
| ChromaDB | ✅ 343 papers | Local |
| Embedding Server | ✅ Port 3005 | Local |
| API Wrapper | ✅ Port 3004 | Local |
| Cloudflare Tunnel | ✅ Active | venture-stud-gale-fuji... |
| VPS | ✅ Online | orebit-sumopod |
| React UI | ✅ Deployed | /var/www/rag-ui |
| Nginx | ✅ Proxying | rag.orebit.id |
| SSL | ✅ Valid | Let's Encrypt |

---

## ✅ FINAL ANSWER

**❌ TIDAK PERLU SYNC APA-APA**

**Kenapa:**
- Cloudflare Tunnel sudah handle semua koneksi
- VPS cuma serve React UI + proxy
- Semua data ada di QwenPaw local
- System sudah fully sinkron otomatis

**Kapan Perlu Action:**
- Hanya jika tunnel URL berubah (update Nginx)
- Hanya jika React UI butuh update (deploy ulang)

**Rekomendasi:**
- Biarkan seperti sekarang
- Cron jobs sudah monitoring semua:
  - `check-cloudflared.sh` (every 5 min)
  - `heartbeat.sh` (every 15 min)
  - `rclone-watchdog` (every 10 min)

---

**Sudah fully operational, tidak perlu sync apa-apa!** ✅

---

**For more details:**
- Test: `bash test-rag-end-to-end.sh`
- Docs: `PRODUCTION_DEPLOYMENT_STATUS.md`
