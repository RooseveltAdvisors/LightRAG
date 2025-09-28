# ClaralyRAG Documentation

Welcome to the comprehensive documentation for ClaralyRAG, a production-ready implementation of LightRAG with Docker orchestration and enhanced features.

## 📚 Documentation Index

### User Documentation

- **[User Guide](User_Guide.md)** - Complete guide for end users
  - Getting started with the web interface
  - Document management and processing
  - Querying strategies and best practices
  - Knowledge graph exploration

### Developer Documentation

- **[Developer Guide](Developer_Guide.md)** - Technical development guide
  - Architecture overview and core components
  - Development setup and code organization
  - Storage backends and extension points
  - Testing strategies and best practices

- **[API Reference](API_Reference.md)** - Complete API documentation
  - REST API endpoints and parameters
  - Request/response formats and examples
  - Authentication and security
  - Client libraries and SDKs

### Deployment Documentation

- **[Docker Deployment Guide](Docker_Deployment_Guide.md)** - Production deployment
  - Docker Compose setup and configuration
  - Service management and monitoring
  - Backup and recovery procedures
  - Troubleshooting and optimization

### Configuration Documentation

- **[Configuration Reference](../CONFIGURATION.md)** - Complete configuration guide
  - Environment variables reference
  - Storage backend configuration
  - Performance tuning settings
  - Security and authentication options

- **[Deployment Guide](../DEPLOYMENT.md)** - Production deployment overview
  - System requirements and architecture
  - Quick start and verification
  - Integration points and scaling

- **[Troubleshooting Guide](../TROUBLESHOOTING.md)** - Issue resolution
  - Common problems and solutions
  - Debug procedures and log analysis
  - Performance optimization tips
  - Recovery procedures

## 🚀 Quick Start

### For Users
1. Access the web interface at `http://localhost:9621`
2. Upload documents via the Documents tab
3. Ask questions using the Query interface
4. Explore relationships in the Graph view

### For Developers
1. Clone the repository
2. Install dependencies: `pip install -e ".[api,dev]"`
3. Configure environment: `cp env.example .env`
4. Start services: `./start.sh`

### For Deployment
1. Ensure Docker and Docker Compose are installed
2. Configure `.env` file with your settings
3. Run `./start.sh` to deploy the complete stack
4. Verify health at `http://localhost:9621/health`

## 🏗️ Architecture Overview

ClaralyRAG is built on a modular architecture:

```
┌─────────────────────────────────────────┐
│            Web Interface                │
├─────────────────────────────────────────┤
│              REST API                   │
├─────────────────────────────────────────┤
│           LightRAG Engine               │
├─────────────────────────────────────────┤
│  PostgreSQL  │   Neo4j    │   Redis     │
│  (pgvector)  │ (Graph DB) │ (Cache)     │
└─────────────────────────────────────────┘
```

### Key Components

- **LightRAG Engine**: Core RAG processing with knowledge graphs
- **PostgreSQL + pgvector**: Vector storage and relational data
- **Neo4j**: Knowledge graph storage with APOC/GDS plugins
- **Redis**: High-performance caching layer
- **FastAPI Server**: REST API and web interface
- **React Web UI**: Interactive document management and querying

## 📋 Features

### Document Processing
- **Multi-format Support**: PDF, DOC, TXT, CSV, and more
- **Intelligent Chunking**: Optimized text segmentation
- **Entity Extraction**: AI-powered entity and relationship identification
- **Knowledge Graph Construction**: Automatic graph building from documents

### Query Capabilities
- **Multiple Query Modes**: Naive, Local, Global, and Hybrid approaches
- **Semantic Search**: Vector similarity and graph-based retrieval
- **Source Attribution**: Comprehensive citation and reference tracking
- **Streaming Responses**: Real-time query result streaming

### Knowledge Graph
- **Interactive Visualization**: Explore entities and relationships
- **Graph Analytics**: Centrality metrics and community detection
- **Entity Management**: Browse, search, and manage extracted entities
- **Relationship Analysis**: Understand connections between concepts

### Production Features
- **Docker Orchestration**: Complete multi-service deployment
- **Health Monitoring**: Comprehensive health checks and status reporting
- **Persistent Storage**: Reliable data persistence across restarts
- **Scalable Architecture**: Designed for production workloads

## 🔧 Configuration

### Environment Variables

Key configuration options:

```env
# Application Settings
HOST=0.0.0.0
PORT=9621
WORKSPACE=production

# LLM Configuration
LLM_BINDING=ollama
LLM_MODEL=llama3.2:latest
LLM_BINDING_HOST=http://playground.intellinum.co:11434

# Storage Backends
LIGHTRAG_KV_STORAGE=PGKVStorage
LIGHTRAG_VECTOR_STORAGE=PGVectorStorage
LIGHTRAG_GRAPH_STORAGE=Neo4JStorage

# Performance Tuning
MAX_ASYNC=4
MAX_PARALLEL_INSERT=2
ENABLE_LLM_CACHE=true
```

