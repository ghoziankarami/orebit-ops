#!/usr/bin/env python3
"""
from scripts.system.workspace_paths import get_workspace_paths
Generate Obsidian notes for ALL PDFs in Google Drive AI_Knowledge.

Purpose: Backfill missing literature notes ensuring every PDF has a corresponding note.
This is a one-time batch operation to close the gap between indexed PDFs and notes.

Usage:
  python3 generate-notes-for-all-pdfs.py [--dry-run] [--verbose] [--yes] [--force]

Flags:
  --dry-run    Show what would be generated without actually creating notes
  --verbose    Print detailed progress (forwarded to enhanced script if implemented)
  --yes        Skip confirmation prompt for large batches
  --force      Overwrite existing notes, including those with manual edits (use with care)

Implementation:
- Delegates to scripts/vector/generate_obsidian_notes_enhanced.py with:
  --project all-papers --llm --index
- Enhanced script processes all PDFs in gdrive, skipping existing notes unless overwritten.

SOP: docs/research/PAPER_QUALITY_ARCHIVAL_SOP.md (Phase 1)
"""

import argparse
import subprocess
import sys
from pathlib import Path

# Configuration
ROOT = get_workspace_paths().root
GDRIVE_DIR = Path("/mnt/gdrive/AI_Knowledge")
NOTES_DIR = Path("/data/obsidian/3. Resources/Papers")
GENERATE_SCRIPT = ROOT / "scripts/vector/generate_obsidian_notes_enhanced.py"
PROJECT_SLUG = "all-papers"

def check_dependencies():
    """Verify required paths exist."""
    if not GENERATE_SCRIPT.exists():
        sys.exit(f"❌ Generate script not found: {GENERATE_SCRIPT}")
    if not NOTES_DIR.exists():
        sys.exit(f"❌ NOTES_DIR not found: {NOTES_DIR}")

def get_pdf_files():
    """List all PDF files in gdrive."""
    try:
        pdfs = list(GDRIVE_DIR.glob("*.pdf"))
        pdfs.sort(key=lambda p: p.name.lower())
        return pdfs
    except OSError as e:
        sys.exit(f"❌ Cannot access gdrive mount ({GDRIVE_DIR}): {e}\n"
                 "   Ensure rclone mount is active: mount | grep AI_Knowledge")

def build_existing_set():
    """Build set of PDF filenames that already have a note in the notes directory.
    Scans all notes once and extracts source filename from 'source: gdrive:AI_Knowledge/Filename.pdf'.
    """
    existing = set()
    for note in NOTES_DIR.glob("*.md"):
        try:
            with open(note, 'r', encoding='utf-8', errors='ignore') as f:
                # Read first 100 lines (enough to find frontmatter)
                for i in range(100):
                    line = f.readline()
                    if not line:
                        break
                    if line.strip().startswith('source:'):
                        # Extract filename after last slash or from gdrive path
                        # Example: source: gdrive:AI_Knowledge/Paper.pdf
                        parts = line.strip().split('gdrive:AI_Knowledge/')
                        if len(parts) > 1:
                            filename = parts[1].strip()
                            existing.add(filename)
                            break
        except Exception:
            continue
    return existing

def note_exists(pdf_path: Path, existing_set: set) -> bool:
    """Check if PDF already has a note based on precomputed set."""
    return pdf_path.name in existing_set

def main():
    parser = argparse.ArgumentParser(description="Generate notes for all PDFs in gdrive")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be done without doing it")
    parser.add_argument("--verbose", action="store_true", help="Print detailed progress")
    parser.add_argument("--yes", "-y", action="store_true", help="Skip confirmation prompt")
    parser.add_argument("--force", action="store_true", help="Overwrite existing notes (including manually edited ones)")
    args = parser.parse_args()

    check_dependencies()
    pdfs = get_pdf_files()
    total_pdfs = len(pdfs)

    # Build set of existing PDFs (fast lookup)
    existing_set = build_existing_set()
    existing = sum(1 for pdf in pdfs if pdf.name in existing_set)
    missing = total_pdfs - existing

    print(f"📊 Status:")
    print(f"   Total PDFs in gdrive: {total_pdfs}")
    print(f"   Existing notes (with source ref): {existing}")
    print(f"   Missing notes: {missing}")
    print()

    if missing == 0:
        print("✅ All PDFs already have notes. Nothing to do.")
        return 0

    if args.dry_run:
        print("🔍 Dry run — showing PDFs that would be processed:")
        for pdf in pdfs:
            if pdf.name not in existing_set:
                print(f"  - {pdf.name}")
        print(f"\nWould generate {missing} notes with LLM summaries and RAG indexing.")
        return 0

    # Confirm before proceeding
    if missing > 20 and not args.yes:
        resp = input(f"⚠️  Will generate {missing} notes. Continue? (y/N): ").strip().lower()
        if resp != 'y':
            print("Aborted.")
            return 1

    # Invoke enhanced script with proper arguments
    print("🚀 Invoking enhanced note generator (LLM + RAG index)...")
    cmd = [
        sys.executable,
        str(GENERATE_SCRIPT),
        "--project", PROJECT_SLUG,
        "--llm",
        "--index"
    ]
    if args.force:
        cmd.append("--overwrite")
    try:
        # Forward stdout/stderr directly to show real-time progress
        result = subprocess.run(cmd, check=True)
        print("\n✅ Enhanced script completed successfully.")
        return 0
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Enhanced script failed with exit code {e.returncode}")
        return e.returncode

if __name__ == "__main__":
    sys.exit(main())
