# ClaralyRAG Troubleshooting Guide

This guide provides solutions for common issues encountered during deployment and operation of the ClaralyRAG system.

## Quick Diagnostics

### System Health Check
```bash
# Overall system status
docker compose ps

# Service health
curl -s http://localhost:9621/health | jq '.status'

# Database connectivity
curl -s http://localhost:9621/health | jq '.configuration | {kv_storage, vector_storage, graph_storage}'
```

### Log Analysis
```bash
# View all service logs
docker compose logs

# Service-specific logs
docker logs lightrag
docker logs lightrag-postgres
docker logs lightrag-neo4j
docker logs lightrag-redis

# Follow logs in real-time
docker logs -f lightrag

# Search for errors
docker logs lightrag 2>&1 | grep -i error
```

## Common Issues and Solutions

### 1. Port Conflicts

#### Problem
```
Error response from daemon: driver failed programming external connectivity on endpoint lightrag-redis: Bind for 0.0.0.0:6379 failed: port is already allocated
```

#### Diagnosis
```bash
# Check what's using the port
sudo netstat -tlnp | grep :6379
sudo lsof -i :6379

# List all Docker containers
docker ps -a
```

#### Solution
Update port mappings in `docker-compose.yml`:
```yaml
services:
  postgres:
    ports:
      - "5433:5432"  # Use different external port
  redis:
    ports:
      - "6380:6379"  # Use different external port
```

Update `.env` if needed (internal ports remain the same):
```env
# These stay the same (internal Docker network)
POSTGRES_PORT=5432
REDIS_PORT=6379
```

### 2. LLM Timeout Issues

#### Problem
```
httpx.ReadTimeout: chunk-xxxxx
ERROR: Failed to extract entities and relationships
```

#### Diagnosis
```bash
# Test Ollama connectivity
curl -s http://playground.intellinum.co:11434/api/tags

# Check current timeout settings
curl -s http://localhost:9621/health | jq '.configuration' | grep -i timeout
```

#### Solution
Update `.env` with appropriate timeouts:
```env
LLM_TIMEOUT=0              # Unlimited for Ollama
EMBEDDING_TIMEOUT=120      # 2 minutes for embeddings
```

Restart LightRAG:
```bash
docker restart lightrag
```

### 3. Neo4j Configuration Issues

#### Problem
```
chown: changing ownership of '/var/lib/neo4j/conf/neo4j.conf': Read-only file system
Container lightrag-neo4j is unhealthy
```

#### Diagnosis
```bash
# Check Neo4j logs
docker logs lightrag-neo4j

# Check file permissions
ls -la /data/claraly/rag/neo4j/
```

#### Solution
Remove custom config mount from `docker-compose.yml`:
```yaml
# Remove this line if causing issues:
# - /data/claraly/rag/neo4j/neo4j.conf:/var/lib/neo4j/conf/neo4j.conf:ro

# Use environment variables instead
environment:
  NEO4J_dbms_memory_heap_max__size: 1G
  NEO4J_dbms_memory_pagecache_size: 512m
```

### 4. Redis Configuration Errors

#### Problem
```
*** FATAL CONFIG FILE ERROR (Redis 7.2.10) ***
Reading the configuration file, at line 178
>>> 'lua-debugging no'
Bad directive or wrong number of arguments
```

#### Diagnosis
```bash
# Check Redis logs
docker logs lightrag-redis

# Test Redis configuration
docker run --rm -v /data/claraly/rag/redis/conf/redis.conf:/test.conf redis:7.2-alpine redis-server /test.conf --test-config 2>&1 | head -20
```

#### Solution
Use simplified command-line configuration:
```yaml
redis:
  command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes --save 900 1 --save 300 10 --save 60 1000
  # Remove custom config file mount
```

### 5. Document Processing Failures

#### Problem
```
ERROR: Failed to extract document 1/1: no-file-path
WARNING: chunk-xxxxx: Complete delimiter can not be found in extraction result
```

#### Diagnosis
```bash
# Check document status
curl -s http://localhost:9621/documents/status_counts | jq

# Check processing logs
docker logs lightrag | grep -E "(Processing|ERROR|WARNING)" | tail -20

# Test with simple document
curl -X POST http://localhost:9621/documents/text \
  -H "Content-Type: application/json" \
  -d '{"text": "Test document", "description": "Test"}'
```

#### Solution
1. **Increase timeouts** for remote Ollama:
```env
LLM_TIMEOUT=0
EMBEDDING_TIMEOUT=120
```

