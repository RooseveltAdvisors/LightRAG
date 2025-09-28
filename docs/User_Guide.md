# ClaralyRAG User Guide

## Table of Contents

1. [Getting Started](#getting-started)
2. [Web Interface](#web-interface)
3. [Document Management](#document-management)
4. [Querying System](#querying-system)
5. [Knowledge Graph Exploration](#knowledge-graph-exploration)
6. [Configuration](#configuration)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

## Getting Started

### What is ClaralyRAG?

ClaralyRAG is an advanced Retrieval-Augmented Generation (RAG) system that combines:
- **Document Processing**: Intelligent text analysis and chunking
- **Knowledge Graphs**: Entity and relationship extraction
- **Vector Search**: Semantic similarity matching
- **Multi-Modal Querying**: Different search strategies for various use cases

### System Requirements

- Web browser (Chrome, Firefox, Safari, Edge)
- Internet connection for LLM services
- Sufficient storage for your documents

### Accessing the System

1. **Web Interface**: Open `http://localhost:9621` in your browser
2. **API Access**: Use the REST API at `http://localhost:9621/docs`
3. **Health Check**: Visit `http://localhost:9621/health` to verify system status

## Web Interface

### Dashboard Overview

The main dashboard provides access to:

- **📄 Documents**: Upload and manage your document collection
- **🔍 Query**: Ask questions and get intelligent responses
- **🕸️ Graph**: Explore the knowledge graph visually
- **⚙️ Settings**: Configure system preferences

### Navigation

- **Header Bar**: Quick access to main features and settings
- **Sidebar**: Detailed navigation and status information
- **Main Content**: Primary workspace for each feature
- **Status Indicators**: Real-time system health and processing status

## Document Management

### Supported File Types

ClaralyRAG supports various document formats:

- **Text Files**: `.txt`, `.md`
- **Office Documents**: `.pdf`, `.doc`, `.docx`, `.ppt`, `.pptx`
- **Data Files**: `.csv`, `.json`
- **Web Content**: Direct text input

### Uploading Documents

#### Method 1: File Upload

1. Navigate to the **Documents** section
2. Click **Upload Documents** button
3. Select files from your computer
4. Add optional description
5. Click **Upload** to start processing

#### Method 2: Text Input

1. Click **Add Text Document**
2. Paste or type your content
3. Add a descriptive title
4. Click **Submit** to process

#### Method 3: Bulk Upload

1. Use **Batch Upload** for multiple files
2. Select multiple files at once
3. The system will process them sequentially
4. Monitor progress in the status panel

### Document Processing

After upload, documents go through several stages:

1. **📤 Uploaded**: File received successfully
2. **🔄 Processing**: Extracting entities and relationships
3. **✅ Processed**: Ready for querying
4. **❌ Failed**: Processing encountered errors

#### Processing Status

Monitor processing status:
- **Status Panel**: Shows overall progress
- **Document List**: Individual document status
- **Notifications**: Alerts for completed/failed processing

### Managing Documents

#### Viewing Documents

- **Document List**: See all uploaded documents
- **Search**: Find specific documents by name or content
- **Filter**: Show only processed, processing, or failed documents
- **Sort**: Order by upload date, status, or file size

#### Document Actions

- **👁️ View**: See document content and metadata
- **📊 Stats**: View processing statistics
- **🗑️ Delete**: Remove individual documents
- **🔄 Reprocess**: Retry failed document processing

#### Bulk Operations

- **Select Multiple**: Use checkboxes to select documents
- **Batch Delete**: Remove multiple documents at once
- **Clear All**: Remove all documents (requires confirmation)

## Querying System

### Query Modes

ClaralyRAG offers four intelligent query modes:

#### 1. Naive Mode
- **Best for**: Simple factual questions
- **How it works**: Pure vector similarity search
- **Speed**: Fastest ⚡
- **Example**: "What is machine learning?"

#### 2. Local Mode
- **Best for**: Context-dependent questions
- **How it works**: Graph-based local reasoning
- **Speed**: Fast ⚡⚡
- **Example**: "How does X relate to Y in my documents?"

#### 3. Global Mode
- **Best for**: Complex analytical questions
- **How it works**: Global knowledge graph analysis
- **Speed**: Moderate ⚡⚡⚡
- **Example**: "What are the main themes across all documents?"

#### 4. Hybrid Mode (Recommended)
- **Best for**: Most questions
- **How it works**: Combines local and global approaches
- **Speed**: Moderate ⚡⚡⚡
- **Example**: "Analyze the relationship between concepts X and Y"

### Asking Questions

#### Basic Querying

1. Navigate to the **Query** section
2. Type your question in the search box
3. Select query mode (Hybrid recommended)
4. Click **Submit** or press Enter
5. View the response with source references

#### Advanced Options

Click **Advanced Settings** to customize:

- **Top K**: Number of entities/relations to retrieve (default: 40)
- **Chunk Top K**: Number of text chunks for context (default: 20)
- **Max Tokens**: Maximum response length (default: 30,000)
- **Enable Reranking**: Improve result relevance (if configured)

#### Query Examples

**Factual Questions:**
- "What is the definition of artificial intelligence?"
- "Who founded Apple Inc.?"
- "When was the iPhone released?"

**Analytical Questions:**
- "What are the main benefits of cloud computing mentioned in the documents?"
- "How do the different machine learning approaches compare?"
- "What are the common themes in the research papers?"

**Relationship Questions:**
- "How is blockchain related to cryptocurrency?"
- "What connections exist between climate change and renewable energy?"
- "Which companies are mentioned alongside Microsoft?"

### Understanding Responses

#### Response Structure

Each response includes:

1. **Main Answer**: AI-generated response to your question
2. **Source References**: Documents that informed the answer
3. **Confidence Indicators**: System confidence in the response
4. **Related Entities**: Key concepts mentioned in the answer

#### Source Citations

- **Reference Numbers**: [1], [2], etc. link to specific documents
- **Document Names**: Click to view the source document
- **Relevance Scores**: How closely each source matches your query

#### Follow-up Questions

The system suggests related questions based on:
- Content of your current query
- Available knowledge in the system
- Common follow-up patterns

## Knowledge Graph Exploration

### Graph Visualization

The knowledge graph shows:
- **Nodes**: Entities (people, organizations, concepts)
- **Edges**: Relationships between entities
- **Colors**: Different entity types
- **Sizes**: Importance/relevance scores

### Navigation Controls

#### Zoom and Pan
- **Mouse Wheel**: Zoom in/out
- **Click and Drag**: Pan around the graph
- **Fit to Screen**: Auto-zoom to show all nodes

#### Node Interaction
- **Click Node**: View detailed information
- **Double-click**: Expand connected nodes
- **Right-click**: Context menu with options

#### Search and Filter
- **Search Box**: Find specific entities
- **Type Filter**: Show only certain entity types
- **Relationship Filter**: Focus on specific relationships

### Graph Layouts

Choose from different visualization layouts:

- **Force-Directed**: Natural clustering of related entities
- **Hierarchical**: Tree-like structure showing relationships
- **Circular**: Entities arranged in a circle
- **Grid**: Organized grid layout

### Entity Details

Click any entity to see:
- **Description**: AI-generated summary
- **Type**: Category (Person, Organization, Concept, etc.)
- **Related Entities**: Direct connections
- **Source Documents**: Documents mentioning this entity
- **Relationship Summary**: Key relationships

### Graph Analysis

#### Centrality Metrics
- **Degree Centrality**: Most connected entities
- **Betweenness Centrality**: Entities that bridge different clusters
- **PageRank**: Most important entities overall

#### Clustering
- **Community Detection**: Find related groups of entities
- **Topic Clusters**: Entities grouped by subject matter
- **Document Clusters**: Entities from the same sources

## Configuration

### System Settings

Access settings through the ⚙️ Settings menu:

#### Query Settings
- **Default Query Mode**: Choose your preferred mode
- **Response Length**: Control answer detail level
- **Language**: Set response language
- **Citation Style**: Choose how sources are referenced

#### Display Settings
- **Theme**: Light or dark mode
- **Graph Colors**: Customize node and edge colors
- **Layout Preferences**: Default graph layout
- **Animation Speed**: Control transition speeds

#### Privacy Settings
- **Query History**: Enable/disable query logging
- **Document Retention**: Set automatic deletion policies
- **Data Export**: Download your data
- **Cache Management**: Clear system cache

### API Configuration

For advanced users and integrations:

#### API Keys
- Generate API keys for programmatic access
- Set rate limits and permissions
- Monitor API usage

#### Webhooks
- Configure notifications for processing completion
- Set up integration endpoints
- Customize payload formats

## Best Practices

### Document Organization

#### Naming Conventions
- Use descriptive filenames
- Include dates for versioned documents
- Group related documents in batches

#### Content Preparation
- **Clean Text**: Remove unnecessary formatting
- **Consistent Structure**: Use similar document structures
- **Rich Metadata**: Add descriptions and tags

#### Batch Processing
- Upload related documents together
- Process large batches during off-peak hours
- Monitor system resources during bulk operations

### Effective Querying

#### Question Formulation
- **Be Specific**: "What are the benefits of solar energy?" vs. "Tell me about energy"
- **Use Context**: Reference specific documents or time periods
- **Ask Follow-ups**: Build on previous questions for deeper insights

#### Mode Selection
- Start with **Hybrid mode** for most questions
- Use **Naive mode** for simple fact-checking
- Use **Global mode** for comprehensive analysis
- Use **Local mode** for document-specific questions

#### Query Optimization
- Break complex questions into smaller parts
- Use keywords that appear in your documents
- Experiment with different phrasings

### Knowledge Graph Utilization

#### Exploration Strategies
- Start with high-centrality nodes
- Follow interesting relationship paths
- Use search to find specific entities
- Export insights for external analysis

#### Graph Maintenance
- Regularly review and clean entity relationships
- Merge duplicate entities when identified
- Update entity descriptions as needed

## Troubleshooting

### Common Issues

#### Documents Not Processing
**Symptoms**: Documents stuck in "Processing" status

**Solutions**:
1. Check document format compatibility
2. Verify file size limits
3. Monitor system resources
4. Check error logs in document details

#### Slow Query Performance
**Symptoms**: Queries taking too long to respond

**Solutions**:
1. Reduce query complexity
2. Use simpler query modes (Naive vs. Global)
3. Decrease Max Tokens setting
4. Check system load

#### Graph Not Loading
**Symptoms**: Empty or broken graph visualization

**Solutions**:
1. Ensure documents are fully processed
2. Check browser compatibility
3. Clear browser cache
4. Reduce graph node limit

#### Login Issues
**Symptoms**: Cannot access the system

**Solutions**:
1. Verify correct URL
2. Check authentication settings
3. Clear browser cookies
4. Contact system administrator

### Performance Optimization

#### System Resources
- Monitor CPU and memory usage
- Ensure adequate disk space
- Check network connectivity to LLM services

#### Query Optimization
- Use appropriate query modes
- Set reasonable token limits
- Cache frequently used queries

#### Document Management
- Remove unnecessary documents
- Archive old documents
- Optimize document formats

### Getting Help

#### Built-in Help
- **Tooltips**: Hover over interface elements
- **Help Sections**: Click ? icons for context help
- **Status Messages**: Read system notifications

#### Documentation
- **API Documentation**: `/docs` endpoint
- **Configuration Guide**: System configuration options
- **Developer Guide**: For technical integration

#### Support Resources
- Check system health at `/health`
- Review processing logs
- Export system diagnostics

### Data Management

#### Backup and Export
- Regularly export your data
- Backup document collections
- Save important query results

#### Privacy and Security
- Review document sharing settings
- Monitor access logs
- Implement data retention policies

#### Migration
- Export data before system upgrades
- Test with sample data first
- Validate results after migration

---

## Quick Reference

### Keyboard Shortcuts
- **Ctrl/Cmd + /** : Open search
- **Ctrl/Cmd + Enter**: Submit query
- **Ctrl/Cmd + K**: Quick actions
- **ESC**: Close modals/dialogs

### Query Mode Quick Guide
- **Simple facts**: Naive mode
- **Document analysis**: Local mode
- **Comprehensive insights**: Global mode
- **General questions**: Hybrid mode

### Status Icons
- 🟢 Healthy/Ready
- 🟡 Processing/Warning
- 🔴 Error/Failed
- ⏳ Pending/Waiting

For technical support and advanced configuration, see the [Developer Guide](Developer_Guide.md) and [API Reference](API_Reference.md).