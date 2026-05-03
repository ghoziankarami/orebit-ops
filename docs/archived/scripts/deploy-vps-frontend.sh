#!/bin/bash
# ===========================================================
# VPS FRONTEND DEPLOYMENT SCRIPT
# Pulls architecture docs from GitHub and sets up VPS as frontend only
# ===========================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub repository
REPO_URL="https://github.com/ghoziankarami/orebit-ops.git"
REPO_DIR="$HOME/orebit-ops"

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE} VPS FRONTEND DEPLOYMENT - SETUP FROM GITHUB${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}Running as root (via sudo)${NC}"
else
    echo -e "${YELLOW}Running as user: $(whoami)${NC}"
fi

echo ""
echo -e "${GREEN}STEP 1: Clone/Update Repository${NC}"
echo "=========================================="

# Clone or update repository
if [ -d "$REPO_DIR" ]; then
    echo "Repository exists, updating..."
    cd "$REPO_DIR"
    git pull origin main
else
    echo "Cloning repository..."
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

echo -e "${GREEN}✓ Repository ready at: $REPO_DIR${NC}"
echo ""

echo -e "${GREEN}STEP 2: Display Architecture Information${NC}"
echo "=========================================="

if [ -f "$REPO_DIR/ARCHITECTURE_SUMMARY.txt" ]; then
    echo "Architecture Summary:"
    cat "$REPO_DIR/ARCHITECTURE_SUMMARY.txt"
else
    echo -e "${YELLOW}Warning: ARCHITECTURE_SUMMARY.txt not found${NC}"
fi

echo ""
echo -e "${GREEN}STEP 3: System Requirements Check${NC}"
echo "=========================================="

# Check available resources
echo "System Information:"
echo "--------------------"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "CPU cores: $(nproc)"
echo "Total RAM: $(free -h | awk '/^Mem:/{print $2}')"
echo "Free RAM: $(free -h | awk '/^Mem:/{print $7}')"
echo "Disk space: $(df -h . | awk 'NR==2{print $4}') free"
echo ""

# Check required packages
echo "Checking required packages:"
echo "----------------------------"
if command -v git &> /dev/null; then
    echo -e "${GREEN}✓ git installed$(git --version | cut -f3 -d' ')${NC}"
else
    echo -e "${RED}✗ git NOT installed${NC}"
    exit 1
fi

if command -v nginx &> /dev/null; then
    echo -e "${GREEN}✓ nginx installed$(nginx -v 2>&1 | cut -f2 -d'/')${NC}"
else
    echo -e "${YELLOW}○ nginx NOT installed (will install later)${NC}"
fi

if command -v certbot &> /dev/null; then
    echo -e "${GREEN}✓ certbot installed${NC}"
else
    echo -e "${YELLOW}○ certbot NOT installed (will install later)${NC}"
fi

echo ""

echo -e "${GREEN}STEP 4: Choose Deployment Option${NC}"
echo "=========================================="
echo ""
echo "This VPS will be configured as PUBLIC FRONTEND ONLY:"
echo "  • Nginx reverse proxy (SSL)"
echo "  • Domain: rag.orebit.id"
echo "  • Forward to QwenPaw via:"
echo ""
echo "Options:"
echo "  1. ngrok tunnel (RECOMMENDED - Easiest)"
echo "       • QwenPaw runs ngrok tunnel"
echo "       • VPS forwards to ngrok URL"
echo "       • No public IP needed"
echo ""
echo "  2. Direct connection (BEST - If QwenPaw has public IP)"
echo "       • VPS forwards directly to QwenPaw IP:3004"
echo "       • Highest performance"
echo "       • Public IP required"
echo ""
echo "  3. SSH tunnel (Flexible)"
echo "       • VPS creates SSH tunnel to QwenPaw"
echo "       • No public IP needed"
echo "       • Requires SSH access"
echo ""
echo -e "${YELLOW}Your choice (1-3):${NC} "
read CHOICE

case $CHOICE in
    1)
        DEPLOYMENT_TYPE="ngrok"
        ;;
    2)
        DEPLOYMENT_TYPE="direct"
        ;;
    3)
        DEPLOYMENT_TYPE="ssh"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}STEP 5: Install Required Packages${NC}"
echo "=========================================="

# Update package list
sudo apt-get update

# Install nginx if not present
if ! command -v nginx &> /dev/null; then
    echo "Installing nginx..."
    sudo apt-get install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    echo -e "${GREEN}✓ nginx installed and started${NC}"
fi

# Install certbot if not present
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    sudo apt-get install -y certbot python3-certbot-nginx
    echo -e "${GREEN}✓ certbot installed${NC}"
fi

echo ""

echo -e "${GREEN}STEP 6: Setup SSL Certificates${NC}"
echo "=========================================="

