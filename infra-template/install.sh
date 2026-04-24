#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command '$1' is not available"
    exit 1
  fi
}

echo "========================================="
echo "  Orebit Workspace Installer"
echo "========================================="
echo

require_command python3
require_command docker
require_command curl
require_command rclone

mkdir -p "$WORKSPACE_ROOT/obsidian-system" "$WORKSPACE_ROOT/rag-system" "$WORKSPACE_ROOT/research-data"

if [ ! -f "$WORKSPACE_ROOT/.env" ]; then
  echo "ERROR: missing $WORKSPACE_ROOT/.env"
  echo "Copy infra-template/.env.template to .env and fill the required values first."
  exit 1
fi

echo "Running preflight validation..."
python3 "$WORKSPACE_ROOT/scripts_preflight_validate.py"

echo
echo "--- Obsidian System ---"
bash "$WORKSPACE_ROOT/obsidian-system/install.sh"

echo
echo "--- RAG System ---"
bash "$WORKSPACE_ROOT/rag-system/install.sh"

echo
echo "--- Research Data ---"
bash "$WORKSPACE_ROOT/research-data/install.sh"

echo
echo "Running postflight verification..."
python3 "$WORKSPACE_ROOT/scripts_postflight_verify.py" || true

echo
echo "========================================="
echo "  Installation Complete"
echo "========================================="
echo "Review any WARN/FAIL messages above before considering the system healthy."
