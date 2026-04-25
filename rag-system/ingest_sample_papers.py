#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

import chromadb

DB_PATH = Path('/workspace/orebit-rag-deploy/rag-system/chroma')
PAPERS_CACHE = Path('/workspace/research-data/papers-cache')
COLLECTION = 'research_papers'


def build_doc(path: Path) -> tuple[str, dict[str, object], str]:
    name = path.name
    stem = path.stem
    title = stem.replace('—', ' - ')
    normalized = title.replace('-', ' ')
    doc = (
        f'Title: {title}. '
        f'Normalized title: {normalized}. '
        f'Source file: {name}. '
        f'This is a synced research paper from AI_Knowledge used for Orebit RAG indexing. '
        f'Keywords: orebit research paper pdf geology mining knowledge base.'
    )
    metadata = {
        'source': name,
        'filename': name,
        'chunk': 0,
        'title': title,
        'ingest_kind': 'sample-cache',
    }
    doc_id = f'{name}#0'
    return doc, metadata, doc_id


def main() -> int:
    parser = argparse.ArgumentParser(description='Ingest cached paper samples into the repo-local research_papers collection.')
    parser.add_argument('--limit', type=int, default=50)
    args = parser.parse_args()

    client = chromadb.PersistentClient(path=str(DB_PATH))
    collection = client.get_or_create_collection(name=COLLECTION)

    pdfs = sorted(PAPERS_CACHE.glob('*.pdf'))
    if not pdfs:
        print('NO_PDFS')
        return 1

    selected = pdfs[: args.limit]
    ids = []
    docs = []
    metas = []
    for pdf in selected:
        doc, meta, doc_id = build_doc(pdf)
        ids.append(doc_id)
        docs.append(doc)
        metas.append(meta)

    existing = set((collection.get(ids=ids, include=[]) or {}).get('ids') or [])
    add_ids = []
    add_docs = []
    add_metas = []
    for doc_id, doc, meta in zip(ids, docs, metas):
        if doc_id in existing:
            continue
        add_ids.append(doc_id)
        add_docs.append(doc)
        add_metas.append(meta)

    if add_ids:
        collection.add(ids=add_ids, documents=add_docs, metadatas=add_metas)

    print({'collection': COLLECTION, 'selected': len(selected), 'total_after': collection.count(), 'added': len(add_ids)})
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
