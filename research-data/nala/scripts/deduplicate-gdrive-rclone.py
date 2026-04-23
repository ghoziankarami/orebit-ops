#!/usr/bin/env python3
"""
Deduplicate PDFs in Google Drive AI_Knowledge using rclone (no mount required).

Identifies duplicate base names (ignoring trailing " (N)" suffixes) and deletes
all but the cleanest version.

Usage:
    python3 deduplicate-gdrive-rclone.py [--dry-run]
"""

import json
import re
import subprocess
import sys
import argparse
from collections import defaultdict
from datetime import datetime

RCLONE_BIN = "/usr/local/bin/rclone"
REMOTE = "gdrive:AI_Knowledge"
LOG_FILE = "/var/log/deduplicate-gdrive-rclone.log"

def log(msg: str):
    timestamp = datetime.now().isoformat()
    line = f"[{timestamp}] {msg}"
    print(line)
    with open(LOG_FILE, 'a') as f:
        f.write(line + '\n')

def get_base_name(filename: str) -> str:
    """Extract base name without ANY trailing ' (N)' suffixes."""
    name = filename[:-4] if filename.lower().endswith('.pdf') else filename
    while True:
        match = re.search(r'\s+\(\d+\)$', name)
        if match:
            name = name[:match.start()]
        else:
            break
    return name

def list_all_pdfs():
    """Get list of all PDFs from remote using rclone lsjson."""
    log(f"Fetching PDF list from {REMOTE}...")
    try:
        result = subprocess.run(
            [RCLONE_BIN, "lsjson", "-R", REMOTE, "--files-only"],
            capture_output=True, text=True, timeout=600
        )
        if result.returncode != 0:
            log(f"❌ rclone lsjson failed: {result.stderr}")
            sys.exit(1)
        files = json.loads(result.stdout)
        pdfs = [f for f in files if f['Name'].lower().endswith('.pdf')]
        log(f"Total PDFs found: {len(pdfs)}")
        return pdfs
    except Exception as e:
        log(f"❌ Error listing PDFs: {e}")
        sys.exit(1)

def identify_duplicates(pdf_files):
    """Group PDFs by base name and return dict of duplicates."""
    groups = defaultdict(list)
    for f in pdf_files:
        base = get_base_name(f['Path'])
        groups[base].append(f)
    
    duplicates = {base: files for base, files in groups.items() if len(files) > 1}
    return duplicates, groups

def plan_deletions(duplicates):
    """For each duplicate group, decide which to keep and which to delete."""
    to_delete = []  # list of file paths
    keep = []       # list of files kept
    
    for base, files in duplicates.items():
        # Sort: files without any (N) suffix first, then by numeric suffix ascending
        def sort_key(f):
            name = f['Name']
            match = re.search(r'\((\d+)\)', name)
            if match:
                return (1, int(match.group(1)))
            return (0, 0)
        files.sort(key=sort_key)
        
        keeper = files[0]
        keep.append(keeper)
        to_delete.extend(files[1:])
    
    return to_delete, keep

def write_delete_list(to_delete, filepath):
    """Write list of relative paths to delete into a file for rclone."""
    with open(filepath, 'w') as f:
        for item in to_delete:
            f.write(item['Path'] + '\n')
    log(f"Delete list written: {filepath} ({len(to_delete)} entries)")

def execute_deletion(list_file, dry_run=False):
    """Run rclone delete with the files-from list."""
    cmd = [RCLONE_BIN, "delete", REMOTE, "--files-from", list_file, "--log-file", LOG_FILE]
    if dry_run:
        cmd.append("--dry-run")
    
    log(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        log("✅ Deletion completed successfully")
        if 'dry-run' in cmd:
            log("DRY-RUN: No files were actually deleted")
    else:
        log(f"❌ Deletion failed: {result.stderr}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Deduplicate PDFs in Google Drive AI_Knowledge")
    parser.add_argument('--dry-run', action='store_true', help='Show what would be deleted')
    args = parser.parse_args()
    
    log("="*60)
    log("GDRIVE PDF DEDUPLICATION (rclone mode)")
    log("="*60)
    
    # 1. List all PDFs
    pdf_files = list_all_pdfs()
    
    # 2. Identify duplicates
    duplicates, all_groups = identify_duplicates(pdf_files)
    total_dup_groups = len(duplicates)
    total_dup_files = sum(len(files) for files in duplicates.values())
    log(f"Duplicate groups: {total_dup_groups}")
    log(f"Total duplicate files to delete: {total_dup_files}")
    
    if total_dup_groups == 0:
        log("✅ No duplicates found!")
        return 0
    
    # Show examples
    log("\n📋 Example duplicate groups:")
    for i, (base, files) in enumerate(list(duplicates.items())[:5]):
        log(f"  {base}.pdf: {len(files)} files")
        for f in files[:3]:
            size_mb = f['Size'] / (1024*1024)
            log(f"    - {f['Path']} ({size_mb:.1f} MB)")
        if len(files) > 3:
            log(f"    ... and {len(files)-3} more")
    
    # 3. Plan deletions
    to_delete, keep = plan_deletions(duplicates)
    log(f"\n🗑️ Files to delete: {len(to_delete)}")
    log(f"✅ Files to keep: {len(keep)}")
    
    # 4. Write delete list
    delete_list_file = "/tmp/duplicate-pdfs-to-delete.txt"
    write_delete_list(to_delete, delete_list_file)
    
    # Show top 10 deletions
    log("\nTop 10 files to delete:")
    for item in to_delete[:10]:
        size_mb = item['Size'] / (1024*1024)
        log(f"  - {item['Path']} ({size_mb:.1f} MB)")
    
    # 5. Confirm and execute
    if args.dry_run:
        log("\n🔍 DRY-RUN mode - not deleting anything")
        return 0
    
    log("\n⚠️ PROCEEDING WITH DELETION (irreversible)")
    execute_deletion(delete_list_file, dry_run=False)
    
    # 6. Summary
    log("="*60)
    log("DEDUPLICATION SUMMARY")
    log("="*60)
    log(f"Duplicate groups processed: {total_dup_groups}")
    log(f"Files deleted: {len(to_delete)}")
    # Could compute total size from rclone output, approximate:
    total_size_mb = sum(item['Size'] for item in to_delete) / (1024*1024)
    log(f"Approx space saved: {total_size_mb:.1f} MB ({total_size_mb/1024:.2f} GB)")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
