# ClaralyRAG Docker Deployment Guide

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Architecture](#architecture)
4. [Prerequisites](#prerequisites)
5. [Configuration](#configuration)
6. [Deployment](#deployment)
7. [Service Management](#service-management)
8. [Monitoring](#monitoring)
9. [Backup and Recovery](#backup-and-recovery)
10. [Troubleshooting](#troubleshooting)
11. [Production Considerations](#production-considerations)

## Overview

ClaralyRAG uses Docker Compose to orchestrate a multi-service production stack including:

- **LightRAG Application**: Core RAG engine with API and web interface
- **PostgreSQL with pgvector**: Vector storage and relational data
- **Neo4j**: Knowledge graph database with APOC and GDS plugins
- **Redis**: High-performance caching layer

This deployment provides a complete, production-ready RAG system with persistent data storage and scalable architecture.

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd ClaralyRAG
```

### 2. Deploy Stack

```bash
# Start all services
./start.sh

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

### Service Communication

- **Internal Network**: All services communicate via Docker network
- **External Access**: Only LightRAG port (9621) exposed externally
- **Database Isolation**: Databases accessible only within the stack
- **Persistent Storage**: All data stored in `/data/claraly/rag/`

## Prerequisites

### System Requirements

- **Docker Engine**: 20.10+ with Docker Compose v2
- **Memory**: Minimum 8GB RAM (16GB recommended)
- **Storage**: 50GB+ available disk space
- **Network**: Access to `playground.intellinum.co:11434` for LLM services

### Directory Structure

Data persistence requires the following structure:

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

### Network Requirements

- **Outbound HTTPS**: Access to Ollama server for LLM services
- **Port Availability**: Ensure ports 5433, 6380, 7474, 7687, 9621 are available
- **DNS Resolution**: Ensure proper DNS resolution for external services

## Configuration

### Environment Variables

The deployment is configured via `.env` file:

```env
# Core Application Settings
HOST=0.0.0.0
PORT=9621
WEBUI_TITLE='Claraly RAG'
WORKSPACE=production

# LLM Configuration (Ollama)
LLM_BINDING=ollama
LLM_MODEL=llama3.2:latest
LLM_BINDING_HOST=http://playground.intellinum.co:11434
LLM_TIMEOUT=600

# Embedding Configuration
EMBEDDING_BINDING=ollama
EMBEDDING_MODEL=bge-m3:latest
EMBEDDING_BINDING_HOST=http://playground.intellinum.co:11434
EMBEDDING_TIMEOUT=120

# Storage Backends (Production)
LIGHTRAG_KV_STORAGE=PGKVStorage
LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
LIGHTRAG_GRAPH_STORAGE=Neo4JStorage
LIGHTRAG_DOC_STATUS_STORAGE=PGDocStatusStorage

# Database Passwords
POSTGRES_PASSWORD=lightrag_pg_2024_secure
NEO4J_PASSWORD=lightrag_neo4j_2024_secure
REDIS_PASSWORD=lightrag_redis_2024_secure

# Performance Settings
MAX_ASYNC=4
MAX_PARALLEL_INSERT=2
ENABLE_LLM_CACHE=true
```

### Service Configuration

#### PostgreSQL (pgvector)

```yaml
postgres:
  image: pgvector/pgvector:pg16
  environment:
    POSTGRES_DB: lightrag
    POSTGRES_USER: lightrag
    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
  command: >
    postgres
    -c shared_preload_libraries=vector
    -c max_connections=200
    -c shared_buffers=256MB
    -c effective_cache_size=1GB
```

#### Neo4j (Knowledge Graph)

```yaml
neo4j:
  image: neo4j:5.23-community
  environment:
    NEO4J_AUTH: neo4j/${NEO4J_PASSWORD}
    NEO4J_PLUGINS: '["apoc", "graph-data-science"]'
    NEO4J_dbms_memory_heap_max__size: 1G
    NEO4J_dbms_memory_pagecache_size: 512m
```

#### Redis (Caching)

```yaml
redis:
  image: redis:7.2-alpine
  command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
```

#### LightRAG Application

```yaml
lightrag:
  image: ghcr.io/hkuds/lightrag:latest
  depends_on:
    postgres: { condition: service_healthy }
    neo4j: { condition: service_healthy }
    redis: { condition: service_healthy }
  environment:
    - LIGHTRAG_KV_STORAGE=PGKVStorage
    - LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
    - LIGHTRAG_GRAPH_STORAGE=Neo4JStorage
```

## Deployment

### Initial Deployment

#### 1. Environment Setup

```bash
# Copy and configure environment
cp env.example .env

# Edit configuration
nano .env  # or vim .env

# Ensure data directories exist with correct permissions
sudo mkdir -p /data/claraly/rag/{postgres/{data,init},neo4j/{data,logs,import,plugins},redis/data,lightrag,inputs,tiktoken,logs}
sudo chown -R $USER:$USER /data/claraly/rag/
```

#### 2. Start Services

```bash
# Start all services
./start.sh

# Alternative: Manual start
docker compose up -d

# Check service status
docker compose ps
```

#### 3. Verify Health

```bash
# Check overall health
curl -s http://localhost:9621/health | jq

# Verify individual services
docker compose ps
docker logs lightrag --tail 50
```

### Service Dependencies

Services start in order based on health checks:

1. **Infrastructure Services**: PostgreSQL, Neo4j, Redis start first
2. **Health Checks**: Each service must pass health checks
3. **Application Start**: LightRAG starts only after all dependencies are healthy

### Port Mapping

Due to potential port conflicts, external ports are mapped:

| Service | Internal Port | External Port | Purpose |
|---------|---------------|---------------|---------|
| LightRAG | 9621 | 9621 | Web interface and API |
| PostgreSQL | 5432 | 5433 | Database access |
| Neo4j HTTP | 7474 | 7474 | Neo4j Browser |
| Neo4j Bolt | 7687 | 7687 | Database protocol |
| Redis | 6379 | 6380 | Cache access |

## Service Management

### Starting and Stopping

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart specific service
docker compose restart lightrag

# Stop specific service
docker compose stop neo4j
```

### Service Updates

```bash
# Update images
docker compose pull

# Restart with new images
docker compose down
docker compose up -d

# Rolling update (minimal downtime)
docker compose up -d --force-recreate lightrag
```

### Log Management

```bash
# View logs
docker compose logs                    # All services
docker compose logs lightrag           # Specific service
docker compose logs -f --tail 100 lightrag  # Follow logs

# Service-specific logs
docker logs lightrag
docker logs lightrag-postgres
docker logs lightrag-neo4j
docker logs lightrag-redis
```

### Health Monitoring

```bash
# Check service health
docker compose ps

# Individual health checks
docker exec lightrag-postgres pg_isready -U lightrag -d lightrag
docker exec lightrag-neo4j cypher-shell -u neo4j -p lightrag_neo4j_2024_secure "RETURN 1"
docker exec lightrag-redis redis-cli -a lightrag_redis_2024_secure ping

# Application health
curl http://localhost:9621/health
```

## Monitoring

### System Metrics

```bash
# Container resource usage
docker stats

# Disk usage
df -h /data/claraly/rag/

# Service status
docker compose ps

# Network connectivity
docker network ls
docker network inspect lightrag-network
```

### Application Metrics

```bash
# Document processing status
curl -s http://localhost:9621/documents/status_counts | jq

# System configuration
curl -s http://localhost:9621/health | jq '.configuration'

# API health
curl -w "@curl-format.txt" -s http://localhost:9621/health

# Create curl-format.txt for timing
cat > curl-format.txt << 'EOF'
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
EOF
```

### Database Monitoring

```bash
# PostgreSQL
docker exec lightrag-postgres psql -U lightrag -d lightrag -c "
SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del
FROM pg_stat_user_tables;"

# Neo4j
docker exec lightrag-neo4j cypher-shell -u neo4j -p lightrag_neo4j_2024_secure -d lightrag "
CALL db.stats.retrieve('GRAPH COUNTS')"

# Redis
docker exec lightrag-redis redis-cli -a lightrag_redis_2024_secure info memory
```

### Automated Monitoring

Create a monitoring script:

```bash
#!/bin/bash
# health-monitor.sh

services=("lightrag" "lightrag-postgres" "lightrag-neo4j" "lightrag-redis")

echo "=== ClaralyRAG Health Check $(date) ==="

for service in "${services[@]}"; do
    status=$(docker inspect --format='{{.State.Health.Status}}' $service 2>/dev/null || echo "not found")
    echo "$service: $status"
done

# API health
api_status=$(curl -s http://localhost:9621/health | jq -r '.status' 2>/dev/null || echo "unreachable")
echo "API: $api_status"

# Document processing
doc_status=$(curl -s http://localhost:9621/documents/status_counts | jq -r '.status_counts' 2>/dev/null || echo "unavailable")
echo "Documents: $doc_status"

echo "=================================="
```

Make it executable and run:

```bash
chmod +x health-monitor.sh
./health-monitor.sh

# Run every 5 minutes
watch -n 300 ./health-monitor.sh
```

## Backup and Recovery

### Data Backup

#### PostgreSQL Backup

```bash
# Create backup
docker exec lightrag-postgres pg_dump -U lightrag lightrag > backup_$(date +%Y%m%d).sql

# Backup with compression
docker exec lightrag-postgres pg_dump -U lightrag lightrag | gzip > backup_$(date +%Y%m%d).sql.gz

# Custom format backup (recommended)
docker exec lightrag-postgres pg_dump -U lightrag -Fc lightrag > backup_$(date +%Y%m%d).dump
```

#### Neo4j Backup

```bash
# Stop Neo4j for consistent backup
docker compose stop neo4j

# Backup data directory
sudo tar -czf neo4j_backup_$(date +%Y%m%d).tar.gz -C /data/claraly/rag/neo4j data

# Restart Neo4j
docker compose start neo4j
```

#### Redis Backup

```bash
# Trigger background save
docker exec lightrag-redis redis-cli -a lightrag_redis_2024_secure BGSAVE

# Copy dump file
cp /data/claraly/rag/redis/data/dump.rdb redis_backup_$(date +%Y%m%d).rdb
```

#### Complete System Backup

```bash
#!/bin/bash
# backup-system.sh

BACKUP_DIR="/backup/claraly-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

echo "Creating system backup in $BACKUP_DIR"

# PostgreSQL backup
echo "Backing up PostgreSQL..."
docker exec lightrag-postgres pg_dump -U lightrag -Fc lightrag > "$BACKUP_DIR/postgres.dump"

# Configuration backup
echo "Backing up configuration..."
cp .env "$BACKUP_DIR/"
cp docker-compose.yml "$BACKUP_DIR/"

# LightRAG data backup
echo "Backing up LightRAG data..."
sudo tar -czf "$BACKUP_DIR/lightrag_data.tar.gz" -C /data/claraly/rag lightrag inputs tiktoken

# Neo4j backup (requires service stop)
echo "Backing up Neo4j..."
docker compose stop neo4j
sudo tar -czf "$BACKUP_DIR/neo4j_data.tar.gz" -C /data/claraly/rag/neo4j data
docker compose start neo4j

# Redis backup
echo "Backing up Redis..."
docker exec lightrag-redis redis-cli -a lightrag_redis_2024_secure BGSAVE
sleep 5
cp /data/claraly/rag/redis/data/dump.rdb "$BACKUP_DIR/"

echo "Backup completed: $BACKUP_DIR"
```

### Recovery Procedures

#### PostgreSQL Recovery

```bash
# Stop services
docker compose down

# Restore from dump
docker compose up -d postgres
sleep 30
docker exec -i lightrag-postgres pg_restore -U lightrag -d lightrag -c < backup.dump

# Restart services
docker compose up -d
```

#### Neo4j Recovery

```bash
# Stop services
docker compose down

# Restore data
sudo rm -rf /data/claraly/rag/neo4j/data/*
sudo tar -xzf neo4j_backup.tar.gz -C /data/claraly/rag/neo4j/

# Fix permissions
sudo chown -R 7474:7474 /data/claraly/rag/neo4j/data

# Restart services
docker compose up -d
```

#### Complete System Recovery

```bash
# Stop all services
docker compose down

# Restore PostgreSQL
docker compose up -d postgres
sleep 30
docker exec -i lightrag-postgres pg_restore -U lightrag -d lightrag -c < postgres.dump

# Restore Neo4j
sudo rm -rf /data/claraly/rag/neo4j/data/*
sudo tar -xzf neo4j_data.tar.gz -C /data/claraly/rag/neo4j/
sudo chown -R 7474:7474 /data/claraly/rag/neo4j/data

# Restore Redis
cp dump.rdb /data/claraly/rag/redis/data/

# Restore LightRAG data
sudo tar -xzf lightrag_data.tar.gz -C /data/claraly/rag/

# Restore configuration
cp .env docker-compose.yml ./

# Start all services
docker compose up -d
```

## Troubleshooting

### Common Issues

#### 1. Port Conflicts

**Problem**: "Port already allocated" errors

**Solution**:
```bash
# Check port usage
sudo netstat -tlnp | grep -E "(5433|6380|7474|7687|9621)"

# Kill conflicting processes
sudo lsof -ti:5433 | xargs sudo kill -9

# Or modify ports in docker-compose.yml
```

#### 2. Insufficient Disk Space

**Problem**: Services failing due to disk space

**Solution**:
```bash
# Check disk usage
df -h /data/claraly/rag/

# Clean Docker system
docker system prune -a

# Clean application data
curl -X DELETE http://localhost:9621/documents/clear_cache
```

#### 3. Database Connection Issues

**Problem**: LightRAG cannot connect to databases

**Solution**:
```bash
# Check service health
docker compose ps

# Test connectivity
docker exec lightrag ping postgres
docker exec lightrag ping neo4j
docker exec lightrag ping redis

# Check environment variables
docker exec lightrag env | grep -E "(POSTGRES|NEO4J|REDIS)"
```

#### 4. LLM Service Issues

**Problem**: Queries failing with timeout errors

**Solution**:
```bash
# Test Ollama connectivity
curl -s http://playground.intellinum.co:11434/api/tags

# Check LLM configuration
docker exec lightrag env | grep LLM

# Increase timeout
# Edit .env: LLM_TIMEOUT=600
docker compose restart lightrag
```

### Debug Commands

```bash
# Container inspection
docker inspect lightrag

# Network debugging
docker network inspect lightrag-network

# Volume inspection
docker volume ls
docker volume inspect claraly_postgres_data

# Resource usage
docker stats --no-stream

# Service logs with timestamps
docker compose logs --timestamps lightrag
```

## Production Considerations

### Security Hardening

#### 1. Network Security

```yaml
# Use custom networks
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access

services:
  lightrag:
    networks: [frontend, backend]
  postgres:
    networks: [backend]  # Database isolated
```

#### 2. Authentication

```env
# Enable authentication
AUTH_ACCOUNTS=admin:secure_password_here,user:another_password

# API key protection
LIGHTRAG_API_KEY=your-secure-api-key-here

# Restrict CORS
CORS_ORIGINS=https://yourdomain.com
```

#### 3. SSL/TLS

```yaml
# Use reverse proxy with SSL
nginx:
  image: nginx:alpine
  ports: ["443:443"]
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf
    - ./certs:/etc/nginx/certs
```

### Scaling Considerations

#### Horizontal Scaling

```yaml
# Scale LightRAG replicas
lightrag:
  deploy:
    replicas: 3
  environment:
    - MAX_ASYNC=2  # Reduce per instance

# Load balancer
nginx:
  image: nginx:alpine
  depends_on: [lightrag]
```

#### Resource Limits

```yaml
services:
  lightrag:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
        reservations:
          memory: 1G
          cpus: '0.5'
```

### Monitoring and Alerting

#### Health Check URLs

```bash
# Setup monitoring endpoints
curl http://localhost:9621/health
curl http://localhost:9621/metrics  # If metrics enabled
```

#### Log Aggregation

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
    labels: "service"
```

### Performance Optimization

#### Database Tuning

```yaml
postgres:
  command: >
    postgres
    -c shared_buffers=512MB
    -c effective_cache_size=2GB
    -c max_connections=100
    -c work_mem=4MB
```

#### Application Tuning

```env
# Optimize for production load
MAX_ASYNC=8
MAX_PARALLEL_INSERT=4
EMBEDDING_FUNC_MAX_ASYNC=16

# Enable all caching
ENABLE_LLM_CACHE=true
ENABLE_LLM_CACHE_FOR_EXTRACT=true
```

For additional troubleshooting, see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) and [CONFIGURATION.md](../CONFIGURATION.md).