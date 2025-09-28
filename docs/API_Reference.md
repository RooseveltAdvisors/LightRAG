# ClaralyRAG API Reference

## Overview

ClaralyRAG provides a comprehensive REST API for document management, knowledge graph operations, and intelligent querying. The API is built with FastAPI and includes OpenAPI documentation available at `/docs`.

## Base URL

```
http://localhost:9621
```

## Authentication

- **Default**: No authentication required
- **Optional**: JWT-based authentication via `AUTH_ACCOUNTS` configuration
- **API Key**: Optional API key protection via `LIGHTRAG_API_KEY`

## API Endpoints

### System Endpoints

#### Health Check
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "working_directory": "/app/data/rag_storage",
  "input_directory": "/app/data/inputs",
  "configuration": {
    "llm_binding": "ollama",
    "llm_model": "llama3.2:latest",
    "embedding_binding": "ollama",
    "embedding_model": "bge-m3:latest",
    "kv_storage": "PGKVStorage",
    "graph_storage": "Neo4JStorage",
    "vector_storage": "PGVectorStorage"
  },
  "auth_mode": "disabled",
  "pipeline_busy": false,
  "core_version": "1.4.9",
  "api_version": "0233"
}
```

### Document Management

#### Upload Text Document
```http
POST /documents/text
Content-Type: application/json

{
  "text": "Document content here...",
  "description": "Document description (optional)",
  "metadata": {
    "source": "custom",
    "category": "knowledge"
  }
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Text successfully received. Processing will continue in background.",
  "track_id": "insert_20250928_043629_eb80019b"
}
```

#### Upload File Document
```http
POST /documents/file
Content-Type: multipart/form-data

