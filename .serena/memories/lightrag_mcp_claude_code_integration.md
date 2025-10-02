# LightRAG MCP Integration with Claude Code

## Session Summary
Successfully configured LightRAG MCP server integration with Claude Code for remote knowledge base access.

## Configuration Details

### MCP Server Setup
- **Container**: `lightrag-mcp` running via Docker Compose
- **Image**: Built from `Dockerfile.mcp`
- **Port**: 9622 (HTTP/SSE transport)
- **Health**: Container healthy and responding to SSE connections
- **Transport**: Server-Sent Events (SSE) for remote MCP access

### Claude Code Configuration
**File**: `~/.claude.json`
```json
"lightrag": {
  "type": "sse",
  "url": "http://localhost:9622/sse/"
}
```

**Key Decision**: Use `localhost` instead of `prodbox.intellinum.co` since Claude Code and MCP server run on same machine.

### MCP Server Implementation
**File**: `lightrag_mcp_server_http.py`
- HTTP/SSE transport using Starlette + Uvicorn
- Endpoint: `/sse/` (note trailing slash required)
- SSE handshake: Returns session endpoint for message exchange
- Async initialization with proper storage setup

### Available Tools
1. **query_lightrag**: Query knowledge base with multiple modes
   - Modes: naive, local, global, hybrid, mix, bypass
   - Returns raw context (default) or LLM-synthesized answers
   - Configurable top_k and chunk_top_k parameters

2. **insert_document**: Add documents to knowledge base
   - Automatic entity/relationship extraction
   - Async document processing

### Environment Variables (Docker)
```bash
LIGHTRAG_WORKING_DIR=/data/lightrag_data
LIGHTRAG_LLM_MODEL=${LLM_MODEL}
LIGHTRAG_LLM_HOST=${LLM_BINDING_HOST}
LIGHTRAG_EMBEDDING_MODEL=${EMBEDDING_MODEL}
LIGHTRAG_EMBEDDING_HOST=${EMBEDDING_BINDING_HOST}
LIGHTRAG_EMBEDDING_DIM=${EMBEDDING_DIM}
MCP_PORT=9622
MCP_HOST=0.0.0.0
```

## Connection Verification
- Server logs show successful SSE connections from `192.168.192.1` (Claude Code)
- Health checks passing with HTTP 200 responses
- SSE endpoint properly returning session IDs for message exchange

## Troubleshooting Notes
1. **SSE Timeout**: Plain HTTP GET to `/sse/` will hang - this is expected as it waits for MCP protocol handshake
2. **Hostname vs Localhost**: Use `localhost` when both services on same machine
3. **Trailing Slash**: `/sse/` endpoint requires trailing slash (307 redirect from `/sse`)
4. **Restart Required**: Claude Code must be restarted after config changes to pick up new MCP servers

## Docker Compose Integration
MCP server depends on main LightRAG service:
```yaml
lightrag-mcp:
  depends_on:
    lightrag:
      condition: service_healthy
  ports:
    - "9622:9622"
  volumes:
    - /data/claraly/rag/lightrag:/data/lightrag_data
```

## Next Steps for User
1. Restart Claude Code completely (exit and relaunch)
2. Run `/mcp` to verify LightRAG appears in server list
3. Test query with LightRAG tools once connected

## Technical Insights
- HTTP/SSE MCP transport enables remote access without stdio limitations
- SSE provides persistent connection for bidirectional communication
- LightRAG initialization is async and must complete before tool calls
- Multiple query modes allow flexible retrieval strategies (vector, graph, hybrid)
