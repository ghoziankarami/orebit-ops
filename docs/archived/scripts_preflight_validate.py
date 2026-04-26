#!/usr/bin/env python3
import json
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

PLACEHOLDER_MARKERS = [
    'YOUR_ACCESS_TOKEN_HERE',
    'YOUR_REFRESH_TOKEN_HERE',
    'YOUR_TOKEN_HERE',
    'YOUR_ROOT_FOLDER_ID',
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


def parse_rclone_remotes(path: Path):
    remotes = {}
    current = None
    if not path.exists():
        return remotes
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        if line.startswith('[') and line.endswith(']'):
            current = line[1:-1].strip()
            remotes[current] = {}
            continue
        if current and '=' in line:
            key, value = line.split('=', 1)
            remotes[current][key.strip()] = value.strip()
    return remotes


def rclone_remote_status(remotes, name):
    remote = remotes.get(name)
    if not remote:
        return 'missing', f"rclone remote '{name}' is missing"

    remote_type = remote.get('type', '')
    if remote_type == 'alias':
        target = remote.get('remote', '')
        if any(marker in target for marker in PLACEHOLDER_MARKERS):
            return 'invalid', f"rclone alias '{name}' points to placeholder data"
        return 'ok', f"rclone alias '{name}' -> {target}"

    token = remote.get('token', '')
    if not token:
        return 'invalid', f"rclone remote '{name}' has no token"
    if any(marker in token for marker in PLACEHOLDER_MARKERS):
        return 'invalid', f"rclone remote '{name}' still uses placeholder token values"
    try:
        token_data = json.loads(token)
    except json.JSONDecodeError:
        return 'invalid', f"rclone remote '{name}' has unreadable token JSON"
    if not token_data.get('refresh_token'):
        return 'invalid', f"rclone remote '{name}' has no refresh token"
    return 'ok', f"rclone remote '{name}' has a non-placeholder refresh token"


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
        remotes = parse_rclone_remotes(RCLONE_FILE)
        for remote_name in ['gdrive', 'gdrive-obsidian', 'gdrive-research']:
            status, message = rclone_remote_status(remotes, remote_name)
            if status == 'ok':
                ok(message)
            elif status == 'missing':
                warn(message)
            else:
                warn(message)
    else:
        warn(f'rclone config missing at {RCLONE_FILE}')

    gdrive_mount = Path('/mnt/gdrive/AI_Knowledge')
    if gdrive_mount.exists():
        ok(f'found Google Drive mount {gdrive_mount}')
    else:
        warn(f'Google Drive mount missing at {gdrive_mount}; see docs/setup/RCLONE_SETUP.md')

    return 1 if failed else 0


if __name__ == '__main__':
    raise SystemExit(main())