echo -e "${YELLOW}Enter your domain (e.g., rag.orebit.id):${NC} "
read DOMAIN

echo ""
echo "Setting up SSL for domain: $DOMAIN"
sudo certbot --nginx -d "$DOMAIN"
echo -e "${GREEN}✓ SSL certificates configured${NC}"
echo ""

echo -e "${GREEN}STEP 7: Configure Nginx${NC}"
echo "=========================================="

NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

case $DEPLOYMENT_TYPE in
    ngrok)
        echo -e "${YELLOW}Enter your ngrok URL from QwenPaw:${NC}"
        echo "Example: https://abcd-12-34-56-78.ngrok-free.app"
        echo "To get ngrok URL on QwenPaw: cat /tmp/ngrok.log | grep -oP 'https://[a-z0-9-]+\.ngrok(-free)?\.app'"
        read NGROK_URL

        sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # Increase timeouts for long-running requests
    proxy_read_timeout 300;
    proxy_connect_timeout 300;
    proxy_send_timeout 300;

    location / {
        proxy_pass $NGROK_URL;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Health check endpoint
    location /health {
        proxy_pass $NGROK_URL/api/rag/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        add_header Content-Type application/json;
    }
}
EOF
        ;;
    direct)
        echo -e "${YELLOW}Enter QwenPaw Public IP:${NC} "
        read QWENPAW_IP

        sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://$QWENPAW_IP:3004;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /health {
        proxy_pass http://$QWENPAW_IP:3004/api/rag/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        add_header Content-Type application/json;
    }
}
EOF
        ;;
    ssh)
        echo -e "${YELLOW}Enter QwenPaw user@IP:${NC} "
        read QWENPAW_SSH

        echo -e "${YELLOW}Creating SSH tunnel...${NC}"
        # Create SSH tunnel in background
        nohup ssh -N -R 3004:127.0.0.1:3004 "$QWENPAW_SSH" > /tmp/qwenpaw-tunnel.log 2>&1 &
        TUNNEL_PID=$!
        echo "$TUNNEL_PID" > /tmp/qwenpaw-tunnel.pid
        echo -e "${GREEN}✓ SSH tunnel started (PID: $TUNNEL_PID)${NC}"

        # Wait for tunnel to establish
        sleep 5

        sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://localhost:3004;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /health {
        proxy_pass http://localhost:3004/api/rag/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        add_header Content-Type application/json;
    }
}
EOF
        ;;
esac

echo -e "${GREEN}✓ Nginx configuration created${NC}"
echo ""

echo -e "${GREEN}STEP 8: Enable Configuration${NC}"
echo "=========================================="

# Enable site
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/

# Test Nginx config
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
echo -e "${GREEN}✓ Nginx restarted${NC}"
echo ""

echo -e "${GREEN}STEP 9: Test Deployment${NC}"
echo "=========================================="

echo "Waiting for services to start..."
sleep 5

echo ""
echo "Testing health check endpoint..."
HEALTH_CHECK=$(curl -s "https://$DOMAIN/health")

if [ -n "$HEALTH_CHECK" ]; then
    echo -e "${GREEN}✓ Health check successful!${NC}"
    echo "Response:"
    echo "$HEALTH_CHECK" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_CHECK"
else
    echo -e "${YELLOW}Warning: Health check endpoint not accessible yet${NC}"
    echo "This might be normal if QwenPaw is not yet configured"
fi

echo ""

echo -e "${GREEN}STEP 10: Setup Complete${NC}"
echo "=========================================="

echo ""
echo -e "${GREEN}DEPLOYMENT COMPLETE!${NC}"
echo ""
echo "Configuration Summary:"
echo "--------------------"
echo "Domain: $DOMAIN"
echo "Deployment type: $DEPLOYMENT_TYPE"
echo "Nginx config: $NGINX_CONF"
echo "SSL: Enabled (Let's Encrypt)"
echo ""
echo "Access URLs:"
echo "----------"
echo "Public UI: https://$DOMAIN"
echo "Health Check: https://$DOMAIN/health"
echo "API Endpoint: https://$DOMAIN/api/rag/query"
echo ""

echo -e "${GREEN}Next Steps:${NC}"
echo "1. Open https://$DOMAIN in your browser"
echo "2. Verify the RAG system is accessible"
echo "3. Test queries via: https://$DOMAIN/api/rag/query"
echo "4. Monitor Nginx logs: sudo journalctl -u nginx -f"
echo ""

echo -e "${GREEN}VPS is now configured as FRONTEND ONLY!${NC}"
echo "✓ No ChromaDB on VPS (saves memory)"
echo "✓ No rclone on VPS (no duplication)"
echo "✓ All system on QwenPaw (single source of truth)"
echo ""

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE} DEPLOYMENT SUCCESSFUL${NC}"
echo -e "${BLUE}=================================================================${NC}"
