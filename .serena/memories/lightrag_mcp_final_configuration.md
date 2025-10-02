# LightRAG MCP Server - Final Working Configuration

## Overview
Successfully configured LightRAG MCP server with stdio transport for Claude Code integration. The server queries the production LightRAG knowledge base using PostgreSQL and Neo4j backends.

## Production File
**Location**: `/data/git/zhg/prod/ClaralyRAG/lightrag_mcp.py`

## Critical Success Factors

### 1. Pipeline Status Initialization
**Required**: Must call `initialize_pipeline_status()` after `initialize_storages()`

```python
from lightrag.kg.shared_storage import initialize_pipeline_status

await rag.initialize_storages()
await initialize_pipeline_status()  # Critical for distributed storage
```

**Error if missing**: "Pipeline namespace 'pipeline_status' not found"

### 2. Workspace Synchronization
**Required**: MCP container must have WORKSPACE environment variable matching production

**docker-compose.yml**:
```yaml
lightrag-mcp:
  environment:
    - WORKSPACE=${WORKSPACE}  # Sync with production workspace
```

**Error if missing**: Query returns `[no-context]` - queries wrong database

### 3. Storage Backend Configuration
**Required**: Must configure storage backends to match production (PostgreSQL + Neo4j)

```python
KV_STORAGE = os.environ.get("LIGHTRAG_KV_STORAGE", "JsonKVStorage")
VECTOR_STORAGE = os.environ.get("LIGHTRAG_VECTOR_STORAGE", "NanoVectorDBStorage")
GRAPH_STORAGE = os.environ.get("LIGHTRAG_GRAPH_STORAGE", "NetworkXStorage")
DOC_STATUS_STORAGE = os.environ.get("LIGHTRAG_DOC_STATUS_STORAGE", "JsonDocStatusStorage")

rag = LightRAG(
    # ... other params
    kv_storage=KV_STORAGE,
    vector_storage=VECTOR_STORAGE,
    graph_storage=GRAPH_STORAGE,
    doc_status_storage=DOC_STATUS_STORAGE,
)
```

**Error if missing**: Uses file-based storage, returns `[no-context]`

### 4. Correct Ollama Initialization Pattern
**Reference**: `examples/lightrag_ollama_demo.py`

**Correct Pattern**:
```python
rag = LightRAG(
    working_dir=WORKING_DIR,
    llm_model_func=ollama_model_complete,  # Pass directly, not wrapped
    llm_model_name=LLM_MODEL,              # Use dedicated parameter
    llm_model_kwargs={                      # Use kwargs dict
        "host": LLM_HOST,
        "options": {"num_ctx": 32768},
    },
    embedding_func=EmbeddingFunc(
        embedding_dim=EMBEDDING_DIM,
        max_token_size=8192,
        func=lambda texts: ollama_embed(
            texts,
            embed_model=EMBEDDING_MODEL,
            host=EMBEDDING_HOST
        ),
    ),
)
```

**Wrong Pattern** (causes error):
```python
# ❌ DO NOT wrap ollama_model_complete with custom function
async def llm_func(prompt, **kwargs):
    return await ollama_model_complete(
        prompt,
        model=LLM_MODEL,  # Conflict: passed as arg AND in kwargs
        **kwargs
    )
```

**Error**: "_ollama_model_if_cache() got multiple values for argument 'model'"

## Environment Variables Required

### From .env (must propagate to container)
```bash
WORKSPACE=production
LIGHTRAG_KV_STORAGE=PGKVStorage
LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
LIGHTRAG_GRAPH_STORAGE=Neo4JStorage
LIGHTRAG_DOC_STATUS_STORAGE=PGDocStatusStorage
```

### LLM Configuration
```bash
LIGHTRAG_LLM_MODEL=llama3.2:latest
LIGHTRAG_LLM_HOST=http://localhost:11434
LIGHTRAG_EMBEDDING_MODEL=bge-m3:latest
LIGHTRAG_EMBEDDING_HOST=http://localhost:11434
LIGHTRAG_EMBEDDING_DIM=1024
```

### Working Directory
```bash
LIGHTRAG_WORKING_DIR=/data/lightrag_data
```

## Docker Integration

### Container Configuration (docker-compose.yml)
```yaml
lightrag-mcp:
  container_name: lightrag-mcp
  build:
    context: .
    dockerfile: Dockerfile.mcp
  image: lightrag-mcp:latest
  depends_on:
    lightrag:
      condition: service_healthy
  volumes:
    - /data/claraly/rag/lightrag:/data/lightrag_data
  env_file:
    - .env
  environment:
    - WORKSPACE=${WORKSPACE}
    - LIGHTRAG_WORKING_DIR=/data/lightrag_data
    - LIGHTRAG_LLM_MODEL=${LLM_MODEL}
    - LIGHTRAG_LLM_HOST=${LLM_BINDING_HOST}
    - LIGHTRAG_EMBEDDING_MODEL=${EMBEDDING_MODEL}
    - LIGHTRAG_EMBEDDING_HOST=${EMBEDDING_BINDING_HOST}
    - LIGHTRAG_EMBEDDING_DIM=${EMBEDDING_DIM}
  restart: unless-stopped
```

### Claude Code MCP Configuration
Uses stdio transport via docker exec:
```json
{
  "mcpServers": {
    "lightrag": {
      "command": "docker",
      "args": [
        "exec",
        "-i",
        "lightrag-mcp",
        "python3",
        "-u",
        "/app/lightrag_mcp.py"
      ]
    }
  }
}
```

## Validation

### Successful Query Result
Query: "covenant clinics"
Returns:
- 60 entities from knowledge graph
- 140+ relationships
- 20 original document chunks
- Comprehensive organizational data

### Troubleshooting

**If query returns `[no-context]`**:
1. Check WORKSPACE variable: `docker compose exec lightrag-mcp env | grep WORKSPACE`
2. Check storage backends: `docker compose exec lightrag-mcp env | grep STORAGE`
3. Verify lightrag container is healthy: `docker compose ps`
4. Check logs: `docker compose logs lightrag-mcp`

**If initialization fails**:
1. Verify `initialize_storages()` is called before `initialize_pipeline_status()`
2. Check database connectivity (PostgreSQL port 5433, Neo4j port 7687)
3. Verify volume mounts for `/data/lightrag_data`

## Files Organization

### Production Files
- `lightrag_mcp.py` - Working MCP server
- `docker-compose.yml` - Container orchestration
- `Dockerfile.mcp` - MCP container build

### Scripts (moved to scripts/)
- `scripts/install_mcp_deps.sh` - MCP dependencies setup
- `scripts/update_claude_config.sh` - Claude config update utility

### Removed (obsolete)
- `lightrag_mcp_server.py` - Old stdio version
- `lightrag_mcp_server_http.py` - Unused HTTP/SSE version

## Reference Implementation
Always refer to `examples/lightrag_ollama_demo.py` for correct Ollama initialization patterns.
