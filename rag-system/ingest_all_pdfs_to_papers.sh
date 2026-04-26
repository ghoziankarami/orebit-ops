#!/bin/bash
set -euo pipefail

VAULT="/app/working/workspaces/default/obsidian-system/vault"
SCRIPT="/app/working/workspaces/default/orebit-ops/rag-system/pdf_to_paper_note.py"
LOG="/tmp/orebit-paper-intake.log"

find "$VAULT" -type f -iname '*.pdf' | while IFS= read -r pdf; do
  echo "[$(date -Iseconds)] ingest $pdf" | tee -a "$LOG"
  python3 "$SCRIPT" "$pdf" >> "$LOG" 2>&1 || true
done

echo "[$(date -Iseconds)] paper intake done" | tee -a "$LOG"
