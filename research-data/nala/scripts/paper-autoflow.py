#!/usr/bin/env python3
"""
Nala Auto-Paper Pipeline
Fully automated: search topics → add to tracker → filter → download → index → generate notes
Author: Nala (Academic Tutor)
Version: 3.0 (2026-03-21) — with integrated filter system

Canonical workflow: docs/ops/CANONICAL_RAG_RESEARCH_SOP.md
"""

import json
import subprocess
import sys
import time
import argparse
import fcntl
from datetime import datetime, timedelta, timezone
from pathlib import Path
import yaml
import requests
import re
from typing import Dict, List, Optional, Tuple

ROOT_DIR = Path(__file__).resolve().parents[3]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from scripts.system.workspace_paths import get_workspace_paths

# Default configuration
CONFIG_PATH = Path("/workspace/research-data/nala/config/nala-paper-topics.yaml")
PROJECT_SLUG = "pinn-geostat-augmented"
DRY_RUN = False
LIMIT = 0

WORKSPACE = get_workspace_paths().root
PAPER_TRACKER_SCRIPT = WORKSPACE / "scripts/paper-tracker/track-papers.py"
GENERATE_NOTES_SCRIPT = WORKSPACE / "scripts/vector/generate_obsidian_notes_enhanced.py"
VECTOR_PYTHON = Path('/opt/vector_venv/bin/python3')
LOG_FILE = Path("/var/log/nala-paper-autoflow.log")
ACTIVITY_LOG = Path("/var/log/paper-indexing-activity.jsonl")
NEW_PAPERS_REPORT = WORKSPACE / "research/paper-tracker/new-papers-apa.md"
FILTER_CONFIG_PATH = WORKSPACE / "scripts/paper-tracker/paper_filter_config.json"
LOCK_FILE = Path("/tmp/nala-paper-autoflow.lock")

# Legacy fallback filter constants.
# These are used only when the newer filter system is disabled/unavailable.
HIGH_IMPACT_JOURNALS = [
    "nature", "science", "ieee", "acm", "springer", "elsevier",
    "computers & geosciences", "mathematical geosciences", "ore geology reviews",
    "economic geology", "mineral deposits", "natural resources research",
    "engineering geology", "journal of geochemical exploration",
    "international journal of applied earth observation and geoinformation",
    "remote sensing", "expert systems with applications", "neural networks",
    "pattern recognition", "journal of petroleum science and engineering",
]
PREDATORY_KEYWORDS = [
    "predatory", "fake journal", "questionable publisher",
    "ijr", "iosr", "world journal of", "international journal of latest",
]


def _first_list_value(value, default=""):
    if isinstance(value, list):
        for item in value:
            if str(item or "").strip():
                return str(item).strip()
        return default
    return str(value or default).strip()


def _extract_crossref_year(item: dict) -> str:
    for field in ('published-print', 'published-online', 'issued', 'created'):
        date_parts = ((item.get(field) or {}).get('date-parts') or [])
        if date_parts and date_parts[0] and date_parts[0][0]:
            return str(date_parts[0][0])
    return ''


def acquire_run_lock():
    LOCK_FILE.parent.mkdir(parents=True, exist_ok=True)
    handle = LOCK_FILE.open('w')
    try:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        handle.close()
        return None
    handle.write(str(Path(__file__).resolve()))
    handle.flush()
    return handle


def parse_args():
    parser = argparse.ArgumentParser(description="Nala Auto-Paper Pipeline")
    parser.add_argument("--config", type=Path, default=CONFIG_PATH,
                        help="Path to YAML config file")
    parser.add_argument("--project", type=str, default=PROJECT_SLUG,
                        help="Project slug for tracking")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would be done without executing")
    parser.add_argument("--limit", type=int, default=0,
                        help="Limit number of papers to process (testing)")
    parser.add_argument("--enable-filter", action="store_true",
                        help="Enable filter system before download")
    parser.add_argument("--filter-config", type=Path, default=FILTER_CONFIG_PATH,
                        help="Path to filter config JSON")
    parser.add_argument("--filter-dry-run", action="store_true",
                        help="Dry run filter (don't update status)")
    return parser.parse_args()

# Import activity logger
sys.path.insert(0, str(WORKSPACE / "scripts/paper-tracker"))
from log_activity import log_activity
# Import metadata fetcher
from metadata_fetcher import enrich_paper_metadata
from filter_papers_lib import PaperFilter, normalize_paper_record, resolve_filter_config_path
# Import metadata fetcher

