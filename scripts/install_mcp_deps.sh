#!/bin/bash
# Install dependencies for LightRAG MCP server (stdio version)

echo "Installing LightRAG MCP Server dependencies..."
echo ""

# Install required packages
pip3 install --user mcp lightrag-hku

echo ""
echo "✅ Installation complete!"
echo ""
echo "Verify installation:"
python3 -c "import mcp; import lightrag; print('✅ All dependencies available')"
