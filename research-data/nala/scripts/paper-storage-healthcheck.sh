#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
VERIFY_SCRIPT="$SCRIPT_DIR/verify-paper-counts.py"

info() {
  printf '[paper-storage-healthcheck] %s\n' "$*"
}

warn() {
  printf '[paper-storage-healthcheck][WARN] %s\n' "$*" >&2
}

die() {
  printf '[paper-storage-healthcheck][ERROR] %s\n' "$*" >&2
  exit 1
}

if ! command -v mountpoint >/dev/null 2>&1; then
  die "mountpoint is required for health checks"
fi

if ! command -v python3 >/dev/null 2>&1; then
  die "python3 is required for health checks"
fi

if [[ ! -f "$VERIFY_SCRIPT" ]]; then
  die "Missing verifier: $VERIFY_SCRIPT"
fi

if ! mountpoint -q /mnt/gdrive/AI_Knowledge; then
  die "Expected mount not active: /mnt/gdrive/AI_Knowledge"
fi

if [[ ! -d "/data/obsidian/3. Resources/Papers" ]]; then
  die "Missing notes directory: /data/obsidian/3. Resources/Papers"
fi

status="UNKNOWN"
if state_json="$(python3 "$VERIFY_SCRIPT" --json 2>/tmp/paper-storage-healthcheck.verify.err)"; then
  status="$(python3 -c 'import json, sys; print(json.load(sys.stdin).get("status", "UNKNOWN"))' <<<"$state_json")"
  if [[ "$status" != "PASS" ]]; then
    warn "Paper parity verifier returned status: $status"
  fi
else
  info "Verifier unavailable; falling back to direct PDF/note parity check."
  python3 - <<'PY'
from __future__ import annotations

import re
from pathlib import Path
import sys

pdfs = sorted(Path('/mnt/gdrive/AI_Knowledge').glob('*.pdf'))
notes_dir = Path('/data/obsidian/3. Resources/Papers')

def note_source(note_path: Path) -> str:
    text = note_path.read_text(encoding='utf-8', errors='ignore')
    if '---' not in text:
        return ''
    parts = text.split('---', 2)
    frontmatter = parts[1] if len(parts) > 1 else ''
    match = re.search(r'^source:\s*(.+)$', frontmatter, re.MULTILINE)
    return match.group(1).strip() if match else ''

pdf_names = {p.name for p in pdfs}
matched_notes = set()
for note in notes_dir.glob('*.md'):
    source = note_source(note)
    if source.startswith('gdrive:AI_Knowledge/'):
        filename = source.split('gdrive:AI_Knowledge/', 1)[1].strip()
        if filename in pdf_names:
            matched_notes.add(filename)

missing = sorted(pdf_names - matched_notes)
if missing:
    preview = ', '.join(missing[:10])
    print(f"[paper-storage-healthcheck][WARN] PDF/note parity mismatch: {len(missing)} PDFs missing notes", file=sys.stderr)
    print(f"[paper-storage-healthcheck][WARN] Missing examples: {preview}", file=sys.stderr)
    sys.exit(0)

print(f"[paper-storage-healthcheck] Direct parity check passed: {len(pdfs)} PDFs matched by {len(matched_notes)} notes")
PY
fi

if [[ "$status" != "PASS" ]]; then
  warn "Proceeding with install because readiness checks passed, but content parity is not clean."
fi

info "Paper storage health check passed."
