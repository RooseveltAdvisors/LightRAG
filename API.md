# ClaralyRAG API Documentation

This document provides comprehensive API documentation for the ClaralyRAG system, including endpoints, usage examples, and testing procedures.

## Base URL

```
http://localhost:9621
```

For remote access, replace `localhost` with your server's IP address.

## API Overview

ClaralyRAG provides a RESTful API with the following main capabilities:
- **Document Management**: Insert, track, and manage documents
- **Query System**: Multiple query modes for information retrieval
- **Graph Operations**: Knowledge graph visualization and search
- **System Monitoring**: Health checks and status information
- **Ollama Compatibility**: Chat interface compatible with Ollama API

## Authentication

By default, authentication is **disabled**. To enable authentication, configure the following environment variables:

```env
AUTH_ACCOUNTS=admin:secure_password,user:another_password
TOKEN_SECRET=your-jwt-secret-key
```

When enabled, include the JWT token in requests:
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:9621/api/endpoint
```

## Document Management API

### Insert Text Document

Add a text document for processing and knowledge graph extraction.

**Endpoint**: `POST /documents/text`

**Request Body**:
```json
{
  "text": "Your document content here",
  "description": "Optional description of the document"
}
```

**Response**:
```json
{
  "status": "success",
  "message": "Text successfully received. Processing will continue in background.",
  "track_id": "insert_20250928_032536_f5d6e515"
}
```

**Example**:
```bash
curl -X POST http://localhost:9621/documents/text \
  -H "Content-Type: application/json" \
  -d '{
    "text": "LightRAG is a powerful Retrieval-Augmented Generation system that combines traditional vector search with knowledge graphs.",
    "description": "LightRAG overview document"
  }'
```

### Insert Multiple Documents

Add multiple text documents in a single request.

**Endpoint**: `POST /documents/texts`

**Request Body**:
```json
{
  "texts": [
    {
      "text": "First document content",
      "description": "First document"
    },
    {
      "text": "Second document content",
      "description": "Second document"
    }
  ]
}
```

### Track Document Processing

Monitor the processing status of documents.

**Endpoint**: `GET /documents/track_status/{track_id}`

**Response**:
```json
{
  "track_id": "insert_20250928_032536_f5d6e515",
  "documents": [
    {
      "id": "doc-4aece0528a1ad3ccde486e88a1e3b64b",
      "content_summary": "LightRAG is a powerful Retrieval-Augmented Generation system...",
      "content_length": 397,
      "status": "processed",
      "created_at": "2025-09-28T03:25:36.570784+00:00",
      "updated_at": "2025-09-28T03:25:36.949443+00:00",
      "track_id": "insert_20250928_032536_f5d6e515",
      "chunks_count": 1,
      "error_msg": null,
      "metadata": {
        "processing_start_time": 1759029936
      },
      "file_path": "no-file-path"
    }
  ],
  "total_count": 1,
  "status_summary": {
    "processed": 1
  }
}
```

**Status Values**:
- `pending`: Queued for processing
- `processing`: Currently being processed
- `processed`: Successfully completed
- `failed`: Processing failed (check `error_msg`)

### Get Document Status Counts

Get summary statistics of document processing status.

**Endpoint**: `GET /documents/status_counts`

**Response**:
```json
{
  "status_counts": {
    "processed": 15,
    "processing": 2,
    "pending": 1,
    "failed": 0,
    "all": 18
  }
}
```

### Get Paginated Documents

Retrieve documents with pagination and filtering.

**Endpoint**: `GET /documents/paginated`

**Query Parameters**:
- `page` (default: 1): Page number
- `page_size` (default: 20): Items per page
- `status`: Filter by status (`pending`, `processing`, `processed`, `failed`)
- `sort_by`: Sort field (`created_at`, `updated_at`, `file_path`)
- `sort_order`: Sort direction (`asc`, `desc`)

**Example**:
```bash
curl "http://localhost:9621/documents/paginated?page=1&page_size=10&status=processed&sort_by=created_at&sort_order=desc"
```

### Scan Documents

Retrieve all documents with optional filtering.

**Endpoint**: `GET /documents/scan`

**Query Parameters**:
- `status`: Filter by processing status
- `limit`: Maximum number of documents to return

### Delete Document

Remove a document and its associated data.

**Endpoint**: `DELETE /documents/delete_document`

**Request Body**:
```json
{
  "document_id": "doc-4aece0528a1ad3ccde486e88a1e3b64b"
}
```

### Clear Cache

Clear the LLM response cache.

**Endpoint**: `DELETE /documents/clear_cache`

**Response**:
```json
{
  "status": "success",
  "message": "Cache cleared successfully"
}
```

## Query API

### Basic Query

Perform retrieval-augmented generation queries with multiple modes.

**Endpoint**: `POST /query`

**Request Body**:
```json
{
  "query": "What is LightRAG?",
  "mode": "hybrid",
  "enable_rerank": false,
  "only_need_context": false
}
```

**Query Modes**:
- `naive`: Basic vector similarity search
- `local`: Context-dependent graph search
- `global`: Global knowledge graph search
- `hybrid`: Combined local + global approach
- `mix`: Integrated knowledge graph + vector retrieval

**Response**:
```json
{
  "response": "LightRAG is a powerful Retrieval-Augmented Generation system that combines traditional vector search with knowledge graphs to provide enhanced document understanding and querying capabilities...",
  "references": [
    {
      "reference_id": "1",
      "file_path": "no-file-path"
    }
  ]
}
```

**Examples**:

```bash
# Naive vector search (fastest)
curl -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is Docker?",
    "mode": "naive"
  }'

