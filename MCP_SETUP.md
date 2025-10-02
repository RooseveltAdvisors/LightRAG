# LightRAG MCP Setup for Claude Code

## Quick Start

**Apply configuration and restart Claude Code:**
```bash
cp /tmp/claude_lightrag.json ~/.claude.json
# Then restart Claude Code
```

## Simplified Code

### File Size Comparison
- `lightrag_mcp.py` - **4.9KB** (new, simplified)
- `lightrag_mcp_server.py` - 11KB (old stdio version)
- `lightrag_mcp_server_http.py` - 12KB (failed SSE version)

### What Was Simplified
- ✅ **313 lines → 150 lines** (52% reduction)
- ✅ Removed HTTP/SSE server complexity
- ✅ Removed OAuth handling
- ✅ Removed resource listing
- ✅ Simplified tool definitions
- ✅ Cleaner error handling
- ✅ **5 dependencies → 2** (lightrag-hku, mcp)

## Configuration

**Claude Code** (`~/.claude.json`):
```json
{
  "mcpServers": {
    "lightrag": {
      "type": "stdio",
      "command": "docker",
      "args": ["exec", "-i", "lightrag-mcp", "python", "/app/lightrag_mcp.py"]
    }
  }
}
```

## Available Tools

1. **query** - Search knowledge base (modes: naive, local, global, hybrid, mix)
2. **insert** - Add documents to knowledge base

## Troubleshooting

```bash
# Container status
docker compose ps lightrag-mcp

# Restart container
docker compose up -d lightrag-mcp

# Test manually
echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | \
  docker exec -i lightrag-mcp python /app/lightrag_mcp.py

# Check logs
docker compose logs lightrag-mcp
```
