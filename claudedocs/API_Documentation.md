# ClaralyRAG API Reference Guide

## Table of Contents

1. [API Overview](#api-overview)
2. [Authentication & Security](#authentication--security)
3. [Configuration Guide](#configuration-guide)
4. [Core Concepts](#core-concepts)
5. [Document Management API](#document-management-api)
6. [Query API](#query-api)
7. [Graph Management API](#graph-management-api)
8. [Ollama Compatibility API](#ollama-compatibility-api)
9. [Request/Response Schemas](#requestresponse-schemas)
10. [Error Handling](#error-handling)
11. [Integration Guides](#integration-guides)
12. [Deployment & Scaling](#deployment--scaling)

---

## API Overview

ClaralyRAG provides a comprehensive REST API built on FastAPI for managing knowledge graphs, documents, and AI-powered queries. The API combines vector search with graph-based reasoning to deliver enhanced Retrieval-Augmented Generation capabilities.

### Architecture

- **FastAPI-based**: Modern async Python web framework with automatic OpenAPI documentation
- **Multi-Modal Processing**: Support for text, PDF, DOCX, PPTX, XLSX, and other document formats
- **Knowledge Graph Integration**: Entity and relationship extraction with graph storage
- **Multiple LLM Providers**: OpenAI, Ollama, Azure OpenAI, AWS Bedrock support
- **Flexible Storage**: JSON, PostgreSQL, Neo4j, MongoDB, Redis backends
- **Real-time Streaming**: WebSocket-style streaming responses for queries

### Base URL Structure

```
http://<host>:<port>/api/v1
```

Default: `http://localhost:9621/api/v1`

### API Versioning

Current version: `v1`

All endpoints are prefixed with `/api/v1/`

---

## Authentication & Security

### JWT Authentication

The API uses JWT (JSON Web Token) based authentication with configurable user accounts.

#### Configuration

Set up authentication in your `.env` file:

```env
# Enable authentication
AUTH_REQUIRED=true

# User accounts (format: username:password_hash)
AUTH_ACCOUNTS=admin:$2b$12$hashed_password,user:$2b$12$another_hash

# JWT settings
JWT_SECRET_KEY=your_secret_key_here
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
```

#### Getting an Access Token

**POST** `/auth/token`

```json
{
  "username": "admin",
  "password": "your_password"
}
```

**Response:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

#### Using Authentication

Include the token in the Authorization header:

```bash
curl -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." \
  http://localhost:9621/api/v1/documents
```

### API Key Authentication

Alternative simple API key authentication:

```env
API_KEY=your_api_key_here
```

Use with `X-API-Key` header:

```bash
curl -H "X-API-Key: your_api_key_here" \
  http://localhost:9621/api/v1/documents
```

---

## Configuration Guide

### Environment Variables

#### Core Settings

```env
# Server Configuration
HOST=0.0.0.0
PORT=9621
WORKING_DIR=./rag_storage
INPUT_DIR=./inputs

# Workspace Isolation
WORKSPACE=default

# Processing Settings
MAX_ASYNC=4
TIMEOUT=300
MAX_PARALLEL_INSERT=2
```

#### LLM Provider Configuration

**OpenAI:**
```env
LLM_BINDING=openai
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini
EMBEDDING_BINDING=openai
OPENAI_EMBEDDING_MODEL=text-embedding-3-small
```

**Ollama:**
```env
LLM_BINDING=ollama
LLM_BINDING_HOST=http://localhost:11434
OLLAMA_MODEL_NAME=llama3.1:8b
EMBEDDING_BINDING=ollama
OLLAMA_EMBEDDING_MODEL=nomic-embed-text
```

**Azure OpenAI:**
```env
LLM_BINDING=azure_openai
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_KEY=...
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4
AZURE_OPENAI_API_VERSION=2024-02-15-preview
```

#### Storage Backend Configuration

**Default (JSON/NetworkX):**
```env
LIGHTRAG_KV_STORAGE=JsonKVStorage
LIGHTRAG_VECTOR_STORAGE=NanoVectorDBStorage
LIGHTRAG_GRAPH_STORAGE=NetworkXStorage
LIGHTRAG_DOC_STATUS_STORAGE=JsonDocStatusStorage
```

**PostgreSQL Stack:**
```env
LIGHTRAG_KV_STORAGE=PGKVStorage
LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
LIGHTRAG_GRAPH_STORAGE=PGGraphStorage
LIGHTRAG_DOC_STATUS_STORAGE=PGDocStatusStorage

# Database connection
PG_DATABASE_URL=postgresql://user:password@localhost:5432/lightrag
```

**Neo4j Graph + Redis KV:**
```env
LIGHTRAG_KV_STORAGE=RedisKVStorage
LIGHTRAG_GRAPH_STORAGE=Neo4JStorage

# Redis
REDIS_URL=redis://localhost:6379/0

# Neo4j
NEO4J_URI=bolt://localhost:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=password
```

---

## Core Concepts

### Query Modes

ClaralyRAG supports multiple query modes for different use cases:

- **`naive`**: Basic vector similarity search
- **`local`**: Context-dependent graph search focusing on specific entities
- **`global`**: Global knowledge graph search for broader insights
- **`hybrid`**: Combines local and global approaches
- **`mix`**: Integrated knowledge graph + vector retrieval (recommended)
- **`bypass`**: Direct LLM query without RAG augmentation

### Document Processing Pipeline

1. **Upload/Insert**: Documents are uploaded or text is inserted
2. **Extraction**: Content is extracted from various file formats
3. **Chunking**: Text is split into manageable chunks
4. **Entity/Relation Extraction**: AI extracts entities and relationships
5. **Graph Construction**: Knowledge graph is built and updated
6. **Vector Indexing**: Embeddings are generated and indexed

### Status Tracking

Documents progress through these statuses:
- `PENDING`: Awaiting processing
- `PROCESSING`: Currently being processed
- `COMPLETED`: Successfully processed
- `FAILED`: Processing failed
- `DELETED`: Marked for deletion

---

## Document Management API

### Upload Documents

**POST** `/documents/upload`

Upload files to the system for processing.

**Content-Type:** `multipart/form-data`

**Parameters:**
- `files`: File uploads (PDF, DOCX, PPTX, XLSX, TXT)
- `description` (optional): Description for the upload batch

**Example:**
```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -F "files=@document.pdf" \
  -F "files=@presentation.pptx" \
  -F "description=Q1 2024 Reports" \
  http://localhost:9621/api/v1/documents/upload
```

**Response:**
```json
{
  "status": "success",
  "message": "Files uploaded successfully",
  "track_id": "track_123456789",
  "file_count": 2,
  "files_uploaded": ["document.pdf", "presentation.pptx"]
}
```

### Insert Text Content

**POST** `/documents/text`

Insert text content directly without file upload.

**Request Body:**
```json
{
  "text": "Your content here...",
  "description": "Content description",
  "meta": {
    "source": "manual_input",
    "author": "John Doe"
  }
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Text inserted successfully",
  "track_id": "track_123456789"
}
```

### Bulk Text Insert

**POST** `/documents/texts`

Insert multiple text documents in a single request.

**Request Body:**
```json
{
  "texts": [
    {
      "text": "First document content...",
      "description": "Document 1"
    },
    {
      "text": "Second document content...",
      "description": "Document 2"
    }
  ]
}
```

### Scan for New Documents

**POST** `/documents/scan`

Scan the input directory for new documents and process them.

**Response:**
```json
{
  "status": "success",
  "message": "Scan completed",
  "files_found": 5,
  "new_files": 2,
  "track_id": "track_123456789"
}
```

### Get Document Status

**GET** `/documents`

List all documents with their processing status.

**Query Parameters:**
- `status` (optional): Filter by status (`PENDING`, `PROCESSING`, `COMPLETED`, `FAILED`)
- `limit` (optional): Number of documents to return (default: 100)
- `offset` (optional): Pagination offset (default: 0)

**Response:**
```json
{
  "documents": [
    {
      "doc_id": "doc_123",
      "filename": "document.pdf",
      "status": "COMPLETED",
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:35:00Z",
      "file_size": 1024000,
      "description": "Q1 2024 Report"
    }
  ],
  "total": 150,
  "has_more": true
}
```

### Paginated Document Listing

**POST** `/documents/paginated`

Advanced document listing with flexible filtering and pagination.

**Request Body:**
```json
{
  "page": 1,
  "page_size": 20,
  "status_filter": "COMPLETED",
  "search_query": "financial report",
  "sort_by": "created_at",
  "sort_order": "desc"
}
```

### Track Processing Status

**GET** `/documents/track_status/{track_id}`

Get the processing status for a specific track ID.

**Response:**
```json
{
  "track_id": "track_123456789",
  "status": "PROCESSING",
  "progress": 0.75,
  "files_total": 4,
  "files_completed": 3,
  "files_failed": 0,
  "started_at": "2024-01-15T10:30:00Z",
  "estimated_completion": "2024-01-15T10:45:00Z"
}
```

### Delete Documents

**DELETE** `/documents/delete_document`

Delete a specific document by ID.

**Request Body:**
```json
{
  "doc_id": "doc_123"
}
```

**DELETE** `/documents`

Clear all documents from the system.

**Response:**
```json
{
  "status": "success",
  "message": "All documents cleared",
  "documents_deleted": 150
}
```

### Cache Management

**POST** `/documents/clear_cache`

Clear various system caches.

**Request Body:**
```json
{
  "clear_llm_cache": true,
  "clear_embedding_cache": true,
  "clear_vector_cache": false
}
```

---

## Query API

### Standard Query

**POST** `/query`

Perform a standard RAG query with response generation.

**Request Body:**
```json
{
  "query": "What are the key findings in the financial reports?",
  "mode": "mix",
  "response_type": "Multiple Paragraphs",
  "top_k": 10,
  "include_references": true,
  "conversation_history": [
    {
      "role": "user",
      "content": "Previous question..."
    },
    {
      "role": "assistant",
      "content": "Previous response..."
    }
  ]
}
```

**Response:**
```json
{
  "response": "Based on the financial reports in the knowledge base, the key findings include...",
  "references": [
    {
      "chunk_id": "chunk_123",
      "document": "Q1_2024_Report.pdf",
      "content": "Revenue increased by 15%...",
      "score": 0.89
    }
  ],
  "query_time": 2.34,
  "mode_used": "mix"
}
```

### Streaming Query

**POST** `/query/stream`

Get real-time streaming responses for long queries.

**Request Body:** Same as standard query with `"stream": true`

**Response:** Server-Sent Events (SSE) stream

```
data: {"type": "chunk", "content": "Based on the", "chunk_id": 1}

data: {"type": "chunk", "content": " financial reports", "chunk_id": 2}

data: {"type": "reference", "reference": {"document": "report.pdf", "score": 0.89}}

data: {"type": "complete", "total_chunks": 45, "query_time": 3.21}
```

### Query with Data Only

**POST** `/query/data`

Retrieve only the context data without generating a response.

**Request Body:**
```json
{
  "query": "financial performance metrics",
  "mode": "mix",
  "top_k": 5,
  "only_need_context": true
}
```

**Response:**
```json
{
  "context": {
    "entities": [
      {
        "name": "Revenue Growth",
        "description": "Quarterly revenue increase",
        "chunk_ids": ["chunk_1", "chunk_5"]
      }
    ],
    "relationships": [
      {
        "source": "Revenue Growth",
        "target": "Market Expansion",
        "description": "Led to increased market share"
      }
    ],
    "chunks": [
      {
        "chunk_id": "chunk_1",
        "content": "Q1 revenue grew 15% year-over-year...",
        "score": 0.92
      }
    ]
  },
  "query_time": 1.23
}
```

---

## Graph Management API

### Get Graph Labels

**GET** `/graph/label/list`

Retrieve all available labels in the knowledge graph.

**Response:**
```json
[
  "Financial Metrics",
  "Market Analysis",
  "Product Development",
  "Customer Insights"
]
```

### Get Popular Labels

**GET** `/graph/label/popular?limit=50`

Get the most connected entities (by node degree).

**Query Parameters:**
- `limit`: Maximum number of labels (1-1000, default: 300)

**Response:**
```json
[
  "Revenue",
  "Market Share",
  "Customer Satisfaction",
  "Product Innovation"
]
```

### Search Labels

**GET** `/graph/label/search?q=financial&limit=20`

Search for labels using fuzzy matching.

**Query Parameters:**
- `q`: Search query string
- `limit`: Maximum results (1-100, default: 50)

### Get Knowledge Graph

**GET** `/graphs?label=Revenue&max_depth=3&max_nodes=100`

Retrieve graph data for a specific label.

**Query Parameters:**
- `label`: Root label for graph traversal
- `max_depth`: Maximum traversal depth (default: 3)
- `max_nodes`: Maximum nodes to return (default: 100)

**Response:**
```json
{
  "nodes": [
    {
      "id": "revenue_001",
      "label": "Revenue",
      "properties": {
        "description": "Total company revenue",
        "value": "$10M Q1 2024"
      }
    }
  ],
  "edges": [
    {
      "source": "revenue_001",
      "target": "growth_002",
      "label": "INCREASED_BY",
      "properties": {
        "percentage": "15%",
        "period": "Q1 2024"
      }
    }
  ]
}
```

### Edit Graph Entities

**POST** `/graph/entity/edit`

Update entity properties in the knowledge graph.

**Request Body:**
```json
{
  "entity_name": "Revenue",
  "updated_data": {
    "description": "Updated revenue description",
    "value": "$12M Q2 2024"
  },
  "allow_rename": false
}
```

### Edit Graph Relations

**POST** `/graph/relation/edit`

Update relationship properties.

**Request Body:**
```json
{
  "source_id": "revenue_001",
  "target_id": "growth_002",
  "updated_data": {
    "percentage": "20%",
    "period": "Q2 2024"
  }
}
```

### Check Entity Exists

**GET** `/graph/entity/exists?name=Revenue`

Check if a specific entity exists in the graph.

**Response:**
```json
{
  "exists": true,
  "entity_id": "revenue_001"
}
```

---

## Ollama Compatibility API

ClaralyRAG provides an Ollama-compatible API for seamless integration with Ollama clients.

### Chat Completion

**POST** `/ollama/api/chat`

Ollama-compatible chat interface with RAG enhancement.

**Request Body:**
```json
{
  "model": "lightrag",
  "messages": [
    {
      "role": "user",
      "content": "What insights can you provide about our financial performance?"
    }
  ],
  "stream": true
}
```

**Query Mode Prefixes:**
- `[naive]`: Use naive mode
- `[local]`: Use local mode
- `[global]`: Use global mode
- `[hybrid]`: Use hybrid mode
- `[bypass]`: Bypass RAG (direct LLM)

**Example with Mode:**
```json
{
  "model": "lightrag",
  "messages": [
    {
      "role": "user",
      "content": "[global] What are the global trends in our industry?"
    }
  ]
}
```

### Generate

**POST** `/ollama/api/generate`

Ollama-compatible generation endpoint.

**Request Body:**
```json
{
  "model": "lightrag",
  "prompt": "Analyze the financial data",
  "stream": false
}
```

### List Models

**GET** `/ollama/api/tags`

List available models (returns LightRAG model).

**Response:**
```json
{
  "models": [
    {
      "name": "lightrag:latest",
      "model": "lightrag:latest",
      "size": 0,
      "digest": "lightrag",
      "modified_at": "2024-01-15T10:30:00Z",
      "details": {
        "parent_model": "",
        "format": "lightrag",
        "family": "lightrag",
        "families": ["lightrag"],
        "parameter_size": "varies",
        "quantization_level": "none"
      }
    }
  ]
}
```

---

## Request/Response Schemas

### Common Data Types

#### QueryRequest
```json
{
  "query": "string (min 3 chars)",
  "mode": "local|global|hybrid|naive|mix|bypass",
  "only_need_context": "boolean (optional)",
  "only_need_prompt": "boolean (optional)",
  "response_type": "string (optional)",
  "top_k": "integer ≥1 (optional)",
  "chunk_top_k": "integer ≥1 (optional)",
  "max_entity_tokens": "integer ≥1 (optional)",
  "max_relation_tokens": "integer ≥1 (optional)",
  "max_total_tokens": "integer ≥1 (optional)",
  "conversation_history": "array of message objects (optional)",
  "user_prompt": "string (optional)",
  "enable_rerank": "boolean (optional)",
  "include_references": "boolean (default: true)",
  "stream": "boolean (default: true)"
}
```

#### InsertTextRequest
```json
{
  "text": "string (required)",
  "description": "string (optional)",
  "meta": "object (optional)"
}
```

#### DocumentsRequest
```json
{
  "page": "integer ≥1 (default: 1)",
  "page_size": "integer 1-1000 (default: 100)",
  "status_filter": "PENDING|PROCESSING|COMPLETED|FAILED|ALL",
  "search_query": "string (optional)",
  "sort_by": "created_at|updated_at|filename|file_size",
  "sort_order": "asc|desc (default: desc)"
}
```

### Response Types

#### Standard Success Response
```json
{
  "status": "success",
  "message": "Operation completed successfully",
  "data": "object (optional)"
}
```

#### Error Response
```json
{
  "status": "error",
  "message": "Error description",
  "error_code": "ERROR_CODE",
  "details": "object (optional)"
}
```

#### Paginated Response
```json
{
  "items": "array",
  "total": "integer",
  "page": "integer",
  "page_size": "integer",
  "total_pages": "integer",
  "has_next": "boolean",
  "has_prev": "boolean"
}
```

---

## Error Handling

### HTTP Status Codes

- **200**: Success
- **201**: Created
- **400**: Bad Request (validation errors)
- **401**: Unauthorized (authentication required)
- **403**: Forbidden (insufficient permissions)
- **404**: Not Found
- **422**: Unprocessable Entity (validation errors)
- **429**: Too Many Requests (rate limiting)
- **500**: Internal Server Error

### Error Response Format

```json
{
  "status": "error",
  "message": "Human-readable error message",
  "error_code": "SPECIFIC_ERROR_CODE",
  "details": {
    "field_errors": {
      "query": ["Query must be at least 3 characters"]
    },
    "request_id": "req_123456789"
  }
}
```

### Common Error Codes

- `INVALID_REQUEST`: Request validation failed
- `AUTHENTICATION_REQUIRED`: Missing or invalid authentication
- `DOCUMENT_NOT_FOUND`: Requested document doesn't exist
- `PROCESSING_FAILED`: Document processing error
- `STORAGE_ERROR`: Database/storage system error
- `LLM_ERROR`: Language model API error
- `RATE_LIMIT_EXCEEDED`: Too many requests

### Retry Logic

For transient errors (5xx status codes), implement exponential backoff:

```python
import time
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

def create_session_with_retries():
    session = requests.Session()
    retry_strategy = Retry(
        total=3,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504],
    )
    adapter = HTTPAdapter(max_retries=retry_strategy)
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    return session
```

---

## Integration Guides

### Python Client

```python
import requests
import json
from typing import Dict, List, Optional

class ClaralyRAGClient:
    def __init__(self, base_url: str, api_key: Optional[str] = None):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        if api_key:
            self.session.headers.update({"X-API-Key": api_key})

    def upload_documents(self, files: List[str], description: str = None) -> Dict:
        """Upload documents to ClaralyRAG"""
        url = f"{self.base_url}/api/v1/documents/upload"

        files_data = []
        for file_path in files:
            files_data.append(('files', open(file_path, 'rb')))

        data = {}
        if description:
            data['description'] = description

        response = self.session.post(url, files=files_data, data=data)
        response.raise_for_status()
        return response.json()

    def query(self, query: str, mode: str = "mix", **kwargs) -> Dict:
        """Perform a RAG query"""
        url = f"{self.base_url}/api/v1/query"

        payload = {
            "query": query,
            "mode": mode,
            **kwargs
        }

        response = self.session.post(url, json=payload)
        response.raise_for_status()
        return response.json()

    def query_stream(self, query: str, mode: str = "mix", **kwargs):
        """Stream query responses"""
        url = f"{self.base_url}/api/v1/query/stream"

        payload = {
            "query": query,
            "mode": mode,
            "stream": True,
            **kwargs
        }

        response = self.session.post(url, json=payload, stream=True)
        response.raise_for_status()

        for line in response.iter_lines():
            if line:
                if line.startswith(b'data: '):
                    data = line[6:].decode('utf-8')
                    if data.strip():
                        yield json.loads(data)

# Usage example
client = ClaralyRAGClient("http://localhost:9621", api_key="your_key")

# Upload documents
result = client.upload_documents(
    files=["report1.pdf", "report2.pdf"],
    description="Q1 2024 Reports"
)
print(f"Upload track ID: {result['track_id']}")

# Query
response = client.query(
    "What are the key financial metrics?",
    mode="mix",
    top_k=10
)
print(response['response'])

# Streaming query
for chunk in client.query_stream("Analyze the financial performance"):
    if chunk.get('type') == 'chunk':
        print(chunk['content'], end='')
```

### JavaScript/Node.js Client

```javascript
class ClaralyRAGClient {
    constructor(baseUrl, apiKey = null) {
        this.baseUrl = baseUrl.replace(/\/$/, '');
        this.apiKey = apiKey;
    }

    async _request(method, endpoint, options = {}) {
        const url = `${this.baseUrl}/api/v1${endpoint}`;
        const headers = {
            'Content-Type': 'application/json',
            ...options.headers
        };

        if (this.apiKey) {
            headers['X-API-Key'] = this.apiKey;
        }

        const response = await fetch(url, {
            method,
            headers,
            ...options
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${await response.text()}`);
        }

        return response.json();
    }

    async uploadDocuments(files, description = null) {
        const formData = new FormData();

        files.forEach(file => {
            formData.append('files', file);
        });

        if (description) {
            formData.append('description', description);
        }

        const response = await fetch(`${this.baseUrl}/api/v1/documents/upload`, {
            method: 'POST',
            headers: this.apiKey ? { 'X-API-Key': this.apiKey } : {},
            body: formData
        });

        return response.json();
    }

    async query(query, options = {}) {
        return this._request('POST', '/query', {
            body: JSON.stringify({
                query,
                mode: 'mix',
                ...options
            })
        });
    }

    async *queryStream(query, options = {}) {
        const response = await fetch(`${this.baseUrl}/api/v1/query/stream`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                ...(this.apiKey ? { 'X-API-Key': this.apiKey } : {})
            },
            body: JSON.stringify({
                query,
                mode: 'mix',
                stream: true,
                ...options
            })
        });

        const reader = response.body.getReader();
        const decoder = new TextDecoder();

        while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            const chunk = decoder.decode(value);
            const lines = chunk.split('\n');

            for (const line of lines) {
                if (line.startsWith('data: ')) {
                    const data = line.slice(6).trim();
                    if (data) {
                        yield JSON.parse(data);
                    }
                }
            }
        }
    }
}

// Usage
const client = new ClaralyRAGClient('http://localhost:9621', 'your_api_key');

// Query
const response = await client.query('What are the key insights?');
console.log(response.response);

// Streaming
for await (const chunk of client.queryStream('Analyze the data')) {
    if (chunk.type === 'chunk') {
        process.stdout.write(chunk.content);
    }
}
```

### Curl Examples

```bash
# Upload documents
curl -X POST \
  -H "X-API-Key: your_key" \
  -F "files=@document.pdf" \
  -F "description=Test upload" \
  http://localhost:9621/api/v1/documents/upload

# Insert text
curl -X POST \
  -H "X-API-Key: your_key" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "This is a test document for the knowledge base.",
    "description": "Test document"
  }' \
  http://localhost:9621/api/v1/documents/text

# Query
curl -X POST \
  -H "X-API-Key: your_key" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What information do you have?",
    "mode": "mix",
    "top_k": 10
  }' \
  http://localhost:9621/api/v1/query

# Stream query
curl -X POST \
  -H "X-API-Key: your_key" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Tell me about the documents",
    "mode": "mix",
    "stream": true
  }' \
  http://localhost:9621/api/v1/query/stream

# Get graph data
curl -X GET \
  -H "X-API-Key: your_key" \
  "http://localhost:9621/api/v1/graphs?label=Revenue&max_depth=2"
```

---

## Deployment & Scaling

### Docker Deployment

**Basic Docker Setup:**

```dockerfile
FROM python:3.11

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 9621
CMD ["python", "-m", "lightrag.api.lightrag_server"]
```

**Docker Compose:**

```yaml
version: '3.8'

services:
  lightrag-api:
    build: .
    ports:
      - "9621:9621"
    environment:
      - WORKING_DIR=/app/data
      - LLM_BINDING=openai
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    volumes:
      - ./data:/app/data
      - ./inputs:/app/inputs
    depends_on:
      - redis
      - postgres

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: lightrag
      POSTGRES_USER: lightrag
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Production Configuration

**Gunicorn WSGI:**

```bash
# Install gunicorn
pip install gunicorn[setproctitle]

# Run with gunicorn
gunicorn lightrag.api.lightrag_server:app \
  --workers 4 \
  --worker-class uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:9621 \
  --timeout 300 \
  --keep-alive 2 \
  --max-requests 1000 \
  --max-requests-jitter 50
```

**Environment Variables for Production:**

```env
# Performance
MAX_ASYNC=8
MAX_PARALLEL_INSERT=4
TIMEOUT=600

# Storage (Production PostgreSQL)
LIGHTRAG_KV_STORAGE=PGKVStorage
LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
LIGHTRAG_GRAPH_STORAGE=PGGraphStorage
LIGHTRAG_DOC_STATUS_STORAGE=PGDocStatusStorage
PG_DATABASE_URL=postgresql://user:pass@postgres:5432/lightrag

# Redis for caching
LIGHTRAG_KV_STORAGE=RedisKVStorage
REDIS_URL=redis://redis:6379/0

# Security
AUTH_REQUIRED=true
JWT_SECRET_KEY=${RANDOM_SECRET_KEY}
API_KEY=${SECURE_API_KEY}

# Logging
LOG_LEVEL=INFO
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lightrag-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: lightrag-api
  template:
    metadata:
      labels:
        app: lightrag-api
    spec:
      containers:
      - name: lightrag-api
        image: lightrag:latest
        ports:
        - containerPort: 9621
        env:
        - name: WORKING_DIR
          value: "/app/data"
        - name: PG_DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: lightrag-secrets
              key: database-url
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: lightrag-secrets
              key: openai-api-key
        volumeMounts:
        - name: data-volume
          mountPath: /app/data
        resources:
          requests:
            memory: "2Gi"
            cpu: "500m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
      volumes:
      - name: data-volume
        persistentVolumeClaim:
          claimName: lightrag-data-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: lightrag-api-service
spec:
  selector:
    app: lightrag-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 9621
  type: LoadBalancer
```

### Scaling Considerations

**Horizontal Scaling:**
- Use shared storage backends (PostgreSQL, Redis, Neo4j)
- Implement load balancing with session affinity for tracking IDs
- Consider message queues for background processing

**Performance Tuning:**
- Adjust `MAX_ASYNC` based on LLM provider rate limits
- Tune `MAX_PARALLEL_INSERT` for document processing throughput
- Configure embedding batch sizes for optimal vector processing
- Use Redis for caching to reduce LLM API calls

**Monitoring:**
- Track API response times and error rates
- Monitor LLM usage and costs
- Set up alerts for processing failures
- Log document processing pipeline status

**Security:**
- Use environment variables for sensitive configuration
- Implement network policies in Kubernetes
- Regular security updates for dependencies
- Input validation and file type restrictions

---

## API Changelog

### v1.0.0 (Current)
- Initial API release
- Document management endpoints
- Query API with multiple modes
- Graph management capabilities
- Ollama compatibility layer
- JWT and API key authentication
- Streaming responses
- Multi-format document support

---

**For additional support and examples, visit the [ClaralyRAG GitHub repository](https://github.com/your-org/claraly-rag) or consult the auto-generated OpenAPI documentation at `/docs` when running the server.**