#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Sync workspace data to Google Drive via rclone
# ============================================================================
# Usage: bash sync-to-gdrive.sh [--dry-run] [--restore]
#
# This script syncs non-repo data to a GDrive folder:
#   gdrive:orebit-workspace-backup/
#
# What gets synced:
#   - Obsidian vault content (markdown files)
#   - Chroma DB data
#   - Research data (Nala configs, paper tracker, etc.)
#   - Environment files (.env)
#   - Rclone config
# ============================================================================

REMOTE="gdrive"
BACKUP_DIR="orebit-workspace-backup"
WORKSPACE="/workspace"
DRY_RUN=false
RESTORE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --restore) RESTORE=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Check rclone
if ! command -v rclone &>/dev/null; then
    echo "ERROR: rclone not found. Install with: curl https://rclone.org/install.sh | sudo bash"
    exit 1
fi

# Check rclone config
if ! rclone listremotes | grep -q "^${REMOTE}:"; then
    echo "ERROR: rclone remote '${REMOTE}' not configured."
    echo "Run: rclone config"
    exit 1
fi

# Check GDrive mount
if ! rclone lsd "${REMOTE}:" &>/dev/null; then
    echo "ERROR: Cannot access GDrive remote '${REMOTE}'."
    echo "Check your rclone config and network connection."
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/tmp/rclone-sync-${TIMESTAMP}.log"

echo "========================================="
echo "  Orebit Workspace GDrive Sync"
echo "  Timestamp: ${TIMESTAMP}"
echo "  Mode: $([ "$RESTORE" = true ] && echo 'RESTORE' || echo 'BACKUP')"
echo "  Dry run: ${DRY_RUN}"
echo "========================================="
echo ""

# Build rclone flags
RCLONE_FLAGS=(--progress --verbose)
if [ "$DRY_RUN" = true ]; then
    RCLONE_FLAGS+=(--dry-run)
fi

if [ "$RESTORE" = true ]; then
    # RESTORE: Download from GDrive to workspace
    echo "Restoring from GDrive..."
    echo ""

    echo "[1/5] Restoring Obsidian vault..."
    rclone sync "${REMOTE}:${BACKUP_DIR}/obsidian-system/vault" "${WORKSPACE}/obsidian-system/vault" "${RCLONE_FLAGS[@]}" 2>&1 | tee -a "$LOG_FILE"
    echo ""

    echo "[2/5] Restoring Obsidian config..."
    rclone sync "${REMOTE}:${BACKUP_DIR}/obsidian-system/.obsidian" "${WORKSPACE}/obsidian-system/vault/.obsidian" "${RCLONE_FLAGS[@]}" 2>&1 | tee -a "$LOG_FILE"
    echo ""

    echo "[3/5] Restoring Chroma DB..."
    rclone sync "${REMOTE}:${BACKUP_DIR}/rag-system/chroma" "${WORKSPACE}/rag-system/chroma" "${RCLONE_FLAGS[@]}" 2>&1 | tee -a "$LOG_FILE"
    echo ""

    echo "[4/5] Restoring research data..."
    rclone sync "${REMOTE}:${BACKUP_DIR}/research-data" "${WORKSPACE}/research-data" "${RCLONE_FLAGS[@]}" 2>&1 | tee -a "$LOG_FILE"
    echo ""

    echo "[5/5] Restoring environment files..."
    mkdir -p "${WORKSPACE}/infra-template"
    rclone sync "${REMOTE}:${BACKUP_DIR}/env-files" "${WORKSPACE}/infra-template" "${RCLONE_FLAGS[@]}" 2>&1 | tee -a "$LOG_FILE"
    echo ""

    echo "Restore complete. Log: ${LOG_FILE}"
