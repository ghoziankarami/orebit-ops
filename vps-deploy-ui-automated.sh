#!/bin/bash
# Deploy RAG Public UI to VPS (Automated)
# Requires SSH keys configured between QwenPaw and VPS

set -euo pipefail

# Configuration
REPO_ROOT="/app/working/workspaces/default/orebit-ops"
VPS_HOST="root@43.157.201.50"
VPS_DEPLOY_DIR="/var/www/rag-ui"
PACKAGE_DIR="${REPO_ROOT}/vps-ui-package"

echo "=== AUTOMATED RAG UI DEPLOYMENT TO VPS ==="
echo ""

# Check if package exists
if [ ! -d "$PACKAGE_DIR" ]; then
    echo "❌ ERROR: UI package not found"
    echo "Run this first: bash vps-prepare-ui-update.sh"
    exit 1
fi

# Test SSH connection
echo "Testing SSH connection to VPS..."
if ! ssh -o ConnectTimeout=5 "${VPS_HOST}" "echo 'SSH OK'" 2>/dev/null; then
    echo "❌ ERROR: Cannot connect to VPS via SSH"
    echo ""
    echo "Manual deployment required:"
    echo "1. Prepare package: bash vps-prepare-ui-update.sh"
    echo "2. Transfer files: scp -r vps-ui-package/* ${VPS_HOST}:${VPS_DEPLOY_DIR}/"
    echo "3. Restart Nginx: ssh ${VPS_HOST} 'sudo systemctl restart nginx'"
    exit 1
fi
echo "✅ SSH connection successful"
echo ""

# Stop Nginx on VPS
echo "Stopping Nginx on VPS..."
ssh "${VPS_HOST}" "sudo systemctl stop nginx" || true
echo "✅ Nginx stopped"
echo ""

# Backup current UI on VPS
echo "Backing up current UI on VPS..."
BACKUP_DIR="${VPS_DEPLOY_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
ssh "${VPS_HOST}" "sudo mv ${VPS_DEPLOY_DIR} ${BACKUP_DIR} 2>/dev/null || true"
echo "✅ Backup created: ${BACKUP_DIR}"
echo ""

# Transfer UI files
echo "Transferring UI files to VPS..."
rsync -avz --delete "${PACKAGE_DIR}/" "${VPS_HOST}:${VPS_DEPLOY_DIR}/"
echo "✅ Files transferred"
echo ""

# Set permissions on VPS
echo "Setting permissions on VPS..."
ssh "${VPS_HOST}" "sudo chown -R www-data:www-data ${VPS_DEPLOY_DIR} && sudo chmod -R 755 ${VPS_DEPLOY_DIR}"
echo "✅ Permissions set"
echo ""

# Start Nginx on VPS
echo "Starting Nginx on VPS..."
ssh "${VPS_HOST}" "sudo systemctl start nginx"
echo "✅ Nginx started"
echo ""

# Verify deployment
echo "Verifying deployment..."
ssh "${VPS_HOST}" "sudo systemctl status nginx --no-pager" | grep -E "Active|running"
echo ""

# Test UI
echo "Testing UI..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://rag.orebit.id/ || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ UI responding: HTTP ${HTTP_CODE}"
else
    echo "⚠️  UI not responding: HTTP ${HTTP_CODE}"
fi

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo ""
echo "Deployment info:"
ssh "${VPS_HOST}" "cat ${VPS_DEPLOY_DIR}/VERSION.txt 2>/dev/null || echo 'Version file not found'"
echo ""
echo "Verification:"
echo "  UI: https://rag.orebit.id/"
echo "  API: https://api.orebit.id/api/rag/health"
echo ""
echo "Rollback available:"
echo "  ssh ${VPS_HOST} 'sudo systemctl stop nginx'"
echo "  ssh ${VPS_HOST} 'sudo rm -rf ${VPS_DEPLOY_DIR}'"
echo "  ssh ${VPS_HOST} 'sudo mv ${BACKUP_DIR} ${VPS_DEPLOY_DIR}'"
echo "  ssh ${VPS_HOST} 'sudo systemctl start nginx'"
