#!/usr/bin/env python3
"""
url_ingest.py — Capture links into Obsidian vault using PARA method.
Determines link type, fetches metadata, writes to correct inbox folder.
"""
import sys
import os
import re
import json
import argparse
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse

VAULT = os.environ.get("VAULT_PATH", "/workspace/obsidian-system/vault")
INDEX_DIR = Path(VAULT) / "0. Inbox"

def get_type(url):
    parsed = urlparse(url)
    host = parsed.netloc.lower()
    path = parsed.path.lower()
    if "youtube.com" in host or "youtu.be" in host or "video.twimg.com" in host:
        return "youtube"
    if "github.com" in host:
        return "github"
    if host in ("medium.com", "dev.to", "blog.dev", "devops.com",
                "thenewstack.io", "hackernoon.com", "towardsdatascience.com",
                "freecodecamp.org", "betterprogramming.pub", "blog.bitsrc.io",
                "javascript.plainenglish.io", "python.plainenglish.io"):
        return "article"
    if host in ("arxiv.org", "papers.ssrn.com", "scholar.google"):
        return "paper"
    return "generic"

def slugify(text):
    text = re.sub(r'[^\w\s-]', '', text)
    return re.sub(r'[-\s]+', '-', text).strip('-')

def fetch_youtube_metadata(url):
    """Use yt-dlp to get YouTube video metadata."""
    import subprocess
    try:
        result = subprocess.run(
            ["yt-dlp", "--dump-json", "--no-download", url],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode == 0:
            data = json.loads(result.stdout)
            return {
                "title": data.get("title", "Untitled"),
                "channel": data.get("uploader", data.get("channel", "Unknown")),
                "duration": data.get("duration_string", "N/A"),
                "description": (data.get("description") or "")[:500],
                "url": url,
                "yt_id": data.get("display_id", ""),
            }
    except Exception:
        pass
    return None

def format_youtube_entry(url, context=""):
    meta = fetch_youtube_metadata(url)
    if meta:
        title = meta["title"]
        channel = meta["channel"]
        duration = meta["duration"]
        desc = meta["description"]
        yt_id = meta.get("yt_id", "")
        video_url = f"https://www.youtube.com/watch?v={yt_id}" if yt_id else url
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
        content = f"""## {title}

**Channel:** {channel}
**Duration:** {duration}
**Captured:** {ts}
**Link:** {video_url}

### Description
{desc[:300]}...

### Notes
{context}
"""
    else:
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
        content = f"""## {url}

**Captured:** {ts}
**Link:** {url}

### Notes
{context}
"""
    return content, meta["title"] if meta else slugify(url)

def format_github_entry(url, context=""):
    parsed = urlparse(url)
    parts = parsed.path.strip("/").split("/")
    owner = parts[0] if len(parts) > 0 else "unknown"
    repo = parts[1] if len(parts) > 1 else ""
    title = f"{owner}/{repo}" if repo else url
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    return f"""## {title}

**URL:** {url}
**Captured:** {ts}

### Notes
{context}
""", title

def format_article_entry(url, context=""):
    parsed = urlparse(url)
    title = parsed.netloc + parsed.path
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    return f"""## {title}

**URL:** {url}
**Captured:** {ts}

### Notes
{context}
""", slugify(title)

def format_generic_entry(url, context=""):
    parsed = urlparse(url)
    title = parsed.netloc + parsed.path
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    return f"""## {title}

**URL:** {url}
**Captured:** {ts}

### Notes
{context}
""", slugify(title)

def get_target_path(link_type, title):
    ts = datetime.now(timezone.utc).strftime("%Y%m%d")
    slug = slugify(title)[:50]
    if link_type == "youtube":
        folder = INDEX_DIR / "YouTube to Watch"
        folder.mkdir(parents=True, exist_ok=True)
        return folder / f"{ts}-{slug}.md"
    elif link_type == "github":
        folder = INDEX_DIR / "GitHub Follow-up"
        folder.mkdir(parents=True, exist_ok=True)
        return folder / f"{ts}-{slug}.md"
    elif link_type == "article":
        folder = INDEX_DIR / "Reading Inbox"
        folder.mkdir(parents=True, exist_ok=True)
        return folder / f"{ts}-{slug}.md"
    elif link_type == "paper":
        folder = INDEX_DIR / "Reading Inbox"
        folder.mkdir(parents=True, exist_ok=True)
        return folder / f"{ts}-{slug}.md"
    else:
        folder = INDEX_DIR / "Links"
        folder.mkdir(parents=True, exist_ok=True)
        return folder / f"{ts}-{slug}.md"

def append_to_index(url, link_type):
    INDEX_FILES = {
        "youtube": INDEX_DIR / "YouTube to Watch.md",
        "github": INDEX_DIR / "GitHub Follow-up.md",
        "article": INDEX_DIR / "Reading Inbox.md",
        "paper": INDEX_DIR / "Reading Inbox.md",
        "generic": INDEX_DIR / "Links.md",
    }
    index_file = INDEX_FILES.get(link_type)
    if not index_file:
        return
    index_file.parent.mkdir(parents=True, exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    entry = f"- [{url}]({url}) — captured {ts}\n"
    with open(index_file, "a") as f:
        f.write(entry)

def ingest(url, context=""):
    link_type = get_type(url)
    print(f"[url_ingest] Type: {link_type} | URL: {url}", file=sys.stderr)

    if link_type == "youtube":
        content, title = format_youtube_entry(url, context)
    elif link_type == "github":
        content, title = format_github_entry(url, context)
    elif link_type == "article":
        content, title = format_article_entry(url, context)
    else:
        content, title = format_generic_entry(url, context)

    target = get_target_path(link_type, title)
    target.parent.mkdir(parents=True, exist_ok=True)
    with open(target, "w") as f:
        f.write(content.strip() + "\n")

    append_to_index(url, link_type)

    result = {
        "status": "captured",
        "file": str(target),
        "type": link_type,
        "url": url,
        "title": title,
    }
    print(json.dumps(result))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Capture links into Obsidian vault")
    parser.add_argument("url", help="URL to capture")
    parser.add_argument("--context", default="", help="Optional notes/context")
    args = parser.parse_args()
    ingest(args.url, args.context)
