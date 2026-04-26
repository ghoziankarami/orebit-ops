#!/usr/bin/env python3
"""
Local Embedding Server — OpenAI-compatible API
Wraps sentence-transformers for QwenPaw integration
"""

from fastapi import FastAPI
from pydantic import BaseModel
from typing import List
from sentence_transformers import SentenceTransformer
import uvicorn

app = FastAPI(title="Local Embedding Server")

# Load model at startup
MODEL = SentenceTransformer("all-MiniLM-L6-v2")
DIMENSIONS = 384

class EmbeddingRequest(BaseModel):
    model: str = "all-MiniLM-L6-v2"
    input: str | List[str]

class EmbeddingResponse(BaseModel):
    object: str = "list"
    data: List[dict]
    model: str
    usage: dict

@app.post("/v1/embeddings")
async def create_embedding(request: EmbeddingRequest):
    texts = request.input if isinstance(request.input, list) else [request.input]
    embeddings = MODEL.encode(texts).tolist()
    
    data = [
        {
            "object": "embedding",
            "index": i,
            "embedding": emb
        }
        for i, emb in enumerate(embeddings)
    ]
    
    return EmbeddingResponse(
        data=data,
        model=request.model,
        usage={"prompt_tokens": sum(len(t.split()) for t in texts), "total_tokens": sum(len(t.split()) for t in texts)}
    )

@app.get("/health")
async def health():
    return {"status": "ok", "model": "all-MiniLM-L6-v2", "dimensions": DIMENSIONS}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=3005)
