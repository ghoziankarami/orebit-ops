#!/usr/bin/env python3
"""Promote reviewed automation candidates into durable vault lanes safely.

This is intentionally conservative:
- only notes explicitly marked Promote are eligible
- notes with ambiguous destination stay in review
- promoted notes keep source lineage and original candidate context
"""

from __future__ import annotations

import argparse
import re
from datetime import datetime, timezone
from pathlib import Path

WORKSPACE_ROOT = Path('/app/working/workspaces/default')
VAULT_ROOT = WORKSPACE_ROOT / 'obsidian-system' / 'vault'
AUTOMATION_DIR = VAULT_ROOT / '0. Inbox' / 'Automation Inbox'
CANDIDATE_ROOT = AUTOMATION_DIR / 'Chat Review Candidates'
PROMOTION_REVIEW_DIR = AUTOMATION_DIR / 'Promotion Review'
PROMOTION_QUEUE = AUTOMATION_DIR / 'Promotion Review Queue.md'

LANE_RULES = {
    'sop': '3. Resources/SOPs',
    'workflow': '3. Resources/Operating Systems',
    'decision': '3. Resources/Frameworks',
    'research': '3. Resources/Research Notes',
    'idea': '0. Inbox/Ideas',
    'image-concept': '3. Resources/Visual Concepts',
}

AMBIGUOUS_MARKERS = (
    'maybe',
    'draft only',
    'needs rewrite',
    'unclear',
    'todo',
    'tbd',
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument('--vault-root', default=str(VAULT_ROOT))
    parser.add_argument('--dry-run', action='store_true')
    return parser.parse_args()


def slugify(text: str, max_len: int = 80) -> str:
    slug = re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')
    return slug[:max_len].strip('-') or 'promoted-note'


def list_candidate_files(root: Path) -> list[Path]:
    if not root.exists():
        return []
    return sorted(root.rglob('*.md'))


def has_promote_checkbox_checked(text: str) -> bool:
    return '- [x] Promote' in text or '- [X] Promote' in text


def parse_field(text: str, field: str) -> str:
    match = re.search(rf'^{re.escape(field)}:\s*(.+)$', text, flags=re.MULTILINE)
    return match.group(1).strip() if match else ''


def parse_title(text: str) -> str:
    for line in text.splitlines():
        if line.startswith('# '):
            return line[2:].strip()
    return 'Promoted Note'


def parse_candidate_type(text: str) -> str:
    value = parse_field(text, 'Candidate Type')
    return value or 'research'


def extract_candidate_output(text: str) -> str:
    marker = '## Candidate Output\n'
    if marker not in text:
        return text
    body = text.split(marker, 1)[1]
    if '\n## Review Decision\n' in body:
        body = body.split('\n## Review Decision\n', 1)[0]
    return body.strip() + '\n'


def recommended_lane(candidate_type: str, content: str) -> str:
    lowered = content.lower()
    if candidate_type == 'research' and 'positioning' in lowered:
        return '3. Resources/Markets'
    if candidate_type == 'research' and 'persona' in lowered:
        return '3. Resources/Personas'
    return LANE_RULES.get(candidate_type, '3. Resources/Research Notes')


def is_ambiguous(text: str) -> bool:
    lowered = text.lower()
    return any(marker in lowered for marker in AMBIGUOUS_MARKERS)


def note_ref(path: Path, label: str | None = None) -> str:
    rel = path.relative_to(VAULT_ROOT).as_posix()
    note_path = rel[:-3] if rel.endswith('.md') else rel
    if label:
        return f'[[{note_path}|{label}]]'
    return f'[[{note_path}]]'


def lane_ref(lane: str) -> str:
    if lane.endswith('/'):
        lane = lane.rstrip('/')
    return f'`{lane}`'


def build_promoted_note(title: str, lane: str, source_path: Path, text: str) -> str:
    captured = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
    candidate_type = parse_candidate_type(text)
    source = parse_field(text, 'Source')
    body = extract_candidate_output(text)
    return (
        '---\n'
        'Kind: Promoted Note\n'
        'Status: Draft\n'
        f'Promoted: {captured}\n'
        f'Promoted From: {source_path.relative_to(VAULT_ROOT).as_posix()}\n'
        f'Source: {source}\n'
        f'Candidate Type: {candidate_type}\n'
        f'Destination Lane: {lane}\n'
        'tags:\n'
        '  - promoted-note\n'
        '  - automation-reviewed\n'
        f'  - {candidate_type}\n'
        '---\n\n'
        f'# {title}\n\n'
        '## Provenance\n'
        f'- Promoted from {note_ref(source_path, "Automation Inbox candidate")} after review.\n'
        f'- Recommended durable lane: {lane_ref(lane)}.\n'
        '- Preserve/edit this note as needed before treating it as final evergreen knowledge.\n\n'
        '## Content\n'
        f'{body}'
    )


def build_review_queue(entries: list[tuple[Path, str, str, str]]) -> str:
    captured = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
    lines = [
        '---',
        'Kind: Dashboard',
        'Status: Active',
        f'Captured: {captured}',
        'tags:',
        '  - workflow/review',
        '  - promotion-review',
        '---',
        '',
        '# Promotion Review Queue',
        '',
        'This queue suggests safe durable lanes for reviewed chat candidates.',
        '',
        '## Rules',
        '- Only candidates explicitly marked `Promote` are considered.',
        '- Suggested destination is conservative and may still be edited by hand.',
        '- Ambiguous notes should stay in review, not be auto-promoted.',
        '',
        '## Current promote-ready candidates',
    ]
    if not entries:
        lines.append('- No promote-ready candidates found.')
        return '\n'.join(lines) + '\n'
    for path, title, lane, reason in entries:
        lines.append(f'- {note_ref(path, title)} -> {lane_ref(lane)} - {reason}')
    return '\n'.join(lines) + '\n'


def main() -> int:
    args = parse_args()
    vault_root = Path(args.vault_root)
    candidate_root = vault_root / '0. Inbox' / 'Automation Inbox' / 'Chat Review Candidates'
    review_dir = vault_root / '0. Inbox' / 'Automation Inbox' / 'Promotion Review'
    review_dir.mkdir(parents=True, exist_ok=True)

    candidates = list_candidate_files(candidate_root)
    promote_ready: list[tuple[Path, str, str, str]] = []
    promoted_count = 0

    for path in candidates:
        text = path.read_text()
        if not has_promote_checkbox_checked(text):
            continue
        title = parse_title(text)
        body = extract_candidate_output(text)
        lane = recommended_lane(parse_candidate_type(text), body)
        reason = 'recommended by candidate type'
        if is_ambiguous(body):
            reason = 'ambiguous content; keep in review'
            promote_ready.append((path, title, lane, reason))
            continue
        promote_ready.append((path, title, lane, reason))
        if args.dry_run:
            continue
        dest_dir = vault_root / lane
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest_path = dest_dir / f'{title}.md'
        if dest_path.exists():
            dest_path = dest_dir / f'{title} - {slugify(path.stem, 24)}.md'
        dest_path.write_text(build_promoted_note(title, lane, path, text))
        promoted_count += 1

    queue_path = vault_root / '0. Inbox' / 'Automation Inbox' / 'Promotion Review Queue.md'
    if not args.dry_run:
        queue_path.write_text(build_review_queue(promote_ready))
    print({
        'candidate_files': len(candidates),
        'promote_ready': len(promote_ready),
        'promoted': promoted_count,
        'queue': str(queue_path),
    })
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
