# LightRAG MCP Server - Technical Patterns and Code References

## MCP Server Implementation Pattern

### Correct MCP SSE Integration with Starlette

**Location**: `lightrag_mcp_server_http.py:300-320`

```python
from mcp.server import Server
from mcp.server.sse import SseServerTransport
from starlette.applications import Starlette
from starlette.routing import Mount

# Create MCP server instance
app = Server("lightrag-mcp-http")

# Define MCP tools (@app.list_tools, @app.call_tool, etc.)

# Create SSE transport
sse_transport = SseServerTransport("/messages")

# ASGI app that handles MCP protocol over SSE
async def mcp_app(scope, receive, send):
    """ASGI app that handles MCP protocol over SSE"""
    async with sse_transport.connect_sse(scope, receive, send) as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            app.create_initialization_options()
        )

# Mount as Starlette route
starlette_app = Starlette(
    debug=True,
    routes=[Mount("/sse", app=mcp_app)]
)
```

**Key Points**:
- `SseServerTransport` is NOT a context manager itself
- Use `connect_sse()` method which IS a context manager
- Mount as ASGI app, not as a Route endpoint
- Trailing slash in URL is handled by Starlette redirect

## LightRAG Initialization Pattern

**Location**: `lightrag_mcp_server_http.py:34-73`

```python
from lightrag import LightRAG, QueryParam
from lightrag.llm.ollama import ollama_model_complete, ollama_embed
from lightrag.utils import EmbeddingFunc

async def initialize_rag():
    """Initialize LightRAG with Ollama models"""
    global rag
    
    if rag is not None:
        return rag
    
    # LLM function wrapper
    async def llm_model_func(prompt, system_prompt=None, history_messages=[], **kwargs) -> str:
        return await ollama_model_complete(
            prompt,
            system_prompt=system_prompt,
            history_messages=history_messages,
            host=LLM_HOST,
            model=LLM_MODEL,
            options={"num_ctx": 32768},
            **kwargs
        )
    
    # Embedding function wrapper
    async def embedding_func(texts: list[str]) -> list[list[float]]:
        embeddings = await ollama_embed(
            texts,
            embed_model=EMBEDDING_MODEL,
            host=EMBEDDING_HOST
        )
        return embeddings.tolist()  # IMPORTANT: Convert numpy to list
    
    # Create LightRAG instance
    rag = LightRAG(
        working_dir=WORKING_DIR,
        llm_model_func=llm_model_func,
        embedding_func=EmbeddingFunc(
            embedding_dim=EMBEDDING_DIM,
            max_token_size=8192,
            func=embedding_func
        )
    )
    
    # CRITICAL: Must initialize storages before use
    await rag.initialize_storages()
    
    return rag
```

**Critical Details**:
1. Function is `ollama_embed` (not `ollama_embedding`)
2. Returns numpy array, must convert to list with `.tolist()`
3. Must call `await rag.initialize_storages()` before operations
4. Import from `lightrag.llm.ollama` (not `lightrag.llm`)

## MCP Tool Definition Pattern

**Location**: `lightrag_mcp_server_http.py:95-169`

```python
@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available LightRAG query tools"""
    return [
        Tool(
            name="query_lightrag",
            description="Query the LightRAG knowledge base. Supports multiple search modes...",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The question or search query"
                    },
                    "mode": {
                        "type": "string",
                        "enum": ["naive", "local", "global", "hybrid", "mix", "bypass"],
                        "default": "hybrid",
                        "description": """Search/retrieval mode:
• naive: Basic vector similarity search without knowledge graph...
• local: Context-dependent search focusing on local knowledge graph...
• global: Search across entire knowledge graph using global relationships...
• hybrid: Combines both local and global knowledge graph retrieval...
• mix: Integrates knowledge graph with vector retrieval...
• bypass: Passes query directly to LLM without retrieval..."""
                    },
                    "only_need_context": {
                        "type": "boolean",
                        "default": True,
                        "description": "If true, returns only raw context without LLM synthesis..."
                    }
                },
                "required": ["query"]
            }
        )
    ]
```

**Best Practices**:
- Detailed descriptions for each enum value
- Clear default values
- Explicit behavior documentation for Claude to understand
- Default to `only_need_context=true` to avoid double LLM processing

