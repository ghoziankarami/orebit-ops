#!/usr/bin/env python3
"""
Move all existing paper notes from 3. Resources/Papers/ to 4. Archives/Papers/legacy/
to make room for a fresh reindex with improved naming.
"""

import shutil
from pathlib import Path

PAPERS_DIR = Path("/data/obsidian/3. Resources/Papers")
LEGACY_DIR = Path("/data/obsidian/4. Archives/Papers/legacy")

def main():
    if not PAPERS_DIR.exists():
        print(f"❌ Papers dir not found: {PAPERS_DIR}")
        return
    LEGACY_DIR.mkdir(parents=True, exist_ok=True)
    notes = list(PAPERS_DIR.glob("*.md"))
    print(f"📦 Moving {len(notes)} notes to legacy archive...")
    moved = 0
    for note in notes:
        target = LEGACY_DIR / note.name
        # If conflict, append timestamp
        if target.exists():
            stem = note.stem
            suffix = note.suffix
            ts = datetime.now().strftime("%Y%m%d_%H%M%S")
            target = LEGACY_DIR / f"{stem}_{ts}{suffix}"
        shutil.move(str(note), str(target))
        print(f"→ {note.name} → {target.name}")
        moved += 1
    print(f"\n✅ Moved {moved} notes to {LEGACY_DIR}")

if __name__ == "__main__":
    from datetime import datetime
    main()
