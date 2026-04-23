#!/usr/bin/env python3
"""
Daily Paper Ingestion Report — Nala
Generates CSV summary of papers added today, quality metrics, sources.
Runs at 20:00 WIB via cron.
"""

import json
import csv
from datetime import datetime, timezone, timedelta
from pathlib import Path
import subprocess
import os
import sys

ROOT_DIR = Path(__file__).resolve().parents[3]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from scripts.system.workspace_paths import get_workspace_paths

# Paths
WORKSPACE = get_workspace_paths().root
ACTIVITY_LOG = Path("/var/log/paper-indexing-activity.jsonl")
TRACKER_DB = WORKSPACE / "research/paper-tracker/papers.json"
REPORTS_DIR = WORKSPACE / "reports/papers/ingestion"

# Telegram config (use same as monitor)
TELEGRAM_BOT_TOKEN = "1973784902:AAG2Y4YXzlOyq4nZW5EX-pYjMiSGz12nA4U"
TELEGRAM_CHAT_ID = "187945281"

def ensure_dir(path: Path):
    path.mkdir(parents=True, exist_ok=True)

def load_activity():
    """Load activity log entries."""
    if not ACTIVITY_LOG.exists():
        return []
    entries = []
    with open(ACTIVITY_LOG, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                entries.append(json.loads(line))
            except:
                continue
    return entries

def load_tracker():
    """Load tracker DB."""
    if not TRACKER_DB.exists():
        return []
    with open(TRACKER_DB, 'r', encoding='utf-8') as f:
        return json.load(f)

def get_today_added(activity):
    """Filter activity for today's 'add' actions."""
    today = datetime.now(timezone.utc).date()
    today_added = []
    for entry in activity:
        ts = entry.get('timestamp')
        if ts:
            try:
                dt = datetime.fromisoformat(ts.rstrip('Z'))
                if dt.date() == today and entry.get('action') == 'add':
                    today_added.append(entry)
            except:
                continue
    return today_added

def generate_csv_report(today_added, output_path: Path):
    """Write CSV with paper details."""
    if not today_added:
        print("No papers added today.")
        return
    
    fieldnames = ['filename', 'title', 'authors', 'year', 'source', 'project', 'identifier', 'status']
    with open(output_path, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for entry in today_added:
            # entry fields are top-level, not nested 'paper'
            writer.writerow({
                'filename': entry.get('filename', ''),
                'title': entry.get('title', ''),
                'authors': entry.get('authors', ''),
                'year': entry.get('year', ''),
                'source': entry.get('source', ''),
                'project': entry.get('project', ''),
                'identifier': entry.get('identifier', ''),
                'status': entry.get('status', '')
            })

def send_telegram(text: str):
    """Send Telegram message."""
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    cmd = [
        "curl", "-s", "-X", "POST", url,
        "-d", f"chat_id={TELEGRAM_CHAT_ID}",
        "-d", f"text={text}",
        "-d", "parse_mode=Markdown"
    ]
    subprocess.run(cmd, capture_output=True)

def main():
    ensure_dir(REPORTS_DIR)
    today_str = datetime.now().strftime("%Y-%m-%d")
    csv_path = REPORTS_DIR / f"ingestion-{today_str}.csv"
    
    activity = load_activity()
    today_added = get_today_added(activity)
    
    generate_csv_report(today_added, csv_path)
    
    # Stats
    total = len(today_added)
    projects = {}
    sources = {}
    for entry in today_added:
        proj = entry.get('project', 'unknown')
        projects[proj] = projects.get(proj, 0) + 1
        src = entry.get('source', 'unknown')  # top-level field
        sources[src] = sources.get(src, 0) + 1
    
    # Build Telegram message
    msg = f"📚 *Daily Paper Ingestion Report* ({today_str})\n\n"
    msg += f"📥 Total papers added: *{total}*\n"
    if projects:
        msg += "\n📂 *By Project:*\n"
        for proj, cnt in sorted(projects.items(), key=lambda x: x[1], reverse=True):
            msg += f"  • {proj}: {cnt}\n"
    if sources:
        msg += "\n🌐 *By Source:*\n"
        for src, cnt in sorted(sources.items(), key=lambda x: x[1], reverse=True)[:5]:
            msg += f"  • {src}: {cnt}\n"
    msg += f"\n📁 Full CSV: `{csv_path}`"
    
    try:
        send_telegram(msg)
        print(f"Telegram sent: {total} papers")
    except Exception as e:
        print(f"Telegram error: {e}")

if __name__ == "__main__":
    main()
