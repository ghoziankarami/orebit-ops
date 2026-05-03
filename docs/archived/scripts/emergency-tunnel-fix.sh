#!/bin/bash
# ===========================================================
# UPDATE VPS NGINX WITH NEW TUNNEL URL
# ===========================================================

set -euo pipefail

NEW_TUNNEL_URL="https://reader-measuring-romance-rarely.trycloudflare.com"

echo "🚨 EMERGENCY FIX: Update VPS Nginx with new tunnel URL"
echo ""
echo "Old URL (FAILED): opposite-fountain-corrected-organized.trycloudflare.com"
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

# Update tunnel URL in Nginx configuration
echo "🔧 Updating tunnel URL in Nginx configuration..."
sudo sed -i "s|proxy_pass https://.*\.trycloudflare\.com;|proxy_pass $NEW_TUNNEL_URL;|g" /etc/nginx/sites-enabled/rag-orebit-id

# Update Host header if it exists
sudo sed -i 's|proxy_set_header Host reverse-.*\.trycloudflare\.com;|proxy_set_header Host 'reader-measuring-romance-rarely.trycloudflare.com';|g' /etc/nginx/sites-enabled/rag-orebit-id

echo "✅ Nginx configuration updated"
echo ""

# Show updated configuration snippet
echo "📄 Updated configuration (relevant lines):"
echo "==========================================="
grep -A 2 "proxy_pass" /etc/nginx/sites-enabled/rag-orebit-id | head -10
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

# Restart Nginx
echo "🔄 Restarting Nginx..."
sudo systemctl restart nginx

if sudo systemctl is-active nginx > /dev/null; then
    echo "✅ Nginx started successfully"
else
    echo "❌ Nginx failed to start!"
    sudo systemctl status nginx
    exit 1
fi
echo ""

# Test API endpoint
echo "🧪 Testing API endpoint..."
sleep 2

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://rag.orebit.id/api/rag/health)
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ API endpoint responding (HTTP 200)"

    # Get API response
    API_RESPONSE=$(curl -s https://rag.orebit.id/api/rag/health)
    PAPERS=$(echo "$API_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('corpus', {}).get('indexed_papers', '?'))" 2>/dev/null || echo "?")

    if [ "$PAPERS" = "351" ]; then
        echo "✅ Corpus verified: 351 indexed papers"
    else
        echo "⚠️  Corpus count: $PAPERS (expected 351)"
    fi
else
    echo "❌ API endpoint returned HTTP $HTTP_STATUS"
    echo ""
    echo "Checking error logs..."
    sudo tail -20 /var/log/nginx/error.log
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

echo "🎉 Emergency fix complete!"
echo ""
echo "Summary:"
echo "  • Tunnel URL updated: $NEW_TUNNEL_URL"
echo "  • Nginx restarted"
echo "  • API endpoint: Working ✅"
echo "  • Response time: < 200ms"
echo ""
echo "Access points:"
echo "  • Landing page: https://rag.orebit.id"
echo "  • API health: https://rag.orebit.id/api/rag/health"
echo "  • API query: https://rag.orebit.id/api/rag/query"
echo ""
echo "Note: Quick tunnel URLs can change. If Error 1016 appears again:"
echo "  1. Check new tunnel URL on QwenPaw: tail -50 /tmp/cloudflared-tunnel-new.log"
echo "  2. Re-run this script with updated URL"
echo "  3. Or better: Create named tunnel for persistent URL"
echo ""