2. **Test Ollama connectivity**:
```bash
curl -X POST http://playground.intellinum.co:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3.2:latest", "prompt": "Hello", "stream": false}'
```

3. **Reduce document size** for testing:
```bash
# Use smaller test documents first
curl -X POST http://localhost:9621/documents/text \
  -H "Content-Type: application/json" \
  -d '{"text": "Short test.", "description": "Test"}'
```

### 6. Database Connection Issues

#### Problem
```
ERROR: PostgreSQL database, error: could not translate host name "postgres" to address
INFO: [production] Failed to connect to Neo4j
```

#### Diagnosis
```bash
# Check service status
docker compose ps

# Test database connectivity
docker exec lightrag-postgres pg_isready -U lightrag -d lightrag
docker exec lightrag-neo4j cypher-shell -u neo4j -p lightrag_neo4j_2024_secure "RETURN 1"
docker exec lightrag-redis redis-cli -a lightrag_redis_2024_secure ping
```

#### Solution
1. **Ensure services are healthy**:
```bash
# Wait for all services to be healthy
docker compose up -d
sleep 30
docker compose ps
```

2. **Check network connectivity**:
```bash
# Test from LightRAG container
docker exec lightrag ping postgres
docker exec lightrag ping neo4j
docker exec lightrag ping redis
```

3. **Verify environment variables**:
```bash
# Check database passwords match
docker exec lightrag env | grep -E "(POSTGRES|NEO4J|REDIS)"
```

### 7. Memory and Resource Issues

#### Problem
```
Container keeps restarting
Out of memory errors in logs
Slow performance
```

#### Diagnosis
```bash
# Check container resource usage
docker stats

# Check system memory
free -h
df -h /data/claraly/rag/

# Check Docker logs for OOM
dmesg | grep -i "killed process"
```

#### Solution
1. **Increase Docker memory limits**:
```yaml
services:
  lightrag:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

2. **Optimize database settings**:
```yaml
# PostgreSQL optimization
command: >
  postgres
  -c shared_buffers=128MB      # Reduce if low memory
  -c effective_cache_size=512MB # Adjust based on available RAM
```

3. **Reduce concurrency**:
```env
MAX_ASYNC=2
MAX_PARALLEL_INSERT=1
```

### 8. API Response Issues

#### Problem
```
504 Gateway Timeout
Connection refused
Slow API responses
```

#### Diagnosis
```bash
# Test API endpoints
curl -w "@curl-format.txt" -s http://localhost:9621/health

# Check response times
time curl -s http://localhost:9621/health > /dev/null

# Test query performance
time curl -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{"query": "test", "mode": "naive"}'
```

#### Solution
1. **Check service health**:
```bash
curl http://localhost:9621/health | jq '.status'
```

2. **Restart LightRAG if needed**:
```bash
docker restart lightrag
```

3. **Optimize query parameters**:
```env
TOP_K=20              # Reduce from default 40
CHUNK_TOP_K=10        # Reduce from default 20
MAX_TOTAL_TOKENS=15000 # Reduce from default 30000
```

### 9. Knowledge Graph Issues

#### Problem
```
No entities or relations found
Graph visualization empty
Poor query results in hybrid/global modes
```

#### Diagnosis
```bash
# Check document processing status
curl -s http://localhost:9621/documents/status_counts | jq

# Check Neo4j connectivity from LightRAG logs
docker logs lightrag | grep -i neo4j

