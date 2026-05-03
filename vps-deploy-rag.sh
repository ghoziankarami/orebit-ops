#!/bin/bash
# ===========================================================
# DEPLOY FULL RAG SYSTEM TO VPS - VPS-SIDE SCRIPT
# ===========================================================
# This script runs on VPS and pulls everything from GitHub
#
# To use:
# 1. SSH into VPS: ssh root@43.157.201.50
# 2. Clone repo: git clone https://github.com/ghoziankarami/orebit-ops.git /root/orebit-ops
# 3. Run this script: bash /root/orebit-ops/deploy-full-rag-to-vps.sh
#
# NO VERCEL NEEDED!
# ===========================================================

set -euo pipefail

VPS_UI_DIR="/var/www/rag-ui"
CLOUDFLARE_TUNNEL_URL="https://reader-measuring-romance-rarely.trycloudflare.com"

echo "🚀 ======================================================="
echo "🚀 DEPLOY FULL RAG SYSTEM TO VPS (VPS-Side Script)"
echo "🚀 ======================================================="
echo ""

# Check if we're in the right directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "")"

if [ ! -d "$SCRIPT_DIR/rag-public/dist" ]; then
    echo "❌ Error: rag-public/dist not found!"
    echo "Need to pull from GitHub first..."
    echo ""
    echo "Run: git pull origin main"
    exit 1
fi

echo "✅ Found rag-public/dist"
echo ""

# Copy UI files to VPS
echo "📦 Copying UI files to /var/www/rag-ui..."
mkdir -p "$VPS_UI_DIR"
cp -r "$SCRIPT_DIR/rag-public/dist/"* "$VPS_UI_DIR/"
chmod -R 755 "$VPS_UI_DIR"
echo "✅ UI files copied"
echo ""

# Generate Nginx configuration
echo "⚙️  Generating Nginx configuration..."
NGINX_CONFIG="/etc/nginx/sites-available/rag-orebit-id"

cat > "$NGINX_CONFIG" << EOF
# RAG.OREBIT.ID - Full Stack Deployment
# Serves React UI and proxies API to QwenPaw

server {
    listen 80;
    listen [::]:80;
    server_name rag.orebit.id api.orebit.id;

    # Redirect HTTP to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name rag.orebit.id api.orebit.id;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/rag.orebit.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rag.orebit.id/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;

    # Health check
    location /health {
        return 200 "OK";
        add_header Content-Type text/plain;
    }

    # React UI (rag.orebit.id)
    location / {
        root $VPS_UI_DIR;
        try_files \$uri \$uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        expires 0;
    }

    # API Proxy to QwenPaw (rag.orebit.id/api/rag/* or api.orebit.id/api/rag/*)
    location /api/rag/ {
        proxy_pass $CLOUDFLARE_TUNNEL_URL;
        proxy_http_version 1.1;
        proxy_set_header Host $CLOUDFLARE_TUNNEL_URL;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # CORS headers
        add_header 'Access-Control-Allow-Origin' 'https://rag.orebit.id' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, x-api-key' always;

        # Timeouts for long queries
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 120s;

        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }

    # Static assets (cache for performance)
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)$ {
        root $VPS_UI_DIR;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/rag-orebit-id-access.log;
    error_log /var/log/nginx/rag-orebit-id-error.log;
}
EOF

echo "✅ Nginx configuration generated"
echo ""

# Enable site and test
echo "🔗 Enabling Nginx site..."
ln -sf "$NGINX_CONFIG" "/etc/nginx/sites-enabled/rag-orebit-id"
echo ""

echo "🧪 Testing Nginx configuration..."
if nginx -t; then
    echo "✅ Nginx configuration valid"
else
    echo "❌ Nginx configuration test failed!"
    exit 1
fi
echo ""

# Obtain SSL certificate if not exists
if [ ! -f "/etc/letsencrypt/live/rag.orebit.id/fullchain.pem" ]; then
    echo "🔒 Obtaining SSL certificate..."
    certbot certonly --nginx -d rag.orebit.id -d api.orebit.id \
        --non-interactive --agree-tos --email admin@orebit.id || {
        echo "⚠️  SSL certificate failed. Trying with test-cert..."
        certbot certonly --nginx -d rag.orebit.id -d api.orebit.id \
            --test-cert --non-interactive --agree-tos --email admin@orebit.id
    }
    echo "✅ SSL certificate obtained"
else
    echo "✅ SSL certificate already exists"
fi
echo ""

# Reload Nginx
echo "🔄 Reloading Nginx..."
systemctl reload nginx
echo "✅ Nginx reloaded"
echo ""

# Test deployment
echo "🧪 Testing deployment..."
sleep 2

# Test UI
echo "Testing UI (http://localhost)..."
UI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "000")
if [ "$UI_STATUS" = "200" ]; then
    echo "✅ UI accessible (HTTP 200)"
else
    echo "⚠️  UI returned HTTP $UI_STATUS"
fi

# Test API
echo ""
echo "Testing API ($CLOUDFLARE_TUNNEL_URL/api/rag/health)..."
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CLOUDFLARE_TUNNEL_URL/api/rag/health" || echo "000")
if [ "$API_STATUS" = "200" ]; then
    echo "✅ API accessible (HTTP 200)"

    API_RESPONSE=$(curl -s "$CLOUDFLARE_TUNNEL_URL/api/rag/health")
    PAPERS=$(echo "$API_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('corpus', {}).get('indexed_papers', '?'))" 2>/dev/null || echo "?")

    if [ "$PAPERS" = "351" ]; then
        echo "✅ API verified: 351 indexed papers"
    else
        echo "⚠️  Corpus count: $PAPERS (expected 351)"
    fi
else
    echo "⚠️  API returned HTTP $API_STATUS"
fi

echo ""
echo "🎉 ======================================================="
echo "🎉 FULL RAG SYSTEM DEPLOYED TO VPS!"
echo "🎉 ======================================================="
echo ""
echo "🌐 Access Points:"
echo "  • UI:      https://rag.orebit.id"
echo "  • API:     https://api.orebit.id/api/rag/*"
echo "  • Health:  https://api.orebit.id/api/rag/health"
echo ""
echo "✨ Features Available:"
echo "  • React UI (Chat, Browse, Library)"
echo "  • Search/Query RAG system"
echo "  • Source citations with confidence scores"
echo "  • Paper library browser (351 papers)"
echo ""
echo "🔧 Architecture:"
echo "  • VPS: Nginx + React UI"
echo "  • API: Proxy to QwenPaw via Cloudflare tunnel"
echo "  • Backend: QwenPaw (ChromaDB + RAG logic)"
echo ""
echo "📋 Test Commands:"
echo "  # Test UI"
echo "  open https://rag.orebit.id"
echo ""
echo "  # Test API Health"
echo "  curl https://api.orebit.id/api/rag/health"
echo ""
echo "  # Test Statistics (with API key)"
echo "  curl -H 'x-api-key: orebit-rag-api-key-2026-03-26-temp' \\"
echo "    https://api.orebit.id/api/rag/stats"
echo ""
echo "⚠️  IMPORTANT: Make sure DNS is configured:"
echo "  rag.orebit.id  →  A  43.157.201.50"
echo "  api.orebit.id  →  A  43.157.201.50"
echo ""
echo "🚀 Deployment complete - NO VERCEL NEEDED!"
