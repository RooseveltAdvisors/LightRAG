#!/bin/bash
# ClaralyRAG Complete Data Cleanup Script
# WARNING: This will delete ALL data from all storage backends and working directories
# Use only in development - DO NOT use in production

set -e

echo "=========================================="
echo "ClaralyRAG Complete Data Cleanup"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will delete ALL data!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup process..."
echo ""

# Step 1: Stop all containers
echo "📦 Stopping Docker containers..."
docker compose down

# Step 2: Clear Neo4j database
echo "🗑️  Clearing Neo4j database..."
docker compose up -d neo4j
sleep 5
docker exec lightrag-neo4j cypher-shell -u neo4j -p lightrag_neo4j_2024_secure "MATCH (n) DETACH DELETE n" || true

# Step 3: Clear PostgreSQL database
echo "🗑️  Clearing PostgreSQL database..."
docker compose up -d postgres
sleep 3
docker exec lightrag-postgres psql -U lightrag_user -d lightrag_db -c "
DROP SCHEMA IF EXISTS lightrag CASCADE;
CREATE SCHEMA lightrag;
" || true

# Step 4: Clear Redis database
echo "🗑️  Clearing Redis cache..."
docker compose up -d redis
sleep 2
docker exec lightrag-redis redis-cli -a lightrag_redis_2024_secure --no-auth-warning FLUSHALL || true

# Step 5: Delete all working directories
echo "🗑️  Deleting working directories..."
rm -rf instances/*
echo "   Deleted: instances/*"

# Step 6: Clean up Docker volumes
echo "🗑️  Stopping containers and removing volumes..."
docker compose down -v

# Step 7: Prune unused volumes
echo "🗑️  Pruning unused Docker volumes..."
docker volume prune -f

# Step 8: Restart all services fresh
echo "🚀 Starting fresh containers..."
docker compose up -d

# Step 9: Wait for services to be healthy
echo "⏳ Waiting for services to become healthy..."
sleep 15

# Step 10: Check status
echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📊 Current status:"
docker compose ps
echo ""
echo "📁 Working directories:"
ls -la instances/ 2>/dev/null || echo "   (empty - as expected)"
echo ""
echo "=========================================="
echo "ClaralyRAG is now running with clean slate"
echo "=========================================="
echo ""
echo "💡 Note: If documents get stuck in 'pending' status,"
echo "   run: docker compose restart lightrag"
echo "   This clears the stuck processing lock."
echo "=========================================="
