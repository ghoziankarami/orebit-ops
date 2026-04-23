#!/bin/bash
# Nala Auto-Paper Pipeline — Geology Indonesia & Saudi Arabia
# Cron: */30 * * * * /usr/bin/python3 /workspace/research-data/nala/scripts/paper-autoflow.py

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/../config/nala-paper-topics-geology.yaml"
PYTHON_SCRIPT="$SCRIPT_DIR/paper-autoflow.py"
LOG_FILE="/var/log/nala-paper-autoflow-geology.log"

timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log() {
    timestamp "$*"
}

# Check prerequisites
for cmd in python3; do
    if ! command -v $cmd &>/dev/null; then
        log "❌ Required command not found: $cmd"
        exit 1
    fi
done

if [ ! -f "$PYTHON_SCRIPT" ]; then
    log "❌ Paper-autoflow script not found: $PYTHON_SCRIPT"
    exit 1
fi

if [ ! -f "$CONFIG" ]; then
    log "❌ Config not found: $CONFIG"
    exit 1
fi

log "=== Nala Geology Research Pipeline Starting ==="
log "Config: $CONFIG"
log "Project: geology-indonesia-saudi"

# Execute Nala autoflow with custom config and project slug
# Pass through any arguments (e.g., --dry-run, --limit)
python3 "$PYTHON_SCRIPT" --config "$CONFIG" --project "geology-indonesia-saudi" "$@"

log "✅ Run completed"
