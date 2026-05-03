#!/bin/bash
# ===========================================================
# SETUP LANDING PAGE FOR rag.orebit.id (VPS)
# ===========================================================

set -euo pipefail

echo "Setting up landing page for rag.orebit.id..."
echo ""

# Check if running on VPS
if [ ! -f "/etc/nginx/sites-enabled/rag-orebit-id" ]; then
    echo "❌ Error: Nginx config not found. Are you on the VPS?"
    exit 1
fi

echo "✅ Detected VPS environment"
echo ""

# Create web directory
echo "📁 Creating web directory..."
sudo mkdir -p /var/www/rag.orebit.id
echo ""

# Create landing page HTML
echo "📄 Creating landing page..."
sudo tee /var/www/rag.orebit.id/index.html > /dev/null << 'EOFPAGE'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Orebit RAG API Service</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 40px 20px;
            line-height: 1.6;
            color: #2c3e50;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container {
            background: white;
            border-radius: 12px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        h1 {
            color: #2c3e50;
            margin-bottom: 10px;
            font-size: 32px;
        }
        .subtitle {
            color: #7f8c8d;
            font-size: 18px;
            margin-bottom: 30px;
        }
        .status-box {
            background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            font-size: 18px;
            font-weight: 500;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .stat-box {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            border: 2px solid #e9ecef;
        }
        .stat-number {
            font-size: 32px;
            font-weight: bold;
            color: #667eea;
            margin: 10px 0;
        }
        .stat-label {
            color: #6c757d;
            font-size: 14px;
        }
        h2 {
            color: #2c3e50;
            margin-top: 40px;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
        }
        .endpoint {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 20px;
            margin: 15px 0;
            border-radius: 0 8px 8px 0;
        }
        .endpoint code {
            display: block;
            background: #2c3e50;
            color: #ecf0f1;
            padding: 10px 15px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            margin: 10px 0;
            overflow-x: auto;
        }
        .endpoint p {
            margin: 5px 0 0 0;
            color: #495057;
        }
        .method {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: bold;
            margin-right: 8px;
        }
        .link {
            color: #667eea;
            text-decoration: none;
            font-weight: 500;
        }
        footer {
            margin-top: 50px;
            padding-top: 20px;
            border-top: 2px solid #e9ecef;
            color: #7f8c8d;
            text-align: center;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Orebit RAG API Service</h1>
        <p class="subtitle">Production-ready RAG system powered by QwenPaw</p>

        <div class="status-box">
            <span>✓ API Status: Healthy & Operational</span>
        </div>

        <div class="stats">
            <div class="stat-box">
                <div class="stat-label">Indexed Papers</div>
                <div class="stat-number">351</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Summaries</div>
                <div class="stat-number">343</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Collections</div>
                <div class="stat-number">93</div>
            </div>
        </div>

        <h2>API Endpoints</h2>

        <div class="endpoint">
            <div>
                <span class="method">GET</span>
                <code>/api/rag/health</code>
            </div>
            <p>Check API status and corpus information</p>
        </div>

        <div class="endpoint">
            <div>
                <span class="method">POST</span>
                <code>/api/rag/query</code>
            </div>
            <p>Query the RAG system with natural language questions</p>
        </div>

        <h2>Quick Test</h2>
        <div class="endpoint">
            <code>curl https://rag.orebit.id/api/rag/health</code>
            <p>Run this command to verify API connectivity</p>
        </div>

        <h2>Documentation</h2>
        <p>
            📄 <a href="https://github.com/ghoziankarami/orebit-ops" class="link">GitHub Repository</a>
        </p>

        <footer>
            <p>Orebit RAG System • Production Environment</p>
            <p>⚡ Powered by QwenPaw</p>
        </footer>
    </div>

    <script>
        // Auto-update stats from API
        fetch('/api/rag/health')
            .then(response => response.json())
            .then(data => {
                const stats = document.querySelectorAll('.stat-number');
                if (data.corpus) {
                    if (stats[0]) stats[0].textContent = data.corpus.indexed_papers || '?';
                    if (stats[1]) stats[1].textContent = data.corpus.summary_count || '?';
                    if (stats[2]) stats[2].textContent = data.corpus.collection_count || '?';
                }
            })
            .catch(err => console.log('Could not fetch stats:', err));
    </script>
</body>
</html>
EOFPAGE

echo "✅ Landing page created"
echo ""

# Update Nginx configuration
echo "🔧 Updating Nginx configuration..."

# Backup current config
sudo cp /etc/nginx/sites-enabled/rag-orebit-id /etc/nginx/sites-enabled/rag-orebit-id.backup.$(date +%Y%m%d-%H%M%S)

# Check if location = / already exists
if sudo grep -q "location = /" /etc/nginx/sites-enabled/rag-orebit-id; then
    echo "⚠️  Root location block exists, updating..."
    # Update root location
    sudo sed -i '/location = /,/\}/c\
\    location = / {\
\        root /var/www/rag.orebit.id;\
\        index index.html;\
\        try_files $uri /index.html;\
\    }' /etc/nginx/sites-enabled/rag-orebit-id
else
    echo "📝 Adding root location block..."
    # Add root location before the API location
    sudo sed -i '/server {/,/location \//a\
\
\    # Root landing page\
\    location = / {\
\        root /var/www/rag.orebit.id;\
\        index index.html;\
\        try_files $uri /index.html;\
\    }' /etc/nginx/sites-enabled/rag-orebit-id
fi

echo "✅ Nginx configuration updated"
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

# Restart Nginx
echo "🔄 Restarting Nginx..."
sudo systemctl restart nginx
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

echo "🎉 Setup complete!"
echo ""
echo "Access points:"
echo "  • Landing page: https://rag.orebit.id"
echo "  • API health:   https://rag.orebit.id/api/rag/health"
echo ""
echo "Next:"
echo "  1. Open https://rag.orebit.id in browser"
echo "  2. Verify landing page displays correctly"
echo "  3. Click API health link to test API"
echo ""
