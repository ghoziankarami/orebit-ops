#!/bin/bash
# ===========================================================
# VPS DEPLOYMENT: Configure api.orebit.id for RAG API
# ===========================================================

set -euo pipefail

echo "🚀 VPS Deployment: Configure api.orebit.id for RAG API"
echo "======================================================="
echo ""

# Step 1: Install dependencies
echo "📦 Step 1: Installing dependencies..."
apt update && apt install -y nginx certbot python3-certbot-nginx
echo "✅ Dependencies installed"
echo ""

# Step 2: Create Nginx configuration for api.orebit.id
echo "⚙️  Step 2: Configuring Nginx for api.orebit.id..."
cat > /etc/nginx/sites-available/api-orebit-id << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name api.orebit.id;

    # Redirect HTTP to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.orebit.id;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/api.orebit.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.orebit.id/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;

    # Proxy to QwenPaw via Cloudflare tunnel
    location /api/rag/ {
        proxy_pass https://reader-measuring-romance-rarely.trycloudflare.com;
        proxy_http_version 1.1;
        proxy_set_header Host reader-measuring-romance-rarely.trycloudflare.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts for long queries
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 120s;

        # CORS headers
        add_header 'Access-Control-Allow-Origin' 'https://rag.orebit.id' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, x-api-key' always;

        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/api-orebit-id-access.log;
    error_log /var/log/nginx/api-orebit-id-error.log;
}
EOF

echo "✅ Nginx configuration created"
echo ""

# Step 3: Enable site and test
echo "🔗 Step 3: Enabling Nginx site..."
ln -sf /etc/nginx/sites-available/api-orebit-id /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
echo "✅ Nginx configuration valid"
echo ""

# Step 4: Obtain SSL certificate
echo "🔒 Step 4: Obtaining SSL certificate..."
# Check if email needs to be provided
EMAIL="${RAG_ADMIN_EMAIL:-admin@orebit.id}"

certbot certonly --nginx -d api.orebit.id --non-interactive --agree-tos --email "$EMAIL" || {
    echo "⚠️  SSL certificate request failed. Trying with --test-cert..."
    certbot certonly --nginx -d api.orebit.id --test-cert --non-interactive --agree-tos --email "$EMAIL"
}
echo "✅ SSL certificate obtained"
echo ""

# Step 5: Restart Nginx
echo "🔄 Step 5: Restarting Nginx..."
systemctl restart nginx
systemctl enable nginx
echo "✅ Nginx restarted and enabled"
echo ""

# Step 6: Test API
echo "🧪 Step 6: Testing API..."
sleep 2

echo "Testing health endpoint..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://api.orebit.id/api/rag/health)

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Health endpoint accessible (HTTP 200)"

    API_RESPONSE=$(curl -s https://api.orebit.id/api/rag/health)
    PAPERS=$(echo "$API_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('corpus', {}).get('indexed_papers', '?'))" 2>/dev/null || echo "?")

    if [ "$PAPERS" = "351" ]; then
        echo "✅ API verified: 351 indexed papers"
    else
        echo "⚠️  Corpus count: $PAPERS (expected 351)"
    fi
else
    echo "⚠️  Health endpoint returned HTTP $HTTP_STATUS"
fi

echo ""
echo "Testing statistics endpoint..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H 'x-api-key: orebit-rag-api-key-2026-03-26-temp' https://api.orebit.id/api/rag/stats)

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Stats endpoint accessible (HTTP 200)"
else
    echo "⚠️  Stats endpoint returned HTTP $HTTP_STATUS"
fi

echo ""
echo "🎉 VPS Deployment Complete!"
echo "================================"
echo ""
echo "Available API endpoints:"
echo "  • GET  /api/rag/health - Health check (no auth)"
echo "  • GET  /api/rag/stats - Statistics (requires API key)"
echo "  • POST /api/rag/answer - Query RAG (requires API key)"
echo "  • GET  /api/rag/browse - Browse papers (requires API key)"
echo ""
echo "API base URL: https://api.orebit.id/api/rag"
echo "API key: orebit-rag-api-key-2026-03-26-temp"
echo ""
echo "Test commands:"
echo "  curl https://api.orebit.id/api/rag/health"
echo "  curl -H 'x-api-key: orebit-rag-api-key-2026-03-26-temp' https://api.orebit.id/api/rag/stats"
echo ""
echo "Nginx logs:"
echo "  Access: tail -f /var/log/nginx/api-orebit-id-access.log"
echo "  Error:  tail -f /var/log/nginx/api-orebit-id-error.log"
echo ""
