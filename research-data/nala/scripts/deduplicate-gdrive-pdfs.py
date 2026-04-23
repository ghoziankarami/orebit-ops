#!/usr/bin/env python3
"""
Deduplicate PDFs in Google Drive AI_Knowledge folder.

Removes duplicate files with pattern: filename (1).pdf, filename (2).pdf etc.
Keeps the cleanest filename (no suffix or lowest number if clean doesn't exist).

Usage:
    python3 deduplicate-gdrive-pdfs.py [--dry-run]
"""

import os
import re
import sys
import argparse
from pathlib import Path
from datetime import datetime
import subprocess

MOUNT_POINT = Path("/mnt/gdrive/AI_Knowledge")
LOG_FILE = Path("/var/log/deduplicate-gdrive.log")

def log(msg: str):
    timestamp = datetime.now().isoformat()
    line = f"[{timestamp}] {msg}"
    print(line)
    with open(LOG_FILE, 'a') as f:
        f.write(line + '\n')

def get_base_name(filename: str) -> str:
    """Extract base name without ANY (N) suffixes and extension."""
    # Remove .pdf extension
    name = filename[:-4] if filename.endswith('.pdf') else filename
    # Remove ALL trailing " (number)" patterns (e.g., " (1) (2) (3)")
    while True:
        match = re.search(r'\s+\(\d+\)$', name)
        if match:
            name = name[:match.start()]
        else:
            break
    return name

def find_duplicates():
    """Find all PDFs and group by base name."""
    pdf_files = [f for f in MOUNT_POINT.iterdir() if f.suffix == '.pdf']
    
    # Group by base name
    groups = {}
    for pdf in pdf_files:
        base = get_base_name(pdf.name)
        if base not in groups:
            groups[base] = []
        groups[base].append(pdf)
    
    # Find groups with duplicates
    duplicates = {base: files for base, files in groups.items() if len(files) > 1}
    return duplicates

def delete_file(filepath: Path, dry_run: bool = True):
    """Delete a file from mount point (actually deletes in gdrive)."""
    if dry_run:
        log(f"  [DRY-RUN] Would delete: {filepath.name}")
        return True
    
    try:
        os.remove(filepath)
        log(f"  ✅ Deleted: {filepath.name}")
        return True
    except Exception as e:
        log(f"  ❌ Failed to delete {filepath.name}: {e}")
        return False

def deduplicate(duplicates: dict, dry_run: bool = True) -> tuple:
    """
    For each duplicate group, keep the cleanest file and delete others.
    
    Returns: (files_deleted, space_saved_mb)
    """
    deleted = 0
    space_saved = 0
    
    for base_name, files in duplicates.items():
        # Sort: files without (N) first, then by number
        def sort_key(f):
            match = re.search(r'\((\d+)\)', f.name)
            if match:
                return (1, int(match.group(1)))  # (1), (2), etc.
            return (0, 0)  # Clean name has priority
        
        files.sort(key=sort_key)
        
        # Keep first (cleanest), delete rest
        to_keep = files[0]
        to_delete = files[1:]
        
        log(f"\n📦 {base_name}.pdf:")
        log(f"  Keep: {to_keep.name}")
        
        for f in to_delete:
            size_mb = f.stat().st_size / (1024 * 1024)
            if delete_file(f, dry_run):
                deleted += 1
                space_saved += size_mb
    
    return deleted, space_saved

def main():
    parser = argparse.ArgumentParser(description="Deduplicate PDFs in gdrive")
    parser.add_argument('--dry-run', action='store_true', help='Show what would be deleted')
    args = parser.parse_args()
    
    log("="*60)
    log("GDRIVE PDF DEDUPLICATION")
    log("="*60)
    
    if not MOUNT_POINT.exists():
        log(f"❌ Mount point not found: {MOUNT_POINT}")
        log("Run: /workspace/scripts/system/check-gdrive-mount.sh")
        return 1
    
    # Find duplicates
    duplicates = find_duplicates()
    
    total_dup_groups = len(duplicates)
    total_dup_files = sum(len(files) for files in duplicates.values())
    
    log(f"\n📊 Found {total_dup_groups} duplicate groups")
    log(f"   Total duplicate files: {total_dup_files}")
    log(f"   Unique base names: {total_dup_groups}")
    
    if total_dup_groups == 0:
        log("✅ No duplicates found!")
        return 0
    
    # Show some examples
    log("\n📋 Examples:")
    for i, (base, files) in enumerate(list(duplicates.items())[:5]):
        log(f"  {base}.pdf: {len(files)} files")
        for f in files:
            size = f.stat().st_size / 1024 / 1024
            log(f"    - {f.name} ({size:.1f} MB)")
    
    # Deduplicate
    log(f"\n{'='*60}")
    log("DEDUPLICATING..." if not args.dry_run else "DRY-RUN (no deletions)")
    log("="*60)
    
    deleted, space_saved = deduplicate(duplicates, args.dry_run)
    
    log(f"\n{'='*60}")
    log("SUMMARY")
    log("="*60)
    log(f"Duplicate groups: {total_dup_groups}")
    log(f"Files deleted: {deleted}")
    log(f"Space saved: {space_saved:.1f} MB ({space_saved/1024:.2f} GB)")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