def enrich_all_pending_metadata(limit=None):
    """Enrich metadata for all pending papers in the tracker database."""
    import json
    from pathlib import Path
    
    db_path = Path("/workspace/research/paper-tracker/papers.json")
    if not db_path.exists():
        log("❌ Tracker DB not found")
        return 0
    
    with open(db_path) as f:
        papers = json.load(f)
    
    pending = [p for p in papers if p.get("status") == "pending"]
    if not pending:
        log("✅ No pending papers to enrich")
        return 0
    
    to_enrich = pending if limit is None else pending[:limit]
    
    log(f"🔍 Enriching metadata for {len(to_enrich)} pending papers...")
    updated = 0
    for paper in to_enrich:
        original = json.dumps(paper, sort_keys=True, default=str)
        try:
            enrich_paper_metadata(paper)
            metadata = paper.get('metadata') or {}
            if not isinstance(metadata, dict):
                metadata = {}
            metadata.setdefault('title', paper.get('title', ''))
            metadata.setdefault('authors', paper.get('authors', []))
            metadata.setdefault('year', paper.get('year', ''))
            metadata.setdefault('venue', paper.get('journal', ''))
            metadata.setdefault('doi', paper.get('doi', ''))
            if paper.get('abstract') and not metadata.get('abstract'):
                metadata['abstract'] = paper.get('abstract', '')
            paper['metadata'] = metadata
            if json.dumps(paper, sort_keys=True, default=str) != original:
                updated += 1
        except Exception as e:
            log(f"  ⚠️ Error enriching {paper.get('id')}: {e}")
    
    with open(db_path, "w") as f:
        json.dump(papers, f, indent=2)
    
    log(f"✅ Enrichment complete: {updated} papers updated")
    return updated

def log(msg):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_msg = f"[{timestamp}] {msg}"
    print(log_msg)
    with open(LOG_FILE, "a") as f:
        f.write(log_msg + "\n")

def load_config(config_path: Path = CONFIG_PATH):
    """Load YAML config."""
    if not config_path.exists():
        raise FileNotFoundError(f"Config not found: {config_path}")
    
    with open(config_path) as f:
        config = yaml.safe_load(f)
    
    return config

