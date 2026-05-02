#!/bin/bash
# ===========================================================
# DEPLOY FULL RAG SYSTEM TO VPS (ONE COMMAND!)
# ===========================================================
# This script deploys EVERYTHING to VPS:
# 1. Copy UI files from rag-public/dist
# 2. Configure Nginx (serve UI + proxy API)
# 3. Setup SSL (if needed)
# 4. Test entire system
#
# Result: rag.orebit.id shows React UI + API working
#
# NO VERCEL NEEDED!
# ===========================================================

set -euo pipefail

VPS_USER="root"
VPS_HOST="43.157.201.50"
VPS_UI_DIR="/var/www/rag-ui"
VPS_NGINX_CONFIG="/etc/nginx/sites-available/rag-orebit-id"

# Get absolute path to this script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAG_PUBLIC_DIST="$SCRIPT_DIR/rag-public/dist"

# Get current tunnel URL
CLOUDFLARE_TUNNEL_URL="https://reader-measuring-romance-rarely.trycloudflare.com"

echo "🚀 ======================================================="
echo "🚀 DEPLOY FULL RAG SYSTEM TO VPS (Nginx + UI + API)"
echo "🚀 ======================================================="
echo ""
echo "VPS: $VPS_USER@$VPS_HOST"
echo "UI Directory: $VPS_UI_DIR"
echo "Cloudflare Tunnel: $CLOUDFLARE_TUNNEL_URL"
echo ""

# Check if rag-public/dist exists
if [ ! -d "$RAG_PUBLIC_DIST" ]; then
    echo "❌ Error: $RAG_PUBLIC_DIST not found!"
    echo "Make sure rag-public is cloned and built."
    exit 1
fi
echo "✅ Found rag-public/dist"
echo ""

# Check SSH access
echo "🔍 Checking SSH access to VPS..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes $VPS_USER@$VPS_HOST "echo 'SSH OK'" > /dev/null 2>&1; then
    echo "❌ Cannot connect to VPS via SSH"
    echo "Please setup SSH keys to $VPS_USER@$VPS_HOST"
    exit 1
fi
echo "✅ SSH connection OK"
echo ""

# Copy UI files to VPS
echo "📦 Copying UI files to VPS..."
ssh $VPS_USER@$VPS_HOST "mkdir -p $VPS_UI_DIR"
rsync -avz --delete "$RAG_PUBLIC_DIST/" $VPS_USER@$VPS_HOST:$VPS_UI_DIR/
echo "✅ UI files copied"
echo ""

# Generate Nginx configuration
echo "⚙️  Generating Nginx configuration..."
TMP_CONFIG=$(mktemp)

cat > "$TMP_CONFIG" << EOF
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

# Deploy Nginx config to VPS
echo "📤 Deploying Nginx configuration to VPS..."
scp "$TMP_CONFIG" $VPS_USER@$VPS_HOST:/tmp/rag-orebit-id.conf.new

# Apply configuration on VPS
ssh $VPS_USER@$VPS_HOST << 'REMOTESSH'
set -e

CONFIG="/etc/nginx/sites-available/rag-orebit-id"
NEW_CONFIG="/tmp/rag-orebit-id.conf.new"
ENABLED="/etc/nginx/sites-enabled/rag-orebit-id"

echo "💾 Backing up old configuration..."
if [ -f "$CONFIG" ]; then
    cp "$CONFIG" "$CONFIG.backup.$(date +%Y%m%d-%H%M%S)"
fi

echo ""
echo "🧪 Testing Nginx configuration..."
mv "$NEW_CONFIG" "$CONFIG"

if nginx -t; then
    echo "✅ Nginx configuration valid"

    # Enable site
    ln -sf "$CONFIG" "$ENABLED"

    echo ""
    echo "🔄 Reloading Nginx..."
    systemctl reload nginx
    echo "✅ Nginx reloaded"
else
    echo "❌ Nginx configuration test failed!"
    # Restore backup if exists
    BACKUP=$(ls -t "$CONFIG.backup."* | head -1 2>/dev/null)
    if [ -n "$BACKUP" ]; then
        echo "Restoring backup..."
        cp "$BACKUP" "$CONFIG"
    fi
    exit 1
fi
REMOTESSH

rm -f "$TMP_CONFIG"
echo "✅ Nginx configuration deployed"
echo ""

# Test deployment
echo "🧪 Testing deployment..."
sleep 2

# Test UI
echo "Testing UI (https://rag.orebit.id)..."
UI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://rag.orebit.id/)
if [ "$UI_STATUS" = "200" ]; then
    echo "✅ UI accessible (HTTP 200)"
else
    echo "⚠️  UI returned HTTP $UI_STATUS"
fi

# Test API
echo ""
echo "Testing API (https://api.orebit.id/api/rag/health)..."
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://api.orebit.id/api/rag/health)
if [ "$API_STATUS" = "200" ]; then
    echo "✅ API accessible (HTTP 200)"

    API_RESPONSE=$(curl -s https://api.orebit.id/api/rag/health)
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
echo "⚠️  Note: Make sure DNS is configured:"
echo "  rag.orebit.id  →  A  43.157.201.50"
echo "  api.orebit.id  →  A  43.157.201.50"
echo ""
echo "🚀 Deployment complete - NO VERCEL NEEDED!"
