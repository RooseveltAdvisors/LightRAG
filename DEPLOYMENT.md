# LightRAG Production Deployment Guide

This guide documents the complete production deployment setup for the ClaralyRAG system, a LightRAG-based Retrieval-Augmented Generation platform with knowledge graphs.

## Overview

ClaralyRAG is deployed as a containerized production stack consisting of:
- **LightRAG Application**: Core RAG system with knowledge graph capabilities
- **PostgreSQL**: Primary data storage with pgvector for vector operations
- **Neo4j**: Knowledge graph database with APOC and GDS plugins
- **Redis**: High-performance caching layer
- **Ollama Integration**: External LLM and embedding services

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   LightRAG      │    │   PostgreSQL     │    │     Neo4j       │
│   Port: 9621    │◄──►│   Port: 5433     │    │  Ports: 7474/   │
│                 │    │   (pgvector)     │    │         7687    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
          │                       │                       │
          │            ┌─────────────────┐               │
          └───────────►│     Redis       │◄──────────────┘
                       │   Port: 6380    │
                       │   (Caching)     │
                       └─────────────────┘
                                │
          ┌─────────────────────────────────────────┐
          │        External Ollama Server           │
          │    playground.intellinum.co:11434       │
          │  ┌─────────────┐  ┌─────────────────┐   │
          │  │    LLM      │  │   Embeddings    │   │
          │  │llama3.2:    │  │ bge-m3:latest   │   │
          │  │latest       │  │                 │   │
          │  └─────────────┘  └─────────────────┘   │
          └─────────────────────────────────────────┘
```

## Prerequisites

### System Requirements
- Docker Engine 20.10+ with Docker Compose
- Minimum 8GB RAM (16GB recommended)
- 50GB available disk space for data persistence
- Network access to `playground.intellinum.co:11434`

### Directory Structure
All data is persisted in `/data/claraly/rag/` with the following structure:
```
/data/claraly/rag/
├── postgres/
│   ├── data/          # PostgreSQL data files
│   └── init/          # Database initialization scripts
├── neo4j/
│   ├── data/          # Neo4j database files
│   ├── logs/          # Neo4j log files
│   ├── import/        # Data import directory
│   └── plugins/       # Neo4j plugins
├── redis/
│   └── data/          # Redis persistence files
├── lightrag/          # LightRAG working directory
├── inputs/            # Document input directory
├── tiktoken/          # Token cache directory
└── logs/              # Application logs
```

## Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd ClaralyRAG
```

### 2. Deploy Stack
```bash
# Start all services
docker compose up -d

# Check service status
docker compose ps

# View logs
docker compose logs -f lightrag
```

### 3. Verify Deployment
```bash
# Health check
curl http://localhost:9621/health

# Web interface
open http://localhost:9621
```

## Configuration

### Environment Variables

The system is configured via `.env` file. Key variables:

#### Core Application
```env
HOST=0.0.0.0
PORT=9621
WEBUI_TITLE='Claraly RAG'
WORKSPACE=production
```

#### LLM Configuration (Ollama)
```env
LLM_BINDING=ollama
LLM_MODEL=llama3.2:latest
LLM_BINDING_HOST=http://playground.intellinum.co:11434
LLM_TIMEOUT=0
```

#### Embedding Configuration
```env
EMBEDDING_BINDING=ollama
EMBEDDING_MODEL=bge-m3:latest
EMBEDDING_BINDING_HOST=http://playground.intellinum.co:11434
EMBEDDING_TIMEOUT=120
```

#### Storage Backends
```env
LIGHTRAG_KV_STORAGE=PGKVStorage
LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
LIGHTRAG_GRAPH_STORAGE=Neo4JStorage
LIGHTRAG_DOC_STATUS_STORAGE=PGDocStatusStorage
```

#### Database Connections
```env
# PostgreSQL
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=lightrag
POSTGRES_PASSWORD=lightrag_pg_2024_secure
POSTGRES_DATABASE=lightrag

# Neo4j
NEO4J_URI=bolt://neo4j:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=lightrag_neo4j_2024_secure
NEO4J_DATABASE=lightrag

# Redis
REDIS_URI=redis://:lightrag_redis_2024_secure@redis:6379
```

