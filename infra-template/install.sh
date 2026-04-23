#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "  Orebit Workspace Installer"
echo "========================================="
echo ""

# Check prerequisites
check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "Installing $1..."
        if command -v apt-get &>/dev/null; then
            apt-get update && apt-get install -y "$1"
        elif command -v dnf &>/dev/null; then
            dnf install -y "$1"
        elif command -v yum &>/dev/null; then
            yum install -y "$1"
        else
            echo "ERROR: Cannot install $1. Please install manually."
            exit 1
        fi
    fi
}

check_command docker
check_command python3
check_command rclone

# Create workspace structure
echo "Creating workspace structure..."
mkdir -p "$WORKSPACE_ROOT"/{obsidian-system/vault,rag-system,research-data,infra-template}

# Run component installers
echo ""
echo "--- Obsidian System ---"
if [ -f "$WORKSPACE_ROOT/obsidian-system/install.sh" ]; then
    bash "$WORKSPACE_ROOT/obsidian-system/install.sh"
else
    echo "SKIP: obsidian-system/install.sh not found"
fi

echo ""
echo "--- RAG System ---"
if [ -f "$WORKSPACE_ROOT/rag-system/install.sh" ]; then
    bash "$WORKSPACE_ROOT/rag-system/install.sh"
else
    echo "SKIP: rag-system/install.sh not found"
fi

echo ""
echo "--- Research Data ---"
if [ -f "$WORKSPACE_ROOT/research-data/install.sh" ]; then
    bash "$WORKSPACE_ROOT/research-data/install.sh"
else
    echo "SKIP: research-data/install.sh not found"
fi

echo ""
echo "========================================="
echo "  Installation Complete"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Set up environment: cp infra-template/.env.template .env"
echo "2. Restore data from backup (if migrating)"
echo "3. Configure rclone: rclone config"
echo "4. Verify services:"
echo "   - Dashboard: curl http://127.0.0.1:8503"
echo "   - API: curl http://127.0.0.1:3004/api/rag/health"
echo "   - Rclone: ls /mnt/gdrive/AI_Knowledge"
