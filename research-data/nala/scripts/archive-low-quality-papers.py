#!/usr/bin/env python3
"""
Archive low-quality papers — moves to archive/low-quality/ and tags notes.
Runs weekly (Sunday 02:00 WIB) via cron.
"""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from datetime import datetime, timezone, timedelta
import sys

ROOT_DIR = Path(__file__).resolve().parents[3]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from scripts.system.workspace_paths import get_workspace_paths

WORKSPACE = get_workspace_paths().root
TRACKER_DB = WORKSPACE / "research/paper-tracker/papers.json"
GDRIVE_ROOT = Path("/mnt/gdrive/AI_Knowledge")
ARCHIVE_DIR = GDRIVE_ROOT / "archive" / "low-quality"
NOTES_DIR = Path("/data/obsidian/3. Resources/Papers")

def log(msg):
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}")

def load_tracker():
    with open(TRACKER_DB, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_tracker(papers):
    with open(TRACKER_DB, 'w', encoding='utf-8') as f:
        json.dump(papers, f, indent=2, ensure_ascii=False)

def is_low_quality(paper: dict) -> tuple[bool, str]:
    """
    Determine if paper is low-quality based on:
    - From arXiv only (no journal version)
    - Low citation count (<5)
    - Predatory keywords in journal
    - Very old (>20 years) without survey source
    Returns: (is_low, reason)
    """
    journal = paper.get('journal', '').lower()
    source = paper.get('source', '').lower()
    year = paper.get('year', '')
    citations = paper.get('citation_count')
    title = paper.get('title', '').lower()
    
    # Check predatory
    predatory_keywords = ['call for papers', 'special issue', 'reviewed', 'scopus indexed', 'fast publication', 'pay to publish', 'predatory', 'spam', 'unverified']
    for kw in predatory_keywords:
        if kw in journal or kw in title:
            return True, f"Predatory keyword: {kw}"
    
    # arXiv only (and not also in high-impact journal)
    if 'arxiv' in source and not any(dom in journal for dom in ['nature', 'science', 'elsevier', 'springer', 'wiley', 'ieee', 'pnas']):
        return True, "arXiv-only (no journal version)"
    
    # Very old, not from geological survey
    year_str = str(year).strip() if year is not None else ''
    if year_str[:4].isdigit():
        yr = int(year_str[:4])
        if yr < 2005 and not any(s in source for s in ['usgs', 'sgs', 'bgs', 'geoscience']):
            return True, f"Too old ({yr}) and not from geological survey"
    
    # Low citations (if available)
    if citations is not None:
        try:
            cit = int(citations)
            if cit < 5:
                return True, f"Low citations ({cit})"
        except:
            pass
    
    return False, ""

def archive_paper(paper: dict, filename: str, dry_run: bool = False):
    """
    Move PDF from active AI_Knowledge root to archive/low-quality/.
    Update Obsidian note with archived markers.
    """
    src = GDRIVE_ROOT / filename
    if not src.exists():
        log(f"❌ Source missing: {filename}")
        return False

    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
    dst = ARCHIVE_DIR / filename
    counter = 1
    while dst.exists():
        stem = src.stem
        suffix = src.suffix
        dst = ARCHIVE_DIR / f"{stem} ({counter}){suffix}"
        counter += 1

    log(f"Archiving: {filename}")
    if dry_run:
        log(f"[dry-run] Would move {src} -> {dst}")
        return True
    try:
        src.rename(dst)
    except Exception as e:
        log(f"❌ Failed to move {filename}: {e}")
        return False
    
    # 2. Update Obsidian note (if exists)
    note_name = filename.replace('.pdf', '.md')
    note_path = NOTES_DIR / note_name
    if note_path.exists():
        # Read, add tags frontmatter, prepend #archived #low-quality to tags list
        content = note_path.read_text(encoding='utf-8')
        if 'tags:' in content:
            # Insert after tags: line
            lines = content.splitlines(keepends=True)
            new_lines = []
            for i, line in enumerate(lines):
                new_lines.append(line)
                if line.strip().startswith('tags:'):
                    # Append low-quality and archived if not present
                    existing = line.strip()
                    if 'low-quality' not in existing:
                        new_lines.append(line.replace('tags:', 'tags:') + ' low-quality')
                    if 'archived' not in existing:
                        new_lines.append(line.replace('tags:', 'tags:') + ' archived')
            note_path.write_text(''.join(new_lines), encoding='utf-8')
            log(f"✅ Updated note tags: {note_name}")
    
    # 3. Update tracker status
    paper['status'] = 'archived'
    paper['corpus_state'] = 'archived'
    paper['archive_reason'] = 'low-quality'
    paper['archive_location'] = dst.relative_to(GDRIVE_ROOT).as_posix()
    paper['storage_location'] = dst.relative_to(GDRIVE_ROOT).as_posix()
    paper['archived_at'] = datetime.now(timezone.utc).isoformat()
    paper['storage_reconciled_at'] = paper['archived_at']
    return True

def main():
    parser = argparse.ArgumentParser(description="Archive low-quality papers")
    parser.add_argument('--threshold', type=int, default=39, help='Unused compatibility arg for older callers')
    parser.add_argument('--dry-run', action='store_true', help='Preview archive actions without moving files')
    args = parser.parse_args()

    log("🚨 Starting low-quality paper archive scan...")
    papers = load_tracker()
    updated = False
    count = 0
    
    for paper in papers:
        if paper.get('status') in ['archived', 'archived-low-quality']:
            continue
        is_low, reason = is_low_quality(paper)
        if is_low:
            filename = paper.get('filename')
            if not filename:
                continue
            log(f"Low-quality: {filename} — {reason}")
            if archive_paper(paper, filename, dry_run=args.dry_run):
                count += 1
                updated = not args.dry_run or updated

    if updated and not args.dry_run:
        save_tracker(papers)
        log(f"💾 Tracker updated ({count} papers archived)")
    elif args.dry_run:
        log(f"🧪 Dry run complete ({count} papers would be archived)")
    else:
        log("✅ No low-quality papers found to archive")
    
    log("Archive run complete.")

if __name__ == "__main__":
    main()
