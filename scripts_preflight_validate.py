#!/usr/bin/env python3
import os
import sys
from pathlib import Path

ROOT = Path('/workspace/orebit-rag-deploy')
ENV_FILE = ROOT / '.env'
RCLONE_FILE = Path.home() / '.config' / 'rclone' / 'rclone.conf'

REQUIRED_PATHS = [
    ROOT / 'README.md',
    ROOT / 'DEPLOYMENT.md',
    ROOT / 'infra-template' / 'install.sh',
    ROOT / 'obsidian-system' / 'install.sh',
    ROOT / 'research-data' / 'install.sh',
    ROOT / 'rag-system' / 'docker-compose.yml',
]

RUNTIME_DIRS = [
    Path('/workspace/obsidian-system'),
    Path('/workspace/rag-system'),
    Path('/workspace/research-data'),
]

REQUIRED_ENV_KEYS = [
    'OPENROUTER_API_KEY',
    'RAG_API_KEY',
]

OPTIONAL_ENV_KEYS = [
    'OPENAI_API_KEY',
    'GOOGLE_API_KEY',
    'TAVILY_API_KEY',
    'BRAVE_API_KEY',
    'TELEGRAM_BOT_TOKEN',
]


def load_env(path: Path):
    values = {}
    if not path.exists():
        return values
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        key, value = line.split('=', 1)
        values[key.strip()] = value.strip()
    return values


def ok(msg):
    print(f'OK   {msg}')


def warn(msg):
    print(f'WARN {msg}')


def fail(msg):
    print(f'FAIL {msg}')


def main():
    failed = False

    for path in REQUIRED_PATHS:
        if path.exists():
            ok(f'found {path}')
        else:
            fail(f'missing {path}')
            failed = True

    if ENV_FILE.exists():
        ok(f'found {ENV_FILE}')
    else:
        fail(f'missing {ENV_FILE}; copy infra-template/.env.template first')
        failed = True

    env = load_env(ENV_FILE)
    for key in REQUIRED_ENV_KEYS:
        if env.get(key):
            ok(f'env {key} is set')
        else:
            fail(f'env {key} is empty or missing')
            failed = True

    for key in OPTIONAL_ENV_KEYS:
        if env.get(key):
            ok(f'env {key} is set')
        else:
            warn(f'env {key} is empty or missing')

    for path in RUNTIME_DIRS:
        if path.exists():
            ok(f'runtime dir exists {path}')
        else:
            warn(f'runtime dir missing {path}; installer may create it')

    vault_dir = Path('/workspace/obsidian-system/vault')
    para_dirs = [
        vault_dir / '0. Inbox',
        vault_dir / '1. Projects',
        vault_dir / '2. Areas',
        vault_dir / '3. Resources',
        vault_dir / '4. Archive',
    ]
    if all(p.exists() for p in para_dirs):
        ok('Obsidian PARA folders exist')
    else:
        warn('Obsidian PARA folders incomplete')

    chroma_db = ROOT / 'rag-system' / 'chroma' / 'chroma.sqlite3'
    if chroma_db.exists():
        ok(f'found Chroma DB {chroma_db}')
    else:
        warn(f'Chroma DB not found at {chroma_db}')

    if RCLONE_FILE.exists():
        ok(f'found rclone config {RCLONE_FILE}')
    else:
        warn(f'rclone config missing at {RCLONE_FILE}')

    gdrive_mount = Path('/mnt/gdrive/AI_Knowledge')
    if gdrive_mount.exists():
        ok(f'found Google Drive mount {gdrive_mount}')
    else:
        warn(f'Google Drive mount missing at {gdrive_mount}')

    return 1 if failed else 0


if __name__ == '__main__':
    raise SystemExit(main())