# Hybrid search (balanced)
curl -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "How does containerization help with deployment?",
    "mode": "hybrid"
  }'

# Global knowledge graph search (most comprehensive)
curl -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "How does LightRAG relate to AI and machine learning?",
    "mode": "global"
  }'
```

### Streaming Query

Get streaming responses for real-time query results.

**Endpoint**: `POST /query/stream`

**Request Body**: Same as basic query

**Response**: Server-Sent Events (SSE) stream

**Example**:
```bash
curl -X POST http://localhost:9621/query/stream \
  -H "Content-Type: application/json" \
  -d '{"query": "Explain LightRAG", "mode": "hybrid"}' \
  --no-buffer
```

### Query Data

Get structured data for queries (entities, relations, chunks).

**Endpoint**: `POST /query/data`

**Request Body**:
```json
{
  "query": "LightRAG capabilities",
  "mode": "global"
}
```

**Response**:
```json
{
  "entities": [...],
  "relations": [...],
  "chunks": [...]
}
```

## Graph API

### Search Graph Labels

Search for entities and relations in the knowledge graph.

**Endpoint**: `GET /graph/label/search`

**Query Parameters**:
- `query`: Search term
- `limit`: Maximum results (default: 20)

**Example**:
```bash
curl "http://localhost:9621/graph/label/search?query=LightRAG&limit=10"
```

**Response**:
```json
{
  "entities": [
    {
      "id": "entity-123",
      "name": "LightRAG",
      "type": "System",
      "description": "Retrieval-Augmented Generation system"
    }
  ],
  "relations": [
    {
      "id": "relation-456",
      "source": "LightRAG",
      "target": "Knowledge Graph",
      "type": "USES"
    }
  ]
}
```

### Get Popular Labels

Get most frequently occurring entities and relations.

**Endpoint**: `GET /graph/label/popular`

**Query Parameters**:
- `limit`: Maximum results (default: 300)

## System API

### Health Check

Check system health and configuration.

**Endpoint**: `GET /health`

**Response**:
```json
{
  "status": "healthy",
  "working_directory": "/app/data/rag_storage",
  "input_directory": "/app/data/inputs",
  "configuration": {
    "llm_binding": "ollama",
    "llm_binding_host": "http://playground.intellinum.co:11434",
    "llm_model": "llama3.2:latest",
    "embedding_binding": "ollama",
    "embedding_binding_host": "http://playground.intellinum.co:11434",
    "embedding_model": "bge-m3:latest",
    "kv_storage": "PGKVStorage",
    "doc_status_storage": "PGDocStatusStorage",
    "graph_storage": "Neo4JStorage",
    "vector_storage": "PGVectorStorage",
    "enable_llm_cache": true,
    "workspace": "production",
    "enable_rerank": false
  },
  "auth_mode": "disabled",
  "pipeline_busy": false,
  "core_version": "1.4.9",
  "api_version": "0233"
}
```

### Authentication Status

Check authentication configuration.

**Endpoint**: `GET /auth-status`

**Response**:
```json
{
  "auth_enabled": false,
  "accounts_configured": false
}
```

### Pipeline Status

Check document processing pipeline status.

**Endpoint**: `GET /documents/pipeline_status`

**Response**:
```json
{
  "pipeline_busy": false,
  "queue_size": 0,
  "processing_documents": []
}
```

## Ollama Compatibility API

ClaralyRAG provides Ollama-compatible endpoints for easy integration.

### Chat Completion

**Endpoint**: `POST /api/chat`

**Request Body**:
```json
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

