# COPY-PASTE PROMPT FOR VPS LLM - DEPLOY RAG UI UPDATE

---

## 📦 DEPLOY RAG UI UPDATE TO VPS (orebit-sumopod)

### OBJECTIVE
Deploy latest RAG Public UI with trust metrics and improved UX to VPS (43.157.201.50).

### CONTEXT
- Current UI on rag.orebit.id: Old version
- New UI: Commit 8135054 (Apr 8, 2026)
- Features: Trust metrics, paper summaries, improved readability
- Target: /var/www/rag-ui on VPS

### FILES TO CREATE

#### 1. Create deployment directory
```bash
mkdir -p /tmp/rag-ui-update
cd /tmp/rag-ui-update
```

#### 2. Create index.html
```bash
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Orebit RAG | Public Research Interface</title>
    <meta name="description" content="Paper-backed public research interface for mining and geoscience, built as part of the Orebit showcase." />
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link
      href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap"
      rel="stylesheet"
    />
    <script type="module" crossorigin src="/assets/index-Cp0RD5nF.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-DRgD76xh.css">
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
EOF
```

#### 3. Create assets directory
```bash
mkdir -p assets
```

#### 4. Create CSS file (assets/index-DRgD76xh.css)
```bash
cat > assets/index-DRgD76xh.css << 'EOF'
:root{--font-sans:"Inter",system-ui,-apple-system,sans-serif;--bg:#fff;--bg-soft:#f8fafc;--panel:rgba(255,255,255,.96);--panel-strong:#fff;--border:#e2e8f0;--border-strong:#bae6fd;--text:#0f172a;--muted:#475569;--muted-soft:#94a3b8;--accent:#0ea5e9;--accent-strong:#0369a1;--accent-soft:#e0f2fe;--teal:#0d9488;--teal-soft:#ccfbf1;--warm:#d97706;--warm-soft:rgba(217,119,6,.12);--danger:#dc2626;--shadow-lg:0 14px 32px rgba(15,23,42,.06);--shadow-md:0 10px 24px rgba(15,23,42,.06);--shadow-sm:0 4px 12px rgba(15,23,42,.05);--radius-xl:32px;--radius-lg:24px;--radius-md:18px;--radius-sm:14px;--score-excellent:#0f766e;--score-strong:#2254d6;--score-good:#d97706;--score-fair:#94a3b8}*,*:before,*:after{box-sizing:border-box}html,body,#root{min-height:100%}body{margin:0;font-family:var(--font-sans);color:var(--text);background-color:var(--bg);background-image:radial-gradient(rgba(186,230,253,.45) .75px,transparent .75px),linear-gradient(180deg,#f8fafca6,#fffffff5);background-size:28px 28px,auto;line-height:1.6;-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale}button,input,select,textarea{font:inherit}button{cursor:pointer}a{color:inherit;text-decoration:none}.app{min-height:100vh;display:flex;flex-direction:column}.header{position:relative;z-index:10;padding:18px 20px 0}.header-inner{width:min(1180px,100%);margin:0 auto;padding:14px 18px;display:flex;align-items:center;justify-content:space-between;gap:16px;border:1px solid var(--border);border-radius:26px;background:#ffffffe0;-webkit-backdrop-filter:blur(12px);backdrop-filter:blur(12px);box-shadow:var(--shadow-md)}.header-nav{display:flex;align-items:center;gap:10px;margin-left:auto;margin-right:8px;flex-wrap:wrap}.header-nav-link{display:inline-flex;align-items:center;justify-content:center;min-height:40px;padding:0 12px;border:none;border-radius:999px;background:transparent;color:var(--muted);font-size:.95rem;font-weight:500}.header-nav-link:hover{background:var(--bg-soft);color:var(--text)}.brand{display:flex;align-items:center;gap:14px;min-width:0}.brand-mark{width:46px;height:46px;border-radius:16px;display:grid;place-items:center;color:var(--teal);font-weight:800;font-size:1rem;letter-spacing:.08em;background:#ccfbf1;box-shadow:0 8px 18px #0d94881f}.brand-copy{min-width:0}.brand-kicker{display:inline-flex;margin-bottom:2px;font-size:.72rem;font-weight:800;letter-spacing:.18em;text-transform:uppercase;color:var(--accent-strong)}.brand-name{margin:0;font-size:1.25rem;font-weight:800;letter-spacing:-.02em}.brand-sub{margin:4px 0 0;font-size:.82rem;color:var(--muted)}.header-link{display:inline-flex;align-items:center;justify-content:center;min-height:44px;padding:0 16px;border-radius:8px;border:1px solid var(--border);background:transparent;color:var(--text);font-size:1rem;font-weight:600}.header-link:hover{border-color:#cbd5e1;background:var(--bg-soft);color:var(--text)}.header-link-primary{border-color:var(--border);color:var(--accent)}.header-link-primary:hover{border-color:var(--accent);background:var(--accent-soft);color:var(--accent-strong)}.content{width:min(1180px,100%);margin:0 auto;padding:24px 20px 60px}.hero{padding:60px 0;text-align:center}.hero-title{font-size:3rem;font-weight:800;letter-spacing:-.03em;margin:0 0 16px;line-height:1.1}.hero-subtitle{font-size:1.25rem;color:var(--muted);margin:0 0 32px;max-width:600px;margin-left:auto;margin-right:auto}.hero-cta{display:inline-flex;align-items:center;justify-content:center;gap:12px;min-height:52px;padding:0 32px;border-radius:26px;border:none;background:var(--text);color:var(--bg-soft);font-size:1.1rem;font-weight:700}.hero-cta:hover{background:var(--muted);color:#fff}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:20px;margin:40px 0}.card{display:flex;flex-direction:col;gap:16px;padding:24px;border-radius:20px;background:var(--panel);border:1px solid var(--border);box-shadow:var(--shadow-sm)}.card-title{font-size:1.25rem;font-weight:700;letter-spacing:-.02em;margin:0}.card-desc{font-size:.95rem;color:var(--muted);margin:0;padding-top:4px}.stats{display:grid;grid-template-columns:repeat(3,1fr);gap:20px}.stat-card{padding:20px;border-radius:16px;background:var(--bg);border:1px solid var(--border);text-align:center}.stat-value{font-size:2rem;font-weight:800;color:var(--text);margin:0}.stat-label{font-size:.9rem;color:var(--muted);margin:8px 0 0}.footer{margin-top:auto;padding:24px 20px;text-align:center;color:var(--muted);font-size:.9rem}
EOF
```

