#!/usr/bin/env python3
"""
ChromaDB Integration for RAG API
Direct integration without Docker
"""

import chromadb
from chromadb.config import Settings
import os

class ChromaRAG:
    def __init__(self, persist_dir="/workspace/orebit-rag-deploy/rag-system/chroma"):
        """Initialize ChromaDB with persistent storage"""
        self.client = chromadb.PersistentClient(path=persist_dir)
        
        # Get or create collections
        self.workspace_collection = self.client.get_or_create_collection(
            name="workspace_docs",
            metadata={"description": "Workspace documents"}
        )
        
        self.papers_collection = self.client.get_or_create_collection(
            name="research_papers",
            metadata={"description": "Research papers"}
        )
        
        self.orebit_collection = self.client.get_or_create_collection(
            name="orebit_knowledge",
            metadata={"description": "Orebit system knowledge"}
        )
    
    def query(self, query_text, collection_name="workspace_docs", n_results=5):
        """Query ChromaDB for similar documents"""
        try:
            collection = self.client.get_collection(collection_name)
            results = collection.query(
                query_texts=[query_text],
                n_results=n_results
            )
            return results
        except Exception as e:
            print(f"Error querying ChromaDB: {e}")
            return None
    
    def add_document(self, document, metadata, doc_id, collection_name="workspace_docs"):
        """Add a document to ChromaDB"""
        try:
            collection = self.client.get_collection(collection_name)
            collection.add(
                documents=[document],
                metadatas=[metadata],
                ids=[doc_id]
            )
            return True
        except Exception as e:
            print(f"Error adding document: {e}")
            return False
    
    def get_stats(self):
        """Get collection statistics"""
        try:
            collections = self.client.list_collections()
            stats = {}
            for coll in collections:
                stats[coll.name] = coll.count()
            return stats
        except Exception as e:
            print(f"Error getting stats: {e}")
            return {}

if __name__ == "__main__":
    # Test ChromaDB integration
    rag = ChromaRAG()
    stats = rag.get_stats()
    print("ChromaDB Stats:", stats)