### Performance Tuning
```env
MAX_ASYNC=4
MAX_PARALLEL_INSERT=2
ENABLE_LLM_CACHE=true
ENABLE_LLM_CACHE_FOR_EXTRACT=true
```

## Service Details

### PostgreSQL (Port 5433)
- **Image**: `pgvector/pgvector:pg16`
- **Purpose**: Primary storage for documents, vectors, and metadata
- **Features**: pgvector extension for vector operations, HNSW indexing
- **Memory**: 256MB shared buffers, 1GB effective cache

### Neo4j (Ports 7474/7687)
- **Image**: `neo4j:5.23-community`
- **Purpose**: Knowledge graph storage and graph-based reasoning
- **Features**: APOC and Graph Data Science plugins
- **Memory**: 1GB heap, 512MB page cache

### Redis (Port 6380)
- **Image**: `redis:7.2-alpine`
- **Purpose**: High-performance caching and session storage
- **Features**: AOF persistence, password protection
- **Configuration**: Essential settings only (optimized for Redis 7.2)

### LightRAG Application (Port 9621)
- **Image**: `ghcr.io/hkuds/lightrag:latest`
- **Purpose**: Core RAG engine with API and web interface
- **Features**: Multi-modal RAG, knowledge graphs, REST API
- **Dependencies**: All database services must be healthy before startup

## Port Configuration

Due to existing service conflicts, the following port mappings are used:
- **LightRAG**: 9621 (standard)
- **PostgreSQL**: 5433 → 5432 (external → internal)
- **Neo4j HTTP**: 7474 (standard)
- **Neo4j Bolt**: 7687 (standard)
- **Redis**: 6380 → 6379 (external → internal)

## Deployment Process

### Initial Deployment
1. **Environment Setup**: Configure `.env` file with appropriate settings
2. **Directory Creation**: Ensure `/data/claraly/rag/` exists with proper permissions
3. **Database Initialization**: PostgreSQL tables created automatically on first run
4. **Service Startup**: All services start with health checks and dependencies
5. **Verification**: API responds at `/health` endpoint

### Health Checks
All services include comprehensive health checks:
- **PostgreSQL**: Connection test with `pg_isready`
- **Neo4j**: Cypher query execution test
- **Redis**: Basic ping command
- **LightRAG**: HTTP endpoint availability

### Data Persistence
All critical data is persisted outside containers:
- Database files survive container restarts
- Configuration changes applied via environment variables
- Log files accessible for debugging

## API Usage

### Document Management
```bash
# Add document
curl -X POST http://localhost:9621/documents/text \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Your document content here",
    "description": "Document description"
  }'

# Check processing status
curl http://localhost:9621/documents/status_counts
```

### Query System
```bash
# Naive vector search
curl -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Your question here",
    "mode": "naive"
  }'

# Hybrid (vector + graph) search
curl -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Your question here",
    "mode": "hybrid"
  }'

# Global knowledge graph search
curl -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Your question here",
    "mode": "global"
  }'
```

### System Monitoring
```bash
# Health status
curl http://localhost:9621/health

# API documentation
curl http://localhost:9621/docs

# Service status
docker compose ps
```

## Troubleshooting

### Common Issues

#### 1. Timeout Errors with Ollama
**Symptoms**: LLM request timeouts, failed document processing
**Solution**:
```env
LLM_TIMEOUT=0  # Disable timeout for Ollama
EMBEDDING_TIMEOUT=120  # Increase embedding timeout
```

#### 2. Port Conflicts
**Symptoms**: "Port already allocated" errors
**Solution**: Modify port mappings in `docker-compose.yml`
```yaml
ports:
  - "5433:5432"  # Use different external port
```

