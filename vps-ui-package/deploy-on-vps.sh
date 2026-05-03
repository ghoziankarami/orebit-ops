#!/bin/bash
# Deploy RAG UI on VPS (orebit-sumopod)
# Run this script directly on VPS

VPS_DEPLOY_DIR="/var/www/rag-ui"
LOCAL_DIR="$(pwd)"

echo "=== DEPLOY RAG UI ON VPS ==="
echo ""

# Check if running on VPS
if [ "$(hostname)" != "orebit-sumopod" ]; then
    echo "ERROR: This script must be run from VPS (orebit-sumopod)"
    echo ""
    echo "To deploy from QwenPaw:"
    echo "1. scp -r /app/working/workspaces/default/orebit-ops/vps-ui-package/* root@43.157.201.50:/tmp/rag-ui-update/"
    echo "2. ssh root@43.157.201.50"
    echo "3. cd /tmp/rag-ui-update"
    echo "4. bash deploy-on-vps.sh"
    exit 1
fi

# Stop Nginx
echo "Step 1: Stopping Nginx..."
sudo systemctl stop nginx || true
echo "  Nginx stopped"
echo ""

# Backup current UI
echo "Step 2: Backing up current UI..."
BACKUP_DIR="${VPS_DEPLOY_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
sudo mv "${VPS_DEPLOY_DIR}" "${BACKUP_DIR}" 2>/dev/null || echo "  No existing UI to backup"
echo "  Backup: ${BACKUP_DIR}"
echo ""

# Deploy new UI
echo "Step 3: Deploying new UI files..."
sudo mkdir -p "${VPS_DEPLOY_DIR}"
sudo cp -r "${LOCAL_DIR}"/* "${VPS_DEPLOY_DIR}/"
echo "  Files copied"
echo ""

# Set permissions
echo "Step 4: Setting permissions..."
sudo chown -R www-data:www-data "${VPS_DEPLOY_DIR}"
sudo chmod -R 755 "${VPS_DEPLOY_DIR}"
echo "  Permissions set: www-data:www-data"
echo ""

# Start Nginx
echo "Step 5: Starting Nginx..."
sudo systemctl start nginx
sudo systemctl status nginx --no-pager | grep -A2 "Active"
echo ""

# Verify
echo "Step 6: Verifying deployment..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://rag.orebit.id/ || echo "000")
echo "  UI Response: HTTP ${HTTP_CODE}"

API_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://api.orebit.id/api/rag/health || echo "000")
echo "  API Response: HTTP ${API_CODE}"

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo ""
echo "Deployment Info:"
cat "${VPS_DEPLOY_DIR}/VERSION.txt" 2>/dev/null || echo "Version file not found"
echo ""
echo "Verification:"
echo "  UI: https://rag.orebit.id/"
echo "  API: https://api.orebit.id/api/rag/health"
echo ""
echo "Rollback (if needed):"
echo "  sudo systemctl stop nginx"
echo "  sudo rm -rf ${VPS_DEPLOY_DIR}"
echo "  sudo mv ${BACKUP_DIR} ${VPS_DEPLOY_DIR}"
echo "  sudo systemctl start nginx"
