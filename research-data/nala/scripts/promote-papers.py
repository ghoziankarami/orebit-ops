#!/usr/bin/env python3
"""
Promote high-quality papers from pending to ready-for-download queue.

Usage:
    python3 promote-papers.py [--dry-run] [--min-score 70]

Workflow:
    1. Load papers from tracker database
    2. Filter pending papers with quality_score >= threshold
    3. Mark them as 'promoted' status
    4. (Optional) Trigger immediate download for promoted papers

Related: quality-score.py (generates scores), archive-papers.py (handles low quality)
"""

import json
import sys
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional

# Config
DB_PATH = Path("/workspace/research/paper-tracker/papers.json")
LOG_FILE = Path("/var/log/paper-promote.log")

def log(msg: str):
    timestamp = datetime.now().isoformat()
    line = f"[{timestamp}] {msg}"
    print(line)
    with open(LOG_FILE, 'a') as f:
        f.write(line + '\n')

def load_papers() -> list:
    """Load papers from tracker database."""
    if not DB_PATH.exists():
        log(f"❌ Database not found: {DB_PATH}")
        return []
    with open(DB_PATH, 'r') as f:
        return json.load(f)  # Returns list

def save_papers(papers: list):
    """Save papers back to database."""
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(DB_PATH, 'w') as f:
        json.dump(papers, f, indent=2, ensure_ascii=False)
    log(f"💾 Saved {len(papers)} papers to database")

def promote_papers(papers: list, min_score: int = 70, dry_run: bool = False) -> tuple:
    """
    Promote papers with quality_score >= min_score.
    
    Returns: (promoted_count, already_promoted, skipped_count)
    """
    promoted = 0
    already_promoted = 0
    skipped = 0
    
    for paper in papers:
        # Skip non-pending papers
        if paper.get('status') != 'pending':
            continue
            
        quality_score = paper.get('quality_score')
        
        # Skip if no quality score
        if quality_score is None:
            skipped += 1
            continue
            
        if quality_score >= min_score:
            if paper.get('promoted'):
                already_promoted += 1
            else:
                if not dry_run:
                    paper['promoted'] = True
                    paper['promoted_at'] = datetime.now().isoformat()
                    paper['status'] = 'ready'  # Ready for download
                promoted += 1
                log(f"⬆️ Promoted: {paper.get('title', 'Unknown')[:60]}... (score: {quality_score})")
    
    return promoted, already_promoted, skipped

def main():
    parser = argparse.ArgumentParser(description="Promote high-quality papers")
    parser.add_argument('--min-score', type=int, default=70,
                        help='Minimum quality score to promote (default: 70)')
    parser.add_argument('--dry-run', action='store_true',
                        help='Show what would be promoted without making changes')
    args = parser.parse_args()
    
    log("="*60)
    log(f"Starting paper promotion (min_score={args.min_score}, dry_run={args.dry_run})")
    
    # Load papers
    papers = load_papers()
    if not papers:
        log("❌ No papers loaded")
        return 1
    
    log(f"📚 Loaded {len(papers)} papers from database")
    
    # Count current states
    pending = sum(1 for p in papers if p.get('status') == 'pending')
    promoted = sum(1 for p in papers if p.get('promoted'))
    log(f"📊 Current: {pending} pending, {promoted} promoted")
    
    # Promote papers
    new_promoted, already_promoted, skipped = promote_papers(
        papers, 
        min_score=args.min_score,
        dry_run=args.dry_run
    )
    
    # Summary
    log("-"*60)
    log(f"✅ Newly promoted: {new_promoted}")
    log(f"✓ Already promoted: {already_promoted}")
    log(f"⚠️ Skipped (no score): {skipped}")
    
    # Save if not dry run
    if not args.dry_run and new_promoted > 0:
        save_papers(papers)
        log(f"💾 Saved changes to database")
    
    log("="*60)
    return 0

if __name__ == "__main__":
    sys.exit(main())