def run_command(cmd, check=True):
    """Run shell command and return exit code."""
    log(f"Running: {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    if result.stdout:
        for line in result.stdout.strip().split('\n'):
            log(f"  OUT: {line}")
    
    if result.stderr:
        for line in result.stderr.strip().split('\n'):
            log(f"  ERR: {line}")
    
    if check and result.returncode != 0:
        raise RuntimeError(f"Command failed: {cmd}\nExit code: {result.returncode}")
    
    return result.returncode

# ============ FILTER INTEGRATION ============
def normalize_paper_for_filter(paper: dict) -> dict:
    """Backward-compatible wrapper around the shared canonical paper normalizer."""
    return normalize_paper_record(paper)

def run_autofilter(config_path: Path, dry_run: bool = False, limit: Optional[int] = None, notify: bool = False) -> Tuple[List[dict], List[dict]]:
    """
    Run filter system on pending papers.
    Returns: (passed_papers, skipped_papers)
    """
    log("🔍 Running autofilter system...")
    
    try:
        # Import filter library
        # Import filter library
        import sys
        sys.path.insert(0, str(Path("/workspace/scripts/paper-tracker")))
        from filter_papers_lib import PaperFilter, resolve_filter_config_path
        
        # Initialize filter
        filter_system = PaperFilter(resolve_filter_config_path(config_path))
        
        # Apply autofilter
        passed, skipped = filter_system.apply_autofilter(
            dry_run=dry_run,
            limit=limit,
            notify=notify
        )
        
        log(f"✅ Autofilter complete: {len(passed)} passed, {len(skipped)} skipped")
        return passed, skipped
        
    except Exception as e:
        log(f"❌ Autofilter failed: {e}")
        import traceback
        log(traceback.format_exc())
        return [], []

def apply_legacy_quality_filter(papers: List[dict]) -> List[dict]:
    """
    Legacy quality filter (from original paper-autoflow.py).
    Used as fallback if filter system is disabled.
    """
    valid_papers = []
    for paper in papers:
        journal = paper.get('journal', '')
        title = paper.get('title', '')
        
        # Check high impact journal whitelist (simplified)
        is_high_impact = False
        if journal:
            journal_lower = journal.lower()
            for keyword in HIGH_IMPACT_JOURNALS:
                if keyword in journal_lower:
                    is_high_impact = True
                    break
        
        # Check predatory signals
        has_predatory = False
        check_text = f"{title} {journal}".lower()
        for keyword in PREDATORY_KEYWORDS:
            if keyword in check_text:
                has_predatory = True
                break
        
        if is_high_impact and not has_predatory:
            valid_papers.append(paper)
        else:
            log(f"  ⏭️ Filtered out: {paper.get('title', 'Unknown')[:50]}... (high_impact={is_high_impact}, predatory={has_predatory})")
    
    log(f"Quality filter: {len(valid_papers)}/{len(papers)} passed")
    return valid_papers
# ============================================

def validate_metadata(paper: Dict, min_citations: int = 5) -> Tuple[bool, str]:
    """
    Validate paper metadata quality.
    NOTE: This is for internal quality scoring, not filtering.
    """
    # Basic checks
    if not paper.get('title'):
        return False, "no title"
    if not paper.get('year'):
        return False, "no year"
    
    # Pipeline policy: public autodownload does not ingest arXiv/preprint sources.
    # They should be handled separately, not mixed into the production paper pipeline.
    journal = paper.get('journal', '')
    if journal:
        journal_lower = journal.lower()
        if any(keyword in journal_lower for keyword in ['arxiv', 'preprint']):
            return False, "preprint source excluded from production pipeline"
    
    return True, "basic validation passed"

def generate_apa_citation(paper: Dict) -> str:
    """Generate APA 7th citation string."""
    authors = paper.get('authors', 'Unknown')
    year = paper.get('year', 'n.d.')
    title = paper.get('title', 'Untitled')
    journal = paper.get('journal', '')
    volume = paper.get('volume', '')
    issue = paper.get('issue', '')
    pages = paper.get('pages', '')
    doi = paper.get('doi', '')
    
    # Format authors
    author_str = authors if ', ' in authors else authors.replace(' and ', ', ')
    
    # Build citation
    citation = f"{author_str} ({year}). {title}."
    if journal:
        citation += f" *{journal}*."
        if volume:
            citation += f" {volume}"
            if issue:
                citation += f"({issue})"
            if pages:
                citation += f", {pages}"
        citation += "."
    if doi:
        citation += f" https://doi.org/{doi}"
    
    return citation

def append_new_papers_report(papers: List[Dict], filenames: List[str]):
    """Append to daily new-papers APA report."""
    NEW_PAPERS_REPORT.parent.mkdir(parents=True, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M WIB")
    with open(NEW_PAPERS_REPORT, "a") as f:
        f.write(f"\n## New Papers — {timestamp}\n\n")
        for paper, fname in zip(papers, filenames):
            citation = generate_apa_citation(paper)
            f.write(f"### {fname}\n")
            f.write(f"{citation}\n\n")
        f.write("---\n\n")

def search_arxiv(topic: str, max_results: int = 5):
    """Search arXiv for papers matching topic."""
    log(f"Searching arXiv for: {topic}")
    
    query = topic.replace(" ", "+")
    url = f"http://export.arxiv.org/api/query?search_query=all:{query}&start=0&max_results={max_results}"
    
    try:
        resp = requests.get(url, timeout=15)
        if resp.status_code != 200:
            log(f"arXiv search failed: HTTP {resp.status_code}")
            return []
        
        import xml.etree.ElementTree as ET
        root = ET.fromstring(resp.text)
        ns = {'atom': 'http://www.w3.org/2005/Atom'}
        
        papers = []
        for entry in root.findall('.//atom:entry', ns):
            try:
                title_elem = entry.find('atom:title', ns)
                summary_elem = entry.find('atom:summary', ns)
                published_elem = entry.find('atom:published', ns)
                author_elems = entry.findall('atom:author/atom:name', ns)
                id_elem = entry.find('atom:id', ns)
                
                if title_elem is None:
                    continue
                
                title = title_elem.text.strip().replace('\n', ' ')
                arxiv_id = id_elem.text.split('/')[-1] if id_elem is not None else None
                url = f"https://arxiv.org/abs/{arxiv_id}" if arxiv_id else None
                pdf_url = f"https://arxiv.org/pdf/{arxiv_id}.pdf" if arxiv_id else None
                
                year = published_elem.text[:4] if published_elem is not None else ""
                authors = [a.text.strip() for a in author_elems]
                
                paper = {
                    'title': title,
                    'arxiv_id': arxiv_id,
                    'url': url,
                    'pdf_url': pdf_url,
                    'year': year,
                    'authors': authors[0] if authors else None,
                    'source': 'arxiv',
                    'journal': 'arXiv'
                }
                papers.append(paper)
            except Exception as e:
                log(f"  Warning: parse error for entry: {e}")
                continue
        
        log(f"Found {len(papers)} papers on arXiv")
        return papers
        
    except Exception as e:
        log(f"arXiv search error: {e}")
        return []


def search_crossref(topic: str, max_results: int = 10):
    """Search Crossref API for papers from all publishers (USGS, Elsevier, Springer, etc.)."""
    log(f"Searching Crossref for: {topic}")
    query = topic.replace(" ", "+")
    url = f"https://api.crossref.org/works?query={query}&rows={max_results}&mailto=research@orebit.id"
    
    try:
        resp = requests.get(url, timeout=15)
        if resp.status_code != 200:
            log(f"Crossref search failed: HTTP {resp.status_code}")
            return []
        
        data = resp.json()
        items = data.get('message', {}).get('items', [])
        papers = []
        for item in items:
            try:
                title = _first_list_value(item.get('title'), 'Untitled')
                doi = item.get('DOI')
                url_item = item.get('URL')
                publisher = item.get('publisher', '')
                
                # Year from published-print / online / issue date
                year = _extract_crossref_year(item)
                
                # Authors: "Family, Given"
                authors_list = []
                for a in item.get('author', []):
                    given = a.get('given', '')
                    family = a.get('family', '')
                    if family:
                        authors_list.append(f"{family}, {given}" if given else family)
                authors = '; '.join(authors_list) if authors_list else None
                
                paper = {
                    'title': title,
                    'doi': doi,
                    'url': url_item,
                    'publisher': publisher,
                    'year': year,
                    'authors': authors,
                    'journal': _first_list_value(item.get('container-title'), publisher),
                    'source': 'crossref'
                }
                papers.append(paper)
            except Exception as e:
                log(f"  Warning: parse Crossref entry: {e}")
                continue
        
        log(f"Found {len(papers)} papers on Crossref")
        return papers
        
    except Exception as e:
        log(f"Crossref search error: {e}")
        return []

def search_papers(topic, max_papers, max_age_days):
    """Search for papers across production sources with quality filter.

    Policy: arXiv/preprint sources are excluded from the production autodownload
    pipeline. We only ingest publisher-indexed candidates here to avoid wasting
    filter/archive effort on sources we already know should not enter the active
    corpus.
    """
    global config
    raw_papers = []

    # Crossref (multi-publisher: USGS, Elsevier, Springer, SGS, etc.)
    crossref_papers = search_crossref(topic, max_papers)
    raw_papers.extend(crossref_papers)

    # TODO: Add other production sources with quality filter
    
    # Apply quality validation (informational only now, filter handled separately)
    valid_papers = []
    for paper in raw_papers:
        is_valid, reason = validate_metadata(paper, min_citations=config.get('min_citations', 5))
        if is_valid:
            valid_papers.append(paper)
        else:
            log(f"  Filtered out: {paper.get('title', 'Unknown')} — {reason}")
    
    log(f"Quality filter: {len(valid_papers)}/{len(raw_papers)} passed")
    return valid_papers

def add_papers_to_tracker(papers, dry_run: bool = False):
    """Add papers directly to tracker database with full metadata (bypass CLI placeholder bug)."""
    import json
    import re
    from pathlib import Path

    def norm(value):
        value = str(value or '').strip().lower()
        value = re.sub(r'\s+', ' ', value)
        return value

    def first_author_surname(authors):
        if isinstance(authors, list):
            first = str(authors[0] if authors else '').strip()
        else:
            first = str(authors or '').strip()
        return norm(first.split()[-1] if first else '')
    
    db_path = WORKSPACE / "research/paper-tracker/papers.json"
    
    # Load existing
    if db_path.exists():
        with open(db_path) as f:
            existing = json.load(f)
    else:
        existing = []

    existing_doi = set()
    existing_url = set()
    existing_pdf_url = set()
    existing_title_year = set()
    existing_author_year = set()
    for row in existing:
        metadata = row.get('metadata') or {}
        title = norm(row.get('title') or metadata.get('title'))
        year = str(row.get('year') or metadata.get('year') or '').strip()
        doi = norm(row.get('doi') or metadata.get('doi'))
        url = norm(row.get('url'))
        pdf_url = norm(row.get('pdf_url'))
        surname = first_author_surname(row.get('authors') or metadata.get('authors'))
        if doi:
            existing_doi.add(doi)
        if url:
            existing_url.add(url)
        if pdf_url:
            existing_pdf_url.add(pdf_url)
        if title and year:
            existing_title_year.add((title, year))
        if surname and year:
            existing_author_year.add((surname, year))
    
    # Add new papers
    added_count = 0
    for paper in papers:
        title = norm(paper.get('title', ''))
        year = str(paper.get('year', '')).strip()
        doi = norm(paper.get('doi', ''))
        url = norm(paper.get('url', ''))
        pdf_url = norm(paper.get('pdf_url', ''))
        surname = first_author_surname(paper.get('authors'))

        placeholder_like = (not title) or title.startswith('paper ')
        exists = (
            (doi and doi in existing_doi) or
            (url and url in existing_url) or
            (pdf_url and pdf_url in existing_pdf_url) or
            ((title, year) in existing_title_year if title and year else False) or
            ((surname, year) in existing_author_year if placeholder_like and surname and year else False)
        )
        
        if exists:
            log(f"  ⏭️ Already exists: {(title or paper.get('title', 'unknown'))[:50]}...")
            continue
        
        # Add metadata and preserve normalized filter fields for downstream stages
        metadata = paper.get('metadata') or {
            'title': paper.get('title', 'Untitled'),
            'authors': paper.get('authors', 'Unknown'),
            'year': paper.get('year', ''),
            'venue': paper.get('journal', ''),
            'doi': paper.get('doi', ''),
            'abstract': paper.get('abstract', ''),
        }
        paper_entry = {
            'id': f"paper_{int(time.time())}_{added_count}",
            'status': 'pending',
            'title': paper.get('title', 'Untitled'),
            'authors': paper.get('authors', 'Unknown'),
            'year': paper.get('year', ''),
            'journal': paper.get('journal', ''),
            'doi': paper.get('doi', ''),
            'url': paper.get('url', ''),
            'pdf_url': paper.get('pdf_url', ''),
            'source': paper.get('source', 'unknown'),
            'metadata': metadata,
            'tags': paper.get('tags', []),
            'notes': '',
            'added_at': datetime.now().isoformat()
        }
        # Enrich metadata (fetch missing fields from DOI/URL)
        try:
            paper_entry = enrich_paper_metadata(paper_entry)
        except Exception as e:
            log(f"  ⚠️ Metadata enrichment failed: {e}")
        existing.append(paper_entry)
        if doi:
            existing_doi.add(doi)
        if url:
            existing_url.add(url)
        if pdf_url:
            existing_pdf_url.add(pdf_url)
        if title and year:
            existing_title_year.add((title, year))
        if surname and year:
            existing_author_year.add((surname, year))
        added_count += 1
        log(f"  ✅ Added to tracker: {title[:50]}...")
    
    if dry_run:
        log(f"[DRY-RUN] Tracker would add {added_count} new papers")
        return added_count

    # Save
    with open(db_path, 'w') as f:
        json.dump(existing, f, indent=2)
    
    log(f"📊 Tracker updated: {added_count} new papers added")
    return added_count

def process_papers_download(papers, project_slug, filter_config_path: Optional[Path] = None) -> int:
    """Download papers using track-papers.py and return how many target papers ended up downloaded."""
    log(f"⬇️  Downloading {len(papers)} papers via track-papers.py...")
    resolved_filter_config = resolve_filter_config_path(filter_config_path)
    
    # Build command: track-papers.py download --project <slug>
    cmd = f"{PAPER_TRACKER_SCRIPT} download --project {project_slug}"
    if resolved_filter_config:
        cmd += f" --filter-config {resolved_filter_config}"
    if DRY_RUN:
        log(f"[DRY-RUN] Would run: {cmd}")
        return len(papers)

    exit_code = run_command(cmd, check=False)
    if exit_code != 0:
        log(f"⚠️ track-papers.py exited with {exit_code}")

    try:
        tracker_rows = json.loads((WORKSPACE / 'research/paper-tracker/papers.json').read_text())
    except Exception as exc:
        log(f"⚠️ Could not read tracker after download: {exc}")
        return 0

    wanted_ids = {p.get('id') for p in papers if p.get('id')}
    wanted_dois = {str(p.get('doi') or '').lower() for p in papers if p.get('doi')}
    downloaded = 0
    for row in tracker_rows:
        if row.get('status') != 'downloaded':
            continue
        row_id = row.get('id')
        row_doi = str(row.get('doi') or '').lower()
        if (row_id and row_id in wanted_ids) or (row_doi and row_doi in wanted_dois):
            downloaded += 1
    log(f"📦 Downloaded target papers: {downloaded}/{len(papers)}")
    return downloaded

def post_process_notes(project_slug: str):
    """Generate Obsidian notes for downloaded papers."""
    log(f"📝 Generating Obsidian notes for project {project_slug}...")
    
    cmd = f"{VECTOR_PYTHON} {GENERATE_NOTES_SCRIPT} --project {project_slug} --llm --index"
    
    if DRY_RUN:
        log(f"[DRY-RUN] Would run: {cmd}")
        return True
    
    exit_code = run_command(cmd, check=False)
    if exit_code != 0:
        log(f"⚠️ Note generation exited with {exit_code}")
    
    return exit_code == 0

def main():
    lock_handle = acquire_run_lock()
    if lock_handle is None:
        log("⚠️ Another paper-autoflow run is already active; skipping overlapping invocation")
        return 0

    try:
        args = parse_args()
        global config
        config = load_config(args.config)
        resolved_filter_config = resolve_filter_config_path(args.filter_config)

        log("="*60)
        log("NALA AUTO-PAPER PIPELINE v3.0")
        log("="*60)
        log(f"Project: {args.project}")
        log(f"Config: {args.config}")
        log(f"Filter config: {resolved_filter_config}")
        log(f"Dry run: {args.dry_run}")
        log(f"Limit: {args.limit if args.limit > 0 else 'unlimited'}")
        log(f"Filter mode: canonical JSON policy (legacy toggle accepted for compatibility: enable_filter={args.enable_filter})")
        log("="*60)

        # Step 1: Search papers
        topics = config.get('topics', [])
        max_papers_per_topic = config.get('max_papers_per_topic', 5)
        max_age_days = config.get('max_age_days', 365*5)

        all_papers = []
        for topic in topics:
            log(f"\n🔍 Searching topic: {topic}")
            papers = search_papers(topic, max_papers_per_topic, max_age_days)
            all_papers.extend(papers)
            time.sleep(1)  # rate limit

        if not all_papers:
            log("❌ No papers found from search")
            return 1

        log(f"\n📊 Total papers found: {len(all_papers)}")

        # Step 1b: Apply canonical filter policy
        log("🔍 Filtering papers using canonical JSON filter system...")
        # Enrich metadata for all searched papers before filtering
        for paper in all_papers:
            try:
                enrich_paper_metadata(paper)
            except Exception as e:
                log(f"  ⚠️ Metadata enrichment failed: {e}")

        filter_system = PaperFilter(resolved_filter_config)
        normalized_papers = [normalize_paper_for_filter(p) for p in all_papers]
        passed_papers, skipped_papers = filter_system.filter_papers_list(normalized_papers)

        if args.limit > 0:
            passed_papers = passed_papers[:args.limit]

        papers_to_add = passed_papers

        log(f"\n🎯 Filter result: {len(papers_to_add)} approved for download")
        if skipped_papers:
            log(f"   ⏭️ Skipped: {len(skipped_papers)} papers (see /var/log/paper-filter.log)")

        if not papers_to_add:
            log("⚠️ No papers passed canonical filter. Nothing to download.")
            return 0

        # Step 2: Add to tracker
        added_count = add_papers_to_tracker(papers_to_add, dry_run=args.dry_run)
        if added_count == 0:
            log("⚠️ No new papers added (all duplicates)")
            return 0

        # Step 3: Download papers
        if not args.dry_run:
            downloaded_count = process_papers_download(papers_to_add, args.project, resolved_filter_config)
            if downloaded_count <= 0:
                log("⚠️ No target papers downloaded; skipping note generation")
                return 0
        else:
            downloaded_count = len(papers_to_add)
            log("[DRY-RUN] Skipping download step")

        # Step 4: Generate Obsidian notes
        if not args.dry_run:
            success = post_process_notes(args.project)
            if not success:
                log("❌ Note generation failed")
                return 1
        else:
            log("[DRY-RUN] Skipping note generation")

        # Step 5: Append report
        filenames = []  # TODO: get actual filenames from download output
        append_new_papers_report(papers_to_add, filenames)

        log("\n✅ Pipeline completed successfully!")
        log(f"📊 Final: {added_count} papers processed")
        log(f"📝 Log: {LOG_FILE}")
        log(f"🔍 Filter log: /var/log/paper-filter.log")
        log(f"📄 Report: {NEW_PAPERS_REPORT}")
        return 0
    finally:
        lock_handle.close()

if __name__ == "__main__":
    sys.exit(main())