### Generate

**Endpoint**: `POST /api/generate`

**Request Body**:
```json
{
  "model": "lightrag",
  "prompt": "Explain LightRAG capabilities",
  "stream": false
}
```

### List Models

**Endpoint**: `GET /api/tags`

**Response**:
```json
{
  "models": [
    {
      "name": "lightrag:latest",
      "modified_at": "2025-09-28T10:30:00Z",
      "size": 1000000000
    }
  ]
}
```

### Version Info

**Endpoint**: `GET /api/version`

**Response**:
```json
{
  "version": "1.4.9"
}
```

### Process List

**Endpoint**: `GET /api/ps`

**Response**:
```json
{
  "models": []
}
```

## Error Responses

### HTTP Status Codes

- `200`: Success
- `400`: Bad Request (invalid input)
- `401`: Unauthorized (when auth enabled)
- `404`: Not Found (invalid endpoint)
- `422`: Unprocessable Entity (validation error)
- `500`: Internal Server Error

### Error Format

```json
{
  "detail": "Error description",
  "error_type": "ValidationError"
}
```

### Common Errors

#### Document Processing Error
```json
{
  "status": "error",
  "message": "Failed to process document",
  "error": "LLM timeout error"
}
```

#### Query Error
```json
{
  "detail": "Query processing failed",
  "error": "No documents available for querying"
}
```

## Testing Procedures

### Basic Functionality Test

```bash
#!/bin/bash
# basic-test.sh

BASE_URL="http://localhost:9621"

echo "1. Health Check"
curl -s "$BASE_URL/health" | jq '.status'

echo "2. Insert Test Document"
TRACK_ID=$(curl -s -X POST "$BASE_URL/documents/text" \
  -H "Content-Type: application/json" \
  -d '{"text": "Test document about containerization and Docker.", "description": "Test"}' \
  | jq -r '.track_id')

echo "Track ID: $TRACK_ID"

echo "3. Wait for Processing"
sleep 20

echo "4. Check Status"
curl -s "$BASE_URL/documents/track_status/$TRACK_ID" | jq '.documents[0].status'

echo "5. Test Query"
curl -s -X POST "$BASE_URL/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "What is Docker?", "mode": "naive"}' \
  | jq -r '.response' | head -3

echo "6. Check Document Counts"
curl -s "$BASE_URL/documents/status_counts" | jq '.status_counts'
```

### Performance Test

```bash
#!/bin/bash
# performance-test.sh

BASE_URL="http://localhost:9621"

echo "Testing Query Performance"

modes=("naive" "hybrid" "global")

for mode in "${modes[@]}"; do
  echo "Testing $mode mode:"
  time curl -s -X POST "$BASE_URL/query" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"Test query\", \"mode\": \"$mode\"}" \
    > /dev/null
done
```

### Load Test

```bash
#!/bin/bash
# load-test.sh

BASE_URL="http://localhost:9621"

echo "Load Testing Document Insertion"

for i in {1..10}; do
  curl -s -X POST "$BASE_URL/documents/text" \
    -H "Content-Type: application/json" \
    -d "{\"text\": \"Test document $i content.\", \"description\": \"Load test $i\"}" &
done

wait
echo "All documents submitted"

# Check processing
sleep 30
curl -s "$BASE_URL/documents/status_counts" | jq '.status_counts'
```

### API Validation Test

```bash
#!/bin/bash
# api-validation-test.sh

BASE_URL="http://localhost:9621"

echo "API Endpoint Validation"

endpoints=(
  "/health"
  "/auth-status"
  "/documents/status_counts"
  "/documents/pipeline_status"
  "/api/version"
  "/api/tags"
)

for endpoint in "${endpoints[@]}"; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$endpoint")
  echo "$endpoint: HTTP $status"
done
```

## SDK Examples

