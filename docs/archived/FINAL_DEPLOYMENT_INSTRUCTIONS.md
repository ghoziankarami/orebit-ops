# FINAL DEPLOYMENT INSTRUCTIONS - ONE COMMAND FIX

## Diagnosis Complete

### ✅ What's Working:
- QwenPaw API: `http://127.0.0.1:3004` → 351 indexed papers
- VPS Nginx: `https://rag.orebit.id/health` → 200 OK
- SSH Network: QwenPaw → VPS port 22 → SUCCESS (confirmed tested)

### ❌ The Problem:
```
QwenPaw container has NO SSH client installed
Cannot create SSH tunnels from QwenPaw to VPS
```

---

## 🔥 FINAL SOLUTION: Expose QwenPaw Port 3004

### Option 1: Infrastructure Port Forward (RECOMMENDED)

Jika akses ke QwenPaw infrastructure/dashboard:

**Setup port forward:**
```
Public IP: 103.139.244.177:3004 → QwenPaw:127.0.0.1:3004
```

**Update Nginx di VPS:**
```bash
# Di VPS:
sudo sed -i 's|proxy_pass http://localhost:3004;|proxy_pass http://103.139.244.177:3004;|' /etc/nginx/sites-enabled/rag.orebit.id
sudo systemctl restart nginx
```

**Test:**
```bash
curl https://rag.orebit.id/api/rag/health
# Should show: indexed_papers: 351 ✅
```

---

### Option 2: Ngrok Tunnel (Alternative)

**Di QwenPaw:**
```bash
# Install ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list
apt-get update && apt-get install ngrok

# Start tunnel
ngrok http 3004

# Copy HTTPS URL yang muncul, misal: https://abc123.ngrok-free.app
```

**Update Nginx di VPS:**
```bash
# Di VPS:
NGROK_URL="https://abc123.ngrok-free.app"  # Ganti dengan URL dari ngrok
sudo sed -i "s|proxy_pass http://localhost:3004;|proxy_pass $NGROK_URL;|" /etc/nginx/sites-enabled/rag.orebit.id
sudo systemctl restart nginx

# Test
curl https://rag.orebit.id/api/rag/health
```

---

### Option 3: VPN/Network Bridge

Jika VPS dan QwenPaw di network yang sama:
- Setup VPN connection
- Route traffic via private IP

---

## 🎯 RECOMMENDATION: Option 1 (Infrastructure Port Forward)

**Simplest:**
1. Check QwenPaw hosting dashboard (Docker/K8s/etc)
2. Add port forward: 3004:3004 (public → private)
3. Update VPS Nginx to use public IP

---

## 📋 QUICK COMMAND (If infrastructure accessible):

```bash
# Di VPS:
sudo nano /etc/nginx/sites-enabled/rag.orebit.id
# ubah: proxy_pass http://localhost:3004;
# jadi: proxy_pass http://103.139.244.177:3004;

# Restart
sudo systemctl restart nginx

# Test
curl https://rag.orebit.id/api/rag/health
```

---

## 💡 Alternative: Use QwenPaw Directly

Jika tujuannya hanya untuk testing/query:

```bash
# Di lokasi yang bisa access QwenPaw:
curl http://103.139.244.177:3004/api/rag/health
# atau
curl http://127.0.0.1:3004/api/rag/health
```

---

**Note: Problem is QwenPaw containerized environment with limited networking options. Infrastructure port forward is simplest solution.**
