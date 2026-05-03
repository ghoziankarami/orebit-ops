#!/bin/bash
# Prepare RAG Public UI for VPS deployment
# This script builds and packages UI files for deployment to VPS

set -euo pipefail

# Configuration
REPO_ROOT="/app/working/workspaces/default/orebit-ops"
RAG_PUBLIC_DIR="${REPO_ROOT}/rag-public"
BUILD_DIR="${RAG_PUBLIC_DIR}/dist"
PACKAGE_DIR="${REPO_ROOT}/vps-ui-package"
VERSION_FILE="${PACKAGE_DIR}/VERSION.txt"

echo "=== PREPARING RAG PUBLIC UI FOR VPS DEPLOYMENT ==="
echo ""

# Step 1: Check rag-public directory
echo "Step 1: Checking rag-public repository..."
if [ ! -d "${RAG_PUBLIC_DIR}" ]; then
    echo "❌ ERROR: rag-public directory not found"
    exit 1
fi

cd "${RAG_PUBLIC_DIR}"

# Step 2: Check git status
echo ""
echo "Step 2: Checking git status..."
CURRENT_COMMIT=$(git rev-parse --short HEAD)
CURRENT_DATE=$(git log -1 --format=%cd --date=short)
echo "Current commit: ${CURRENT_COMMIT}"
echo "Commit date: ${CURRENT_DATE}"

# Step 3: Build UI
echo ""
echo "Step 3: Building RAG Public UI..."
if command -v npm &> /dev/null; then
    echo "Building with npm..."
    npm install
    npm run build
elif command -v pnpm &> /dev/null; then
    echo "Building with pnpm..."
    pnpm install
    pnpm build
else
    echo "⚠️  WARNING: No npm/pnpm found, using existing build..."
fi

# Step 4: Check build output
echo ""
echo "Step 4: Checking build output..."
if [ ! -d "${BUILD_DIR}" ]; then
    echo "❌ ERROR: Build directory not found: ${BUILD_DIR}"
    exit 1
fi

BUILD_SIZE=$(du -sh "${BUILD_DIR}" | cut -f1)
echo "Build size: ${BUILD_SIZE}"
echo "Files: $(find "${BUILD_DIR}" -type f | wc -l)"

# Step 5: Create package
echo ""
echo "Step 5: Creating deployment package..."
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"

# Copy build files
cp -r "${BUILD_DIR}"/* "${PACKAGE_DIR}/"

# Create version information
cat > "${VERSION_FILE}" << EOF
RAG Public UI Deployment Package
=================================
Commit: ${CURRENT_COMMIT}
Date: ${CURRENT_DATE}
Built: $(date -Iseconds)
Deployed by: QwenPaw
Host: QwenPaw (Local)
Target: VPS (orebit-sumopod)

Features in this build:
$(cd "${RAG_PUBLIC_DIR}" && git log -1 --pretty="format:%s")

Recent changes:
$(cd "${RAG_PUBLIC_DIR}" && git log -5 --oneline)
EOF

# Create deployment script
cat > "${PACKAGE_DIR}/deploy-to-vps.sh" << 'DEPLOY_SCRIPT'
#!/bin/bash
# Deploy RAG Public UI to VPS
# Run this script from VPS or use scp to transfer files

set -euo pipefail

VPS_HOST="root@43.157.201.50"
VPS_DEPLOY_DIR="/var/www/rag-ui"
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== DEPLOYING RAG PUBLIC UI TO VPS ==="
echo ""

# Option 1: Deploy from VPS (if files are on VPS)
if [ "$(hostname)" = "orebit-sumopod" ]; then
    echo "Deploying from VPS..."
    echo "Stopping Nginx..."
    sudo systemctl stop nginx || true

    echo "Backing up current UI..."
    sudo mv "${VPS_DEPLOY_DIR}" "${VPS_DEPLOY_DIR}.backup.$(date +%Y%m%d-%H%M%S)" || true

    echo "Copying new UI files..."
    sudo cp -r "${LOCAL_DIR}"/* "${VPS_DEPLOY_DIR}/"

    echo "Setting permissions..."
    sudo chown -R www-data:www-data "${VPS_DEPLOY_DIR}"
    sudo chmod -R 755 "${VPS_DEPLOY_DIR}"

    echo "Starting Nginx..."
    sudo systemctl start nginx

    echo "Verifying deployment..."
    sudo systemctl status nginx --no-pager || true

else
    echo "This script must be run from VPS (orebit-sumopod)"
    echo ""
    echo "To deploy from QwenPaw, use:"
    echo "  scp -r ${LOCAL_DIR}/* ${VPS_HOST}:${VPS_DEPLOY_DIR}/"
    echo "  ssh ${VPS_HOST} 'sudo systemctl restart nginx'"
    exit 1
fi

echo ""
echo "✅ Deployment complete!"
echo ""
cat "${VPS_DEPLOY_DIR}/VERSION.txt"
DEPLOY_SCRIPT

chmod +x "${PACKAGE_DIR}/deploy-to-vps.sh"

# Step 6: Create archive
echo ""
echo "Step 6: Creating archive..."
ARCHIVE_NAME="rag-ui-package-${CURRENT_COMMIT}.tar.gz"
tar -czf "${REPO_ROOT}/${ARCHIVE_NAME}" -C "${REPO_ROOT}" "$(basename "${PACKAGE_DIR}")"

# Step 7: Summary
echo ""
echo "=== PREPARATION COMPLETE ==="
echo ""
echo "Package created: ${REPO_ROOT}/${ARCHIVE_NAME}"
echo "Package directory: ${PACKAGE_DIR}"
echo ""
echo "NEXT STEPS:"
echo "1. Review version information:"
cat "${VERSION_FILE}"
echo ""
echo "2. Transfer to VPS:"
echo "   scp ${REPO_ROOT}/${ARCHIVE_NAME} root@43.157.201.50:/tmp/"
echo ""
echo "3. Extract and deploy on VPS:"
echo "   ssh root@43.157.201.50"
echo "   cd /tmp"
echo "   tar -xzf ${ARCHIVE_NAME}"
echo "   cd vps-ui-package"
echo "   bash deploy-to-vps.sh"
echo ""
echo "OR use automated deployment (if SSH keys configured):"
echo "   bash ${REPO_ROOT}/deploy-ui-to-vps-automated.sh"

echo ""
echo "✅ Ready for deployment!"
