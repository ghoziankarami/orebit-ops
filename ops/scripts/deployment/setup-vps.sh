#!/bin/bash

# VPS SETUP SCRIPT FOR RAG.OREBIT.ID
# This script sets up the complete RAG system on a new Ubuntu VPS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VPS_IP="43.157.201.50"
DOMAIN_RAG="rag.orebit.id"
DOMAIN_API="api.orebit.id"
DOCKER_REPO="ghoziankarami/orebit-ops"
BRANCH="main"

echo -e "${GREEN}=== RAG.OREBIT.ID VPS SETUP (orebit-sumopod) ===${NC}"
echo "VPS IP: $VPS_IP"
echo "Domains: $DOMAIN_RAG, $DOMAIN_API"
echo ""

# Step 1: Update System
echo -e "${YELLOW}Step 1: Updating system packages...${NC}"
sudo apt-get update && sudo apt-get upgrade -y

# Step 2: Install Dependencies
echo -e "${YELLOW}Step 2: Installing dependencies...${NC}"
sudo apt-get install -y \
    curl \
    wget \
    git \
    docker.io \
    docker-compose \
    nginx \
    certbot \
    python3-certbot-nginx \
    ufw \
    htop \
    tree

# Step 3: Install Docker (if not already installed via docker.io)
echo -e "${YELLOW}Step 3: Setting up Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker ubuntu
fi

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Verify Docker
docker --version
docker-compose --version

# Step 4: Setup Firewall
echo -e "${YELLOW}Step 4: Configuring firewall...${NC}"
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3004/tcp  # RAG API
sudo ufw allow 8000/tcp  # Embedding Server
sudo ufw allow 8001/tcp  # ChromaDB
sudo ufw --force enable

# Step 5: Create Project Directory
echo -e "${YELLOW}Step 5: Creating project directory...${NC}"
sudo mkdir -p /opt/orebit-rag
sudo chown -R ubuntu:ubuntu /opt/orebit-rag
cd /opt/orebit-rag

# Step 6: Clone Repository
echo -e "${YELLOW}Step 6: Cloning repository...${NC}"
if [ -d "orebit-ops" ]; then
    cd orebit-ops
    git fetch origin
    git checkout main
    git pull origin main
else
    git clone -b $BRANCH https://github.com/$DOCKER_REPO.git
    cd orebit-ops
fi

# Step 7: Setup Environment Variables
echo -e "${YELLOW}Step 7: Setting up environment variables...${NC}"
cd rag-system
mkdir -p .env

# Create .env file
cat > /opt/orebit-rag/orebit-ops/rag-system/.env <<EOF
# RAG API Configuration
PORT=3004
RAG_API_HOST=0.0.0.0
OREBIT_EMBEDDING_API_URL=http://embedding-server:8000/v1/embeddings
RAG_API_KEY=orebit-rag-2026-secret-key-change-me

# Optional
RAG_STATS_TTL_MS=60000
RAG_RESPONSE_CACHE_TTL_MS=300000

# Domain configuration
DOMAIN_RAG=$DOMAIN_RAG
DOMAIN_API=$DOMAIN_API
EOF

# Step 8: Build and Start Services
echo -e "${YELLOW}Step 8: Building and starting services...${NC}"
sudo docker-compose down  # Stop any existing services
sudo docker-compose up --build -d

# Step 9: Wait for services to be ready
echo -e "${YELLOW}Step 9: Waiting for services to start...${NC}"
sleep 30

# Check service status
sudo docker-compose ps

# Step 10: Test API Health
echo -e "${YELLOW}Step 10: Testing API health...${NC}"
sleep 10
curl -f http://localhost:3004/api/rag/health || echo -e "${RED}API health check failed${NC}"

# Step 11: Setup Nginx
echo -e "${YELLOW}Step 11: Setting up Nginx...${NC}"
sudo tee /etc/nginx/sites-available/rag-orebit-id <<'EOF'
# RAG.orebit.id - Reverse Proxy
server {
    listen 80;
    server_name rag.orebit.id;

    location / {
        proxy_pass http://localhost:3004;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# api.orebit.id - Reverse Proxy
server {
    listen 80;
    server_name api.orebit.id;

    location / {
        proxy_pass http://localhost:3004;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/rag-orebit-id /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# Step 12: Setup SSL Certificates
echo -e "${YELLOW}Step 12: Setting up SSL certificates (this will take a minute)...${NC}"
echo -e "${YELLOW}Note: Make sure DNS records are pointed to $VPS_IP first!${NC}"
sleep 2

# Request SSL certificates (interactive - will need user confirmation)
read -p "Are DNS records ($DOMAIN_RAG, $DOMAIN_API) pointing to $VPS_IP? (yes/no): "确认_dns

if [[ $确认_dns == "yes" ]]; then
    sudo certbot --nginx -d $DOMAIN_RAG -d $DOMAIN_API --email admin@orebit.id --agree-tos --non-interactive

    # Setup auto-renewal
    sudo certbot renew --dry-run
else
    echo -e "${RED}Skipping SSL setup. Please set up DNS records first and run:${NC}"
    echo "sudo certbot --nginx -d $DOMAIN_RAG -d $DOMAIN_API"
fi

# Step 13: Setup Auto-Start
echo -e "${YELLOW}Step 13: Setting up auto-start services...${NC}"
# Docker should already auto-start from systemctl enable
# Create a startup script for Docker Compose
sudo tee /etc/systemd/system/orebit-rag.service <<EOF
[Unit]
Description=Orebit RAG System
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/orebit-rag/orebit-ops/rag-system
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable orebit-rag.service
sudo systemctl daemon-reload

# Step 14: Final Status Check
echo -e "${GREEN}=== SETUP COMPLETE! ===${NC}"
echo ""
echo "Services Status:"
sudo docker-compose ps
echo ""
echo "Nginx Status:"
sudo systemctl status nginx --no-pager
echo ""
echo "Docker Status:"
sudo systemctl status docker --no-pager
echo ""
echo -e "${GREEN}=== NEXT STEPS ===${NC}"
echo "1. Verify DNS records:"
echo "   - $DOMAIN_RAG → A → $VPS_IP"
echo "   - $DOMAIN_API → A → $VPS_IP"
echo ""
echo "2. Test the deployment:"
echo "   curl https://$DOMAIN_RAG/api/rag/health"
echo "   curl https://$DOMAIN_API/api/rag/health"
echo ""
echo "3. Check logs:"
echo "   cd /opt/orebit-rag/orebit-ops/rag-system"
echo "   sudo docker-compose logs -f"
echo ""
echo "4. SSL Certificate Auto-Renewal:"
echo "   crontab -e"
echo "   Add: 0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'"
echo ""
echo -e "${GREEN}=== VPS SETUP COMPLETE ===${NC}"
