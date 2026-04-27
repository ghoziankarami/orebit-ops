#!/usr/bin/env python3
"""
RAG Rebuild — No Docker Required
Direct ChromaDB + local embeddings integration for the local Obsidian vault.
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path
import hashlib
from typing import Any

import chromadb
import requests
from sentence_transformers import SentenceTransformer

# Persistent paths (NOT /workspace/)
PERSIST_DIR = "/app/working/workspaces/default/file_store/chroma"
VAULT_DIR = "/app/working/workspaces/default/obsidian-system/vault"
EMBEDDING_MODEL = "all-MiniLM-L6-v2"
EMBEDDING_API_URL = os.getenv("OREBIT_EMBEDDING_API_URL", "http://127.0.0.1:3005/v1/embeddings")
COLLECTION_NAME = "vault_docs"

PRIORITY_DIR_MARKERS = (
    "0. Inbox",
    "1. Projects",
    "2. Areas",
    "3. Resources",
)

PRIORITY_FILE_MARKERS = (
    "START HERE",
    "README",
    "Home",
    "SOP",
    "Workflow",
    "Research Playground",
    "Control Center",
)

EXCLUDED_PATH_PARTS = {
    ".obsidian",
    ".git",
    ".trash",
    ".locks",
    "Attachments",
    "Templates",
    "docs",
    "Daily Notes",
}

EXCLUDED_FILENAME_PATTERNS = (
    r"^\d{4}-\d{2}-\d{2}\.md$",
    r"^\d{4}-\d{2}-\d{2}-.+\.md$",
    r"^Untitled",
)


class NoDockerRAG:
    def __init__(self, persist_dir: str = PERSIST_DIR, embedding_model: str = EMBEDDING_MODEL):
        os.makedirs(persist_dir, exist_ok=True)
        self.client = chromadb.PersistentClient(path=persist_dir)
        self.embedding_model_name = embedding_model
        self._local_model: SentenceTransformer | None = None
        self.embedding_mode = "api" if self._embedding_api_healthy() else "local"

        if self.embedding_mode == "local":
            print(f"Loading embedding model locally: {embedding_model}...")
            self._local_model = SentenceTransformer(embedding_model)
            print("Embedding model loaded.")
        else:
            print(f"Using embedding API: {EMBEDDING_API_URL}")

        self.collection = self.client.get_or_create_collection(
            name=COLLECTION_NAME,
            metadata={"description": "Canonical Obsidian vault documents"},
        )

    def _embedding_api_healthy(self) -> bool:
        health_url = EMBEDDING_API_URL.replace("/v1/embeddings", "/health")
        try:
            resp = requests.get(health_url, timeout=5)
            return resp.ok
        except requests.RequestException:
            return False

    def embed(self, texts: list[str]) -> list[list[float]]:
        if self.embedding_mode == "api":
            resp = requests.post(
                EMBEDDING_API_URL,
                json={"model": self.embedding_model_name, "input": texts},
                timeout=120,
            )
            resp.raise_for_status()
            payload = resp.json()
            return [item["embedding"] for item in payload["data"]]

        assert self._local_model is not None
        return self._local_model.encode(texts, show_progress_bar=False).tolist()

    def should_index_file(self, filepath: Path, vault_path: Path) -> tuple[bool, str]:
        rel = filepath.relative_to(vault_path)
        rel_str = rel.as_posix()
        name = filepath.name

        if filepath.suffix.lower() not in {".md", ".txt"}:
            return False, "non-text"
        if any(part in EXCLUDED_PATH_PARTS for part in rel.parts):
            return False, "excluded-path"
        if rel.parts and rel.parts[0] == "4. Archive":
            return False, "archive"
        if any(re.match(pattern, name) for pattern in EXCLUDED_FILENAME_PATTERNS):
            return False, "routine-note"
        if not any(marker in rel_str for marker in PRIORITY_DIR_MARKERS):
            return False, "out-of-scope"
        return True, "ok"

    def path_weight(self, rel_path: str) -> float:
        if rel_path.startswith("3. Resources/Operating Systems/"):
            return 1.6
        if rel_path.startswith("3. Resources/SOPs/"):
            return 1.55
        if rel_path.startswith("0. Inbox/"):
            return 1.45
        if rel_path.startswith("1. Projects/"):
            return 1.35
        if rel_path.startswith("3. Resources/Research Notes/"):
            return 1.35
        if rel_path.startswith("3. Resources/Frameworks/"):
            return 1.3
        if rel_path.startswith("2. Areas/"):
            return 1.2
        if rel_path.startswith("3. Resources/"):
            return 1.1
        return 1.0

    def boost_for_query(self, rel_path: str, filename: str, query_text: str) -> float:
        score = self.path_weight(rel_path)
        lowered_query = query_text.lower()
        lowered_path = rel_path.lower()
        lowered_name = filename.lower()

        if any(token in lowered_query for token in ("obsidian", "inbox", "automation", "review", "workflow", "para", "second brain", "second-brain", "sop")):
            if "operating systems" in lowered_path:
                score += 0.55
            if "/sops/" in lowered_path:
                score += 0.5
            if lowered_path.startswith("0. inbox/"):
                score += 0.4
            if any(marker.lower() in lowered_name for marker in PRIORITY_FILE_MARKERS):
                score += 0.3
        return score

    def ingest_file(self, filepath: Path, vault_path: Path) -> bool:
        try:
            should_index, _ = self.should_index_file(filepath, vault_path)
            if not should_index:
                return False

            content = filepath.read_text(encoding="utf-8", errors="ignore")
            if len(content.strip()) < 80:
                return False

            rel_path = filepath.relative_to(vault_path).as_posix()
            doc_id = hashlib.md5(str(filepath).encode()).hexdigest()
            filename = filepath.name
            embedding = self.embed([content])[0]

            self.collection.upsert(
                embeddings=[embedding],
                documents=[content],
                metadatas=[{
                    "source": str(filepath),
                    "relative_path": rel_path,
                    "filename": filename,
                    "type": "vault_document",
                    "path_weight": self.path_weight(rel_path),
                }],
                ids=[doc_id],
            )
            return True
        except Exception as exc:
            print(f"Error ingesting {filepath}: {exc}")
            return False

    def ingest_vault(self, vault_dir: str = VAULT_DIR) -> int:
        vault_path = Path(vault_dir)
        if not vault_path.exists():
            print(f"Vault not found: {vault_dir}")
            return 0

        files = sorted(list(vault_path.rglob("*.md")) + list(vault_path.rglob("*.txt")))
        print(f"Found {len(files)} candidate documents in vault")

        ingested = 0
        for filepath in files:
            if self.ingest_file(filepath, vault_path):
                ingested += 1
                if ingested % 25 == 0:
                    print(f"  ... ingested {ingested}/{len(files)}")

        print(f"Successfully ingested: {ingested}/{len(files)} documents")
        return ingested

    def query(self, query_text: str, n_results: int = 5) -> dict[str, Any]:
        query_embedding = self.embed([query_text])[0]
        raw_results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=max(n_results * 4, 12),
            include=["documents", "metadatas", "distances"],
        )

        docs = raw_results.get("documents", [[]])[0]
        metas = raw_results.get("metadatas", [[]])[0]
        distances = raw_results.get("distances", [[]])[0]
        ids = raw_results.get("ids", [[]])[0]

        rescored = []
        for doc_id, doc, meta, distance in zip(ids, docs, metas, distances):
            meta = meta or {}
            rel_path = str(meta.get("relative_path") or meta.get("source") or "")
            filename = str(meta.get("filename") or Path(rel_path).name)
            boost = self.boost_for_query(rel_path, filename, query_text)
            similarity = 1.0 / (1.0 + float(distance))
            final_score = similarity * boost
            rescored.append((final_score, doc_id, doc, meta, distance))

        rescored.sort(key=lambda item: item[0], reverse=True)
        top = rescored[:n_results]

        return {
            "ids": [[item[1] for item in top]],
            "embeddings": None,
            "documents": [[item[2] for item in top]],
            "metadatas": [[item[3] for item in top]],
            "distances": [[item[4] for item in top]],
            "scores": [[round(item[0], 4) for item in top]],
            "embedding_mode": self.embedding_mode,
        }

    def get_stats(self) -> dict[str, Any]:
        count = self.collection.count()
        sample = self.collection.get(include=["metadatas"], limit=min(500, max(count, 1)))
        by_prefix: dict[str, int] = {}
        for meta in sample.get("metadatas", []) or []:
            rel = str((meta or {}).get("relative_path") or "")
            prefix = rel.split("/", 1)[0] if rel else "unknown"
            by_prefix[prefix] = by_prefix.get(prefix, 0) + 1
        return {
            "total_documents": count,
            "by_prefix": by_prefix,
            "embedding_mode": self.embedding_mode,
        }

    def reset(self) -> None:
        try:
            self.client.delete_collection(COLLECTION_NAME)
        except Exception:
            pass
        self.collection = self.client.get_or_create_collection(
            name=COLLECTION_NAME,
            metadata={"description": "Canonical Obsidian vault documents"},
        )
        print("Collection reset.")


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python rag_no_docker.py <command>")
        print("Commands:")
        print("  ingest     - Ingest vault documents")
        print("  query <q>  - Query RAG")
        print("  stats      - Show collection stats")
        print("  reset      - Reset collection")
        return

    command = sys.argv[1]
    rag = NoDockerRAG()

    if command == "ingest":
        rag.ingest_vault()
    elif command == "query":
        query = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else "test query"
        print(json.dumps(rag.query(query), indent=2))
    elif command == "stats":
        print(rag.get_stats())
    elif command == "reset":
        rag.reset()
    else:
        print(f"Unknown command: {command}")


if __name__ == "__main__":
    main()
