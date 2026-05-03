# COPY-PASTE PROMPT FOR VPS LLM
# Copy this entire text and paste to your LLM on VPS (orebit-sumopod)

---

# DEPLOY RAG UI UPDATE TO VPS (orebit-sumopod)

## OBJECTIVE
Deploy latest RAG Public UI update to VPS (orebit-sumopod, 43.157.201.50) with trust metrics and improved UX.

## CONTEXT
- Current UI: Old version (unknown)
- New UI: Commit 8135054 (Apr 8, 2026)
- Build date: May 2, 2026
- Features: Trust metrics, paper summaries, improved readability

## FILES TO DEPLOY
Package location: QwenPaw → `/app/working/workspaces/default/orebit-ops/vps-ui-package/`

Package contains:
- index.html - UI entry
- assets/ - JS/CSS files
- VERSION.txt - Version info
- deploy-on-vps.sh - Deployment script

## INSTRUCTIONS FOR VPS LLM

### Step 1: Create Deployment Directory
```bash
mkdir -p /tmp/rag-ui-update
cd /tmp/rag-ui-update
```

### Step 2: Create FILES (Copy content below)

#### File: index.html
```html
<!doctype html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>RAG Public</title><link rel="stylesheet" href="./assets/index-DRgD76xh.css"></head><body><div id="app"></div><script src="./assets/index-Cp0RD5nF.js"></script></body></html>
```

#### File: assets/index-Cp0RD5nF.js
(Need to get the actual content from vps-ui-package/assets/index-Cp0RD5nF.js)

#### File: assets/index-DRgD76xh.css
(Need to get the actual content from vps-ui-package/assets/index-DRgD76xh.css)

### Step 3: Create Deployment Script
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
echo "Stopping Nginx..."
sudo systemctl stop nginx || true
BACKUP_DIR="${VPS_DEPLOY_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
sudo mv "${VPS_DEPLOY_DIR}" "${BACKUP_DIR}" 2>/dev/null || echo "No existing UI"
echo "Backup: ${BACKUP_DIR}"
echo "Deploying new UI..."
sudo mkdir -p "${VPS_DEPLOY_DIR}"
sudo cp -r "${LOCAL_DIR}"/* "${VPS_DEPLOY_DIR}/"
echo "Setting permissions..."
sudo chown -R www-data:www-data "${VPS_DEPLOY_DIR}"
sudo chmod -R 755 "${VPS_DEPLOY_DIR}"
echo "Starting Nginx..."
sudo systemctl start nginx
sudo systemctl status nginx --no-pager | grep -A2 "Active"
echo "Verifying..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://rag.orebit.id/ || echo "000")
echo "UI Response: HTTP ${HTTP_CODE}"
echo "=== DEPLOYMENT COMPLETE ==="
echo "Rollback: sudo systemctl stop nginx; sudo mv ${BACKUP_DIR} ${VPS_DEPLOY_DIR}; sudo systemctl start nginx"
EOF
chmod +x deploy-on-vps.sh
```

### Step 4: Execute Deployment
```bash
bash deploy-on-vps.sh
```

### Step 5: Verify
```bash
curl -I https://rag.orebit.id/
curl -s https://api.orebit.id/api/rag/health
```

## FILES NEEDED (GET THESE FROM QwenPaw)

From QwenPaw, copy these files to VPS:
- index.html → /tmp/rag-ui-update/
- assets/index-Cp0RD5nF.js → /tmp/rag-ui-update/assets/
- assets/index-DRgD76xh.css → /tmp/rag-ui-update/assets/

Copy methods:
```bash
# From QwenPaw
scp -r /app/working/workspaces/default/orebit-ops/vps-ui-package/* \
  root@43.157.201.50:/tmp/rag-ui-update/
```

Or manually:
```bash
# Read each file content from QwenPaw
cat /app/working/workspaces/default/orebit-ops/vps-ui-package/index.html
cat /app/working/workspaces/default/orebit-ops/vps-ui-package/assets/index-Cp0RD5nF.js
cat /app/working/workspaces/default/orebit-ops/vps-ui-package/assets/index-DRgD76xh.css
```

## ROLLBACK IF ERROR
```bash
sudo systemctl stop nginx
sudo rm -rf /var/www/rag-ui
sudo mv /var/www/rag-ui.backup.YYYYMMDD-HHMMSS /var/www/rag-ui
sudo systemctl start nginx
```

## SUCCESS CRITERIA
- [ ] Nginx running (sudo systemctl status nginx)
- [ ] UI responds HTTP 200 (curl -I https://rag.orebit.id/)
- [ ] API responds HTTP 200 (curl -I https://api.orebit.id/api/rag/health)
- [ ] No errors in Nginx logs

## ESTIMATED TIME
- 2-5 minutes completion

---
