#!/usr/bin/env python3
"""
Deduplicate Paper Notes - Remove duplicate Obsidian notes based on PDF source
Author: Siro
Created: 2026-03-19
"""

import re
from pathlib import Path
from collections import defaultdict

PAPERS_DIR = Path("/data/obsidian/3. Resources/Papers")
DRY_RUN = False  # Set to False to actually delete

def extract_source_from_note(note_path: Path) -> str:
    """Extract source field from frontmatter."""
    try:
        with open(note_path, 'r', encoding='utf-8') as f:
            content = f.read(2000)  # Read first 2000 chars
        # Find source: line in frontmatter
        match = re.search(r'^source:\s*(.+)$', content, re.MULTILINE)
        if match:
            return match.group(1).strip()
    except Exception as e:
        print(f"   ⚠️ Error reading {note_path.name}: {e}")
    return ""

def is_duplicate_filename(filename: str) -> bool:
    """Check if filename has (1), (2), etc. suffix."""
    return bool(re.search(r'\s+\(\d+\)\.md$', filename))

def get_base_filename(filename: str) -> str:
    """Remove (1), (2) suffix to get base filename."""
    return re.sub(r'\s+\(\d+\)(\.md)$', r'\1', filename)

def main():
    print("🔍 Scanning for duplicate paper notes...")
    print(f"📁 Directory: {PAPERS_DIR}")
    print(f"🧪 Mode: {'DRY RUN (no files deleted)' if DRY_RUN else 'LIVE (will delete duplicates)'}")
    print()
    
    # Group notes by source
    source_to_notes = defaultdict(list)
    duplicate_suffix_notes = []
    
    for note in PAPERS_DIR.glob("*.md"):
        source = extract_source_from_note(note)
        if source:
            source_to_notes[source].append(note)
        
        if is_duplicate_filename(note.name):
            duplicate_suffix_notes.append(note)
    
    # Find duplicates by source
    print("📊 ANALYSIS:")
    print(f"   Total notes: {len(list(PAPERS_DIR.glob('*.md')))}")
    print(f"   Notes with (1), (2) suffix: {len(duplicate_suffix_notes)}")
    print(f"   Unique PDF sources: {len(source_to_notes)}")
    print()
    
    # Find sources with multiple notes
    duplicates_by_source = {src: notes for src, notes in source_to_notes.items() if len(notes) > 1}
    print(f"   PDF sources with multiple notes: {len(duplicates_by_source)}")
    print()
    
    if not duplicates_by_source and not duplicate_suffix_notes:
        print("✅ No duplicates found!")
        return
    
    # Strategy 1: Remove notes with (1), (2) suffix if base note exists
    print("🗑️  STRATEGY 1: Remove suffix duplicates if base exists")
    removed_count = 0
    
    for dup_note in duplicate_suffix_notes:
        base_name = get_base_filename(dup_note.name)
        base_path = PAPERS_DIR / base_name
        
        if base_path.exists():
            # Check if they have the same source
            dup_source = extract_source_from_note(dup_note)
            base_source = extract_source_from_note(base_path)
            
            if dup_source == base_source and dup_source:
                print(f"   🗑️  DELETE: {dup_note.name}")
                print(f"      (same source as {base_name})")
                if not DRY_RUN:
                    dup_note.unlink()
                removed_count += 1
            else:
                print(f"   ⚠️  KEEP: {dup_note.name} (different source or no source)")
        else:
            print(f"   ⚠️  KEEP: {dup_note.name} (base note doesn't exist)")
    
    print()
    print(f"   Removed: {removed_count} duplicate notes")
    print()
    
    # Rebuild source_to_notes mapping after Strategy 1 deletions
    print("🔄 Rebuilding source mapping after Strategy 1...")
    source_to_notes = defaultdict(list)
    for note in PAPERS_DIR.glob("*.md"):
        source = extract_source_from_note(note)
        if source:
            source_to_notes[source].append(note)
    
    duplicates_by_source = {src: notes for src, notes in source_to_notes.items() if len(notes) > 1}
    print(f"   Found {len(duplicates_by_source)} sources with multiple notes remaining")
    print()
    
    # Strategy 2: For sources with multiple notes, keep the newest
    print("🗑️  STRATEGY 2: For same source, keep newest note")
    removed_count_2 = 0
    
    for source, notes in duplicates_by_source.items():
        if len(notes) <= 1:
            continue
        
        # Sort by modification time, keep newest
        notes_sorted = sorted(notes, key=lambda n: n.stat().st_mtime, reverse=True)
        keep = notes_sorted[0]
        to_remove = notes_sorted[1:]
        
        print(f"   Source: {source}")
        print(f"      ✅ KEEP: {keep.name} (newest)")
        for note in to_remove:
            print(f"      🗑️  DELETE: {note.name}")
            if not DRY_RUN:
                note.unlink()
            removed_count_2 += 1
        print()
    
    print(f"   Removed: {removed_count_2} duplicate notes")
    print()
    
    # Summary
    total_removed = removed_count + removed_count_2
    print("=" * 60)
    print(f"✅ SUMMARY:")
    print(f"   Total duplicates removed: {total_removed}")
    if DRY_RUN:
        print(f"   ⚠️  DRY RUN - No files were actually deleted")
        print(f"   To actually delete, edit script and set DRY_RUN = False")
    else:
        print(f"   ✅ Files deleted successfully")
    print("=" * 60)

if __name__ == "__main__":
    main()