#### 3. Neo4j Configuration Issues
**Symptoms**: Container restart loops, permission errors
**Solution**: Remove custom config mount, use environment variables
```yaml
# Remove this line if causing issues:
# - /path/to/neo4j.conf:/var/lib/neo4j/conf/neo4j.conf:ro
```

#### 4. Redis Configuration Errors
**Symptoms**: Redis fails to start with config errors
**Solution**: Use simplified command-line configuration
```yaml
command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
```

### Log Analysis
```bash
# Service-specific logs
docker logs lightrag
docker logs lightrag-postgres
docker logs lightrag-neo4j
docker logs lightrag-redis

# Follow logs in real-time
docker logs -f lightrag

# All services logs
docker compose logs
```

### Database Verification
```bash
# PostgreSQL
docker exec lightrag-postgres psql -U lightrag -d lightrag -c "SELECT COUNT(*) FROM lightrag_doc_full;"

# Neo4j (via LightRAG logs)
grep "Connected to lightrag" <(docker logs lightrag)

# Redis
docker exec lightrag-redis redis-cli -a lightrag_redis_2024_secure ping
```

## Security Considerations

### Database Security
- All databases use strong passwords
- Services communicate within Docker network
- External access limited to necessary ports only

### API Security
- No authentication enabled by default (configure `AUTH_ACCOUNTS` if needed)
- API key protection available (`LIGHTRAG_API_KEY`)
- CORS configured for web interface access

### Network Security
- Services isolated in Docker network
- Only LightRAG port exposed externally
- Database ports mapped to non-standard external ports

## Backup and Recovery

### Database Backups
```bash
# PostgreSQL backup
docker exec lightrag-postgres pg_dump -U lightrag lightrag > backup.sql

# Neo4j backup (stop service first)
docker compose stop neo4j
cp -r /data/claraly/rag/neo4j/data /backup/neo4j-$(date +%Y%m%d)
docker compose start neo4j

# Redis backup
docker exec lightrag-redis redis-cli -a lightrag_redis_2024_secure BGSAVE
cp /data/claraly/rag/redis/data/dump.rdb /backup/redis-$(date +%Y%m%d).rdb
```

### Recovery Process
1. Stop services: `docker compose down`
2. Restore data directories from backup
3. Start services: `docker compose up -d`
4. Verify functionality via health checks

## Maintenance

### Regular Tasks
- Monitor disk usage in `/data/claraly/rag/`
- Review application logs for errors
- Update Docker images periodically
- Backup databases regularly

### Updates
```bash
# Update images
docker compose pull

# Restart with new images
docker compose down
docker compose up -d
```

### Performance Monitoring
- Monitor memory usage of database containers
- Check LightRAG processing times in logs
- Verify Ollama service availability
- Monitor knowledge graph growth in Neo4j

## Integration Points

### External Dependencies
- **Ollama Server**: Must be accessible at `playground.intellinum.co:11434`
- **Models Required**: `llama3.2:latest`, `bge-m3:latest`
- **Network**: Outbound HTTPS access for model downloads

### API Integration
- RESTful API available at port 9621
- OpenAPI specification at `/docs`
- WebSocket support for streaming queries
- Ollama-compatible chat endpoint for integration

## Production Considerations

### Scaling
- Increase `MAX_ASYNC` for higher concurrency
- Scale database resources based on load
- Consider Redis clustering for high availability
- Monitor Ollama server capacity

### Monitoring
- Set up log aggregation for centralized monitoring
- Configure alerting for service health checks
- Monitor API response times and error rates
- Track knowledge graph growth and performance

### High Availability
- Consider PostgreSQL replication for critical deployments
- Implement Neo4j clustering for enterprise use
- Use Redis Sentinel for cache high availability
- Deploy multiple LightRAG instances behind load balancer

## Version Information

- **LightRAG**: v1.4.9/0233
- **PostgreSQL**: 16 with pgvector
- **Neo4j**: 5.23 Community with APOC/GDS
- **Redis**: 7.2 Alpine
- **Docker Compose**: v3.8 specification

---

For additional support, consult the LightRAG documentation at the project repository or review the API documentation at `http://localhost:9621/docs`.