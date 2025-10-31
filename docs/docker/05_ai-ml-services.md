# AI/ML Enhanced Services

## Overview

Services leveraging artificial intelligence and machine learning capabilities.

## Google Gemini API Integration

### API Configuration
- **Provider**: Google Generative AI (Gemini)
- **Base URL**: `https://generativelanguage.googleapis.com/v1beta`
- **Authentication**: API key-based authentication

### Models in Use

| Model                      | Purpose                         | Services                           | Capabilities                               |
| -------------------------- | ------------------------------- | ---------------------------------- | ------------------------------------------ |
| **OpenAI GPT-4/GPT-3.5**   | General AI chat and assistance  | Lobe Chat                          | Text generation, code assistance, analysis |
| **Anthropic Claude**       | Advanced reasoning and analysis | Lobe Chat                          | Complex reasoning, document analysis       |
| **Google Gemini**          | Multi-modal AI interactions     | Lobe Chat, Karakeep, Paperless-GPT | Text, image, and document processing       |
| **Azure OpenAI**           | Enterprise AI services          | Lobe Chat                          | Scalable AI with enterprise features       |
| **gemini-2.5-flash-lite**  | Fast text processing            | Karakeep                           | Quick content analysis, tagging            |
| **gemini-2.5-flash-image** | Image analysis and OCR          | Karakeep, Paperless-GPT            | Image content extraction, OCR              |
| **gemini-1.5-pro**         | Advanced document understanding | Paperless-GPT                      | Complex document analysis                  |
| **gemini-1.5-pro-vision**  | Enhanced OCR capabilities       | Paperless-GPT                      | Superior OCR for scanned documents         |

## AI-Enhanced Services

### Lobe Chat - Multi-LLM AI Chat Interface
- **Purpose**: Modern AI chat interface supporting multiple LLM providers
- **Domain**: chat.alimunee.com
- **Database**: PostgreSQL with pgvector for embeddings
- **Authentication**: Zitadel SSO integration
- **Documentation**: [📖](../../services/lobe-chat/documentation.md)

#### AI Features
- **Multi-Provider Support**: OpenAI, Anthropic, Google, Azure, and more
- **Multi-Modal Conversations**: Text, image, and file interactions
- **Conversation Management**: Persistent chat history with AI embeddings
- **Plugin System**: Extensible functionality with community plugins
- **File Processing**: AI-powered document analysis and image understanding
- **Team Collaboration**: Share conversations and collaborate on AI tasks

### Karakeep - AI-Powered Bookmark Manager
- **Purpose**: Intelligent bookmark management with AI analysis
- **Domain**: keep.alimunee.com
- **Database**: PostgreSQL + Meilisearch
- **Documentation**: [📖](../../services/karakeep/documentation.md)

#### AI Features
- **Automatic Tagging**: Content-based tag generation using Gemini
- **Content Summarization**: AI-generated summaries of bookmarked content
- **Image Analysis**: OCR and content description for images
- **Semantic Search**: Meilisearch-powered intelligent search

### Paperless-GPT - AI Document Enhancement
- **Purpose**: AI enhancement for paperless-ngx document management
- **Domain**: aidocs.alimunee.com
- **Integration**: Enhances Paperless-ngx capabilities
- **Documentation**: [📖](../../services/paperless-gpt/documentation.md)

#### AI Features
- **Enhanced OCR**: Superior text extraction using Gemini Vision
- **Automatic Title Generation**: AI-generated document titles
- **Smart Tagging**: Automatic tag suggestions and assignment
- **Correspondent Detection**: Automatic sender/recipient identification

### Immich - GPU-Accelerated ML
- **Purpose**: Photo management with AI-powered features
- **Domain**: photos.alimunee.com
- **Hardware**: NVIDIA GTX 1070 with CUDA acceleration
- **Documentation**: [📖](../../services/immich/documentation.md)

#### AI Features
- **Face Recognition**: GPU-accelerated face detection and clustering
- **Object Classification**: Automatic object and scene recognition
- **Smart Search**: Natural language photo search
- **Duplicate Detection**: AI-powered duplicate photo identification

## GPU/AI Resource Management

### NVIDIA Configuration for AI
- **GPU**: NVIDIA GeForce GTX 1070 (8GB VRAM)
- **Driver**: NVIDIA 580.95.05 with CUDA 13.0
- **Container Toolkit**: nvidia-container-toolkit (latest)

### Resource Allocation
- **Primary GPU User**: Immich ML processing
- **Secondary Usage**: Jellyfin transcoding (when not doing ML)
- **Resource Monitoring**: Automatic load balancing between services

## Integration Patterns

### AI Service Configuration
```yaml
# Standard AI service configuration
networks:
  - proxy                 # Web interface access
  - [service]_internal    # Database and internal services
  - db_network           # Shared database access (if needed)

environment:
  - AI_PROVIDER=gemini
  - API_BASE_URL=https://generativelanguage.googleapis.com/v1beta
  - API_KEY=${GEMINI_API_KEY}
```

### Multi-LLM Chat Configuration (Lobe Chat)
```yaml
# Lobe Chat supports multiple AI providers simultaneously
environment:
  - OPENAI_API_KEY=${OPENAI_API_KEY}
  - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
  - GOOGLE_API_KEY=${GOOGLE_API_KEY}
  - AZURE_API_KEY=${AZURE_API_KEY}
  - AZURE_ENDPOINT=${AZURE_ENDPOINT}
  # Database with vector embeddings
  - DATABASE_URL=postgresql://user:pass@db:5432/lobe_chat
  # S3 storage for file uploads
  - S3_ENDPOINT=http://minio:9000
  - S3_BUCKET=lobe-chat
```

### Cross-Service AI Integration
- **Lobe Chat → PostgreSQL**: Conversation embeddings stored for semantic search
- **Lobe Chat → MinIO**: File uploads processed by AI for multi-modal conversations
- **Lobe Chat → Zitadel**: SSO integration for user management and access control
- **Karakeep → Meilisearch**: AI-generated content indexed for semantic search
- **Paperless-GPT → Paperless-ngx**: Enhanced documents fed back to main system
- **Immich ML → Photo Library**: AI analysis results stored with photos

---

*For detailedML service configuration, refer to individual service documentation and [troubleshooting.md](troubleshooting.md)*