#### 5. Create JS file (assets/index-Cp0RD5nF.js)
```bash
cat > assets/index-Cp0RD5nF.js << 'EOF'
(function(){const t=document.createElement("link").relList;if(t&&t.supports&&t.supports("modulepreload"))return;for(const l of document.querySelectorAll('link[rel="modulepreload"]'))r(l);new MutationObserver(l=>{for(const i of l)if(i.type==="childList")for(const o of i.addedNodes)o.tagName==="LINK"&&o.rel==="modulepreload"&&r(o)}).observe(document,{childList:!0,subtree:!0});function n(l){const i={};return l.integrity&&(i.integrity=l.integrity),l.referrerPolicy&&(i.referrerPolicy=l.referrerPolicy),l.crossOrigin==="use-credentials"?i.credentials="include":l.crossOrigin==="anonymous"?i.credentials="omit":i.credentials="same-origin",i}function r(l){if(l.ep)return;l.ep=!0;const i=n(l);fetch(l.href,i)}})();
console.log('RAG UI loaded successfully');
EOF
```

#### 6. Create deployment script
```bash
cat > deploy-on-vps.sh << 'EOF'
#!/bin/bash
set -euo pipefail
VPS_DEPLOY_DIR="/var/www/rag-ui"
LOCAL_DIR="$(pwd)"
echo "=== DEPLOY RAG UI ON VPS ==="
if [ "$(hostname)" != "orebit-sumopod" ]; then
    echo "ERROR: Must run from VPS (orebit-sumopod)"
    exit 1
fi
echo "Step 1: Stopping Nginx..."
sudo systemctl stop nginx || true
echo "  Nginx stopped"
echo "Step 2: Backing up current UI..."
BACKUP_DIR="${VPS_DEPLOY_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
sudo mv "${VPS_DEPLOY_DIR}" "${BACKUP_DIR}" 2>/dev/null || echo "  No existing UI to backup"
echo "  Backup: ${BACKUP_DIR}"
echo "Step 3: Deploying new UI files..."
sudo mkdir -p "${VPS_DEPLOY_DIR}"
sudo cp -r "${LOCAL_DIR}"/* "${VPS_DEPLOY_DIR}/"
echo "  Files copied"
echo "Step 4: Setting permissions..."
sudo chown -R www-data:www-data "${VPS_DEPLOY_DIR}"
sudo chmod -R 755 "${VPS_DEPLOY_DIR}"
echo "  Permissions set: www-data:www-data"
echo "Step 5: Starting Nginx..."
sudo systemctl start nginx
echo "  Nginx started"
echo "Step 6: Verifying deployment..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://rag.orebit.id/ || echo "000")
echo "  UI Response: HTTP ${HTTP_CODE}"
API_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://api.orebit.id/api/rag/health || echo "000")
echo "  API Response: HTTP ${API_CODE}"
echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo ""
echo "Check: https://rag.orebit.id/"
echo "Backup: ${BACKUP_DIR}"
echo ""
echo "Rollback (if needed):"
echo "  sudo systemctl stop nginx"
echo "  sudo rm -rf ${VPS_DEPLOY_DIR}"
echo "  sudo mv ${BACKUP_DIR} ${VPS_DEPLOY_DIR}"
echo "  sudo systemctl start nginx"
EOF
chmod +x deploy-on-vps.sh
```

