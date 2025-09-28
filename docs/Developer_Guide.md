# ClaralyRAG Developer Guide

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Core Components](#core-components)
3. [Development Setup](#development-setup)
4. [Code Organization](#code-organization)
5. [Key Design Patterns](#key-design-patterns)
6. [Storage Backends](#storage-backends)
7. [API Development](#api-development)
8. [Testing](#testing)
9. [Extension Points](#extension-points)
10. [Performance Optimization](#performance-optimization)

## Architecture Overview

ClaralyRAG is built on a modular architecture that separates concerns across multiple layers:

```
┌─────────────────────────────────────────┐
│                Web UI                   │
├─────────────────────────────────────────┤
│              FastAPI Server             │
├─────────────────────────────────────────┤
│           LightRAG Core Engine          │
├─────────────────────────────────────────┤
│  Storage Abstraction Layer              │
├─────────────┬───────────┬───────────────┤
│ KV Storage  │ Vector DB │ Graph Storage │
└─────────────┴───────────┴───────────────┘
```

### Layer Responsibilities

- **Web UI**: React-based interface for document management and querying
- **FastAPI Server**: REST API, authentication, and request handling
- **LightRAG Core**: Document processing, entity extraction, and query engine
- **Storage Layer**: Pluggable backends for different data types

## Core Components

### 1. LightRAG Engine (`lightrag/lightrag.py`)

The main orchestrator that coordinates all operations:

```python
from lightrag import LightRAG
from lightrag.utils import EmbeddingFunc

# Initialize with custom configuration
rag = LightRAG(
    working_dir=WORKING_DIR,
    llm_model_func=your_llm_function,
    embedding_func=EmbeddingFunc(
        embedding_dim=1024,
        func=your_embedding_function
    )
)

# Required initialization pattern
await rag.initialize_storages()
await initialize_pipeline_status()

# Document operations
await rag.ainsert("document content")
result = await rag.aquery("query", mode="hybrid")

# Cleanup
await rag.finalize_storages()
```

### 2. Storage Backends (`lightrag/kg/`)

All storage operations go through abstract base classes:

```python
# Base storage interfaces
from lightrag.base import (
    BaseKVStorage,           # Key-value storage
    BaseVectorStorage,       # Vector embeddings
    BaseGraphStorage,        # Knowledge graph
    BaseDocStatusStorage     # Document processing status
)

# Production implementations
from lightrag.kg.postgres_impl import (
    PGKVStorage,
    PGVectorStorage,
    PGGraphStorage,
    PGDocStatusStorage
)
```

### 3. Document Processing Pipeline (`lightrag/operate.py`)

Multi-stage processing with async coordination:

1. **Text Chunking**: Split documents into manageable pieces
2. **Entity Extraction**: Use LLM to identify entities and relationships
3. **Graph Construction**: Build knowledge graph from extracted data
4. **Vector Indexing**: Create embeddings for similarity search

### 4. Query Engine (`lightrag/operate.py`)

Four query modes with different retrieval strategies:

- **Naive**: Pure vector similarity search
- **Local**: Context-aware graph traversal
- **Global**: Global graph pattern matching
- **Hybrid**: Combined approach for best results

## Development Setup

### Prerequisites

```bash
# System requirements
Python 3.10+
Docker and Docker Compose
PostgreSQL 16+ with pgvector
Neo4j 5.23+ with APOC/GDS plugins
Redis 7.2+
```

### Installation

```bash
# Clone repository
git clone <repository-url>
cd ClaralyRAG

# Install development dependencies
pip install -e ".[api,dev]"

# Setup environment
cp env.example .env
# Edit .env with your configuration

# Start dependencies
docker compose up -d postgres neo4j redis

# Run development server
lightrag-server --reload
```

### Development Environment

```bash
# Install pre-commit hooks for code quality
pre-commit install

# Run tests
python -m pytest tests/

# Format code
ruff format .
ruff check --fix .

# Type checking
mypy lightrag/
```

## Code Organization

### Directory Structure

```
lightrag/
├── __init__.py           # Main exports
├── lightrag.py           # Core LightRAG class
├── base.py              # Storage base classes
├── operate.py           # Document processing & querying
├── utils.py             # Utility functions
├── prompt.py            # LLM prompts
├── constants.py         # Configuration constants
├── exceptions.py        # Custom exceptions
├── types.py             # Type definitions
├── namespace.py         # Workspace isolation
├── rerank.py            # Reranking implementations
├── kg/                  # Storage implementations
│   ├── json_*.py        # JSON-based storage
│   ├── postgres_*.py    # PostgreSQL implementations
│   ├── neo4j_impl.py    # Neo4j graph storage
│   ├── redis_impl.py    # Redis caching
│   └── milvus_impl.py   # Milvus vector storage
├── llm/                 # LLM provider integrations
│   ├── openai.py        # OpenAI/compatible APIs
│   ├── ollama.py        # Ollama integration
│   ├── azure_openai.py  # Azure OpenAI
│   └── anthropic.py     # Anthropic Claude
└── api/                 # FastAPI server
    ├── lightrag_server.py  # Main server
    ├── config.py           # Configuration
    ├── auth.py             # Authentication
    ├── routers/            # API endpoints
    └── webui/              # Static web interface
```

### Import Patterns

```python
# Core imports
from lightrag import LightRAG
from lightrag.utils import EmbeddingFunc
from lightrag.base import BaseKVStorage

# Storage implementations
from lightrag.kg.postgres_impl import PGKVStorage
from lightrag.kg.neo4j_impl import Neo4JStorage

# LLM implementations
from lightrag.llm.openai import gpt_4o_mini_complete
from lightrag.llm.ollama import ollama_model_complete
```

## Key Design Patterns

### 1. Async-First Architecture

All I/O operations use async/await:

```python
class LightRAG:
    async def ainsert(self, content: str) -> None:
        """Async document insertion"""
        await self._ensure_initialized()
        await self._process_document(content)

    async def aquery(self, query: str, mode: str = "hybrid") -> str:
        """Async querying"""
        await self._ensure_initialized()
        return await self._execute_query(query, mode)
```

### 2. Storage Abstraction

All storage operations go through abstract interfaces:

```python
class BaseKVStorage:
    async def get(self, key: str) -> Any: ...
    async def set(self, key: str, value: Any) -> None: ...
    async def delete(self, key: str) -> None: ...

class PGKVStorage(BaseKVStorage):
    async def get(self, key: str) -> Any:
        # PostgreSQL-specific implementation
        ...
```

### 3. Configuration Management

Environment-based configuration with fallbacks:

```python
from lightrag.utils import get_env_value

# Get configuration with type conversion and defaults
llm_timeout = get_env_value("LLM_TIMEOUT", int, 180)
chunk_size = get_env_value("CHUNK_SIZE", int, 1200)
workspace = get_env_value("WORKSPACE", str, "default")
```

### 4. Error Handling

Comprehensive error handling with context:

```python
from lightrag.exceptions import LightRAGError

try:
    await rag.ainsert(content)
except LightRAGError as e:
    logger.error(f"LightRAG operation failed: {e}")
    # Handle specific error types
except Exception as e:
    logger.error(f"Unexpected error: {e}")
    # Handle general errors
```

### 5. Workspace Isolation

Multi-tenant support through workspace isolation:

```python
# Each workspace gets isolated data
rag_prod = LightRAG(workspace="production")
rag_dev = LightRAG(workspace="development")

# Storage backends automatically handle workspace separation
```

## Storage Backends

### Implementing Custom Storage

Create a custom storage backend by extending base classes:

```python
from lightrag.base import BaseKVStorage
import aioredis

class RedisKVStorage(BaseKVStorage):
    def __init__(self, config: dict):
        self.redis = aioredis.from_url(config["redis_url"])

    async def get(self, key: str) -> Any:
        data = await self.redis.get(self._make_key(key))
        return self._deserialize(data) if data else None

    async def set(self, key: str, value: Any) -> None:
        await self.redis.set(
            self._make_key(key),
            self._serialize(value)
        )

    def _make_key(self, key: str) -> str:
        return f"{self.config.workspace}:{key}"
```

### Storage Backend Selection

Configure storage backends via environment variables:

```env
# Storage backend selection
LIGHTRAG_KV_STORAGE=PGKVStorage
LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
LIGHTRAG_GRAPH_STORAGE=Neo4JStorage
LIGHTRAG_DOC_STATUS_STORAGE=PGDocStatusStorage

# Backend-specific configuration
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
NEO4J_URI=bolt://localhost:7687
REDIS_URI=redis://localhost:6379
```

## API Development

### Adding New Endpoints

Create new API routes by extending the router system:

```python
# lightrag/api/routers/custom_routes.py
from fastapi import APIRouter, Depends
from lightrag.api.auth import get_auth_dependency

router = APIRouter(prefix="/custom", tags=["custom"])

@router.get("/endpoint")
async def custom_endpoint(
    auth=Depends(get_auth_dependency())
):
    """Custom API endpoint"""
    return {"message": "Custom response"}

# Register in lightrag_server.py
from .routers.custom_routes import router as custom_router
app.include_router(custom_router)
```

### Request/Response Models

Use Pydantic models for type safety:

```python
from pydantic import BaseModel
from typing import Optional, List

class QueryRequest(BaseModel):
    query: str
    mode: str = "hybrid"
    top_k: int = 40
    max_tokens: int = 30000

class QueryResponse(BaseModel):
    response: str
    references: List[dict]
    processing_time: float
```

### Middleware and Dependencies

```python
from fastapi import Depends, HTTPException
from lightrag.api.auth import verify_api_key

async def require_api_key(api_key: str = Depends(verify_api_key)):
    """Dependency for API key validation"""
    if not api_key:
        raise HTTPException(401, "API key required")
    return api_key

@router.post("/protected-endpoint")
async def protected_endpoint(
    api_key: str = Depends(require_api_key)
):
    """Endpoint requiring API key"""
    ...
```

## Testing

### Unit Tests

```python
import pytest
from lightrag import LightRAG
from lightrag.kg.json_kv_impl import JsonKVStorage

@pytest.mark.asyncio
async def test_document_insertion():
    """Test document insertion and retrieval"""
    rag = LightRAG(
        working_dir="/tmp/test_rag",
        kv_storage=JsonKVStorage
    )

    await rag.initialize_storages()

    # Insert document
    await rag.ainsert("Test document content")

    # Query document
    result = await rag.aquery("test", mode="naive")
    assert "test" in result.lower()

    await rag.finalize_storages()
```

### Integration Tests

```python
import pytest
from fastapi.testclient import TestClient
from lightrag.api.lightrag_server import app

@pytest.fixture
def client():
    return TestClient(app)

def test_health_endpoint(client):
    """Test health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_document_upload(client):
    """Test document upload via API"""
    response = client.post(
        "/documents/text",
        json={
            "text": "Test document",
            "description": "Test"
        }
    )
    assert response.status_code == 200
    assert "track_id" in response.json()
```

### Performance Tests

```python
import asyncio
import time
from lightrag import LightRAG

async def benchmark_query_performance():
    """Benchmark query performance"""
    rag = LightRAG(working_dir="./benchmark_data")
    await rag.initialize_storages()

    # Warmup
    await rag.aquery("warmup query")

    # Benchmark
    start_time = time.time()
    for i in range(100):
        await rag.aquery(f"test query {i}")

    elapsed = time.time() - start_time
    print(f"100 queries in {elapsed:.2f}s ({100/elapsed:.1f} QPS)")

    await rag.finalize_storages()
```

## Extension Points

### Custom LLM Providers

Implement custom LLM providers:

```python
from lightrag.llm.base import BaseLLM

class CustomLLMProvider(BaseLLM):
    def __init__(self, config: dict):
        self.api_key = config["api_key"]
        self.base_url = config["base_url"]

    async def acomplete(self, prompt: str, **kwargs) -> str:
        """Complete a prompt using custom LLM"""
        # Implement your LLM API call
        response = await self._make_api_call(prompt, **kwargs)
        return response["choices"][0]["text"]

    async def _make_api_call(self, prompt: str, **kwargs):
        """Make HTTP request to your LLM API"""
        # Implement HTTP request logic
        pass

# Register in configuration
def get_custom_llm_func():
    provider = CustomLLMProvider(config)
    return provider.acomplete
```

### Custom Embedding Functions

```python
from lightrag.utils import EmbeddingFunc
import numpy as np

def custom_embedding_func(texts: List[str]) -> np.ndarray:
    """Custom embedding implementation"""
    # Implement your embedding logic
    embeddings = []
    for text in texts:
        embedding = compute_embedding(text)  # Your implementation
        embeddings.append(embedding)
    return np.array(embeddings)

# Use with LightRAG
embedding_func = EmbeddingFunc(
    embedding_dim=768,
    func=custom_embedding_func
)

rag = LightRAG(
    embedding_func=embedding_func,
    working_dir="./data"
)
```

### Custom Rerankers

```python
from lightrag.rerank.base import BaseReranker

class CustomReranker(BaseReranker):
    def __init__(self, config: dict):
        self.model = load_reranker_model(config["model_path"])

    async def arerank(
        self,
        query: str,
        documents: List[str],
        top_k: int = 10
    ) -> List[Tuple[str, float]]:
        """Rerank documents by relevance"""
        scores = await self._compute_scores(query, documents)
        ranked_docs = sorted(
            zip(documents, scores),
            key=lambda x: x[1],
            reverse=True
        )
        return ranked_docs[:top_k]
```

## Performance Optimization

### Configuration Tuning

```env
# Concurrency settings
MAX_ASYNC=8                 # Increase for more LLM concurrency
MAX_PARALLEL_INSERT=4       # Increase for faster document processing
EMBEDDING_FUNC_MAX_ASYNC=16 # Increase for faster embedding

# Memory optimization
CHUNK_SIZE=800              # Smaller chunks for less memory
MAX_TOTAL_TOKENS=15000      # Reduce context size

# Caching
ENABLE_LLM_CACHE=true       # Cache LLM responses
ENABLE_LLM_CACHE_FOR_EXTRACT=true  # Cache extraction results
```

### Database Optimization

```sql
-- PostgreSQL performance tuning
-- Add to postgresql.conf
shared_buffers = 256MB
effective_cache_size = 1GB
random_page_cost = 1.1
effective_io_concurrency = 200

-- Create indexes for better performance
CREATE INDEX CONCURRENTLY idx_lightrag_chunks_embedding
    ON lightrag_chunks USING hnsw (embedding vector_cosine_ops);

CREATE INDEX CONCURRENTLY idx_lightrag_entities_name
    ON lightrag_entities (entity_name);
```

### Memory Management

```python
import gc
from lightrag.utils import cleanup_memory

async def process_large_dataset(documents):
    """Process large datasets with memory management"""
    batch_size = 10

    for i in range(0, len(documents), batch_size):
        batch = documents[i:i + batch_size]

        # Process batch
        await rag.ainsert_batch(batch)

        # Clean up memory
        gc.collect()
        await cleanup_memory()
```

### Monitoring and Profiling

```python
import time
import psutil
from contextlib import asynccontextmanager

@asynccontextmanager
async def performance_monitor(operation_name: str):
    """Monitor operation performance"""
    start_time = time.time()
    start_memory = psutil.Process().memory_info().rss

    try:
        yield
    finally:
        end_time = time.time()
        end_memory = psutil.Process().memory_info().rss

        elapsed = end_time - start_time
        memory_delta = end_memory - start_memory

        print(f"{operation_name}: {elapsed:.2f}s, "
              f"memory: {memory_delta / 1024 / 1024:.1f}MB")

# Usage
async with performance_monitor("Document Processing"):
    await rag.ainsert(large_document)
```

## Best Practices

### 1. Error Handling

```python
from lightrag.exceptions import LightRAGError
import logging

logger = logging.getLogger(__name__)

async def robust_document_processing(content: str):
    """Process documents with comprehensive error handling"""
    try:
        await rag.ainsert(content)
        logger.info("Document processed successfully")

    except LightRAGError as e:
        logger.error(f"LightRAG error: {e}")
        # Handle specific LightRAG errors

    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        # Handle unexpected errors
```

### 2. Configuration Management

```python
from dataclasses import dataclass
from lightrag.utils import get_env_value

@dataclass
class AppConfig:
    """Centralized configuration management"""
    llm_timeout: int = get_env_value("LLM_TIMEOUT", int, 180)
    chunk_size: int = get_env_value("CHUNK_SIZE", int, 1200)
    max_async: int = get_env_value("MAX_ASYNC", int, 4)
    workspace: str = get_env_value("WORKSPACE", str, "default")

    def validate(self):
        """Validate configuration"""
        if self.chunk_size < 100:
            raise ValueError("CHUNK_SIZE must be >= 100")
        if self.max_async < 1:
            raise ValueError("MAX_ASYNC must be >= 1")

config = AppConfig()
config.validate()
```

### 3. Testing Strategies

```python
# Use dependency injection for testability
class LightRAGService:
    def __init__(self, rag: LightRAG):
        self.rag = rag

    async def process_document(self, content: str) -> str:
        await self.rag.ainsert(content)
        return await self.rag.aquery("summary")

# Test with mock LightRAG
@pytest.mark.asyncio
async def test_service():
    mock_rag = MockLightRAG()
    service = LightRAGService(mock_rag)

    result = await service.process_document("test")
    assert result == "expected summary"
```

### 4. Production Deployment

```python
# Use health checks and graceful shutdown
import signal
import asyncio

class LightRAGServer:
    def __init__(self):
        self.rag = None
        self.shutdown_event = asyncio.Event()

    async def startup(self):
        """Initialize server"""
        self.rag = LightRAG(working_dir="./data")
        await self.rag.initialize_storages()

        # Setup signal handlers
        for sig in (signal.SIGTERM, signal.SIGINT):
            signal.signal(sig, self._signal_handler)

    async def shutdown(self):
        """Graceful shutdown"""
        if self.rag:
            await self.rag.finalize_storages()

    def _signal_handler(self, sig, frame):
        """Handle shutdown signals"""
        self.shutdown_event.set()
```

For more detailed information, see the [API Reference](API_Reference.md) and [Configuration Guide](../CONFIGURATION.md).