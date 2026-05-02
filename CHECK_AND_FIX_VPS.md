# Check & Fix VPS - Step by Step

## Step 1: Check Current Nginx Configuration

```bash
# Di VPS:
cat /etc/nginx/sites-enabled/rag.orebit.id | grep proxy_pass
```

**Expected output:**
```
proxy_pass https://opposite-fountain-corrected-organized.trycloudflare.com;
```

**Jika masih menunjukkan:**
```
proxy_pass http://103.139.244.177:3004;
```
Berarti command sed gagal, lakukan Step 2.

---

## Step 2: Manually Fix Nginx Configuration

```bash
# Di VPS:
sudo nano /etc/nginx/sites-enabled/rag.orebit.id
```

**Cari baris ini:**
```nginx
proxy_pass http://103.139.244.177:3004;
```

**Ubah menjadi:**
```nginx
proxy_pass https://opposite-fountain-corrected-organized.trycloudflare.com;
```

**Save:**
- `Ctrl+O` (save)
- `Enter` (confirm)
- `Ctrl+X` (exit)

---

## Step 3: Restart Nginx

```bash
# Di VPS:
sudo systemctl restart nginx
```

---

## Step 4: Test Nginx Configuration

```bash
# Test syntax
sudo nginx -t
```

**Should show:**
```
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

---

## Step 5: Test VPS Connection to Cloudflare Tunnel

```bash
# Di VPS - test direct to tunnel URL
curl https://opposite-fountain-corrected-organized.trycloudflare.com/api/rag/health
```

**Should return:**
```json
{"status":"healthy","indexed_papers":351}
```

**Jika ini berhasil, berarti VPS bisa connect ke Cloudflare tunnel.**

---

## Step 6: Test via Domain

```bash
# Test via domain
curl https://rag.orebit.id/api/rag/health
```

**Should return:**
```json
{"status":"healthy","indexed_papers":351}
```

---

## 🚨 TROUBLESHOOTING:

### Jika Step 5 Gagal (502 Bad Gateway):

```bash
# Cek Nginx error logs
sudo tail -50 /var/log/nginx/error.log

# Cek jika ada SSL certificate issue
# Ubah config untuk men-disable SSL verification sementara:
sudo nano /etc/nginx/sites-enabled/rag.orebit.id

# Tambahkan baris ini setelah proxy_pass:
proxy_ssl_verify off;
proxy_ssl_server_name on;

# Restart Nginx
sudo systemctl restart nginx

# Test lagi
curl https://rag.orebit.id/api/rag/health
```

---

### Jika Connection refused:

```bash
# Cek jika cloudflared masih running di QwenPaw
# Di QwenPaw:
ps aux | grep cloudflared

# Jika tidak running, restart:
nohup cloudflared tunnel --url http://127.0.0.1:3004 > /tmp/cloudflared-tunnel.log 2>&1 &

# Cek tunnel URL baru
cat /tmp/cloudflared-tunnel.log | grep "https://"

# Update Nginx VPS dengan URL baru
```

---

### Alternative: Check Complete Nginx Config

```bash
# Di VPS - view full config
cat /etc/nginx/sites-enabled/rag.orebit.id
```

**Expected complete config:**
```nginx
server {
    listen 80;
    server_name rag.orebit.id;

    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name rag.orebit.id;

    ssl_certificate /etc/letsencrypt/live/rag.orebit.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rag.orebit.id/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass https://opposite-fountain-corrected-organized.trycloudflare.com;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # SSL forwarding options
        proxy_ssl_server_name on;
        proxy_ssl_protocols TLSv1.2 TLSv1.3;
        proxy_ssl_verify off;
    }
}
```

---

## 🔍 DIAGNOSTIC COMMANDS:

```bash
# 1. Check what Nginx is proxying to
cat /etc/nginx/sites-enabled/rag.orebit.id | grep -E "proxy_pass|server_name"

# 2. Test direct connection from VPS to tunnel
curl -v https://opposite-fountain-corrected-organized.trycloudflare.com/api/rag/health 2>&1 | grep -E "HTTP|healthy|papers"

# 3. Test Nginx local
curl http://localhost/api/rag/health

# 4. Get Nginx error logs
sudo tail -30 /var/log/nginx/error.log

# 5. Get Nginx access logs
sudo tail -30 /var/log/nginx/access.log

# 6. Check Nginx status
sudo systemctl status nginx | head -20
```

---

## ✅ SUCCESS CRITERIA:

```
✅ Nginx config shows: proxy_pass via cloudflare URL
✅ curl to cloudflare URL returns 351 papers
✅ curl to rag.orebit.id returns 351 papers
✅ No 502 Bad Gateway errors
```

---

**Run Step 1 first, then send screenshot!** 📸
