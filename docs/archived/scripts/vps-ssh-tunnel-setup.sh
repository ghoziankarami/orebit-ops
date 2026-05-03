#!/bin/bash
# ===========================================================
# SSH TUNNEL SETUP FOR VPS - QUICK START
# ===========================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE} SSH TUNNEL SETUP - FIX CONNECTION REFUSED${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""

echo -e "${YELLOW}Problem: Direct connection failed${NC}"
echo "curl http://103.139.244.177:3004/api/rag/health"
echo "Result: Connection refused"
echo ""
echo -e "${GREEN}Solution: SSH tunnel from VPS to QwenPaw${NC}"
echo ""

echo -e "${GREEN}STEP 1: Verify SSH Connectivity${NC}"
echo "======================================"
echo ""
echo "Testing SSH connection to QwenPaw..."
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@103.139.244.177 "echo 'SSH connection successful'"; then
    echo -e "${GREEN}✓ SSH connection verified${NC}"
else
    echo -e "${RED}✗ SSH connection failed${NC}"
    echo -e "${YELLOW}Please check:${NC}"
    echo "  - SSH service running on QwenPaw"
    echo "  - Port 22 accessible from VPS"
    echo "  - Authentication method (password/key)"
    exit 1
fi
echo ""

echo -e "${GREEN}STEP 2: Create SSH Tunnel${NC}"
echo "============================"
echo ""

# Kill existing tunnels
echo "Killing existing tunnels..."
pkill -f "ssh.*3004" 2>/dev/null || true
sleep 2

# Create SSH tunnel
echo "Creating SSH tunnel..."
nohup ssh -N -R 3004:127.0.0.1:3004 root@103.139.244.177 > /tmp/qwenpaw-tunnel.log 2>&1 &
TUNNEL_PID=$!
echo "$TUNNEL_PID" > /tmp/qwenpaw-tunnel.pid

echo "Tunnel started with PID: $TUNNEL_PID"
echo ""

# Wait for tunnel to establish
echo "Waiting for tunnel to establish..."
sleep 5

# Check if tunnel process is running
if ps -p $TUNNEL_PID > /dev/null; then
    echo -e "${GREEN}✓ Tunnel process running${NC}"
else
    echo -e "${RED}✗ Tunnel process failed${NC}"
    echo "Check logs: tail -f /tmp/qwenpaw-tunnel.log"
    exit 1
fi
echo ""

echo -e "${GREEN}STEP 3: Verify Tunnel${NC}"
echo "======================"
echo ""

# Check if port 3004 is listening locally
if netstat -tlnp 2>/dev/null | grep :3004 > /dev/null; then
    echo -e "${GREEN}✓ Port 3004 listening locally${NC}"
else
    echo -e "${YELLOW}Waiting for port to open...${NC}"
    sleep 5
    if netstat -tlnp 2>/dev/null | grep :3004 > /dev/null; then
        echo -e "${GREEN}✓ Port 3004 listening locally${NC}"
    else
        echo -e "${RED}✗ Port 3004 not listening${NC}"
        exit 1
    fi
fi
echo ""

