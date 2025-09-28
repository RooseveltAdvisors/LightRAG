#!/bin/bash

# ClaralyRAG Production Startup Script
# Explicitly sets all environment variables to avoid .env loading issues

export POSTGRES_PASSWORD=lightrag_pg_2024_secure
export NEO4J_PASSWORD=lightrag_neo4j_2024_secure
export REDIS_PASSWORD=lightrag_redis_2024_secure

echo "🚀 Starting ClaralyRAG Production Stack..."
echo "📊 PostgreSQL Password: $POSTGRES_PASSWORD"
echo "🕸️  Neo4j Password: $NEO4J_PASSWORD"
echo "⚡ Redis Password: $REDIS_PASSWORD"

# Start all services with explicit environment variables
docker compose up -d

echo "✅ All services started. Checking health..."
sleep 45

echo "🔍 Checking service health..."
docker compose ps
echo ""

echo "📋 LightRAG Health Check:"
curl -s http://localhost:9621/health | jq '.' || echo "❌ LightRAG not ready yet"

echo ""
echo "🎉 Startup complete! Access LightRAG at http://localhost:9621"