else
    # BACKUP: Upload from workspace to GDrive
    echo "Backing up to GDrive..."
    echo ""

    echo "[1/6] Backing up Obsidian vault content..."
    if [ -d "${WORKSPACE}/obsidian-system/vault" ]; then
        rclone sync "${WORKSPACE}/obsidian-system/vault" "${REMOTE}:${BACKUP_DIR}/obsidian-system/vault" \
            --exclude "*.zip" \
            --exclude ".obsidian/plugins/**" \
            --exclude ".obsidian/themes/**" \
            "${RCLONE_FLAGS[@]}" 2>&1 | tee -a "$LOG_FILE"
    else
        echo "SKIP: ${WORKSPACE}/obsidian-system/vault not found"
    fi
    echo ""

    echo "[2/6] Backing up Obsidian config..."
    if [ -d "${WORKSPACE}/obsidian-system/vault/.obsidian" ]; then
        rclone sync "${WORKSPACE}/obsidian-system/vault/.obsidian" "${REMOTE}:${BACKUP_DIR}/obsidian-system/.obsidian" \
            --exclude "plugins/**" \
            --exclude "themes/**" \
            --exclude "icons/**" \
            "${RCLONE_FLAGS[@]}" 2>&1 | tee -a "$LOG_FILE"
    else
        echo "SKIP: .obsidian config not found"
    fi
    echo ""

    echo "[3/6] Backing up Chroma DB..."
    if [ -d "${WORKSPACE}/rag-system/chroma" ]; then
        rclone sync "${WORKSPACE}/rag-system/chroma" "${REMOTE}:${BACKUP_DIR}/rag-system/chroma" "${RCLONE_FLAGS[@]}" 2>&1 | tee -a "$LOG_FILE"
    else
        echo "SKIP: ${WORKSPACE}/rag-system/chroma not found"
    fi
    echo ""

    echo "[4/6] Backing up research data..."
    if [ -d "${WORKSPACE}/research-data" ]; then
        rclone sync "${WORKSPACE}/research-data" "${REMOTE}:${BACKUP_DIR}/research-data" \
            --exclude "__pycache__/**" \
            --exclude "*.pyc" \
            "${RCLONE_FLAGS[@]}" 2>&1 | tee -a "$LOG_FILE"
    else
        echo "SKIP: ${WORKSPACE}/research-data not found"
    fi
    echo ""

    echo "[5/6] Backing up environment files..."
    if [ -f "${WORKSPACE}/infra-template/.env" ]; then
        mkdir -p "/tmp/env-backup-${TIMESTAMP}"
        cp "${WORKSPACE}/infra-template/.env" "/tmp/env-backup-${TIMESTAMP}/" 2>/dev/null || true
        cp "${WORKSPACE}/rag-system/.env" "/tmp/env-backup-${TIMESTAMP}/rag-system.env" 2>/dev/null || true
        rclone sync "/tmp/env-backup-${TIMESTAMP}" "${REMOTE}:${BACKUP_DIR}/env-files" "${RCLONE_FLAGS[@]}" 2>&1 | tee -a "$LOG_FILE"
        rm -rf "/tmp/env-backup-${TIMESTAMP}"
    else
        echo "SKIP: No .env files found"
    fi
    echo ""

    echo "[6/6] Backing up rclone config..."
    if [ -f "${HOME}/.config/rclone/rclone.conf" ]; then
        mkdir -p "/tmp/rclone-backup-${TIMESTAMP}"
        cp "${HOME}/.config/rclone/rclone.conf" "/tmp/rclone-backup-${TIMESTAMP}/" 2>/dev/null || true
        rclone sync "/tmp/rclone-backup-${TIMESTAMP}" "${REMOTE}:${BACKUP_DIR}/rclone-config" "${RCLONE_FLAGS[@]}" 2>&1 | tee -a "$LOG_FILE"
        rm -rf "/tmp/rclone-backup-${TIMESTAMP}"
    else
        echo "SKIP: rclone.conf not found"
    fi
    echo ""

    echo "Backup complete. Log: ${LOG_FILE}"
fi

echo ""
echo "========================================="
echo "  Done"
echo "========================================="