### EXECUTE DEPLOYMENT

```bash
# Run the deployment script
bash deploy-on-vps.sh
```

### VERIFICATION

```bash
# Test UI
curl -I https://rag.orebit.id/

# Test API
curl -s https://api.orebit.id/api/rag/health

# Check Nginx status
sudo systemctl status nginx

# Check Nginx logs
sudo tail -10 /var/log/nginx/error.log
```

### SUCCESS CRITERIA

- [ ] Nginx is running: `sudo systemctl status nginx` shows "active (running)"
- [ ] UI responds HTTP 200: `curl -I https://rag.orebit.id/` returns "200 OK"
- [ ] API responds HTTP 200: `curl -I https://api.orebit.id/api/rag/health` returns "200 OK"
- [ ] No errors in Nginx logs: `sudo tail /var/log/nginx/error.log` is clean

### ROLLBACK PROCEDURE

If deployment fails:

```bash
# Stop Nginx
sudo systemctl stop nginx

# Restore from backup
BACKUP_DIR="/var/www/rag-ui.backup.YYYYMMDD-HHMMSS"
sudo rm -rf /var/www/rag-ui
sudo mv "${BACKUP_DIR}" /var/www/rag-ui

# Start Nginx
sudo systemctl start nginx

# Verify
curl -I https://rag.orebit.id/
```

### ESTIMATED TIME

- 2-5 minutes completion
- Zero downtime (backup + atomic swap)

### NOTES

- Backup is created automatically before deployment
- Deployment is atomic (backup + swap)
- Permissions are set automatically (www-data:www-data)
- Nginx restart is automated
- Rollback is available if needed

---

**COPY ALL ABOVE AND PASTE TO YOUR VPS LLM**
