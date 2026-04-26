#!/usr/bin/env python3
"""
RAG Rebuild — No Docker Required
Direct ChromaDB + sentence-transformers integration
"""

import os
import sys
from pathlib import Path
import chromadb
from chromadb.config import Settings
from sentence_transformers import SentenceTransformer
import glob
import hashlib

# Persistent paths (NOT /workspace/)
PERSIST_DIR = "/app/working/workspaces/default/file_store/chroma"
VAULT_DIR = "/app/working/workspaces/default/obsidian-system/vault"
EMBEDDING_MODEL = "all-MiniLM-L6-v2"  # Small, fast, good quality

class NoDockerRAG:
    def __init__(self, persist_dir=PERSIST_DIR, embedding_model=EMBEDDING_MODEL):
        """Initialize ChromaDB + local embeddings"""
        os.makedirs(persist_dir, exist_ok=True)
        
        # ChromaDB client
        self.client = chromadb.PersistentClient(path=persist_dir)
        
        # Embedding model (local, no API calls)
        print(f"Loading embedding model: {embedding_model}...")
        self.embedding_model = SentenceTransformer(embedding_model)
        print("Embedding model loaded.")
        
        # Get or create collection
        self.collection = self.client.get_or_create_collection(
            name="vault_docs",
            metadata={"description": "Obsidian vault documents"}
        )
    
    def embed(self, texts):
        """Generate embeddings locally"""
        return self.embedding_model.encode(texts, show_progress_bar=False).tolist()
    
    def ingest_file(self, filepath):
        """Ingest a single markdown/text file"""
        try:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            
            if len(content.strip()) < 50:
                return False  # Skip tiny files
            
            doc_id = hashlib.md5(filepath.encode()).hexdigest()
            filename = os.path.basename(filepath)
            
            # Generate embedding
            embedding = self.embed([content])[0]
            
            # Add to ChromaDB
            self.collection.add(
                embeddings=[embedding],
                documents=[content],
                metadatas=[{
                    "source": filepath,
                    "filename": filename,
                    "type": "vault_document"
                }],
                ids=[doc_id]
            )
            return True
        except Exception as e:
            print(f"Error ingesting {filepath}: {e}")
            return False
    
    def ingest_vault(self, vault_dir=VAULT_DIR):
        """Ingest all markdown/text files in vault"""
        vault_path = Path(vault_dir)
        if not vault_path.exists():
            print(f"Vault not found: {vault_dir}")
            return 0
        
        files = list(vault_path.rglob("*.md")) + list(vault_path.rglob("*.txt"))
        print(f"Found {len(files)} documents in vault")
        
        ingested = 0
        for filepath in files:
            if self.ingest_file(str(filepath)):
                ingested += 1
                if ingested % 10 == 0:
                    print(f"  ... ingested {ingested}/{len(files)}")
        
        print(f"Successfully ingested: {ingested}/{len(files)} documents")
        return ingested
    
    def query(self, query_text, n_results=5):
        """Query RAG for similar documents"""
        query_embedding = self.embed([query_text])[0]
        
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=n_results,
            include=["documents", "metadatas", "distances"]
        )
        return results
    
    def get_stats(self):
        """Get collection stats"""
        count = self.collection.count()
        return {"total_documents": count}
    
    def reset(self):
        """Reset collection"""
        try:
            self.client.delete_collection("vault_docs")
            self.collection = self.client.get_or_create_collection(
                name="vault_docs",
                metadata={"description": "Obsidian vault documents"}
            )
            print("Collection reset.")
        except Exception as e:
            print(f"Error resetting: {e}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python rag_no_docker.py <command>")
        print("Commands:")
        print("  ingest     — Ingest vault documents")
        print("  query <q>  — Query RAG")
        print("  stats      — Show collection stats")
        print("  reset      — Reset collection")
        return
    
    command = sys.argv[1]
    rag = NoDockerRAG()
    
    if command == "ingest":
        rag.ingest_vault()
    elif command == "query":
        query = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else "test query"
        results = rag.query(query)
        print(json.dumps(results, indent=2))
    elif command == "stats":
        print(rag.get_stats())
    elif command == "reset":
        rag.reset()
    else:
        print(f"Unknown command: {command}")

if __name__ == "__main__":
    import json
    main()
