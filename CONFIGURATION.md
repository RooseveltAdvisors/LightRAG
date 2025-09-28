# ClaralyRAG Configuration Reference

This document provides a comprehensive reference for all configuration options available in the ClaralyRAG production deployment.

## Configuration Sources

Configuration is managed through multiple sources in order of precedence:

1. **Environment Variables** (`.env` file) - Primary configuration
2. **Docker Compose** (`docker-compose.yml`) - Service definitions
3. **Database Initialization** - PostgreSQL and Neo4j setup scripts
4. **Application Defaults** - LightRAG built-in settings

## Environment Variables Reference

### Core Application Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `HOST` | `0.0.0.0` | Server bind address |
| `PORT` | `9621` | Server port |
| `WEBUI_TITLE` | `'Claraly RAG'` | Web interface title |
| `WEBUI_DESCRIPTION` | `"Claraly Graph Based RAG System"` | Web interface description |
| `WORKERS` | `2` | Number of worker processes |
| `WORKSPACE` | `production` | Data isolation namespace |

### LLM Configuration

#### Ollama LLM Settings
| Variable | Value | Description |
|----------|-------|-------------|
| `LLM_BINDING` | `ollama` | LLM provider type |
| `LLM_MODEL` | `llama3.2:latest` | LLM model identifier |
| `LLM_BINDING_HOST` | `http://playground.intellinum.co:11434` | Ollama server URL |
| `LLM_BINDING_API_KEY` | `not-required` | API key (not needed for Ollama) |
| `LLM_TIMEOUT` | `0` | Request timeout (0 = unlimited for Ollama) |

#### Ollama Model Parameters
| Variable | Value | Description |
|----------|-------|-------------|
| `OLLAMA_LLM_NUM_CTX` | `32768` | Context window size |
| `OPENAI_LLM_MAX_COMPLETION_TOKENS` | `9000` | Maximum output tokens |

### Embedding Configuration

| Variable | Value | Description |
|----------|-------|-------------|
| `EMBEDDING_BINDING` | `ollama` | Embedding provider |
| `EMBEDDING_MODEL` | `bge-m3:latest` | Embedding model |
| `EMBEDDING_DIM` | `1024` | Vector dimensions |
| `EMBEDDING_BINDING_HOST` | `http://playground.intellinum.co:11434` | Ollama server URL |
| `EMBEDDING_BINDING_API_KEY` | `your_api_key` | API key placeholder |
| `EMBEDDING_TIMEOUT` | `120` | Request timeout in seconds |
| `OLLAMA_EMBEDDING_NUM_CTX` | `8192` | Embedding context size |

### Storage Backend Configuration

#### Primary Storage Selection
| Variable | Value | Description |
|----------|-------|-------------|
| `LIGHTRAG_KV_STORAGE` | `PGKVStorage` | Key-value storage backend |
| `LIGHTRAG_VECTOR_STORAGE` | `PGVectorStorage` | Vector storage backend |
| `LIGHTRAG_GRAPH_STORAGE` | `Neo4JStorage` | Graph storage backend |
| `LIGHTRAG_DOC_STATUS_STORAGE` | `PGDocStatusStorage` | Document status storage |

### Database Connection Settings

#### PostgreSQL Configuration
| Variable | Value | Description |
|----------|-------|-------------|
| `POSTGRES_HOST` | `postgres` | Database host (Docker service name) |
| `POSTGRES_PORT` | `5432` | Internal database port |
| `POSTGRES_USER` | `lightrag` | Database username |
| `POSTGRES_PASSWORD` | `lightrag_pg_2024_secure` | Database password |
| `POSTGRES_DATABASE` | `lightrag` | Database name |
| `POSTGRES_MAX_CONNECTIONS` | `12` | Connection pool size |

#### PostgreSQL Vector Settings
| Variable | Value | Description |
|----------|-------|-------------|
| `POSTGRES_VECTOR_INDEX_TYPE` | `HNSW` | Vector index algorithm |
| `POSTGRES_HNSW_M` | `16` | HNSW construction parameter |
| `POSTGRES_HNSW_EF` | `200` | HNSW search parameter |
| `POSTGRES_IVFFLAT_LISTS` | `100` | IVFFlat lists (alternative) |

