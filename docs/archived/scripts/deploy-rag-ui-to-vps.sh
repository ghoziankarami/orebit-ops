#!/bin/bash
# ===========================================================
# DEPLOY FULL RAG UI TO VPS (Option 2: VPS Nginx)
# ===========================================================

set -euo pipefail

VPS_USER="root"
VPS_HOST="43.157.201.50"
VPS_UI_DIR="/var/www/rag-orebit-ui"
VPS_CONFIG="/etc/nginx/sites-enabled/rag-orebit-id"

echo "🚀 Deploy Full RAG UI to VPS"
echo "================================"
echo ""
echo "VPS: $VPS_USER@$VPS_HOST"
echo "UI Directory: $VPS_UI_DIR"
echo "Nginx Config: $VPS_CONFIG"
echo ""

# Check if running from correct directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAG_PUBLIC_DIR="$SCRIPT_DIR/rag-public"

if [ ! -d "$RAG_PUBLIC_DIR/dist" ]; then
    echo "❌ Error: rag-public/dist not found"
    echo "Are you in the orebit-ops directory?"
    exit 1
fi

echo "✅ Found rag-public/dist folder"
echo ""

# Step 1: Check SSH access
echo "🔍 Step 1: Checking SSH access to VPS..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes $VPS_USER@$VPS_HOST "echo 'SSH connection OK'" > /dev/null 2>&1; then
    echo "✅ SSH connection established"
else
    echo "❌ Cannot connect to VPS via SSH"
    echo "Make sure you have SSH keys set up for $VPS_USER@$VPS_HOST"
    exit 1
fi
echo ""

# Step 2: Create UI directory on VPS
echo "📁 Step 2: Creating UI directory on VPS..."
ssh $VPS_USER@$VPS_HOST "mkdir -p $VPS_UI_DIR"
echo "✅ UI directory created: $VPS_UI_DIR"
echo ""

# Step 3: Copy UI files to VPS
echo "📦 Step 3: Copying UI files to VPS..."
rsync -avz --delete "$RAG_PUBLIC_DIR/dist/" $VPS_USER@$VPS_HOST:$VPS_UI_DIR/
echo "✅ UI files copied successfully"
echo ""

