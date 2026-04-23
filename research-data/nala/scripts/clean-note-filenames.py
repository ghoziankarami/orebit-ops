#!/usr/bin/env python3
"""
Clean up existing paper note filenames to match current canonical format.

- Uses frontmatter (title, authors, year) to compute ideal filename
- Sanitizes illegal characters
- Handles duplicates by appending (2), (3), etc.
- Renames files in place
"""

import yaml
import re
from datetime import datetime
from pathlib import Path

PAPERS_DIR = Path("/data/obsidian/3. Resources/Papers")

def sanitize(s: str) -> str:
    return re.sub(r'[:/\\?*"<>|]', '_', s).strip()

def make_filename(meta: dict, pdf_stem: str = "") -> str:
    authors = meta.get('authors') or []
    if authors:
        surname = authors[0].split()[-1]
    else:
        author = meta.get('author', 'Unknown')
        surname = author.split()[-1] if author != "Unknown" else "Unknown"
    surname = re.sub(r'[^a-zA-Z0-9]', '', surname) or "Unknown"
    year = str(meta.get('year', datetime.now().year))
    raw_title = meta.get('title') or pdf_stem
    # Remove repeated prefix
    pattern = rf'^{re.escape(surname)}\s*{year}\s*[-–—]?\s*'
    cleaned = re.sub(pattern, '', raw_title, flags=re.IGNORECASE).strip()
    if not cleaned or len(cleaned) < 3:
        cleaned = raw_title
    cleaned = sanitize(cleaned)
    filename = f"{surname} {year} — {cleaned}.md"
    return filename

def main():
    if not PAPERS_DIR.exists():
        print(f"❌ Papers dir not found: {PAPERS_DIR}")
        return
    notes = list(PAPERS_DIR.glob("*.md"))
    print(f"🔍 Found {len(notes)} notes to inspect")
    renamed = 0
    skipped = 0
    for note in notes:
        try:
            content = note.read_text(encoding='utf-8', errors='ignore')
            parts = content.split('---')
            if len(parts) < 2:
                print(f"⚠️ Skipping {note.name}: no frontmatter")
                skipped += 1
                continue
            frontmatter = yaml.safe_load(parts[1])
            if not frontmatter:
                print(f"⚠️ Skipping {note.name}: empty frontmatter")
                skipped += 1
                continue
            meta = {
                'title': frontmatter.get('title', ''),
                'authors': frontmatter.get('authors', []),
                'year': frontmatter.get('year', datetime.now().year)
            }
            pdf_stem = frontmatter.get('source', '').split('/')[-1].replace('.pdf','') if frontmatter.get('source') else ''
            ideal = make_filename(meta, pdf_stem)
            if ideal != note.name:
                target = PAPERS_DIR / ideal
                counter = 1
                while target.exists():
                    stem = Path(ideal).stem
                    suffix = Path(ideal).suffix
                    ideal = f"{stem} ({counter}){suffix}"
                    target = PAPERS_DIR / ideal
                    counter += 1
                note.rename(target)
                print(f"✅ Renamed: {note.name} → {target.name}")
                renamed += 1
            else:
                skipped += 1
        except Exception as e:
            print(f"❌ Error processing {note.name}: {e}")
            skipped += 1
    print(f"\n✅ Done. Renamed: {renamed}, Skipped (already good/error): {skipped}")

if __name__ == "__main__":
    main()
