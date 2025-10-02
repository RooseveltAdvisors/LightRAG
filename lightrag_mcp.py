#!/usr/bin/env python3
"""
LightRAG MCP Server (stdio transport)
Provides Claude Code access to LightRAG knowledge base
"""
import asyncio
import os
from typing import Any

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

from lightrag import LightRAG, QueryParam
from lightrag.llm.ollama import ollama_model_complete, ollama_embed
from lightrag.utils import EmbeddingFunc
from lightrag.kg.shared_storage import initialize_pipeline_status

# Configuration from environment
WORKING_DIR = os.environ.get("LIGHTRAG_WORKING_DIR", "./lightrag_data")
LLM_MODEL = os.environ.get("LIGHTRAG_LLM_MODEL", "llama3.2:latest")
LLM_HOST = os.environ.get("LIGHTRAG_LLM_HOST", "http://localhost:11434")
EMBEDDING_MODEL = os.environ.get("LIGHTRAG_EMBEDDING_MODEL", "bge-m3:latest")
EMBEDDING_HOST = os.environ.get("LIGHTRAG_EMBEDDING_HOST", "http://localhost:11434")
EMBEDDING_DIM = int(os.environ.get("LIGHTRAG_EMBEDDING_DIM", "1024"))

# Storage backend configuration
KV_STORAGE = os.environ.get("LIGHTRAG_KV_STORAGE", "JsonKVStorage")
VECTOR_STORAGE = os.environ.get("LIGHTRAG_VECTOR_STORAGE", "NanoVectorDBStorage")
GRAPH_STORAGE = os.environ.get("LIGHTRAG_GRAPH_STORAGE", "NetworkXStorage")
DOC_STATUS_STORAGE = os.environ.get("LIGHTRAG_DOC_STATUS_STORAGE", "JsonDocStatusStorage")

# Global RAG instance
rag: LightRAG | None = None

# Create MCP server
app = Server("lightrag")


async def initialize_rag():
    """Initialize LightRAG with Ollama models"""
    global rag
    if rag:
        return rag

    rag = LightRAG(
        working_dir=WORKING_DIR,
        llm_model_func=ollama_model_complete,
        llm_model_name=LLM_MODEL,
        llm_model_kwargs={
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
        kv_storage=KV_STORAGE,
        vector_storage=VECTOR_STORAGE,
        graph_storage=GRAPH_STORAGE,
        doc_status_storage=DOC_STATUS_STORAGE,
    )

    await rag.initialize_storages()
    await initialize_pipeline_status()
    return rag


@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available tools"""
    return [
        Tool(
            name="query",
            description="Query the LightRAG knowledge base with multiple search modes",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The search query"
                    },
                    "mode": {
                        "type": "string",
                        "enum": ["naive", "local", "global", "hybrid", "mix"],
                        "default": "hybrid",
                        "description": "naive=vector search, local=local graph, global=global graph, hybrid=both, mix=comprehensive"
                    },
                    "top_k": {
                        "type": "integer",
                        "default": 40,
                        "description": "Number of entities/relationships to retrieve"
                    }
                },
                "required": ["query"]
            }
        ),
        Tool(
            name="insert",
            description="Insert document into LightRAG knowledge base",
            inputSchema={
                "type": "object",
                "properties": {
                    "content": {
                        "type": "string",
                        "description": "Document content to insert"
                    }
                },
                "required": ["content"]
            }
        )
    ]


@app.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Handle tool calls"""
    global rag

    if not rag:
        await initialize_rag()

    try:
        if name == "query":
            result = await rag.aquery(
                arguments["query"],
                param=QueryParam(
                    mode=arguments.get("mode", "hybrid"),
                    only_need_context=True,
                    top_k=arguments.get("top_k", 40)
                )
            )
            if result is None or result == "":
                result = "[no-context]"
            return [TextContent(type="text", text=result)]

        elif name == "insert":
            await rag.ainsert(arguments["content"])
            return [TextContent(
                type="text",
                text=f"Inserted {len(arguments['content'])} characters into knowledge base"
            )]

        else:
            return [TextContent(type="text", text=f"Unknown tool: {name}")]

    except Exception as e:
        return [TextContent(type="text", text=f"Error: {str(e)}")]


async def main():
    """Main entry point"""
    try:
        await initialize_rag()
        async with stdio_server() as (read_stream, write_stream):
            await app.run(read_stream, write_stream, app.create_initialization_options())
    finally:
        if rag:
            await rag.finalize_storages()


if __name__ == "__main__":
    asyncio.run(main())
