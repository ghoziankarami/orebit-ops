#!/usr/bin/env python3
"""Append proposed tasks into the canonical PARA task staging file."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

OBSIDIAN_ROOT = Path('/workspace/obsidian-system/vault')
TASK_STAGING_FILE = OBSIDIAN_ROOT / '0. Inbox' / 'Task Staging.md'


def ensure_staging_file() -> None:
    TASK_STAGING_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not TASK_STAGING_FILE.exists():
        TASK_STAGING_FILE.write_text('# Task Staging\n\n', encoding='utf-8')


def build_task_line(task_desc: str, due_date: str | None = None, priority: str | None = None) -> str:
    task_line = f'- [ ] {task_desc}'
    if due_date:
        task_line += f' 📅 {due_date}'
    if priority:
        task_line += f' #priority/{priority}'
    task_line += ' #task-staging'
    return task_line


def create_staged_task(task_desc: str, due_date: str | None = None, priority: str | None = None) -> Path:
    ensure_staging_file()
    task_line = build_task_line(task_desc, due_date=due_date, priority=priority)
    content = TASK_STAGING_FILE.read_text(encoding='utf-8').rstrip('\n')
    existing = {line.strip() for line in content.splitlines()}
    if task_line.strip() not in existing:
        if content:
            content += '\n'
        content += task_line + '\n'
        TASK_STAGING_FILE.write_text(content, encoding='utf-8')
    return TASK_STAGING_FILE


def main() -> int:
    parser = argparse.ArgumentParser(description='Append a proposed task to the PARA staging file.')
    parser.add_argument('task', help='Task description')
    parser.add_argument('--due', default=None, help='Due date in YYYY-MM-DD format')
    parser.add_argument('--priority', choices=['high', 'medium', 'low'], default=None)
    args = parser.parse_args()
    path = create_staged_task(args.task, due_date=args.due, priority=args.priority)
    print(path)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