#### Neo4j Configuration
| Variable | Value | Description |
|----------|-------|-------------|
| `NEO4J_URI` | `bolt://neo4j:7687` | Neo4j connection URI |
| `NEO4J_USERNAME` | `neo4j` | Neo4j username |
| `NEO4J_PASSWORD` | `lightrag_neo4j_2024_secure` | Neo4j password |
| `NEO4J_DATABASE` | `lightrag` | Neo4j database name |
| `NEO4J_MAX_CONNECTION_POOL_SIZE` | `100` | Connection pool size |
| `NEO4J_CONNECTION_TIMEOUT` | `30` | Connection timeout (seconds) |
| `NEO4J_CONNECTION_ACQUISITION_TIMEOUT` | `30` | Pool acquisition timeout |
| `NEO4J_MAX_TRANSACTION_RETRY_TIME` | `30` | Transaction retry time |
| `NEO4J_MAX_CONNECTION_LIFETIME` | `300` | Connection lifetime (seconds) |
| `NEO4J_LIVENESS_CHECK_TIMEOUT` | `30` | Health check timeout |
| `NEO4J_KEEP_ALIVE` | `true` | Enable keep-alive |

#### Redis Configuration
| Variable | Value | Description |
|----------|-------|-------------|
| `REDIS_URI` | `redis://:lightrag_redis_2024_secure@redis:6379` | Redis connection string |
| `REDIS_SOCKET_TIMEOUT` | `30` | Socket timeout |
| `REDIS_CONNECT_TIMEOUT` | `10` | Connection timeout |
| `REDIS_MAX_CONNECTIONS` | `100` | Maximum connections |
| `REDIS_RETRY_ATTEMPTS` | `3` | Retry attempts |

### Document Processing Settings

#### Content Processing
| Variable | Value | Description |
|----------|-------|-------------|
| `SUMMARY_LANGUAGE` | `English` | Processing language |
| `CHUNK_SIZE` | `1200` | Document chunk size |
| `CHUNK_OVERLAP_SIZE` | `100` | Chunk overlap |
| `FORCE_LLM_SUMMARY_ON_MERGE` | `8` | Merge trigger threshold |
| `SUMMARY_MAX_TOKENS` | `1200` | Summary length limit |
| `SUMMARY_CONTEXT_SIZE` | `12000` | Summary context window |

#### Entity Recognition
| Variable | Value | Description |
|----------|-------|-------------|
| `ENTITY_TYPES` | `["Person", "Creature", "Organization", "Location", "Event", "Concept", "Method", "Content", "Data", "Artifact", "NaturalObject"]` | Recognized entity types |

### Performance Configuration

#### Concurrency Settings
| Variable | Value | Description |
|----------|-------|-------------|
| `MAX_ASYNC` | `4` | Maximum concurrent LLM requests |
| `MAX_PARALLEL_INSERT` | `2` | Parallel document processing |
| `EMBEDDING_FUNC_MAX_ASYNC` | `8` | Embedding concurrency |
| `EMBEDDING_BATCH_NUM` | `10` | Embedding batch size |

#### Caching Configuration
| Variable | Value | Description |
|----------|-------|-------------|
| `ENABLE_LLM_CACHE` | `true` | Enable LLM response caching |
| `ENABLE_LLM_CACHE_FOR_EXTRACT` | `true` | Cache extraction results |

### Query Configuration

#### Search Parameters
| Variable | Value | Description |
|----------|-------|-------------|
| `COSINE_THRESHOLD` | `0.2` | Vector similarity threshold |
| `TOP_K` | `40` | Maximum entities/relations retrieved |
| `CHUNK_TOP_K` | `20` | Maximum chunks for naive search |
| `MAX_ENTITY_TOKENS` | `6000` | Entity context limit |
| `MAX_RELATION_TOKENS` | `8000` | Relation context limit |
| `MAX_TOTAL_TOKENS` | `30000` | Total context limit |
| `RELATED_CHUNK_NUMBER` | `5` | Related chunks per entity |