### Storage Options

ClaralyRAG supports multiple storage backends:

- **Production**: PostgreSQL + Neo4j + Redis
- **Development**: JSON + NetworkX (lightweight)
- **Hybrid**: Mix and match based on requirements

## 🐳 Docker Deployment

### Quick Deployment

```bash
# Clone repository
git clone <repository-url>
cd ClaralyRAG

# Start complete stack
./start.sh

# Verify deployment
curl http://localhost:9621/health
```

### Service Management

```bash
# View status
docker compose ps

# View logs
docker compose logs -f lightrag

# Restart service
docker compose restart lightrag

# Scale services
docker compose up -d --scale lightrag=3
```

## 🔍 Usage Examples

### Document Upload

```bash
# Upload text document
curl -X POST http://localhost:9621/documents/text \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Your document content here",
    "description": "Document description"
  }'
```

### Querying

```bash
# Hybrid query (recommended)
curl -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is artificial intelligence?",
    "mode": "hybrid"
  }'
```

### Graph Exploration

```bash
# Get graph data
curl http://localhost:9621/graph/data?limit=1000

# Search entities
curl -X POST http://localhost:9621/graph/search \
  -H "Content-Type: application/json" \
  -d '{"query": "machine learning"}'
```

## 🔒 Security

### Authentication Options

- **No Authentication**: Default for development
- **JWT Authentication**: Token-based user authentication
- **API Key Protection**: Secure API access

### Production Security

```env
# Enable authentication
AUTH_ACCOUNTS=admin:secure_password,user:another_password

# API key protection
LIGHTRAG_API_KEY=your-secure-api-key

# Restrict CORS
CORS_ORIGINS=https://yourdomain.com
```

## 📊 Monitoring

### Health Checks

```bash
# System health
curl http://localhost:9621/health

# Document processing status
curl http://localhost:9621/documents/status_counts

# Service status
docker compose ps
```

### Performance Monitoring

```bash
# Container resources
docker stats

# Database metrics
curl http://localhost:9621/health | jq '.configuration'

# Query performance
time curl -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{"query": "test", "mode": "naive"}'
```

## 🆘 Support

### Self-Help Resources

1. **Check System Health**: `/health` endpoint
2. **Review Logs**: `docker compose logs`
3. **Configuration Validation**: Environment variable checks
4. **Documentation**: Comprehensive guides for all scenarios

### Troubleshooting

Common issues and solutions:

- **Port Conflicts**: Modify port mappings in `docker-compose.yml`
- **Memory Issues**: Adjust `MAX_ASYNC` and `MAX_PARALLEL_INSERT`
- **Database Connections**: Verify service health and passwords
- **LLM Timeouts**: Increase `LLM_TIMEOUT` setting

### Getting Help

1. **Documentation**: Start with the relevant guide above
2. **Health Check**: Verify system status
3. **Logs Analysis**: Review container logs for errors
4. **Configuration Review**: Validate environment settings

## 🚦 Status and Health

### System Requirements Met ✅

- Docker Engine 20.10+ with Compose v2
- 8GB+ RAM (16GB recommended for production)
- 50GB+ available storage
- Network access to LLM services

### Current Status ✅

- **All Services**: Healthy and operational
- **Document Processing**: Working without timeout issues
- **Query System**: All modes functional
- **Knowledge Graph**: Properly extracting and storing entities
- **API**: Fully functional with OpenAPI documentation

### Recent Fixes ✅

- **Worker Timeout Issue**: Resolved LLM worker timeout problems
- **Environment Loading**: Fixed Docker environment variable loading
- **Database Authentication**: Resolved Neo4j and PostgreSQL connection issues
- **Port Conflicts**: Configured non-conflicting port mappings

## 📈 Roadmap

### Planned Enhancements

- **Enhanced Reranking**: Native Ollama reranker integration
- **Multi-Modal Support**: Image and video processing
- **Advanced Analytics**: Enhanced graph analytics and insights
- **Performance Optimization**: Further query and processing improvements
- **Enterprise Features**: Advanced authentication and multi-tenancy

### Community Contributions

ClaralyRAG builds on the excellent LightRAG project and welcomes contributions for:

- Documentation improvements
- Feature enhancements
- Bug fixes and optimizations
- Integration examples
- Performance benchmarks

---

## 📖 Documentation Navigation

- **Start Here**: [User Guide](User_Guide.md) for end users
- **Development**: [Developer Guide](Developer_Guide.md) for technical implementation
- **API Integration**: [API Reference](API_Reference.md) for programmatic access
- **Production Deployment**: [Docker Deployment Guide](Docker_Deployment_Guide.md)
- **Configuration**: [Configuration Reference](../CONFIGURATION.md)
- **Troubleshooting**: [Troubleshooting Guide](../TROUBLESHOOTING.md)

Each guide includes practical examples, best practices, and comprehensive reference material for successful implementation and operation of ClaralyRAG.