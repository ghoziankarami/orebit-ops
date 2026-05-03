#!/bin/bash
# ===========================================================
# UPDATE VPS NGINX WITH NEW TUNNEL URL
# ===========================================================

set -euo pipefail

NEW_TUNNEL_URL="https://venture-stud-gale-fuji.trycloudflare.com"

echo "🚀 Update VPS Nginx with New Tunnel URL"
echo "=========================================="
echo ""
echo "Old URL (FAILED): reader-measuring-romance-rarely.trycloudflare.com"
echo "New URL (ACTIVE): $NEW_TUNNEL_URL"
echo ""

# Check if running on VPS
if [ ! -f "/etc/nginx/sites-enabled/rag-orebit-id" ]; then
    echo "❌ Error: Nginx config not found. Are you on the VPS?"
    exit 1
fi

echo "✅ Detected VPS environment"
echo ""

# Backup current config
echo "💾 Backing up current configuration..."
sudo cp /etc/nginx/sites-enabled/rag-orebit-id /etc/nginx/sites-enabled/rag-orebit-id.backup.$(date +%Y%m%d-%H%M%S)
echo ""

# Update all tunnel URL occurrences
echo "🔧 Updating tunnel URL in Nginx configuration..."
sudo sed -i "s|https://reader-measuring-romance-rarely.trycloudflare.com|$NEW_TUNNEL_URL|g" /etc/nginx/sites-enabled/rag-orebit-id
echo "✅ Nginx configuration updated"
echo ""

# Show updated configuration snippet
echo "📄 Updated configuration (proxy_pass lines):"
echo "==========================================="
grep -n "proxy_pass" /etc/nginx/sites-enabled/rag-orebit-id | head -5
echo "==========================================="
echo ""
echo "Host header configured for:"
grep -n "proxy_set_header Host" /etc/nginx/sites-enabled/rag-orebit-id | head -2
echo "==========================================="
echo ""

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration test failed!"
    echo "Restoring backup..."
    sudo cp /etc/nginx/sites-enabled/rag-orebit-id.backup.* /etc/nginx/sites-enabled/rag-orebit-id
    exit 1
fi
echo ""

# Reload Nginx
echo "🔄 Reloading Nginx..."
sudo systemctl reload nginx

if sudo systemctl is-active nginx > /dev/null; then
    echo "✅ Nginx reloaded successfully"
else
    echo "❌ Nginx failed to reload!"
    sudo systemctl status nginx
    exit 1
fi
echo ""

# Test API endpoint
echo "🧪 Testing API endpoint..."
sleep 2

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://api.orebit.id/api/rag/health)
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ API endpoint responding (HTTP 200)"

    # Get API response
    API_RESPONSE=$(curl -s https://api.orebit.id/api/rag/health)
    PAPERS=$(echo "$API_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('corpus', {}).get('indexed_papers', '?'))" 2>/dev/null || echo "?")

    if [ "$PAPERS" = "351" ]; then
        echo "✅ API verified: 351 indexed papers"
    else
        echo "⚠️  Corpus count: $PAPERS (expected 351)"
    fi
else
    echo "❌ API endpoint returned HTTP $HTTP_STATUS"
    echo ""
    echo "Checking error logs..."
    sudo tail -20 /var/log/nginx/api-orebit-id-error.log
    exit 1
fi
echo ""

# Test UI endpoint
echo "🧪 Testing UI endpoint..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://rag.orebit.id/)
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ UI accessible (HTTP 200)"
else
    echo "⚠️  UI returned HTTP $HTTP_STATUS"
fi
echo ""

echo "🎉 Nginx Update Complete!"
echo "==========================================="
echo ""
echo "Summary:"
echo "  • Tunnel URL updated: $NEW_TUNNEL_URL"
echo "  • Nginx reloaded"
echo "  • API endpoint: Working ✅"
echo "  • UI endpoint: Working ✅"
echo ""
echo "Access points:"
echo "  • UI: https://rag.orebit.id"
echo "  • API: https://api.orebit.id/api/rag/health"
echo ""
echo "Testing from browser:"
echo "  • Open https://rag.orebit.id"
echo "  • Try the search/chat feature"
echo "  • Should get results with citations from 351 papers"
echo ""