#### Chunk Selection
| Variable | Value | Description |
|----------|-------|-------------|
| `KG_CHUNK_PICK_METHOD` | `VECTOR` | Chunk selection strategy |

### Reranking Configuration

| Variable | Value | Description |
|----------|-------|-------------|
| `RERANK_BINDING` | `null` | Reranker provider (disabled) |
| `RERANK_BY_DEFAULT` | `False` | Enable reranking by default |
| `MIN_RERANK_SCORE` | `0.0` | Minimum rerank score threshold |

> **Note**: BGE reranker (`xitao/bge-reranker-v2-m3:latest`) is available on Ollama but not currently supported by LightRAG for direct integration.

### Security Settings

#### Authentication (Optional)
| Variable | Value | Description |
|----------|-------|-------------|
| `AUTH_ACCOUNTS` | `admin:admin123,user1:pass456` | User accounts (disabled by default) |
| `TOKEN_SECRET` | `Your-Key-For-LightRAG-API-Server` | JWT secret key |
| `TOKEN_EXPIRE_HOURS` | `48` | Token expiration |
| `GUEST_TOKEN_EXPIRE_HOURS` | `24` | Guest token expiration |
| `JWT_ALGORITHM` | `HS256` | JWT algorithm |

#### API Security
| Variable | Value | Description |
|----------|-------|-------------|
| `LIGHTRAG_API_KEY` | `your-secure-api-key-here` | API key protection |
| `WHITELIST_PATHS` | `/health,/api/*` | Whitelisted endpoints |

### Logging Configuration

| Variable | Value | Description |
|----------|-------|-------------|
| `LOG_LEVEL` | `INFO` | Logging level |
| `VERBOSE` | `False` | Verbose debugging |
| `LOG_MAX_BYTES` | `10485760` | Log file size limit |
| `LOG_BACKUP_COUNT` | `5` | Log file rotation count |

### Directory Configuration

| Variable | Value | Description |
|----------|-------|-------------|
| `INPUT_DIR` | `/data/claraly/rag/data/inputs` | Document input directory |
| `WORKING_DIR` | `/data/claraly/rag/data/rag_storage` | LightRAG working directory |
| `TIKTOKEN_CACHE_DIR` | `/data/claraly/rag/data/tiktoken` | Token cache directory |
| `LOG_DIR` | `/app/logs` | Log file directory |

### Web Interface Configuration

| Variable | Value | Description |
|----------|-------|-------------|
| `MAX_GRAPH_NODES` | `1000` | Maximum nodes in web UI graph |
| `CORS_ORIGINS` | `*` | CORS allowed origins |

### Ollama Emulation

| Variable | Value | Description |
|----------|-------|-------------|
| `OLLAMA_EMULATING_MODEL_NAME` | `lightrag` | Ollama model alias |
| `OLLAMA_EMULATING_MODEL_TAG` | `latest` | Model tag |

## Docker Compose Configuration

### Service Dependencies

```yaml
lightrag:
  depends_on:
    postgres:
      condition: service_healthy
    neo4j:
      condition: service_healthy
    redis:
      condition: service_healthy
```

### Port Mappings

| Service | External Port | Internal Port | Purpose |
|---------|---------------|---------------|---------|
| lightrag | 9621 | 9621 | Web interface and API |
| postgres | 5433 | 5432 | Database access (conflict avoidance) |
| neo4j | 7474 | 7474 | Neo4j Browser |
| neo4j | 7687 | 7687 | Bolt protocol |
| redis | 6380 | 6379 | Redis access (conflict avoidance) |

### Volume Mappings

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `/data/claraly/rag/postgres/data` | `/var/lib/postgresql/data` | PostgreSQL data |
| `/data/claraly/rag/postgres/init` | `/docker-entrypoint-initdb.d` | DB initialization |
| `/data/claraly/rag/neo4j/data` | `/data` | Neo4j data |
| `/data/claraly/rag/neo4j/logs` | `/logs` | Neo4j logs |
| `/data/claraly/rag/redis/data` | `/data` | Redis persistence |
| `/data/claraly/rag/lightrag` | `/data/claraly/rag/data/rag_storage` | LightRAG data |

### Health Checks

#### PostgreSQL
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U lightrag -d lightrag"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

