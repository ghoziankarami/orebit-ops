#!/bin/bash
# capture-link.sh — Capture a link into Obsidian vault using PARA method
# Usage: bash capture-link.sh "URL" [--context "notes"]
set -euo pipefail

VAULT_PATH="${VAULT_PATH:-/app/working/workspaces/default/obsidian-system/vault}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PYTHON_SCRIPT="${SCRIPT_DIR}/url_ingest.py"

URL=""
CONTEXT=""

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --context)
            CONTEXT="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            if [[ -z "$URL" ]]; then
                URL="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$URL" ]]; then
    echo "Usage: bash capture-link.sh \"URL\" [--context \"notes\"]"
    exit 1
fi

# Run ingestion
export VAULT_PATH
echo "[capture-link] Capturing: $URL"
echo "[capture-link] Context: ${CONTEXT:-none}"

result=$(python3 "$PYTHON_SCRIPT" "$URL" --context "${CONTEXT:-}" 2>&1)
echo "[capture-link] $result"

# Optional push to Drive when the canonical rclone write path is trusted.
if [[ -x "${SCRIPT_DIR}/../sync/sync-inbox-push.sh" ]]; then
    echo "[capture-link] Syncing to Google Drive..."
    bash "${SCRIPT_DIR}/../sync/sync-inbox-push.sh" || true
fi

echo "[capture-link] Done."
