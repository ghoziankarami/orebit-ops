#!/usr/bin/env python3
"""
Calculate quality score for papers in tracker.
Score range: 0-100 based on:
- Citations (0-40)
- Journal impact (0-30)
- Recency (0-20)
- Source type (0-10)

Usage:
    python3 quality-score.py [--dry-run]

Updates papers.json with quality_score field.
"""

import json
import sys
import argparse
import re
from pathlib import Path
from datetime import datetime, timedelta

# Config
DB_PATH = Path("/workspace/research/paper-tracker/papers.json")
LOG_FILE = Path("/var/log/quality-score.log")

# Journal impact scoring (simplified)
HIGH_IMPACT = {
    'nature', 'science', 'cell', 'pnas', 'ijc', 'ijfcs', 'geostatistics',
    'computers & geosciences', 'journal of computational physics', 'neural networks',
    'international conference on machine learning', 'icml', 'neurips', 'iclr',
    'ieee transactions', 'springer', 'elsevier',
    'mdpi', 'frontiers', 'wiley', 'usgs', 'sgs', 'bgs', 'geoscience australia',
    'aapg', 'seg', 'eage', 'soc expl geophys'
}
MID_IMPACT = {
    'journal of geophysics', 'geophysical prospecting', 'pure and applied geophysics',
    'tectonics', 'gji', 'geology', 'gsw', 'aapg bulletin',
    'proceedings of the', 'acm', 'aaai', 'ijcnn', 'pattern recognition'
}

def log(msg: str):
    timestamp = datetime.now().isoformat()
    line = f"[{timestamp}] {msg}"
    print(line)
    with open(LOG_FILE, 'a') as f:
        f.write(line + '\n')

def load_papers() -> list:
    if not DB_PATH.exists():
        log(f"❌ Database not found: {DB_PATH}")
        return []
    with open(DB_PATH, 'r') as f:
        return json.load(f)

def save_papers(papers: list):
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(DB_PATH, 'w') as f:
        json.dump(papers, f, indent=2, ensure_ascii=False)
    log(f"💾 Saved {len(papers)} papers")

def score_citations(citations: int) -> int:
    """0-40 points based on citation count."""
    if citations is None:
        return 0
    try:
        c = int(citations)
        if c >= 500:
            return 40
        elif c >= 200:
            return 30
        elif c >= 100:
            return 20
        elif c >= 50:
            return 10
        elif c >= 10:
            return 5
        else:
            return 0
    except:
        return 0

def score_journal_func(journal: str) -> int:
    """0-30 points based on journal impact."""
    if not journal:
        return 0
    journal_lower = journal.lower()
    for high in HIGH_IMPACT:
        if high in journal_lower:
            return 30
    for mid in MID_IMPACT:
        if mid in journal_lower:
            return 20
    return 5  # Unknown/low-tier journal still gets some points if other criteria met

def score_recency(year: str) -> int:
    """0-20 points based on publication year."""
    if year is None:
        return 0
    year_str = str(year).strip()
    if not year_str:
        return 0
    year_match = year_str[:4]
    if not year_match.isdigit():
        return 0
    pub_year = int(year_match)
    current_year = datetime.now().year
    age = current_year - pub_year
    if age <= 2:
        return 20
    elif age <= 5:
        return 15
    elif age <= 10:
        return 10
    elif age <= 20:
        return 5
    else:
        return 0

def score_source(source: str) -> int:
    """0-10 points based on source type."""
    if not source:
        return 0
    source_lower = source.lower()
    if 'arxiv.org' in source_lower:
        return 5  # Preprint gets lower points
    elif any(x in source_lower for x in ['doi.org', 'crossref', 'pubmed']):
        return 10
    elif any(x in source_lower for x in ['usgs.gov', 'bgs.ac.uk', 'ga.gov.au']):
        return 8  # Government survey gets solid points
    else:
        return 5

def infer_year(paper: dict):
    """Best-effort year inference from sparse metadata."""
    current_year = datetime.now().year
    for value in (
        paper.get('year'),
        paper.get('journal'),
        paper.get('title'),
        paper.get('source'),
    ):
        if value is None:
            continue
        text = str(value)
        matches = re.findall(r'(19\d{2}|20\d{2}|21\d{2})', text)
        for match in matches:
            year = int(match)
            if 1900 <= year <= current_year + 1:
                return year
    return None


def normalized_component_score(points: float, max_points: float) -> float:
    if max_points <= 0:
        return 0.0
    return max(0.0, min(points / max_points, 1.0))


def calculate_quality_score(paper: dict) -> float:
    """Calculate overall quality score 0-100."""
    citations = paper.get('citation_count') or paper.get('citations')
    journal = paper.get('journal', '')
    year = infer_year(paper)
    source = paper.get('source', '')
    
    # Weights
    w_cit = 0.40
    w_journ = 0.30
    w_rec = 0.20
    w_src = 0.10
    
    cit_pts = score_citations(citations)
    jour_pts = score_journal_func(journal)
    rec_pts = score_recency(year)
    src_pts = score_source(source)
    
    total = 100 * (
        normalized_component_score(cit_pts, 40) * w_cit +
        normalized_component_score(jour_pts, 30) * w_journ +
        normalized_component_score(rec_pts, 20) * w_rec +
        normalized_component_score(src_pts, 10) * w_src
    )
    
    # Boost if has DOI and journal (indicates proper publication)
    if paper.get('doi') and journal:
        total += 5

    # Modest fallback boosts for sparse but credible publication metadata.
    if paper.get('doi') and not source:
        total += 5
    if journal and not citations:
        total += 5
    
    # Cap at 100
    return min(total, 100.0)

def main():
    parser = argparse.ArgumentParser(description="Calculate quality scores for papers")
    parser.add_argument('--dry-run', action='store_true',
                        help='Show scores without saving')
    args = parser.parse_args()
    
    log("="*60)
    log("QUALITY SCORING STARTED")
    log("="*60)
    
    papers = load_papers()
    if not papers:
        log("❌ No papers to score")
        return 1
    
    # Stats
    total = len(papers)
    scored_prev = sum(1 for p in papers if 'quality_score' in p)
    log(f"📚 Total papers: {total}")
    log(f"📊 Already scored: {scored_prev}")
    
    # Score papers
    updated = 0
    scores = []
    
    for paper in papers:
        if 'quality_score' in paper and not args.dry_run:
            continue  # Skip already scored unless dry-run
            
        score = calculate_quality_score(paper)
        scores.append(score)
        paper['quality_score'] = round(score, 2)
        updated += 1
        
        if args.dry_run and updated <= 5:
            log(f"  {paper.get('title', 'Unknown')[:50]}... -> {score:.1f}")
    
    # Summary statistics
    if scores:
        avg = sum(scores) / len(scores)
        high = sum(1 for s in scores if s >= 70)
        medium = sum(1 for s in scores if 40 <= s < 70)
        low = sum(1 for s in scores if s < 40)
        
        log("\n📈 SCORE DISTRIBUTION:")
        log(f"  High (≥70): {high} ({high/total*100:.1f}%)")
        log(f"  Medium (40-69): {medium} ({medium/total*100:.1f}%)")
        log(f"  Low (<40): {low} ({low/total*100:.1f}%)")
        log(f"  Average: {avg:.1f}")
    
    log(f"\n✅ Updated {updated} papers with quality_score")
    
    # Save
    if not args.dry_run and updated > 0:
        save_papers(papers)
    
    log("="*60)
    return 0

if __name__ == "__main__":
    sys.exit(main())