# Step 4: Get current tunnel URL
echo "🔗 Step 4: Getting current Cloudflare tunnel URL..."
TUNNEL_URL=$(curl -s http://127.0.0.1:3004/api/rag/health | jq -r '.tunnel_url // empty' 2>/dev/null || echo "")

if [ -z "$TUNNEL_URL" ]; then
    # Try to get from log file
    TUNNEL_URL=$(tail -50 /tmp/cloudflared-tunnel-new.log 2>/dev/null | grep -oP 'https://[^ ]+\.trycloudflare\.com' | tail -1 || echo "")
fi

if [ -z "$TUNNEL_URL" ]; then
    # Use known URL
    TUNNEL_URL="https://reader-measuring-romance-rarely.trycloudflare.com"
fi

echo "📍 Tunnel URL: $TUNNEL_URL"
echo ""

# Step 5: Generate Nginx configuration
echo "⚙️  Step 5: Generating Nginx configuration..."
TEMP_NGINX=$(mktemp)

cat > "$TEMP_NGINX" << 'EOF'
# RAG UI + API Proxy Configuration
# Serves React UI for rag.orebit.id and proxies API to QwenPaw

server {
    listen 80;
    listen [::]:80;
    server_name rag.orebit.id api.orebit.id;

    # Redirect HTTP to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name rag.orebit.id api.orebit.id;

    # SSL Configuration (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/rag.orebit.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rag.orebit.id/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;

    # Root directory for React UI
    root /var/www/rag-orebit-ui;
    index index.html;

    # React UI SPA routes
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # API proxy to QwenPaw via Cloudflare tunnel
    location /api/rag/ {
        proxy_pass TUNNEL_URL_PLACEHOLDER;
        proxy_http_version 1.1;
        proxy_set_header Host TUNNEL_URL_PLACEHOLDER;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts for long queries
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 120s;

        # Cache API responses
        proxy_cache api_cache;
        proxy_cache_bypass $http_pragma$http_authorization;
        proxy_cache_valid 200 5m;
        proxy_cache_use_stale error timeout updating;
        add_header X-Cache-Status $upstream_cache_status;
    }

    # Static assets caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Logging
    access_log /var/log/nginx/rag-orebit-id-access.log;
    error_log /var/log/nginx/rag-orebit-id-error.log;
}
EOF

# Replace tunnel URL placeholder
sed -i "s|TUNNEL_URL_PLACEHOLDER|$TUNNEL_URL|g" "$TEMP_NGINX"

echo "✅ Nginx configuration generated"
echo ""

# Step 6: Deploy Nginx configuration to VPS
echo "📤 Step 6: Deploying Nginx configuration..."
scp "$TEMP_NGINX" $VPS_USER@$VPS_HOST:/tmp/rag-orebit-id.conf.new

# On VPS: backup old config, test new config, apply
ssh $VPS_USER@$VPS_HOST << 'REMOTESSH'
set -e

CONFIG="/etc/nginx/sites-enabled/rag-orebit-id"
NEW_CONFIG="/tmp/rag-orebit-id.conf.new"
BACKUP_CONFIG="/etc/nginx/sites-enabled/rag-orebit-id.backup.$(date +%Y%m%d-%H%M%S)"

echo "💾 Backing up existing configuration..."
if [ -f "$CONFIG" ]; then
    cp "$CONFIG" "$BACKUP_CONFIG"
    echo "✅ Backup created: $BACKUP_CONFIG"
fi

echo ""
echo "🧪 Testing new configuration..."
mv "$NEW_CONFIG" "$CONFIG"

if nginx -t; then
    echo "✅ Nginx configuration is valid"
    echo ""
    echo "🔄 Reloading Nginx..."
    systemctl reload nginx
    echo "✅ Nginx reloaded successfully"
else
    echo "❌ Nginx configuration test failed!"
    echo "Restoring backup..."
    mv "$BACKUP_CONFIG" "$CONFIG"
    exit 1
fi
REMOTESSH

echo ""
echo "✅ Nginx configuration deployed and reloaded"
rm -f "$TEMP_NGINX"
echo ""

# Step 7: Test UI deployment
echo "🧪 Step 7: Testing UI deployment..."
sleep 2

# Test main page
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://rag.orebit.id/)
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Landing page accessible (HTTP 200)"
else
    echo "⚠️  Landing page returned HTTP $HTTP_STATUS"
fi

# Test API health
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://rag.orebit.id/api/rag/health)
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ API health endpoint accessible (HTTP 200)"

    API_RESPONSE=$(curl -s https://rag.orebit.id/api/rag/health)
    PAPERS=$(echo "$API_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('corpus', {}).get('indexed_papers', '?'))" 2>/dev/null || echo "?")

    if [ "$PAPERS" = "351" ]; then
        echo "✅ API verified: 351 indexed papers"
    else
        echo "⚠️  Corpus count: $PAPERS (expected 351)"
    fi
else
    echo "⚠️  API health endpoint returned HTTP $HTTP_STATUS"
fi

echo ""
echo "🎉 UI Deployment Complete!"
echo "================================"
echo ""
echo "Full RAG UI is now live at: https://rag.orebit.id"
echo ""
echo "Features available:"
echo "  • Natural language chat with RAG"
echo "  • Source citations with confidence scores"
echo "  • Paper library browser (351 papers)"
echo "  • Evidence trail for verification"
echo "  • Statistics dashboard"
echo ""
echo "API Endpoints:"
echo "  • GET /api/rag/health - Health check"
echo "  • GET /api/rag/stats - Statistics"
echo "  • POST /api/rag/answer - Query RAG"
echo "  • GET /api/rag/browse - Browse papers"
echo ""
echo "Tunnel URL: $TUNNEL_URL"
echo ""
echo "If UI shows errors:"
echo "  1. Clear browser cache and reload"
echo "  2. Check browser console for errors"
echo "  3. Verify API: curl https://rag.orebit.id/api/rag/health"
echo "  4. Check Nginx logs: ssh $VPS_USER@$VPS_HOST 'tail -50 /var/log/nginx/rag-orebit-id-error.log'"
echo ""
