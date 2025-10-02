# LightRAG MCP Troubleshooting Session

## Problem
Claude Code failing to connect to LightRAG MCP server with error: "Failed to reconnect to lightrag"

## Investigation Summary

### Server Status
✅ **Container Health**: lightrag-mcp running and healthy
✅ **Port Listening**: 9622 accessible on localhost and network
✅ **SSE Endpoint**: Responding with HTTP 200 and proper SSE handshake
✅ **Logs**: Showing successful connections from 192.168.192.1 (Claude Code IP)

### Configuration Verified
**File**: `~/.claude.json`
```json
"lightrag": {
  "type": "sse",
  "url": "http://localhost:9622/sse/"
}
```

### Technical Discoveries

#### SSE Endpoint Behavior
- Endpoint `/sse/` returns SSE stream with session endpoint
- OAuth discovery endpoint `/sse/.well-known/openid-configuration` also returns SSE stream (not JSON)
- This is expected behavior for MCP SSE transport - handles OAuth internally
- All requests under `/sse` mount are treated as SSE connections

#### Connection Pattern
```
Claude Code (192.168.192.1) -> GET /sse/ -> HTTP 200
                             -> GET /sse/.well-known/openid-configuration -> HTTP 200
```

Both endpoints successfully respond, but Claude Code still reports connection failure.

### Attempted Solutions

1. **Hostname Change**: Changed `prodbox.intellinum.co` → `localhost`
   - Reason: Both services on same machine
   - Result: Still failing

2. **OAuth Endpoint Configuration**: Tried adding explicit OAuth JSON routes
   - Attempted to override SSE mount with Route definitions
   - Result: Mount catches all `/sse/*` requests (routing order issue)
   - Reverted to let SSE transport handle OAuth internally

3. **Multiple Restarts**: Both MCP server and Claude Code restarted
   - MCP server reinitializes properly
   - Claude Code config reloaded
   - Result: Connection still fails

### Current Hypothesis

The issue may be:

1. **SSE Transport Incompatibility**: MCP Python `SseServerTransport` may not be fully compatible with Claude Code's SSE client expectations
   
2. **OAuth Handshake Issue**: Claude Code might expect specific OAuth response format that differs from what `SseServerTransport` provides

3. **Message Protocol Mismatch**: After SSE connection established, the MCP protocol message format might not match expectations

4. **Network Stack Issue**: Even though both on localhost, network stack routing might have issues (192.168.192.1 in logs suggests Docker network)

### Alternative Approaches to Consider

1. **Switch to stdio Transport**: 
   - More reliable for local MCP servers
   - No OAuth/HTTP complexity
   - Would require changing Docker setup to expose stdio interface

2. **Use HTTP (non-SSE) Transport**:
   - Some MCP clients support simple HTTP POST
   - Simpler than SSE streaming
   - Check if Claude Code supports this

3. **Debug Claude Code Logs**:
   - Look for specific error messages in Claude Code output
   - May reveal exact handshake failure point

4. **Test with Reference MCP SSE Server**:
   - Use a known-working SSE MCP server to verify Claude Code's SSE support
   - Isolate whether issue is our implementation or general incompatibility

### Code State

**Current Implementation**: `lightrag_mcp_server_http.py`
- Using Python MCP SDK `mcp.server.sse.SseServerTransport`
- Starlette + Uvicorn for HTTP server
- Mount at `/sse` with ASGI bridge to MCP app
- LightRAG async initialization on startup

**Known Working**:
- SSE handshake and session endpoint generation
- MCP server initialization and tool registration  
- OAuth discovery endpoints (via SSE transport)
- Docker health checks passing

**Unknown/Failing**:
- Actual MCP protocol message exchange
- Tool discovery from Claude Code side
- Persistent connection maintenance

### Next Investigation Steps

1. Check Claude Code debug logs for specific error
2. Test with simpler MCP SSE reference implementation
3. Consider stdio transport as proven alternative
4. Verify MCP SDK version compatibility with Claude Code expectations

## Files Modified
- `/data/git/zhg/prod/ClaralyRAG/lightrag_mcp_server_http.py` - Multiple OAuth routing attempts
- `/home/yuan/.claude.json` - URL configuration changes

## Lessons Learned
- SSE MCP transport is complex with OAuth discovery requirements
- Starlette routing order matters (Routes must precede Mount for precedence)
- SSE transport handles OAuth internally - manual routes interfere
- Docker network creates IP complexity even on localhost
- Connection logs showing HTTP 200 don't guarantee MCP protocol success
