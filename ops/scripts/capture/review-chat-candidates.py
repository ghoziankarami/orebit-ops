#!/usr/bin/env python3
"""Stage likely high-value chat outputs into Automation Inbox.

This reviewer scans dialog JSONL files, extracts assistant text responses,
and writes only conservative candidates into the Obsidian Automation Inbox.
It prefers under-capture over noisy vault spam.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, List

WORKSPACE_ROOT = Path("/app/working/workspaces/default")
DIALOG_DIR = WORKSPACE_ROOT / "dialog"
VAULT_ROOT = WORKSPACE_ROOT / "obsidian-system" / "vault"
AUTOMATION_DIR = VAULT_ROOT / "0. Inbox" / "Automation Inbox"
CANDIDATE_DIR = AUTOMATION_DIR / "Chat Review Candidates"
STATE_PATH = AUTOMATION_DIR / ".chat-review-state.json"
QUEUE_NOTE = AUTOMATION_DIR / "Automation Review Queue.md"

KEYWORD_TO_TYPE = {
    "sop": "sop",
    "standard operating procedure": "sop",
    "workflow": "workflow",
    "playbook": "workflow",
    "runbook": "workflow",
    "image concept": "image-concept",
    "visual concept": "image-concept",
    "decision": "decision",
    "persona": "research",
    "positioning": "research",
    "market": "research",
    "research": "research",
    "idea": "idea",
}

SKIP_PHRASES = (
    "searching memory for relevant context",
    "i'll inspect",
    "i'm checking",
    "i'm applying",
    "i found",
)

META_PROGRESS_PHRASES = (
    "sudah saya",
    "yang saya update",
    "yang saya ubah",
    "yang saya tambahkan",
    "lanjutannya sudah",
    "saya lanjut",
    "saya sudah lanjutkan",
    "saya juga mulai",
    "saya bisa atur ini",
    "saya sudah cek semuanya",
    "kabar bagus",
    "hal yang sengaja tidak saya sentuh",
    "natural next steps",
    "kalau mau, next step",
    "the user wants me to stop and summarize",
    "let me give a clear summary",
    "i stopped because the repo is no longer clean",
    "i see the issue now",
    "maaf, saya harus jujur",
)

REUSE_SIGNAL_PHRASES = (
    "root cause",
    "review procedure",
    "destination examples",
    "current system rule",
    "simple model",
    "working loop",
    "operating sop",
    "decision rule",
    "promotion rule",
    "capture rule",
    "why this was staged",
    "final state",
    "audit result",
    "hasil audit",
    "the two failures are",
)

NOISE_TITLE_PREFIXES = (
    "sudah saya",
    "yang saya",
    "lanjut",
    "lanjutannya",
    "sip,",
    "bisa, dan sekarang",
    "oke,",
    "ok,",
    "siap,",
    "at ",
    "saya sudah kerjakan",
)

NOISE_TITLE_CONTAINS = (
    "kabar bagus",
    "hasil penting",
    "amankan itu",
    "clear summary",
    "issue now",
    "likely classification",
    "chat candidate",
    "status github tooling",
    "berikut final state",
)

NOISE_BODY_PHRASES = (
    "yang saya update",
    "sudah saya lanjutkan",
    "sip, saya sudah amankan itu",
    "lanjutannya sudah beres",
    "bisa, dan sekarang sudah mulai saya atur",
    "hal yang sengaja tidak saya sentuh",
    "let me give a clear summary",
    "the user wants me to stop and summarize",
)


@dataclass
class Candidate:
    digest: str
    date: str
    source_file: str
    message_id: str
    title: str
    candidate_type: str
    score: int
    content: str
    context: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dialog-dir", default=str(DIALOG_DIR))
    parser.add_argument("--vault-root", default=str(VAULT_ROOT))
    parser.add_argument("--limit", type=int, default=10)
    parser.add_argument("--days", type=int, default=7)
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def load_state(path: Path) -> dict:
    if not path.exists():
        return {"seen": {}}
    try:
        data = json.loads(path.read_text())
        data.setdefault("seen", {})
        return data
    except Exception:
        return {"seen": {}}


def save_state(path: Path, state: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n")


def slugify(text: str, max_len: int = 80) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return slug[:max_len].strip("-") or "chat-candidate"


def normalize_text(parts: Iterable[object] | str) -> str:
    if isinstance(parts, str):
        return parts.strip()

    blocks: List[str] = []
    for part in parts:
        if isinstance(part, str):
            text = part.strip()
            if text:
                blocks.append(text)
            continue
        if isinstance(part, dict) and part.get("type") == "text":
            text = part.get("text", "").strip()
            if text:
                blocks.append(text)
    return "\n\n".join(blocks).strip()


def infer_type(text: str) -> str:
    lowered = text.lower()
    for needle, candidate_type in KEYWORD_TO_TYPE.items():
        if needle in lowered:
            return candidate_type
    return "research"


def infer_title(text: str, candidate_type: str) -> str:
    lines = [line.strip("# -*\t ") for line in text.splitlines() if line.strip()]
    for line in lines:
        lowered = line.lower()
        if lowered.startswith(NOISE_TITLE_PREFIXES):
            continue
        if any(fragment in lowered for fragment in NOISE_TITLE_CONTAINS):
            continue
        if 18 <= len(line) <= 100:
            return line.rstrip(":.")
    return f"Chat candidate - {candidate_type}"


def is_meta_progress_reply(text: str) -> bool:
    lowered = text.lower()
    if any(phrase in lowered for phrase in META_PROGRESS_PHRASES):
        return True

    first_lines = [line.strip().lower() for line in text.splitlines() if line.strip()][:3]
    if any(line.startswith(NOISE_TITLE_PREFIXES) for line in first_lines):
        return True
    if any("summary" in line or "ringkas" in line for line in first_lines):
        return True
    if len(text) < 500 and any(line.startswith(("i see", "maaf", "sorry", "okay", "oke", "sip")) for line in first_lines):
        return True

    return False


def has_reuse_signal(text: str) -> bool:
    lowered = text.lower()
    if any(phrase in lowered for phrase in REUSE_SIGNAL_PHRASES):
        return True
    if "## " in text or "```" in text:
        return True
    if re.search(r"\b(1\.|2\.|3\.|- )", text):
        return True
    return False


def looks_like_stacktrace_fragment(text: str) -> bool:
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    if not lines:
        return False
    if len(text) < 800 and any(line.startswith("at ") for line in lines[:5]):
        return True
    return False


def score_text(text: str) -> int:
    lowered = text.lower()
    if any(phrase in lowered for phrase in SKIP_PHRASES):
        return 0
    if any(phrase in lowered for phrase in NOISE_BODY_PHRASES):
        return 0
    if is_meta_progress_reply(text):
        return 0
    if looks_like_stacktrace_fragment(text):
        return 0

    score = 0
    if len(text) >= 900:
        score += 2
    if len(text) >= 1500:
        score += 1
    if "##" in text or "```" in text or "|" in text:
        score += 2
    if re.search(r"\b(1\.|2\.|3\.|- )", text):
        score += 1
    if any(keyword in lowered for keyword in KEYWORD_TO_TYPE):
        score += 2
    if any(keyword in lowered for keyword in ("recommend", "should", "deploy", "capture", "research", "workflow", "sop", "root cause", "review", "procedure", "decision", "criteria")):
        score += 2
    if any(marker in lowered for marker in ("what i changed", "what i added", "yang saya pasang", "root cause analysis", "review rules")):
        score += 2
    if has_reuse_signal(text):
        score += 2
    if len(text) < 700 and not has_reuse_signal(text):
        return 0
    return score


def recent_dialogs(dialog_dir: Path, days: int) -> List[Path]:
    paths = sorted(dialog_dir.glob("*.jsonl"))
    if days <= 0 or len(paths) <= days:
        return paths
    return paths[-days:]


def extract_candidates(dialog_path: Path) -> List[Candidate]:
    candidates: List[Candidate] = []
    last_user_text = ""

    for raw_line in dialog_path.read_text().splitlines():
        if not raw_line.strip():
            continue
        try:
            message = json.loads(raw_line)
        except json.JSONDecodeError:
            continue

        role = message.get("role")
        content = message.get("content") or []
        text = normalize_text(content)
        if role == "user":
            last_user_text = text[:500]
            continue
        if role != "assistant" or not text:
            continue

        score = score_text(text)
        if score < 4:
            continue

        candidate_type = infer_type(text)
        title = infer_title(text, candidate_type)
        lowered_title = title.lower()
        if lowered_title.startswith(NOISE_TITLE_PREFIXES):
            continue
        if any(fragment in lowered_title for fragment in NOISE_TITLE_CONTAINS):
            continue
        digest = hashlib.sha1(f"{dialog_path.name}:{message.get('id','')}:{text[:300]}".encode()).hexdigest()[:12]
        candidates.append(
            Candidate(
                digest=digest,
                date=dialog_path.stem,
                source_file=dialog_path.name,
                message_id=message.get("id", ""),
                title=title,
                candidate_type=candidate_type,
                score=score,
                content=text,
                context=last_user_text or "Captured from dialog review.",
            )
        )
    return candidates


def candidate_note_path(vault_root: Path, candidate: Candidate) -> Path:
    automation_dir = vault_root / "0. Inbox" / "Automation Inbox"
    candidate_dir = automation_dir / "Chat Review Candidates" / candidate.date
    filename = f"{candidate.date}-{slugify(candidate.title)}-{candidate.digest}.md"
    return candidate_dir / filename


def render_candidate(candidate: Candidate) -> str:
    captured = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    source_ref = f"dialog/{candidate.source_file}#{candidate.message_id}" if candidate.message_id else f"dialog/{candidate.source_file}"
    return (
        "---\n"
        "Kind: Automation Candidate\n"
        "Status: Review\n"
        f"Candidate Type: {candidate.candidate_type}\n"
        f"Confidence: {candidate.score}\n"
        f"Captured: {captured}\n"
        f"Source: {source_ref}\n"
        "tags:\n"
        "  - automation-candidate\n"
        "  - chat-review\n"
        f"  - {candidate.candidate_type}\n"
        "---\n\n"
        f"# {candidate.title}\n\n"
        "## Why this was staged\n"
        "- Assistant response looked structured or reusable enough to review later.\n"
        "- Staged automatically instead of being promoted directly into durable lanes.\n\n"
        "## Source Prompt Context\n"
        f"{candidate.context}\n\n"
        "## Candidate Output\n"
        f"{candidate.content}\n\n"
        "## Review Decision\n"
        "- [ ] Promote\n"
        "- [ ] Keep in Automation Inbox\n"
        "- [ ] Archive\n"
        "- [ ] Discard as noise\n"
    )


def render_queue_note(candidates: List[Candidate], vault_root: Path) -> str:
    captured = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [
        "---",
        "Kind: Dashboard",
        "Status: Active",
        f"Captured: {captured}",
        "tags:",
        "  - workflow/review",
        "  - automation",
        "  - chat-review",
        "---",
        "",
        "# Automation Review Queue",
        "",
        "Staged candidates from `dialog/*.jsonl` that looked reusable enough to review, but not safe enough to promote automatically.",
        "",
        "## Review rules",
        "- Promote only if the note is specific, reusable, and still worth finding later.",
        "- Keep candidates here if they need rewriting or splitting before promotion.",
        "- Archive or discard obvious noise so the inbox does not accumulate dead drafts.",
        "",
        "## Current candidates",
    ]

    if not candidates:
        lines.extend(["", "- No staged candidates in the current scan window."])
        return "\n".join(lines) + "\n"

    for candidate in candidates:
        rel = candidate_note_path(vault_root, candidate).relative_to(vault_root)
        lines.append(f"- [{candidate.title}]({rel.as_posix()}) - `{candidate.candidate_type}` - confidence {candidate.score} - source `{candidate.source_file}`")
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    dialog_dir = Path(args.dialog_dir)
    vault_root = Path(args.vault_root)
    automation_dir = vault_root / "0. Inbox" / "Automation Inbox"
    state_path = automation_dir / ".chat-review-state.json"
    queue_note = automation_dir / "Automation Review Queue.md"

    state = load_state(state_path)
    seen = state.setdefault("seen", {})
    all_candidates: List[Candidate] = []
    new_candidates: List[Candidate] = []

    for dialog_path in recent_dialogs(dialog_dir, args.days):
        for candidate in extract_candidates(dialog_path):
            all_candidates.append(candidate)
            if candidate.digest not in seen:
                new_candidates.append(candidate)

    all_candidates = sorted(all_candidates, key=lambda item: (item.date, item.score, item.title), reverse=True)
    new_candidates = sorted(new_candidates, key=lambda item: (item.date, item.score, item.title), reverse=True)[: args.limit]

    if args.dry_run:
        print(json.dumps({
            "scanned_files": [path.name for path in recent_dialogs(dialog_dir, args.days)],
            "candidate_count": len(all_candidates),
            "new_candidate_count": len(new_candidates),
            "titles": [candidate.title for candidate in new_candidates],
        }, indent=2))
        return 0

    automation_dir.mkdir(parents=True, exist_ok=True)
    written: List[Candidate] = []
    for candidate in new_candidates:
        path = candidate_note_path(vault_root, candidate)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(render_candidate(candidate))
        seen[candidate.digest] = {
            "date": candidate.date,
            "title": candidate.title,
            "path": str(path.relative_to(vault_root)),
            "source_file": candidate.source_file,
        }
        written.append(candidate)

    queue_candidates = [candidate for candidate in all_candidates if candidate.digest in seen]
    queue_note.write_text(render_queue_note(queue_candidates[:50], vault_root))
    save_state(state_path, state)

    print(json.dumps({
        "written": len(written),
        "queue_entries": min(len(queue_candidates), 50),
        "automation_dir": str(automation_dir),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
