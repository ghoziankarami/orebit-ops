#!/usr/bin/env python3
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

CHECKS = [
    ("RAG API health", "http://127.0.0.1:3004/api/rag/health", 200),
    ("RAG dashboard health", "http://127.0.0.1:8503/_stcore/health", 200),
    ("RAG query GET guard", "http://127.0.0.1:3004/api/rag/query", 405),
]


def fetch(url):
    try:
        with urllib.request.urlopen(url, timeout=5) as resp:
            return resp.status, resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read().decode("utf-8", errors="replace")
    except Exception as exc:
        return None, str(exc)


def main():
    failed = False
    for label, url, expected in CHECKS:
        status, body = fetch(url)
        if status == expected:
            print(f"OK   {label}: {status}")
        else:
            failed = True
            print(f"FAIL {label}: got {status}, expected {expected}")

    vault = Path('/workspace/obsidian-system/vault')
    para = [
        vault / '0. Inbox',
        vault / '1. Projects',
        vault / '2. Areas',
        vault / '3. Resources',
        vault / '4. Archive',
    ]
    if all(p.exists() for p in para):
        print('OK   Obsidian PARA folders present')
    else:
        failed = True
        print('FAIL Obsidian PARA folders incomplete')

    research = [
        Path('/workspace/research-data/nala'),
        Path('/workspace/research-data/orebit'),
        Path('/workspace/research-data/papers-index'),
    ]
    if all(p.exists() for p in research):
        print('OK   Research data directories present')
    else:
        failed = True
        print('FAIL Research data directories incomplete')

    gdrive = Path('/mnt/gdrive/AI_Knowledge')
    if gdrive.exists():
        print('OK   Google Drive mount present')
    else:
        print('WARN Google Drive mount missing')

    return 1 if failed else 0


if __name__ == '__main__':
    raise SystemExit(main())