#### Neo4j
```yaml
healthcheck:
  test: ["CMD", "cypher-shell", "-u", "neo4j", "-p", "${NEO4J_PASSWORD}", "RETURN 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

#### Redis
```yaml
healthcheck:
  test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 30s
```

#### LightRAG
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:9621/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

### Network Configuration

```yaml
networks:
  default:
    name: lightrag-network
    driver: bridge
```

## Database-Specific Configuration

### PostgreSQL Settings

#### Performance Tuning (via command arguments)
```yaml
command: >
  postgres
  -c shared_preload_libraries=vector
  -c max_connections=200
  -c shared_buffers=256MB
  -c effective_cache_size=1GB
  -c maintenance_work_mem=64MB
  -c checkpoint_completion_target=0.9
  -c wal_buffers=16MB
  -c default_statistics_target=100
  -c random_page_cost=1.1
  -c effective_io_concurrency=200
```

### Neo4j Settings (via environment variables)

```yaml
environment:
  NEO4J_AUTH: neo4j/${NEO4J_PASSWORD}
  NEO4J_PLUGINS: '["apoc", "graph-data-science"]'
  NEO4J_dbms_security_procedures_unrestricted: "apoc.*,gds.*"
  NEO4J_dbms_security_procedures_allowlist: "apoc.*,gds.*"
  NEO4J_dbms_memory_heap_initial__size: 512m
  NEO4J_dbms_memory_heap_max__size: 1G
  NEO4J_dbms_memory_pagecache_size: 512m
  NEO4J_dbms_default__database: lightrag
```

### Redis Settings (via command line)

```yaml
command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes --save 900 1 --save 300 10 --save 60 1000
```

## Configuration Validation

### Environment Variable Validation

Before deployment, validate configuration:

```bash
# Check required variables are set
echo "LLM_BINDING: $LLM_BINDING"
echo "POSTGRES_PASSWORD: $POSTGRES_PASSWORD"
echo "NEO4J_PASSWORD: $NEO4J_PASSWORD"
echo "REDIS_PASSWORD: $REDIS_PASSWORD"

# Test Ollama connectivity
curl -s http://playground.intellinum.co:11434/api/tags | jq '.models[].name'
```

### Service Configuration Test

```bash
# PostgreSQL connection
docker exec lightrag-postgres pg_isready -U lightrag -d lightrag

# Neo4j connection
docker exec lightrag-neo4j cypher-shell -u neo4j -p lightrag_neo4j_2024_secure "RETURN 1"

# Redis connection
docker exec lightrag-redis redis-cli -a lightrag_redis_2024_secure ping

# LightRAG health
curl http://localhost:9621/health | jq '.status'
```

## Configuration Templates

### Development Environment
For development, you may want to adjust:
```env
LOG_LEVEL=DEBUG
VERBOSE=True
MAX_ASYNC=2
MAX_PARALLEL_INSERT=1
ENABLE_LLM_CACHE=false
```

### High-Performance Environment
For high-load scenarios:
```env
MAX_ASYNC=8
MAX_PARALLEL_INSERT=4
EMBEDDING_FUNC_MAX_ASYNC=16
POSTGRES_MAX_CONNECTIONS=50
```

### Security-Hardened Environment
For production security:
```env
AUTH_ACCOUNTS=admin:secure_password_here
LIGHTRAG_API_KEY=your-secure-api-key
CORS_ORIGINS=https://your-domain.com
LOG_LEVEL=WARNING
```

## Configuration Change Management

### Safe Configuration Updates

1. **Environment Variables**: Update `.env` and restart containers
2. **Database Settings**: Require service restart
3. **Model Changes**: Clear workspace and reinitialize

### Rolling Updates

```bash
# Update environment
vim .env

# Restart specific service
docker compose restart lightrag

# Verify configuration
curl http://localhost:9621/health | jq '.configuration'
```

### Configuration Backup

```bash
# Backup current configuration
cp .env .env.backup.$(date +%Y%m%d)
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d)
```

---

This configuration reference ensures proper setup and maintenance of the ClaralyRAG production environment. For troubleshooting configuration issues, refer to the DEPLOYMENT.md guide.