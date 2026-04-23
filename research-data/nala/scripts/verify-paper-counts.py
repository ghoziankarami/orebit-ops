#!/usr/bin/env python3
"""
Verify peer-reviewed PDF parity, arXiv separation, and RAG coverage.

Canonical contract:
- Peer-reviewed active PDFs in Google Drive should match active Obsidian paper summary notes.
- arXiv items should be traceable/indexed separately and must not remain in the downloaded-PDF lane.
- Outputs a machine-readable state for health/reporting surfaces.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

import yaml

ROOT_DIR = Path(__file__).resolve().parents[3]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from scripts.system.workspace_paths import get_workspace_paths
from scripts.vector.validate_paper_notes import is_gdrive_note

ROOT = get_workspace_paths().root
GDRIVE_MOUNT = Path('/mnt/gdrive/AI_Knowledge')
OBSIDIAN_PAPERS = Path('/data/obsidian/3. Resources/Papers')
TRACKER_DB = ROOT / 'research/paper-tracker/papers.json'
PAPERS_DB = ROOT / '.vector_db' / 'papers' / 'chroma.sqlite3'
WORKSPACE_DB = ROOT / '.vector_db' / 'workspace' / 'chroma.sqlite3'
STATE_PATH = ROOT / '.state' / 'paper_count_parity.json'
REPAIR_QUEUE_PATH = ROOT / '.state' / 'paper_note_repair_queue.json'
MANUAL_RECOVERY_PATH = ROOT / '.state' / 'paper_manual_recovery_queue.json'
LOG_FILE = Path('/var/log/paper-counts-verify.log')


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z')


def log(msg: str) -> None:
    line = f"[{now_iso()}] {msg}"
    print(line)
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    with LOG_FILE.open('a', encoding='utf-8') as f:
        f.write(line + '\n')


def parse_frontmatter(note_path: Path) -> dict:
    text = note_path.read_text(encoding='utf-8', errors='ignore')
    if '---' not in text:
        return {}
    parts = text.split('---', 2)
    front = parts[1] if len(parts) >= 2 else ''
    data = yaml.safe_load(front)
    return data if isinstance(data, dict) else {}


def load_tracker() -> list[dict]:
    if not TRACKER_DB.exists():
        return []
    return json.loads(TRACKER_DB.read_text(encoding='utf-8'))


def is_arxiv_row(row: dict) -> bool:
    url = str(row.get('url') or '')
    return 'arxiv.org/abs/' in url or str(row.get('source_type') or '') == 'arxiv' or str(row.get('doc_type') or '') == 'arxiv'


def download_attempted(row: dict) -> bool:
    if is_arxiv_row(row):
        return False
    status = str(row.get('status') or '').lower()
    pending_reason = str(row.get('pending_reason') or '')
    resolver_status = str(row.get('resolver_status') or '')
    return status == 'downloaded' or pending_reason.startswith('download_http_') or pending_reason in {
        'resolved_to_html_not_pdf',
        'manual_download_needed',
        'download_exception',
        'downloaded_file_too_small',
        'no_direct_pdf_url',
    } or resolver_status == 'manual_download_needed'


def tracker_split(papers: list[dict]) -> dict:
    peer_downloaded = []
    arxiv_downloaded = []
    pending_arxiv = []
    peer_download_attempted_rows = []
    outcome_counts = {
        'attempted': 0,
        'downloaded': 0,
        'blocked_403': 0,
        'resolved_html_only': 0,
        'manual_download_needed': 0,
        'other_download_failure': 0,
    }
    for row in papers:
        is_arxiv = is_arxiv_row(row)
        if is_arxiv and row.get('status') == 'pending':
            pending_arxiv.append(row)
        if row.get('status') == 'downloaded':
            if is_arxiv:
                arxiv_downloaded.append(row)
            else:
                peer_downloaded.append(row)
        if download_attempted(row):
            peer_download_attempted_rows.append(row)
            outcome_counts['attempted'] += 1
        if not is_arxiv and str(row.get('status') or '').lower() == 'downloaded':
            outcome_counts['downloaded'] += 1
        pending_reason = str(row.get('pending_reason') or '')
        resolver_status = str(row.get('resolver_status') or '')
        row_status = str(row.get('status') or '').lower()
        if row_status == 'pending' and pending_reason.startswith('download_http_403'):
            outcome_counts['blocked_403'] += 1
        if row_status == 'pending' and pending_reason == 'resolved_to_html_not_pdf':
            outcome_counts['resolved_html_only'] += 1
        if row_status == 'pending' and (pending_reason == 'manual_download_needed' or resolver_status == 'manual_download_needed'):
            outcome_counts['manual_download_needed'] += 1
        if row_status == 'pending' and (pending_reason.startswith('download_http_') or pending_reason in {
            'download_exception',
            'downloaded_file_too_small',
            'no_direct_pdf_url',
        }):
            outcome_counts['other_download_failure'] += 1
    return {
        'peer_downloaded': peer_downloaded,
        'arxiv_downloaded': arxiv_downloaded,
        'pending_arxiv': pending_arxiv,
        'peer_download_attempted_rows': peer_download_attempted_rows,
        'download_outcomes': outcome_counts,
    }


def count_active_pdfs() -> int:
    if not GDRIVE_MOUNT.exists():
        return 0
    return len(list(GDRIVE_MOUNT.glob('*.pdf')))


def canonical_pdf_filename_from_source(source: str) -> str | None:
    if not source:
        return None
    prefix = 'gdrive:AI_Knowledge/'
    if not str(source).startswith(prefix):
        return None
    return str(source)[len(prefix):].strip() or None


def classify_gold_notes() -> dict:
    active_pdf_names = {p.name for p in GDRIVE_MOUNT.glob('*.pdf')} if GDRIVE_MOUNT.exists() else set()
    active_summary_notes = []
    active_gold_notes = []
    orphan_gold = []
    arxiv_notes = []
    other_notes = []
    repair_queue = []

    if not OBSIDIAN_PAPERS.exists():
        return {
            'active_summary_notes': active_summary_notes,
            'active_gold_notes': active_gold_notes,
            'orphan_gold_notes': orphan_gold,
            'arxiv_notes': arxiv_notes,
            'other_notes': other_notes,
            'repair_queue': repair_queue,
        }

    for note in OBSIDIAN_PAPERS.glob('*.md'):
        fm = parse_frontmatter(note)
        source = str(fm.get('source') or '')
        doc_type = str(fm.get('doc_type') or fm.get('type') or '').strip().lower()
        filename = canonical_pdf_filename_from_source(source)
        is_gold = is_gdrive_note(note)
        record = {'note': note.name, 'source': source, 'filename': filename}

        if filename and filename in active_pdf_names:
            active_summary_notes.append(record)
            if is_gold:
                active_gold_notes.append(record)
            else:
                repair_queue.append({
                    'pdf_filename': filename,
                    'note_name': note.name,
                    'reason': 'legacy_or_non_gold_note',
                    'source': source,
                })
            continue

        if is_gold:
            orphan_gold.append(record)
            continue

        if source.startswith('arxiv:') or doc_type == 'arxiv':
            arxiv_notes.append(note)
            continue

        other_notes.append(note)

    matched = {item['pdf_filename'] for item in repair_queue}
    summary_matched = {item['filename'] for item in active_summary_notes if item.get('filename')}
    for pdf_name in sorted(active_pdf_names):
        if pdf_name in summary_matched or pdf_name in matched:
            continue
        repair_queue.append({
            'pdf_filename': pdf_name,
            'note_name': None,
            'reason': 'missing_note',
            'source': f'gdrive:AI_Knowledge/{pdf_name}',
        })

    repair_queue.sort(key=lambda item: (item['reason'], item['pdf_filename']))
    return {
        'active_summary_notes': active_summary_notes,
        'active_gold_notes': active_gold_notes,
        'orphan_gold_notes': orphan_gold,
        'arxiv_notes': arxiv_notes,
        'other_notes': other_notes,
        'repair_queue': repair_queue,
    }


def count_sqlite_distinct(db_path: Path, query: str, params: tuple = ()) -> int:
    if not db_path.exists():
        return 0
    conn = sqlite3.connect(str(db_path))
    cur = conn.cursor()
    cur.execute(query, params)
    row = cur.fetchone()
    conn.close()
    return int((row or [0])[0] or 0)


def fetch_sqlite_distinct_strings(db_path: Path, query: str, params: tuple = ()) -> set[str]:
    if not db_path.exists():
        return set()
    conn = sqlite3.connect(str(db_path))
    cur = conn.cursor()
    cur.execute(query, params)
    rows = {str(row[0]) for row in cur.fetchall() if row and row[0]}
    conn.close()
    return rows


def canonicalize_pdf_source(value: str) -> str:
    text = str(value or '').strip()
    prefix = 'gdrive:AI_Knowledge/'
    if text.startswith(prefix):
        return text[len(prefix):]
    return Path(text).name if text else ''


def rag_counts() -> dict:
    active_pdf_names = {p.name for p in GDRIVE_MOUNT.glob('*.pdf')} if GDRIVE_MOUNT.exists() else set()
    peer_sources = fetch_sqlite_distinct_strings(
        PAPERS_DB,
        "SELECT DISTINCT string_value FROM embedding_metadata WHERE key='source'"
    )
    peer_fulltext = len({canonicalize_pdf_source(value) for value in peer_sources} & active_pdf_names)
    arxiv_workspace = count_sqlite_distinct(
        WORKSPACE_DB,
        "SELECT COUNT(DISTINCT string_value) FROM embedding_metadata WHERE key='source' AND string_value LIKE 'arxiv:%'"
    )
    paper_notes_workspace = count_sqlite_distinct(
        WORKSPACE_DB,
        "SELECT COUNT(DISTINCT string_value) FROM embedding_metadata WHERE key='source' AND string_value LIKE 'data/obsidian/3. Resources/Papers/%'"
    )
    return {
        'peer_fulltext_rag': peer_fulltext,
        'arxiv_workspace_rag': arxiv_workspace,
        'paper_notes_workspace_rag': paper_notes_workspace,
    }


def oa_recommendation(row: dict, publisher: str, reason: str) -> dict:
    candidates = [str(c) for c in (row.get('resolver_candidates') or [])]
    blob = ' '.join(candidates + [str(row.get('pdf_url') or ''), str(row.get('url') or ''), str(row.get('resolver_landing_url') or '')]).lower()
    if 'idisnotopenaccess' in blob:
        return {'tier': 'dead_end', 'score': 0, 'recommended_action': 'skip_non_oa_record', 'next_try_url': row.get('resolver_landing_url') or row.get('url'), 'rationale': 'Traceable record exists but OA subset says non-open-access.'}
    if publisher == 'mdpi':
        return {'tier': 'high', 'score': 90, 'recommended_action': 'retry_with_browser_impersonation', 'next_try_url': row.get('pdf_url') or row.get('resolver_landing_url'), 'rationale': 'MDPI direct PDF often needs browser impersonation / curl_cffi-style fetch rather than plain requests.'}
    if 'pmc.ncbi.nlm.nih.gov' in blob or 'europepmc.org' in blob:
        return {'tier': 'medium', 'score': 65, 'recommended_action': 'retry_pmc_or_europepmc_candidate', 'next_try_url': next((c for c in candidates if 'pmc.ncbi.nlm.nih.gov' in c or 'europepmc.org' in c), row.get('resolver_landing_url') or row.get('url')), 'rationale': 'PMC/Europe PMC trace exists; retry only if OA subset candidate is available.'}
    if publisher == 'elsevier_or_pmc':
        return {'tier': 'low', 'score': 35, 'recommended_action': 'retry_html_landing_with_browser_fallback', 'next_try_url': row.get('resolver_landing_url') or row.get('url'), 'rationale': 'HTML landing may expose links, but many Elsevier cases remain non-OA or delivery-blocked.'}
    if publisher == 'taylor_and_francis':
        return {'tier': 'low', 'score': 30, 'recommended_action': 'inspect_taylor_chapter_landing', 'next_try_url': row.get('resolver_landing_url') or row.get('url'), 'rationale': 'Chapter landing is reachable but static PDF path is not evident.'}
    return {'tier': 'low', 'score': 20, 'recommended_action': 'manual_review', 'next_try_url': row.get('resolver_landing_url') or row.get('url'), 'rationale': 'No strong OA proof detected.'}


def build_manual_recovery_queue(papers: list[dict]) -> dict:
    items = []
    by_reason: dict[str, int] = {}
    by_publisher: dict[str, int] = {}
    by_tier: dict[str, int] = {}
    for row in papers:
        if is_arxiv_row(row):
            continue
        if str(row.get('status') or '').lower() != 'pending':
            continue
        pending_reason = str(row.get('pending_reason') or '')
        resolver_status = str(row.get('resolver_status') or '')
        if pending_reason not in {'download_http_403', 'resolved_to_html_not_pdf', 'manual_download_needed'} and resolver_status != 'manual_download_needed':
            continue
        detail = ' '.join([
            str(row.get('pdf_url') or ''),
            str(row.get('url') or ''),
            str(row.get('resolver_landing_url') or ''),
            str(row.get('manual_download_reason') or ''),
        ]).lower()
        publisher = 'other'
        if 'mdpi' in detail:
            publisher = 'mdpi'
        elif 'europepmc' in detail or 'pmc' in detail or 'sciencedirect' in detail or 'elsevier' in detail or 'linkinghub.elsevier' in detail:
            publisher = 'elsevier_or_pmc'
        elif 'tandfonline' in detail or 'taylor' in detail:
            publisher = 'taylor_and_francis'
        reason = str(row.get('manual_download_reason') or pending_reason or resolver_status or 'manual_download_needed')
        by_reason[reason] = by_reason.get(reason, 0) + 1
        by_publisher[publisher] = by_publisher.get(publisher, 0) + 1
        recommendation = oa_recommendation(row, publisher, reason)
        by_tier[recommendation['tier']] = by_tier.get(recommendation['tier'], 0) + 1
        items.append({
            'id': row.get('id'),
            'title': row.get('title'),
            'doi': row.get('doi'),
            'pending_reason': pending_reason,
            'manual_download_reason': row.get('manual_download_reason'),
            'resolver_status': resolver_status,
            'publisher_family': publisher,
            'oa_proof_tier': recommendation['tier'],
            'oa_proof_score': recommendation['score'],
            'recommended_action': recommendation['recommended_action'],
            'recommended_next_try_url': recommendation['next_try_url'],
            'recommendation_rationale': recommendation['rationale'],
            'pdf_url': row.get('pdf_url'),
            'url': row.get('url'),
            'resolver_landing_url': row.get('resolver_landing_url'),
            'resolver_candidate_count': row.get('resolver_candidate_count'),
            'resolver_candidates': (row.get('resolver_candidates') or [])[:8],
        })
    tier_order = {'high': 0, 'medium': 1, 'low': 2, 'dead_end': 3}
    items.sort(key=lambda item: (
        tier_order.get(item['oa_proof_tier'], 9),
        -int(item.get('oa_proof_score') or 0),
        0 if item['publisher_family'] == 'mdpi' else 1 if item['publisher_family'] == 'elsevier_or_pmc' else 2,
        item.get('title') or '',
    ))
    return {
        'generated_at': now_iso(),
        'count': len(items),
        'by_reason': by_reason,
        'by_publisher_family': by_publisher,
        'by_tier': by_tier,
        'items': items,
    }


def build_external_access_queue(papers: list[dict]) -> dict:
    items = []
    by_reason: dict[str, int] = {}
    by_publisher: dict[str, int] = {}
    for row in papers:
        if is_arxiv_row(row):
            continue
        if str(row.get('status') or '').lower() != 'manual_external_access':
            continue
        detail = ' '.join([
            str(row.get('pdf_url') or ''),
            str(row.get('url') or ''),
            str(row.get('resolver_landing_url') or ''),
            str(row.get('manual_download_reason') or ''),
        ]).lower()
        publisher = 'other'
        if 'europepmc' in detail or 'pmc' in detail or 'sciencedirect' in detail or 'elsevier' in detail or 'linkinghub.elsevier' in detail:
            publisher = 'elsevier_or_pmc'
        elif 'tandfonline' in detail or 'taylor' in detail:
            publisher = 'taylor_and_francis'
        reason = str(row.get('external_access_reason') or row.get('manual_download_reason') or row.get('pending_reason') or 'external_access_blocked')
        by_reason[reason] = by_reason.get(reason, 0) + 1
        by_publisher[publisher] = by_publisher.get(publisher, 0) + 1
        items.append({
            'id': row.get('id'),
            'title': row.get('title'),
            'doi': row.get('doi'),
            'publisher_family': publisher,
            'external_access_reason': reason,
            'reviewed_at': row.get('external_access_reviewed_at'),
            'recommended_next_try_url': row.get('resolver_landing_url') or row.get('url') or row.get('pdf_url'),
            'pdf_url': row.get('pdf_url'),
            'url': row.get('url'),
            'resolver_landing_url': row.get('resolver_landing_url'),
            'resolver_candidate_count': row.get('resolver_candidate_count'),
            'resolver_candidates': (row.get('resolver_candidates') or [])[:8],
        })
    items.sort(key=lambda item: (0 if item['publisher_family'] == 'elsevier_or_pmc' else 1, item.get('title') or ''))
    return {
        'generated_at': now_iso(),
        'count': len(items),
        'by_reason': by_reason,
        'by_publisher_family': by_publisher,
        'items': items,
    }


def build_state() -> dict:
    papers = load_tracker()
    t = tracker_split(papers)
    notes = classify_gold_notes()
    rag = rag_counts()
    manual_recovery = build_manual_recovery_queue(papers)
    external_access = build_external_access_queue(papers)
    active_pdfs = count_active_pdfs()
    active_summary_count = len(notes['active_summary_notes'])
    active_gold_count = len(notes['active_gold_notes'])
    total_gold_count = active_gold_count + len(notes['orphan_gold_notes'])
    parity_gap = active_pdfs - active_summary_count
    arxiv_downloaded = t['arxiv_downloaded']
    status = 'PASS'
    if parity_gap != 0 or arxiv_downloaded:
        status = 'WARN'
    state = {
        'generated_at': now_iso(),
        'status': status,
        'peer_reviewed': {
            'active_gdrive_pdfs': active_pdfs,
            'obsidian_summary_notes': active_summary_count,
            'active_matched_summary_notes': active_summary_count,
            'active_matched_gold_notes': active_gold_count,
            'total_gold_notes': total_gold_count,
            'orphan_gold_notes': len(notes['orphan_gold_notes']),
            'tracker_downloaded_entries': len(t['peer_downloaded']),
            'parity_gap': parity_gap,
            'repair_queue': len(notes['repair_queue']),
            'download_outcomes': t['download_outcomes'],
        },
        'arxiv': {
            'pending_tracker_entries': len(t['pending_arxiv']),
            'tracker_downloaded_policy_violations': len(arxiv_downloaded),
            'obsidian_notes': len(notes['arxiv_notes']),
            'workspace_rag_entries': rag['arxiv_workspace_rag'],
            'downloaded_examples': [
                {
                    'id': row.get('id'),
                    'title': row.get('title'),
                    'filename': row.get('filename'),
                    'url': row.get('url'),
                }
                for row in arxiv_downloaded[:10]
            ],
        },
        'rag': rag,
        'notes': {
            'peer_reviewed': active_gold_count,
            'peer_reviewed_total_gold': total_gold_count,
            'arxiv': len(notes['arxiv_notes']),
            'other': len(notes['other_notes']),
        },
        'manual_recovery': {
            'count': manual_recovery['count'],
            'by_reason': manual_recovery['by_reason'],
            'by_publisher_family': manual_recovery['by_publisher_family'],
            'by_tier': manual_recovery.get('by_tier', {}),
        },
        'external_access': {
            'count': external_access['count'],
            'by_reason': external_access['by_reason'],
            'by_publisher_family': external_access['by_publisher_family'],
        },
    }
    REPAIR_QUEUE_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPAIR_QUEUE_PATH.write_text(json.dumps({
        'generated_at': state['generated_at'],
        'active_gdrive_pdfs': active_pdfs,
        'active_matched_summary_notes': active_summary_count,
        'active_matched_gold_notes': active_gold_count,
        'repair_queue_count': len(notes['repair_queue']),
        'items': notes['repair_queue'],
        'orphan_gold_notes': notes['orphan_gold_notes'],
    }, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    MANUAL_RECOVERY_PATH.write_text(json.dumps(manual_recovery, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    external_access_path = ROOT / '.state' / 'paper_external_access_queue.json'
    external_access_path.write_text(json.dumps(external_access, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    return state


def main() -> int:
    parser = argparse.ArgumentParser(description='Verify peer-reviewed parity and arXiv separation')
    parser.add_argument('--json', action='store_true', help='print JSON only')
    args = parser.parse_args()

    state = build_state()
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps(state, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

    if args.json:
        print(json.dumps(state, indent=2, ensure_ascii=False))
    else:
        log('============================================================')
        log('PAPER PARITY / ARXIV SEPARATION CHECK')
        log(f"Peer-reviewed active PDFs: {state['peer_reviewed']['active_gdrive_pdfs']}")
        log(f"Peer-reviewed active-matched summary notes: {state['peer_reviewed']['active_matched_summary_notes']}")
        log(f"Peer-reviewed active-matched gold notes: {state['peer_reviewed']['active_matched_gold_notes']}")
        log(f"Peer-reviewed total gold notes: {state['peer_reviewed']['total_gold_notes']}")
        log(f"Peer-reviewed orphan gold notes: {state['peer_reviewed']['orphan_gold_notes']}")
        log(f"Peer-reviewed tracker downloaded entries: {state['peer_reviewed']['tracker_downloaded_entries']}")
        outcomes = state['peer_reviewed']['download_outcomes']
        log(
            "Peer-reviewed download outcomes: "
            f"attempted={outcomes['attempted']} downloaded={outcomes['downloaded']} "
            f"blocked_403={outcomes['blocked_403']} resolved_html_only={outcomes['resolved_html_only']} "
            f"manual_download_needed={outcomes['manual_download_needed']} other_download_failure={outcomes['other_download_failure']}"
        )
        log(f"Parity gap (active PDFs - active-matched summary notes): {state['peer_reviewed']['parity_gap']}")
        log(f"Repair queue: {state['peer_reviewed']['repair_queue']}")
        log(f"arXiv pending tracker entries: {state['arxiv']['pending_tracker_entries']}")
        log(f"arXiv downloaded policy violations: {state['arxiv']['tracker_downloaded_policy_violations']}")
        log(f"arXiv workspace RAG entries: {state['arxiv']['workspace_rag_entries']}")
        log(f"Peer-reviewed fulltext RAG entries: {state['rag']['peer_fulltext_rag']}")
        if state['arxiv']['downloaded_examples']:
            log('Examples of arXiv downloaded policy violations:')
            for row in state['arxiv']['downloaded_examples'][:5]:
                log(f"  - {row['id']}: {row['title'][:100]}")
        log(f"Repair queue written: {REPAIR_QUEUE_PATH}")
        log(f"State written: {STATE_PATH}")
    return 0 if state['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
