#!/bin/bash
# ===========================================================
# CLOUDFLARED TUNNEL AUTO-RESTART SETUP (QwenPaw)
# ===========================================================

set -euo pipefail

echo "Setting up Cloudflare Tunnel systemd service..."

# Create tunnel URL file (for easy reference)
TUNNEL_URL="https://opposite-fountain-corrected-organized.trycloudflare.com"
echo "Tunnel URL: $TUNNEL_URL" > /tmp/tunnel-url.txt

# Create systemd service
cat > /tmp/cloudflared-tunnel.service << 'EOF'
[Unit]
Description=Cloudflare Tunnel for QwenPaw RAG
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel --url http://127.0.0.1:3004
Restart=on-failure
RestartSec=10
StandardOutput=append:/tmp/cloudflared-tunnel.log
StandardError=append:/tmp/cloudflared-tunnel.log

[Install]
WantedBy=multi-user.target
EOF

# Install service
echo "Installing systemd service..."
sudo cp /tmp/cloudflared-tunnel.service /etc/systemd/system/

# Reload systemd
echo "Reloading systemd..."
sudo systemctl daemon-reload

# Enable auto-start on boot
echo "Enabling service for auto-start on boot..."
sudo systemctl enable cloudflared-tunnel.service

# Start the service
echo "Starting Cloudflare Tunnel service..."
sudo systemctl start cloudflared-tunnel.service

# Wait a moment for tunnel to establish
echo "Waiting for tunnel to establish..."
sleep 10

# Check service status
echo "Checking service status..."
sudo systemctl status cloudflared-tunnel.service | head -20

# Get new tunnel URL (might be different from quick tunnel)
echo ""
echo "Getting tunnel URL..."
NEW_TUNNEL_URL=$(grep "https://" /tmp/cloudflared-tunnel.log | grep "trycloudflare.com" | tail -1 | grep -o "https://[^ ]*")
if [ -n "$NEW_TUNNEL_URL" ]; then
    echo "New Tunnel URL: $NEW_TUNNEL_URL"
    echo "$NEW_TUNNEL_URL" > /tmp/tunnel-url.txt
fi

# Test tunnel
echo ""
echo "Testing tunnel..."
curl -s http://127.0.0.1:3004/api/rag/health | python3 -m json.tool | grep -E "status|indexed_papers"

echo ""
echo "✅ Cloudflare Tunnel service setup complete!"
echo ""
echo "Commands:"
echo "  Check status: sudo systemctl status cloudflared-tunnel"
echo "  View logs: cat /tmp/cloudflared-tunnel.log"
echo "  Restart: sudo systemctl restart cloudflared-tunnel"
echo "  Stop: sudo systemctl stop cloudflared-tunnel"
echo ""
echo "Tunnel URL saved in: /tmp/tunnel-url.txt"