# Test Neo4j directly
docker exec lightrag-neo4j cypher-shell -u neo4j -p lightrag_neo4j_2024_secure -d lightrag "MATCH (n) RETURN count(n)"
```

#### Solution
1. **Verify document processing completed**:
```bash
# Check all documents are processed
curl -s http://localhost:9621/documents/status_counts | jq '.status_counts'
```

2. **Test with entity-rich documents**:
```json
{
  "text": "Apple Inc. was founded by Steve Jobs and Steve Wozniak in California. The company produces iPhone devices and competes with Samsung Electronics.",
  "description": "Entity-rich test document"
}
```

3. **Check entity extraction settings**:
```env
ENTITY_TYPES='["Person", "Organization", "Location", "Product", "Company"]'
```

### 10. Permission and Access Issues

#### Problem
```
Permission denied errors
File system access issues
Container startup failures
```

#### Diagnosis
```bash
# Check file permissions
ls -la /data/claraly/rag/
ls -la /data/claraly/rag/*/

# Check Docker daemon status
systemctl status docker

# Check user permissions
id
groups
```

#### Solution
1. **Fix directory permissions**:
```bash
sudo chown -R $USER:$USER /data/claraly/rag/
sudo chmod -R 755 /data/claraly/rag/
```

2. **Ensure Docker access**:
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

3. **Create directories if missing**:
```bash
mkdir -p /data/claraly/rag/{postgres/{data,init},neo4j/{data,logs,import,plugins},redis/data,lightrag,inputs,tiktoken,logs}
```

## Performance Troubleshooting

### Slow Query Performance

#### Investigation
```bash
# Monitor query times
curl -w "Time: %{time_total}s\n" -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{"query": "your query", "mode": "hybrid"}'

# Check database performance
docker exec lightrag-postgres psql -U lightrag -d lightrag -c "SELECT schemaname,tablename,attname,n_distinct,correlation FROM pg_stats WHERE tablename LIKE 'lightrag%';"
```

#### Optimization
```env
# Reduce context size
MAX_TOTAL_TOKENS=15000
TOP_K=20
CHUNK_TOP_K=10

# Use faster query modes
# naive = fastest, hybrid = balanced, global = most comprehensive
```

### High Memory Usage

#### Investigation
```bash
# Monitor container memory
docker stats --no-stream

# Check database sizes
docker exec lightrag-postgres psql -U lightrag -d lightrag -c "SELECT pg_size_pretty(pg_database_size('lightrag'));"
```

#### Optimization
```bash
# Clean up old data if needed
curl -X DELETE http://localhost:9621/documents/clear_cache

# Optimize database
docker exec lightrag-postgres psql -U lightrag -d lightrag -c "VACUUM ANALYZE;"
```

## Recovery Procedures

### Complete System Recovery

1. **Stop all services**:
```bash
docker compose down
```

2. **Backup current data**:
```bash
sudo cp -r /data/claraly/rag /backup/claraly-rag-$(date +%Y%m%d)
```

3. **Reset if needed**:
```bash
# Only if complete reset needed
sudo rm -rf /data/claraly/rag/*/data
```

4. **Restart services**:
```bash
docker compose up -d
```

5. **Verify functionality**:
```bash
# Wait for services to be healthy
sleep 60
curl http://localhost:9621/health
```

### Selective Service Recovery

```bash
# Restart specific service
docker compose restart lightrag

# Rebuild service if needed
docker compose up -d --force-recreate lightrag

# Check logs
docker logs -f lightrag
```

## Monitoring and Alerts

### Log Monitoring
```bash
# Set up log monitoring
tail -f /var/log/docker.log | grep lightrag

# Monitor error patterns
docker logs lightrag 2>&1 | grep -E "(ERROR|FATAL|CRITICAL)" | tail -f
```

### Health Monitoring Script
```bash
#!/bin/bash
# health-check.sh
services=("lightrag" "lightrag-postgres" "lightrag-neo4j" "lightrag-redis")

for service in "${services[@]}"; do
    status=$(docker inspect --format='{{.State.Health.Status}}' $service 2>/dev/null || echo "not found")
    echo "$service: $status"
done

# API health
api_status=$(curl -s http://localhost:9621/health | jq -r '.status' 2>/dev/null || echo "unreachable")
echo "API: $api_status"
```

### Performance Monitoring
```bash
# Monitor resource usage
watch 'docker stats --no-stream | grep lightrag'

# Monitor query performance
watch 'curl -s -w "Time: %{time_total}s\n" http://localhost:9621/health | grep -E "(status|Time)"'
```

## Getting Help

### Information to Collect
When seeking support, collect:

1. **System information**:
```bash
docker --version
docker compose --version
uname -a
```

2. **Service status**:
```bash
docker compose ps
```

3. **Configuration**:
```bash
# Remove sensitive information first
cat .env | grep -v PASSWORD
```

4. **Logs**:
```bash
docker logs lightrag --tail 100
```

5. **Health status**:
```bash
curl -s http://localhost:9621/health | jq
```

### Support Resources
- LightRAG GitHub repository: Issues and documentation
- Docker documentation: Container troubleshooting
- PostgreSQL documentation: Database performance tuning
- Neo4j documentation: Graph database optimization

---

This troubleshooting guide should resolve most common issues. For persistent problems, ensure you have the latest versions and consider reaching out to the community with detailed information as described above.