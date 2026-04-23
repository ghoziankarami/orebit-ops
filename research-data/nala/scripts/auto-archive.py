#!/usr/bin/env python3
"""
Auto-archive workflow: Score quality + archive low-quality papers automatically.

Usage:
    python3 auto-archive.py [--dry-run] [--min-promote 70] [--max-archive 39]

Workflow:
    1. Run quality scoring on pending papers (if not scored)
    2. Promote HIGH quality papers (score >= 70)
    3. Archive LOW quality papers (score <= 39)
    4. Leave MEDIUM quality for manual review

This is designed to run via cron (e.g., daily at 02:00).
"""

import subprocess
import sys
import argparse
from pathlib import Path
from datetime import datetime

LOG_FILE = Path("/var/log/paper-auto-archive.log")

def log(msg: str):
    timestamp = datetime.now().isoformat()
    line = f"[{timestamp}] {msg}"
    print(line)
    with open(LOG_FILE, 'a') as f:
        f.write(line + '\n')

def run_script(script_path: Path, args: list) -> int:
    """Run a script and return exit code."""
    cmd = [sys.executable, str(script_path)] + args
    log(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.stdout:
        log(result.stdout.strip())
    if result.stderr:
        log(f"STDERR: {result.stderr.strip()}")
    return result.returncode

def main():
    parser = argparse.ArgumentParser(description="Auto-archive workflow")
    parser.add_argument('--min-promote', type=int, default=70,
                        help='Min score to promote (default: 70)')
    parser.add_argument('--max-archive', type=int, default=999,
                        help='Max score to archive (default: 999 = disabled until metadata ready)')
    parser.add_argument('--dry-run', action='store_true',
                        help='Dry run - no changes')
    parser.add_argument('--no-quality-score', action='store_true',
                        help='Skip quality scoring (assume already scored)')
    args = parser.parse_args()
    
    BASE_DIR = Path(__file__).resolve().parent
    
    log("="*60)
    log("AUTO-ARCHIVE WORKFLOW")
    log(f"min_promote={args.min_promote}, max_archive={args.max_archive}, dry_run={args.dry_run}")
    log("="*60)
    
    exit_code = 0
    
    # Step 1: Quality scoring
    if not args.no_quality_score:
        log("\n[STEP 1] Running quality scoring...")
        quality_script = BASE_DIR / "quality-score.py"
        if quality_script.exists():
            result = run_script(quality_script, ['--dry-run'] if args.dry_run else [])
            if result != 0:
                log(f"⚠️ Quality scoring returned {result}")
                exit_code = 1
        else:
            log(f"⚠️ Quality scoring script not found: {quality_script}")
    
    # Step 2: Promote high quality
    log("\n[STEP 2] Promoting high-quality papers...")
    promote_script = BASE_DIR / "promote-papers.py"
    if promote_script.exists():
        promote_args = ['--min-score', str(args.min_promote)]
        if args.dry_run:
            promote_args.append('--dry-run')
        result = run_script(promote_script, promote_args)
        if result != 0:
            log(f"⚠️ Promote returned {result}")
    else:
        log(f"⚠️ Promote script not found: {promote_script}")
    
    # Step 3: Archive low quality
    log("\n[STEP 3] Archiving low-quality papers...")
    archive_script = BASE_DIR / "archive-low-quality-papers.py"
    if archive_script.exists():
        archive_args = ['--threshold', str(args.max_archive)]
        if args.dry_run:
            archive_args.append('--dry-run')
        result = run_script(archive_script, archive_args)
        if result != 0:
            log(f"⚠️ Archive returned {result}")
    else:
        log(f"⚠️ Archive script not found: {archive_script}")
    
    log("\n" + "="*60)
    log("AUTO-ARCHIVE COMPLETE")
    log("="*60)
    
    return exit_code

if __name__ == "__main__":
    sys.exit(main())
