# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaralyRAG is a fork/variant of LightRAG - a simple and fast Retrieval-Augmented Generation system that uses knowledge graphs for enhanced document understanding and querying. The system combines vector search with graph-based reasoning to provide comprehensive answers.

## Core Architecture

### Main Components
- **LightRAG Core** (`lightrag/lightrag.py`): Main RAG engine with async initialization pattern
- **Knowledge Graph** (`lightrag/kg/`): Graph storage and manipulation layer
- **LLM Integration** (`lightrag/llm/`): Support for multiple LLM providers (OpenAI, Ollama, Azure, etc.)
- **API Server** (`lightrag/api/`): FastAPI-based web interface and REST API
- **Storage Abstraction**: Multiple backend support (JSON, PostgreSQL, Neo4j, MongoDB, Redis, etc.)

### Key Design Patterns
- **Async-First**: All core operations use async/await pattern
- **Storage Agnostic**: Pluggable storage backends via base classes
- **Multi-Modal**: Supports text, document processing, and knowledge graph operations
- **Pipeline Architecture**: Document processing through extraction → chunking → graph building

## Development Commands

### Environment Setup
```bash
# Install core package
pip install -e .

# Install with API support (includes FastAPI, auth, etc.)
pip install -e ".[api]"

# Copy environment configuration
cp env.example .env
```

### Running the System
```bash
# Start the web server (requires .env configuration)
lightrag-server

# Start with Gunicorn (production)
lightrag-gunicorn

# Docker deployment
docker compose up
```

### Development Tools
```bash
# Code formatting and linting (pre-commit hooks)
ruff format
ruff check --fix

# Run pre-commit hooks manually
pre-commit run --all-files
```

### Testing
```bash
# Run available tests
python -m pytest tests/

# Test specific components
python tests/test_lightrag_ollama_chat.py
python tests/test_graph_storage.py
```

## Critical Initialization Pattern

**IMPORTANT**: LightRAG requires explicit async initialization in this specific order:

```python
# 1. Create instance
rag = LightRAG(working_dir=WORKING_DIR, ...)

# 2. Initialize storage backends (REQUIRED)
await rag.initialize_storages()

# 3. Initialize pipeline status (REQUIRED)
await initialize_pipeline_status()

# 4. Now ready for operations
await rag.ainsert("content")
result = await rag.aquery("question")

# 5. Clean up when done
await rag.finalize_storages()
```

**Common Errors if initialization is skipped:**
- `AttributeError: __aenter__` → Missing `initialize_storages()`
- `KeyError: 'history_messages'` → Missing `initialize_pipeline_status()`

## Configuration System

### Environment Variables
- Configuration primarily through `.env` file (see `env.example`)
- Storage backends selected via `LIGHTRAG_*_STORAGE` variables
- LLM/Embedding providers via `*_BINDING` variables
- Workspace isolation via `WORKSPACE` variable

### Storage Backend Matrix
- **KV Storage**: JsonKVStorage (default), PGKVStorage, RedisKVStorage, MongoKVStorage
- **Vector Storage**: NanoVectorDBStorage (default), PGVectorStorage, MilvusVectorDBStorage, etc.
- **Graph Storage**: NetworkXStorage (default), Neo4JStorage, PGGraphStorage, MemgraphStorage
- **Doc Status**: JsonDocStatusStorage (default), PGDocStatusStorage, MongoDocStatusStorage

## Code Patterns

### LLM Function Injection
LightRAG requires injecting LLM and embedding functions:

```python
rag = LightRAG(
    working_dir=WORKING_DIR,
    llm_model_func=your_llm_function,  # Must follow specific signature
    embedding_func=EmbeddingFunc(
        embedding_dim=1536,
        func=your_embedding_function
    )
)
```

### Query Modes
- `"naive"`: Basic vector search
- `"local"`: Context-dependent graph search
- `"global"`: Global knowledge graph search
- `"hybrid"`: Combined local + global
- `"mix"`: Integrated KG + vector retrieval

### Async Operations
All core operations have async variants:
- `insert()` / `ainsert()`
- `query()` / `aquery()`
- `delete_by_entity()` / `adelete_by_entity()`

## Important File Locations

### Core Implementation
- `lightrag/lightrag.py`: Main LightRAG class
- `lightrag/base.py`: Storage abstractions and base classes
- `lightrag/operate.py`: Core extraction and query operations
- `lightrag/kg/`: Knowledge graph implementation

### API Layer
- `lightrag/api/lightrag_server.py`: Main FastAPI server
- `lightrag/api/config.py`: API configuration
- `lightrag/api/routers/`: API endpoint definitions

### Examples
- `examples/lightrag_openai_demo.py`: Basic OpenAI usage (officially supported)
- `examples/lightrag_openai_compatible_demo.py`: Streaming example (officially supported)
- Other examples are community contributions

## Development Guidelines

### Code Quality
- Uses Ruff for formatting and linting (configured in `pyproject.toml`)
- Pre-commit hooks enforce code quality
- Excludes `lightrag/api/webui/` from most quality checks

### Testing Strategy
- Limited test coverage currently
- Focus on storage backends and core functionality
- API endpoint testing available

### Storage Switching
**WARNING**: When changing embedding models, must clear data directory except optionally preserve `kv_store_llm_response_cache.json` for LLM cache.

## Production Considerations

### Recommended Stack
- **Small Scale**: Default JSON/NetworkX storage
- **Production**: Redis + Neo4j/PostgreSQL + Milvus/Qdrant
- **Enterprise**: Full PostgreSQL stack with pgvector and Apache AGE

### Performance Settings
- `MAX_ASYNC`: Concurrent LLM requests (default: 4)
- `MAX_PARALLEL_INSERT`: Document processing parallelism (default: 2)
- Context size must be ≥32K tokens for proper operation

### Authentication
- JWT-based authentication in API layer
- Configurable via `AUTH_ACCOUNTS` and related env vars
- API key protection available

## API Integration

The system provides both programmatic and REST API access:
- Web UI for document management and graph visualization
- REST endpoints for all core operations
- Ollama-compatible chat interface
- OpenAPI documentation available

Refer to `lightrag/api/README.md` for detailed API documentation.