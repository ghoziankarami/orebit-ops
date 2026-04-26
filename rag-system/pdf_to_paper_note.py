#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
from pathlib import Path

import chromadb
import requests

DB_PATH = Path('/app/working/workspaces/default/file_store/chroma')
VAULT = Path('/app/working/workspaces/default/obsidian-system/vault')
PAPERS_DIR = VAULT / '0. Inbox' / 'Papers'
COLLECTION = 'paper_docs'
EMBEDDING_URL = 'http://127.0.0.1:3005/v1/embeddings'
EMBED_MODEL = 'all-MiniLM-L6-v2'


def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r'[^a-z0-9]+', '-', text)
    return text.strip('-') or 'paper'


def extract_pdf_text(pdf: Path) -> str:
    candidates = [
        ['pdftotext', '-layout', str(pdf), '-'],
        ['mutool', 'draw', '-F', 'txt', str(pdf)],
    ]
    for cmd in candidates:
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout
        except FileNotFoundError:
            continue
    raise RuntimeError('No working PDF text extractor found. Install pdftotext or mutool.')


def chunk_text(text: str, max_chars: int = 2200) -> list[str]:
    text = re.sub(r'\s+', ' ', text).strip()
    if not text:
        return []
    chunks = []
    start = 0
    while start < len(text):
        chunks.append(text[start:start + max_chars])
        start += max_chars
    return chunks


def embed_texts(texts: list[str]) -> list[list[float]]:
    response = requests.post(
        EMBEDDING_URL,
        json={'model': EMBED_MODEL, 'input': texts},
        timeout=300,
    )
    response.raise_for_status()
    data = response.json().get('data', [])
    return [item['embedding'] for item in data]


def ingest_pdf(pdf: Path) -> dict[str, object]:
    client = chromadb.PersistentClient(path=str(DB_PATH))
    collection = client.get_or_create_collection(name=COLLECTION)

    text = extract_pdf_text(pdf)
    chunks = chunk_text(text)
    if not chunks:
        raise RuntimeError(f'No extractable text from {pdf}')

    ids = [f"{pdf.name}#{i}" for i in range(len(chunks))]
    metas = [{
        'source': str(pdf),
        'filename': pdf.name,
        'chunk': i,
        'title': pdf.stem,
        'ingest_kind': 'pdf-text',
    } for i in range(len(chunks))]

    existing = set((collection.get(ids=ids, include=[]) or {}).get('ids') or [])
    add_ids, add_docs, add_metas = [], [], []
    for doc_id, doc, meta in zip(ids, chunks, metas):
        if doc_id in existing:
            continue
        add_ids.append(doc_id)
        add_docs.append(doc)
        add_metas.append(meta)

    if add_ids:
        embeddings = embed_texts(add_docs)
        collection.add(ids=add_ids, documents=add_docs, metadatas=add_metas, embeddings=embeddings)

    return {
        'collection': COLLECTION,
        'chunks_total': len(chunks),
        'chunks_added': len(add_ids),
        'pdf': str(pdf),
        'preview': chunks[0][:1200],
    }


def write_summary_note(pdf: Path, ingest_result: dict[str, object]) -> Path:
    PAPERS_DIR.mkdir(parents=True, exist_ok=True)
    title = pdf.stem
    slug = slugify(title)
    out = PAPERS_DIR / f"{slug}.md"
    preview = ingest_result['preview']
    content = f"""---
Kind: Literature Synthesis
Status: Draft
Paper: {pdf.name}
Domain:
Project:
tags:
  - literature
  - synthesis
  - rag
---

# {title}

## Citation
- Source PDF: `{pdf}`

## Core Question
- 

## Summary
{preview}

## Methods
- Extracted from PDF text into local RAG collection `{COLLECTION}`

## Key Findings
- Review the extracted preview and refine manually.
- Query the local RAG with this paper title or domain terms.
- Promote stable synthesis later to `3. Resources/Literature Notes/`.

## Why It Matters
- Keeps paper intake visible in Obsidian while the source PDF is also indexed in local RAG.

## Reusable Insights
- 
- 

## Related Notes
- `0. Inbox/Papers/README.md`
"""
    out.write_text(content, encoding='utf-8')
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description='Ingest a PDF into local RAG and create an Obsidian paper note.')
    parser.add_argument('pdf_path')
    args = parser.parse_args()

    pdf = Path(args.pdf_path)
    if not pdf.exists():
        raise SystemExit(f'PDF not found: {pdf}')

    ingest_result = ingest_pdf(pdf)
    note = write_summary_note(pdf, ingest_result)
    print(json.dumps({'ingest': ingest_result, 'note': str(note)}, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