file: <file_upload>
description: "Optional description"
```

**Supported formats:** PDF, DOC, DOCX, PPT, PPTX, TXT, CSV, MD

#### Get Document Status
```http
GET /documents/status_counts
```

**Response:**
```json
{
  "status_counts": {
    "processed": 5,
    "processing": 1,
    "failed": 0,
    "all": 6
  }
}
```

#### List Documents
```http
GET /documents/list?limit=20&offset=0
```

**Response:**
```json
{
  "documents": [
    {
      "doc_id": "doc-123",
      "file_path": "document.txt",
      "status": "processed",
      "created_at": "2025-09-28T04:30:00Z",
      "metadata": {}
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

#### Delete Document
```http
DELETE /documents/{doc_id}
```

**Response:**
```json
{
  "status": "success",
  "message": "Document deleted successfully"
}
```

#### Clear All Documents
```http
DELETE /documents/clear
```

### Query System

#### Standard Query
```http
POST /query
Content-Type: application/json

{
  "query": "What is artificial intelligence?",
  "mode": "hybrid",
  "only_need_context": false,
  "use_rerank": false,
  "top_k": 40,
  "chunk_top_k": 20,
  "max_tokens": 30000
}
```

**Query Modes:**
- `naive`: Basic vector similarity search
- `local`: Context-dependent graph search
- `global`: Global knowledge graph search
- `hybrid`: Combined local + global (recommended)
- `mix`: Integrated KG + vector retrieval

**Response:**
```json
{
  "response": "Artificial intelligence (AI) refers to...",
  "references": [
    {
      "reference_id": "1",
      "file_path": "ai_document.pdf"
    }
  ]
}
```

#### Streaming Query
```http
POST /query/stream
Content-Type: application/json

{
  "query": "Explain machine learning",
  "mode": "hybrid"
}
```

**Response:** Server-Sent Events (SSE) stream

### Knowledge Graph Operations

#### Get Graph Data
```http
GET /graph/data?limit=1000
```

**Response:**
```json
{
  "nodes": [
    {
      "id": "entity_123",
      "label": "Apple Inc.",
      "type": "Organization",
      "description": "Technology company...",
      "weight": 0.95
    }
  ],
  "edges": [
    {
      "source": "entity_123",
      "target": "entity_456",
      "label": "founded_by",
      "description": "Founded by relationship",
      "weight": 0.87
    }
  ]
}
```

#### Search Graph
```http
POST /graph/search
Content-Type: application/json

{
  "query": "Apple",
  "limit": 100
}
```

#### Delete Graph Entities
```http
DELETE /graph/entities
Content-Type: application/json

{
  "entity_names": ["Entity Name 1", "Entity Name 2"]
}
```

### Ollama Compatible API

ClaralyRAG provides Ollama-compatible endpoints for seamless integration with AI chat applications:

#### Chat Completion
```http
POST /ollama/api/chat
Content-Type: application/json

{
  "model": "lightrag",
  "messages": [
    {
      "role": "user",
      "content": "What is LightRAG?"
    }
  ],
  "stream": false
}
```

#### List Models
```http
GET /ollama/api/tags
```

**Response:**
```json
{
  "models": [
    {
      "name": "lightrag:latest",
      "digest": "sha256:...",
      "size": 0,
      "modified_at": "2025-09-28T00:00:00Z"
    }
  ]
}
```

## Error Handling

### HTTP Status Codes

- `200`: Success
- `400`: Bad Request (invalid parameters)
- `401`: Unauthorized (when auth is enabled)
- `404`: Not Found (resource doesn't exist)
- `422`: Validation Error (invalid request body)
- `500`: Internal Server Error

### Error Response Format

```json
{
  "detail": "Error description",
  "error_type": "ValidationError",
  "status_code": 422
}
```

## Rate Limiting

- No built-in rate limiting
- Concurrent request limits controlled by `MAX_ASYNC` setting
- Document processing limits controlled by `MAX_PARALLEL_INSERT`

## Configuration

Key environment variables affecting API behavior:

```env
# Server Configuration
HOST=0.0.0.0
PORT=9621
WORKERS=2

# Authentication (Optional)
AUTH_ACCOUNTS=admin:password,user:pass
LIGHTRAG_API_KEY=your-api-key

# Processing Limits
MAX_ASYNC=4
MAX_PARALLEL_INSERT=2

# LLM Configuration
LLM_TIMEOUT=600
EMBEDDING_TIMEOUT=120

# Storage Configuration
LIGHTRAG_KV_STORAGE=PGKVStorage
LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
LIGHTRAG_GRAPH_STORAGE=Neo4JStorage
```

## WebSocket Support

Real-time updates available via WebSocket connections for:
- Document processing status
- Query progress (streaming)
- Graph updates

Connect to: `ws://localhost:9621/ws`

## CORS Configuration

```env
CORS_ORIGINS=*  # Allow all origins (default)
# CORS_ORIGINS=http://localhost:3000,https://yourdomain.com
```

## OpenAPI Documentation

Interactive API documentation available at:
- Swagger UI: `http://localhost:9621/docs`
- ReDoc: `http://localhost:9621/redoc`
- OpenAPI JSON: `http://localhost:9621/openapi.json`

## SDK and Client Libraries

### Python Client Example

```python
import requests

# Upload document
response = requests.post(
    "http://localhost:9621/documents/text",
    json={
        "text": "Your document content",
        "description": "Test document"
    }
)

# Query system
response = requests.post(
    "http://localhost:9621/query",
    json={
        "query": "What is this about?",
        "mode": "hybrid"
    }
)
print(response.json()["response"])
```

### JavaScript Client Example

```javascript
// Upload document
const uploadResponse = await fetch('http://localhost:9621/documents/text', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    text: 'Your document content',
    description: 'Test document'
  })
});

// Query system
const queryResponse = await fetch('http://localhost:9621/query', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    query: 'What is this about?',
    mode: 'hybrid'
  })
});

const result = await queryResponse.json();
console.log(result.response);
```

## Performance Considerations

### Optimization Settings

```env
# Query Performance
TOP_K=40                    # Entities/relations retrieved
CHUNK_TOP_K=20              # Chunks for naive search
MAX_TOTAL_TOKENS=30000      # Total context limit

# Processing Performance
MAX_ASYNC=4                 # Concurrent LLM requests
MAX_PARALLEL_INSERT=2       # Parallel document processing
EMBEDDING_FUNC_MAX_ASYNC=8  # Embedding concurrency
```

### Caching

```env
ENABLE_LLM_CACHE=true              # Cache LLM responses
ENABLE_LLM_CACHE_FOR_EXTRACT=true  # Cache extraction results
```

## Monitoring and Logging

### Health Monitoring

```bash
# Check system health
curl http://localhost:9621/health

# Monitor document processing
curl http://localhost:9621/documents/status_counts

# Check pipeline status
curl http://localhost:9621/documents/pipeline_status
```

### Log Configuration

```env
LOG_LEVEL=INFO              # Logging level
LOG_MAX_BYTES=10485760      # Log file size limit
LOG_BACKUP_COUNT=5          # Log rotation count
LOG_DIR=/app/logs           # Log directory
```

## Security Best Practices

1. **Enable Authentication**: Set `AUTH_ACCOUNTS` for production
2. **Use API Keys**: Configure `LIGHTRAG_API_KEY` for API access
3. **Restrict CORS**: Set specific origins in `CORS_ORIGINS`
4. **Use HTTPS**: Deploy behind SSL termination
5. **Monitor Access**: Enable comprehensive logging
6. **Validate Inputs**: API includes built-in input validation

## Troubleshooting

### Common Issues

1. **Document Processing Stuck**
   ```bash
   # Check pipeline status
   curl http://localhost:9621/documents/pipeline_status

   # Restart processing
   curl -X POST http://localhost:9621/documents/pipeline/restart
   ```

2. **Query Timeouts**
   - Increase `LLM_TIMEOUT` setting
   - Reduce `MAX_TOTAL_TOKENS` for shorter context
   - Use `naive` mode for faster queries

3. **Memory Issues**
   - Reduce `MAX_ASYNC` and `MAX_PARALLEL_INSERT`
   - Clear document cache periodically
   - Monitor system resources

### Debug Mode

Enable debug logging:
```env
LOG_LEVEL=DEBUG
VERBOSE=True
```

For comprehensive troubleshooting, see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md).