## Docker Configuration Pattern

**Lean MCP Dockerfile** (`Dockerfile.mcp`):

```dockerfile
FROM python:3.11-slim

# Install uv for fast dependency management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app
COPY lightrag_mcp_server_http.py /app/

# Install dependencies using uv (fast!)
RUN uv pip install --system \
    lightrag-hku \
    mcp \
    starlette \
    uvicorn[standard] \
    sse-starlette

EXPOSE 9622
CMD ["python", "/app/lightrag_mcp_server_http.py"]
```

**Key Design Decisions**:
1. Lean base image (python:3.11-slim, not full LightRAG image)
2. Copy uv from official image (fast package installation)
3. Install only necessary dependencies for MCP layer
4. Single Python file deployment (simple, fast builds)

**Docker Compose Integration** (`docker-compose.yml:186-219`):

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
  ports:
    - "9622:9622"
  volumes:
    - /data/claraly/rag/lightrag:/data/lightrag_data
  env_file:
    - .env
  environment:
    - LIGHTRAG_WORKING_DIR=/data/lightrag_data
    - LIGHTRAG_LLM_MODEL=${LLM_MODEL}
    - LIGHTRAG_LLM_HOST=${LLM_BINDING_HOST}
    - LIGHTRAG_EMBEDDING_MODEL=${EMBEDDING_MODEL}
    - LIGHTRAG_EMBEDDING_HOST=${EMBEDDING_BINDING_HOST}
    - LIGHTRAG_EMBEDDING_DIM=${EMBEDDING_DIM}
    - MCP_PORT=9622
    - MCP_HOST=0.0.0.0
  restart: unless-stopped
  healthcheck:
    test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:9622/sse')"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 60s
```

## Common Pitfalls and Solutions

### Pitfall 1: Wrong Import Path
```python
# ❌ Wrong
from lightrag.llm import ollama_model_complete, ollama_embedding

# ✅ Correct
from lightrag.llm.ollama import ollama_model_complete, ollama_embed
```

### Pitfall 2: Numpy Array Return
```python
# ❌ Wrong - Returns numpy array
embeddings = await ollama_embed(texts, embed_model=..., host=...)
return embeddings

# ✅ Correct - Convert to list
embeddings = await ollama_embed(texts, embed_model=..., host=...)
return embeddings.tolist()
```

### Pitfall 3: Missing Storage Initialization
```python
# ❌ Wrong - No initialization
rag = LightRAG(working_dir=..., llm_model_func=..., embedding_func=...)
await rag.aquery("question")  # Will fail with __aenter__ error

# ✅ Correct
rag = LightRAG(working_dir=..., llm_model_func=..., embedding_func=...)
await rag.initialize_storages()  # Must initialize first
await rag.aquery("question")
```

### Pitfall 4: SSE Transport Context Manager
```python
# ❌ Wrong - SseServerTransport is not a context manager
async with SseServerTransport("/messages") as transport:
    await app.run(transport.read_stream, ...)

# ✅ Correct - Use connect_sse method
transport = SseServerTransport("/messages")
async with transport.connect_sse(scope, receive, send) as (read_stream, write_stream):
    await app.run(read_stream, write_stream, ...)
```

## Claude Code Configuration

**Global MCP Server Config** (`~/.claude.json`):

```json
{
  "mcpServers": {
    "lightrag": {
      "type": "sse",
      "url": "http://localhost:9622/sse/"
    }
  }
}
```

**Key Points**:
- Type is `"sse"` (not `"stdio"` or `"http"`)
- URL includes trailing slash: `/sse/`
- Use `localhost` for same-machine access
- Use full hostname/IP for remote access

## Performance Characteristics

- **Container Build Time**: ~2-3 seconds (with cache)
- **Startup Time**: ~3-4 seconds (Ollama dependency installation)
- **SSE Connection**: Persistent, low-latency streaming
- **Query Latency**: Depends on Ollama response time
- **Memory Footprint**: ~100-200MB (lean Python + dependencies)

## Testing Verification

```bash
# Check service is running
docker compose logs lightrag-mcp --tail 20

# Test SSE endpoint (should stream events)
curl http://localhost:9622/sse/

# Expected: HTTP 200, content-type: text/event-stream, persistent connection
```