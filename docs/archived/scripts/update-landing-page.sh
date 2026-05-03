#!/bin/bash
# ===========================================================
# UPDATE LANDING PAGE TO V2 (Static Values + Link to Live API)
# ===========================================================

set -euo pipefail

echo "Updating landing page to V2 (static values with live API link)..."
echo ""

# Check if running on VPS
if [ ! -f "/etc/nginx/sites-enabled/rag-orebit-id" ]; then
    echo "❌ Error: Nginx config not found. Are you on the VPS?"
    exit 1
fi

echo "✅ Detected VPS environment"
echo ""

# Update landing page V2
echo "📄 Updating landing page to V2..."

# Read new landing page content from repository
NEW_LANDING_PAGE="/app/working/workspaces/default/orebit-ops/rag-orebit-id-index-V2.html"
DEST_LANDING_PAGE="/var/www/rag.orebit.id/index.html"

# Copy new landing page
sudo cp "$NEW_LANDING_PAGE" "$DEST_LANDING_PAGE"

echo "✅ Landing page updated to V2"
echo ""

# Set proper permissions
echo "🔐 Setting file permissions..."
sudo chown -R www-data:www-data /var/www/rag.orebit.id
sudo chmod -R 755 /var/www/rag.orebit.id
echo ""

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration test failed!"
    exit 1
fi
echo ""

# Reload Nginx (no restart needed, just reload)
echo "🔄 Reloading Nginx..."
sudo systemctl reload nginx
echo ""

# Verify Nginx status
if sudo systemctl is-active nginx > /dev/null; then
    echo "✅ Nginx is running"
else
    echo "❌ Nginx failed to start!"
    exit 1
fi
echo ""

# Test landing page
echo "🧪 Testing landing page..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://rag.orebit.id/)
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Landing page accessible (HTTP 200)"
else
    echo "⚠️  Landing page returned HTTP $HTTP_STATUS"
fi
echo ""

# Test API
echo "🧪 Testing API endpoint..."
API_STATUS=$(curl -s https://rag.orebit.id/api/rag/health | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', 'ERROR'))" 2>/dev/null || echo "ERROR")
if [ "$API_STATUS" = "healthy" ]; then
    echo "✅ API endpoint working (status: healthy)"
else
    echo "⚠️  API endpoint returned: $API_STATUS"
fi
echo ""

echo "🎉 Update complete!"
echo ""
echo "Changes made:"
echo "  • Updated landing page to V2 (static values)"
echo "  • Stats now show: 351 papers, 343 summaries, 93 collections"
echo "  • Added clickable link to live health check API"
echo "  • Removed JavaScript dependency (more reliable)"
echo ""
echo "Access points:"
echo "  • Landing page: https://rag.orebit.id"
echo "  • Health check: https://rag.orebit.id/api/rag/health"
echo ""
echo "Next:"
echo "  1. Open https://rag.orebit.id in browser"
echo "  2. Verify stats display correctly (351, 343, 93)"
echo "  3. Click link to get live statistics"
echo ""
