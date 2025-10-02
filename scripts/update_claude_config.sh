#!/bin/bash
# Update Claude Code configuration to use stdio transport via docker exec

CONFIG_FILE="$HOME/.claude.json"
BACKUP_FILE="$HOME/.claude.json.backup.$(date +%s)"

echo "Backing up current config to: $BACKUP_FILE"
cp "$CONFIG_FILE" "$BACKUP_FILE"

# Create new config with stdio transport over docker exec
cat > /tmp/claude_lightrag.json << 'EOF'
{
  "mcpServers": {
    "lightrag": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "exec",
        "-i",
        "lightrag-mcp",
        "python",
        "/app/lightrag_mcp.py"
      ]
    }
  }
}
EOF

echo ""
echo "✅ New configuration created. To apply:"
echo ""
echo "Option 1 - Replace entire config (if you only have lightrag MCP):"
echo "  cp /tmp/claude_lightrag.json ~/.claude.json"
echo ""
echo "Option 2 - Manually merge with existing MCPs:"
echo "  cat /tmp/claude_lightrag.json"
echo "  # Then manually add the lightrag section to your ~/.claude.json"
echo ""
echo "📋 Prerequisites:"
echo "  1. Rebuild and restart the container:"
echo "     docker compose up -d --build lightrag-mcp"
echo ""
echo "  2. Apply the configuration:"
echo "     cp /tmp/claude_lightrag.json ~/.claude.json"
echo ""
echo "  3. Restart Claude Code"
echo ""
echo "📋 What changed:"
echo "  - Transport: SSE → stdio (more reliable)"
echo "  - Connection: Docker exec for containerized stdio"
echo "  - Environment: All config via docker-compose.yml"
