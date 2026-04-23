#!/usr/bin/env python3
"""
from scripts.system.workspace_paths import get_workspace_paths
Add auto-crossref: for each paper note, query RAG for similar papers and append links under "## Related Concepts".

Behavior:
  - Reads all notes from 3. Resources/Papers/*.md
  - Uses ChromaDB collection 'papers_summary' to find top 3 similar notes (by LLM summary)
  - Excludes self
  - Appends wikilinks ([[Filename]]) under existing "## Related Concepts" or creates new section.
  - Idempotent: avoids adding duplicates.
"""

import argparse
import frontmatter
from pathlib import Path
import sys

try:
    import chromadb
except ImportError:
    print("❌ chromadb not installed. Run: pip install chromadb")
    sys.exit(1)

# Paths
WORKSPACE = get_workspace_paths().root
VECTOR_DB_PAPERS = WORKSPACE / ".vector_db" / "papers"
PAPERS_DIR = Path("/data/obsidian/3. Resources/Papers")

def get_collection():
    client = chromadb.PersistentClient(path=str(VECTOR_DB_PAPERS))
    return client.get_collection("papers_summary")

def get_related_notes(note_filename: str, top_k: int = 3) -> list:
    """Return list of similar note filenames (excluding self)."""
    coll = get_collection()
    try:
        results = coll.query(
            query_texts=[note_filename],
            n_results=top_k + 1,  # +1 to account for self hit
            include=['metadatas']
        )
    except Exception as e:
        print(f"   ⚠️ Query failed: {e}")
        return []
    filenames = []
    metas = results.get('metadatas', [[]])[0]
    for meta in metas:
        if not meta:
            continue
        fname = meta.get('filename')
        if fname and fname != note_filename and fname not in filenames:
            filenames.append(fname)
    return filenames[:top_k]

def ensure_related_section(content: str) -> (str, bool):
    """Ensure content has a '## Related Concepts' section; return new content and whether it was added."""
    if "## Related Concepts" in content:
        return content, False
    # Append at the end (before My Notes? Typically after LLM Summary or before My Notes)
    # We'll add just after the frontmatter and any initial sections? Simpler: append at end.
    # But better: insert before "## My Notes" if present, else at end.
    insert_marker = "## My Notes"
    if insert_marker in content:
        idx = content.find(insert_marker)
        new_section = "## Related Concepts\n\n"
        content = content[:idx] + new_section + content[idx:]
    else:
        content = content.rstrip() + "\n\n## Related Concepts\n\n"
    return content, True

def add_wikilinks(note_path: Path, dry_run: bool = False, verbose: bool = False):
    post = frontmatter.load(note_path)
    content = post.content
    original = content

    # Get related filenames
    related = get_related_notes(note_path.name, top_k=3)
    if not related:
        if verbose:
            print(f"   ↺ {note_path.name}: no related found")
        return 0

    # Build wikilink lines
    links = [f"[[{fname}]]" for fname in related]
    section_header = "## Related Concepts"
    # Remove existing Related Concepts section if present (to avoid duplicates)
    # We'll do a simple replace: if section exists, replace its content with new links.
    import re
    pattern = re.compile(r'## Related Concepts\s*\n+((?:.|\n)*?)(?=\n## |\Z)', re.MULTILINE)
    m = pattern.search(content)
    if m:
        # Replace existing section content
        new_section = "\n".join([f"- {link}" for link in links]) + "\n"
        content = content[:m.start(1)] + new_section + content[m.end(1):]
    else:
        # Insert new section (ensure newlines)
        if "## My Notes" in content:
            idx = content.find("## My Notes")
            insert = "## Related Concepts\n\n" + "\n".join([f"- {link}" for link in links]) + "\n\n"
            content = content[:idx] + insert + content[idx:]
        else:
            content = content.rstrip() + "\n\n## Related Concepts\n\n" + "\n".join([f"- {link}" for link in links]) + "\n"
    # Update frontmatter unchanged
    new_post = frontmatter.Post(content, **post.metadata)
    if dry_run:
        print(f"   🚩 Would update {note_path.name} with {len(links)} related links")
        return 1
    try:
        with open(note_path, 'w', encoding='utf-8') as f:
            f.write(frontmatter.dumps(new_post))
        if verbose:
            print(f"   ✅ Updated {note_path.name} with {len(links)} related links")
        return 1
    except Exception as e:
        print(f"   ❌ Failed write {note_path.name}: {e}")
        return 0

def main():
    parser = argparse.ArgumentParser(description="Add auto-crossref to paper notes.")
    parser.add_argument('--dry-run', action='store_true', help='Preview changes without writing')
    parser.add_argument('--verbose', action='store_true', help='Print each note processed')
    parser.add_argument('--limit', type=int, default=0, help='Limit number of notes (for testing)')
    args = parser.parse_args()

    notes = list(PAPERS_DIR.glob("*.md"))
    if args.limit > 0:
        notes = notes[:args.limit]
    total = len(notes)
    print(f"🔍 Adding auto-crossref to {total} notes")
    updated = 0
    for note in notes:
        try:
            changed = add_wikilinks(note, dry_run=args.dry_run, verbose=args.verbose)
            updated += changed
        except Exception as e:
            print(f"   ❌ Error processing {note.name}: {e}")
    print(f"\n✅ Done. {updated} notes {'would be ' if args.dry_run else ''}updated with related concepts.")

if __name__ == "__main__":
    main()