### Python Client

```python
import requests
import json
import time

class ClaralyRAGClient:
    def __init__(self, base_url="http://localhost:9621"):
        self.base_url = base_url

    def health_check(self):
        response = requests.get(f"{self.base_url}/health")
        return response.json()

    def insert_document(self, text, description=""):
        data = {"text": text, "description": description}
        response = requests.post(
            f"{self.base_url}/documents/text",
            json=data
        )
        return response.json()

    def track_document(self, track_id):
        response = requests.get(
            f"{self.base_url}/documents/track_status/{track_id}"
        )
        return response.json()

    def query(self, query, mode="hybrid", enable_rerank=False):
        data = {
            "query": query,
            "mode": mode,
            "enable_rerank": enable_rerank
        }
        response = requests.post(
            f"{self.base_url}/query",
            json=data
        )
        return response.json()

    def wait_for_processing(self, track_id, timeout=300):
        """Wait for document processing to complete"""
        start_time = time.time()
        while time.time() - start_time < timeout:
            status = self.track_document(track_id)
            if status['documents'][0]['status'] == 'processed':
                return True
            elif status['documents'][0]['status'] == 'failed':
                raise Exception(f"Processing failed: {status['documents'][0]['error_msg']}")
            time.sleep(5)
        raise TimeoutError("Document processing timeout")

# Usage example
client = ClaralyRAGClient()

# Check health
health = client.health_check()
print(f"System status: {health['status']}")

# Insert document
result = client.insert_document(
    text="LightRAG is an advanced RAG system with knowledge graphs.",
    description="LightRAG introduction"
)
track_id = result['track_id']

# Wait for processing
client.wait_for_processing(track_id)

# Query the system
response = client.query("What is LightRAG?", mode="hybrid")
print(response['response'])
```

### JavaScript Client

```javascript
class ClaralyRAGClient {
    constructor(baseUrl = 'http://localhost:9621') {
        this.baseUrl = baseUrl;
    }

    async healthCheck() {
        const response = await fetch(`${this.baseUrl}/health`);
        return response.json();
    }

    async insertDocument(text, description = '') {
        const response = await fetch(`${this.baseUrl}/documents/text`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ text, description }),
        });
        return response.json();
    }

    async trackDocument(trackId) {
        const response = await fetch(`${this.baseUrl}/documents/track_status/${trackId}`);
        return response.json();
    }

    async query(query, mode = 'hybrid', enableRerank = false) {
        const response = await fetch(`${this.baseUrl}/query`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                query,
                mode,
                enable_rerank: enableRerank,
            }),
        });
        return response.json();
    }

    async waitForProcessing(trackId, timeout = 300000) {
        const startTime = Date.now();
        while (Date.now() - startTime < timeout) {
            const status = await this.trackDocument(trackId);
            if (status.documents[0].status === 'processed') {
                return true;
            } else if (status.documents[0].status === 'failed') {
                throw new Error(`Processing failed: ${status.documents[0].error_msg}`);
            }
            await new Promise(resolve => setTimeout(resolve, 5000));
        }
        throw new Error('Document processing timeout');
    }
}

// Usage example
(async () => {
    const client = new ClaralyRAGClient();

    // Check health
    const health = await client.healthCheck();
    console.log(`System status: ${health.status}`);

    // Insert document
    const result = await client.insertDocument(
        'LightRAG combines vector search with knowledge graphs.',
        'LightRAG overview'
    );

    // Wait for processing
    await client.waitForProcessing(result.track_id);

    // Query
    const response = await client.query('What is LightRAG?', 'hybrid');
    console.log(response.response);
})();
```

## API Rate Limits

Currently, no rate limiting is implemented. For production use, consider implementing rate limiting at the reverse proxy level:

```nginx
# Nginx rate limiting example
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

server {
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://localhost:9621;
    }
}
```

## WebSocket Support

For real-time updates, the system supports WebSocket connections for streaming query responses and document processing status updates.

**Connection**: `ws://localhost:9621/ws`

**Message Format**:
```json
{
  "type": "query_stream",
  "data": {
    "query": "Your question",
    "mode": "hybrid"
  }
}
```

---

This API documentation provides comprehensive coverage of all ClaralyRAG endpoints and usage patterns. For additional examples and integration patterns, refer to the web interface at `http://localhost:9621`.