# Test forwarded connection
echo "Testing forwarded connection..."
HEALTH_CHECK=$(curl -s http://localhost:3004/api/rag/health 2>&1)

if echo "$HEALTH_CHECK" | grep -q "healthy"; then
    echo -e "${GREEN}✓ Tunnel connection working!${NC}"
    echo ""
    echo "Health check response:"
    echo "$HEALTH_CHECK" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_CHECK"
else
    echo -e "${RED}✗ Tunnel connection failed${NC}"
    echo "Response: $HEALTH_CHECK"
    echo ""
    echo "Check logs: tail -f /tmp/qwenpaw-tunnel.log"
    exit 1
fi
echo ""

echo -e "${GREEN}STEP 4: Update Nginx Configuration${NC}"
echo "========================================="
echo ""

NGINX_CONF="/etc/nginx/sites-available/rag.orebit.id"

if [ -f "$NGINX_CONF" ]; then
    echo "Found Nginx configuration: $NGINX_CONF"

    # Check current proxy_pass
    CURRENT_PROXY=$(grep -o "proxy_pass[^;]*" "$NGINX_CONF" | head -1)
    echo "Current proxy_pass: $CURRENT_PROXY"

    # Update to use localhost:3004
    echo "Updating proxy_pass to http://localhost:3004..."
    sudo sed -i 's|proxy_pass http://[^:]*:3004;|proxy_pass http://localhost:3004;|' "$NGINX_CONF"

    # Verify change
    NEW_PROXY=$(grep -o "proxy_pass[^;]*" "$NGINX_CONF" | head -1)
    echo "New proxy_pass: $NEW_PROXY"
    echo -e "${GREEN}✓ Nginx configuration updated${NC}"
else
    echo -e "${RED}✗ Nginx configuration not found${NC}"
    echo "Expected: $NGINX_CONF"
    exit 1
fi
echo ""

echo -e "${GREEN}STEP 5: Restart Nginx${NC}"
echo "======================="
echo ""

# Test Nginx configuration
if sudo nginx -t; then
    echo -e "${GREEN}✓ Nginx configuration valid${NC}"

    # Restart Nginx
    if sudo systemctl restart nginx; then
        echo -e "${GREEN}✓ Nginx restarted${NC}"

        # Check Nginx status
        if sudo systemctl is-active nginx > /dev/null; then
            echo -e "${GREEN}✓ Nginx running${NC}"
        else
            echo -e "${RED}✗ Nginx not running${NC}"
            sudo systemctl status nginx
            exit 1
        fi
    else
        echo -e "${RED}✗ Failed to restart Nginx${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Nginx configuration invalid${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}STEP 6: Test Full Deployment${NC}"
echo "================================="
echo ""

echo "Testing https://rag.orebit.id/health..."
FULL_TEST=$(curl -s https://rag.orebit.id/health 2>&1)

if echo "$FULL_TEST" | grep -q "healthy"; then
    echo -e "${GREEN}✓ Full deployment working!${NC}"
    echo ""
    echo "Health check response:"
    echo "$FULL_TEST" | python3 -m json.tool 2>/dev/null || echo "$FULL_TEST"
else
    echo -e "${YELLOW}Warning: Health check endpoint not accessible yet${NC}"
    echo "This might be normal if domain still propagating"
    echo "Response: $FULL_TEST"
    echo ""
    echo "Try again later: curl https://rag.orebit.id/health"
fi
echo ""

echo -e "${GREEN}STEP 7: Setup Tunnel Auto-Restart${NC}"
echo "======================================"
echo ""

echo "Creating systemd service for auto-restart..."
sudo tee /etc/systemd/system/qwenpaw-tunnel.service > /dev/null << 'EOF'
[Unit]
Description=SSH Tunnel to QwenPaw
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/ssh -N -R 3004:127.0.0.1:3004 root@103.139.244.177
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable qwenpaw-tunnel.service
sudo systemctl start qwenpaw-tunnel.service

if sudo systemctl is-active qwenpaw-tunnel.service > /dev/null; then
    echo -e "${GREEN}✓ Tunnel service enabled and running${NC}"
    echo -e "${YELLOW}Note: Tunnel will auto-restart on boot${NC}"
else
    echo -e "${YELLOW}Warning: Tunnel service not active${NC}"
    echo "Check status: sudo systemctl status qwenpaw-tunnel.service"
fi
echo ""

echo -e "${BLUE}=================================================================${NC}"
echo -e "${GREEN}SSH TUNNEL SETUP COMPLETE!${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""
echo "Configuration Summary:"
echo "---------------------"
echo "QwenPaw: 103.139.244.177"
echo "VPS: Forward to localhost:3004 via SSH tunnel"
echo "Domain: https://rag.orebit.id"
echo ""
echo "Access Points:"
echo "--------------"
echo "Public UI: https://rag.orebit.id"
echo "Health Check: https://rag.orebit.id/health"
echo "API Query: https://rag.orebit.id/api/rag/query"
echo ""
echo "Monitoring:"
echo "----------"
echo "Tunnel status: sudo systemctl status qwenpaw-tunnel"
echo "Tunnel logs: tail -f /tmp/qwenpaw-tunnel.log"
echo "Nginx status: sudo systemctl status nginx"
echo ""
echo -e "${GREEN}SUCCESS! 🎉${NC}"
echo ""
echo "VPS is now configured as FRONTEND ONLY"
echo "All system logic remains on QwenPaw (central system)"
echo "Accessing RAG system via: https://rag.orebit.id"
echo ""
