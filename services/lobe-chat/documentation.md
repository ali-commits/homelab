# Lobe Chat

## Purpose

Lobe Chat is an open-source, modern ChatGPT/LLM UI framework that provides a comprehensive AI chat interface. It supports multiple AI providers (OpenAI, Anthropic, Google, Azure), multi-modal conversations, plugin system, and advanced features like conversation management, file uploads, and team collaboration. This deployment includes server-side database storage for persistent conversations and user management.

## Configuration

### Environment Variables

| Variable                       | Description                               | Default                              | Required |
| ------------------------------ | ----------------------------------------- | ------------------------------------ | -------- |
| `NEXT_PUBLIC_SERVICE_MODE`     | Service mode (server/client)              | `server`                             | Yes      |
| `APP_URL`                      | Application URL                           | `https://chat.alimunee.com`          | Yes      |
| `DATABASE_DRIVER`              | Database driver type                      | `node`                               | Yes      |
| `DB_PASSWORD`                  | PostgreSQL database password              | -                                    | Yes      |
| `DATABASE_URL`                 | PostgreSQL connection string              | -                                    | Yes      |
| `KEY_VAULTS_SECRET`            | Encryption key for sensitive data storage | -                                    | Yes      |
| `NEXT_AUTH_SECRET`             | NextAuth.js secret for session encryption | -                                    | Yes      |
| `NEXT_PUBLIC_ENABLE_NEXT_AUTH` | Enable NextAuth authentication            | `1`                                  | Yes      |
| `NEXT_AUTH_SSO_PROVIDERS`      | SSO provider name                         | `zitadel`                            | Yes      |
| `NEXTAUTH_URL`                 | NextAuth callback base URL                | `https://chat.alimunee.com/api/auth` | Yes      |
| `AUTH_ZITADEL_ID`              | Zitadel OAuth client ID                   | -                                    | Yes      |
| `AUTH_ZITADEL_SECRET`          | Zitadel OAuth client secret               | -                                    | Yes      |
| `AUTH_ZITADEL_ISSUER`          | Zitadel issuer URL                        | `https://zitadel.alimunee.com`       | Yes      |
| `MINIO_ROOT_USER`              | MinIO root username                       | -                                    | Yes      |
| `MINIO_ROOT_PASSWORD`          | MinIO root password                       | -                                    | Yes      |
| `S3_ACCESS_KEY_ID`             | S3/MinIO access key for file storage      | -                                    | Yes      |
| `S3_SECRET_ACCESS_KEY`         | S3/MinIO secret key                       | -                                    | Yes      |
| `S3_ENDPOINT`                  | S3/MinIO endpoint URL                     | `http://lobe-chat-minio:9000`        | Yes      |
| `S3_BUCKET`                    | S3 bucket name for file storage           | `lobe-chat`                          | Yes      |
| `S3_PUBLIC_DOMAIN`             | Public domain for S3 file access          | `https://minio-lobe.alimunee.com`    | Yes      |
| `S3_ENABLE_PATH_STYLE`         | Enable S3 path-style URLs                 | `1`                                  | Yes      |
| `OPENAI_API_KEY`               | OpenAI API key                            | -                                    | No       |
| `OPENAI_PROXY_URL`             | OpenAI API proxy URL                      | -                                    | No       |
| `ANTHROPIC_API_KEY`            | Anthropic Claude API key                  | -                                    | No       |
| `GOOGLE_API_KEY`               | Google Gemini API key                     | -                                    | No       |
| `AZURE_API_KEY`                | Azure OpenAI API key                      | -                                    | No       |
| `AZURE_ENDPOINT`               | Azure OpenAI endpoint                     | -                                    | No       |

### Ports and Domains

- **Lobe Chat**: 3210 (internal) → https://chat.alimunee.com
- **PostgreSQL**: 5432 (internal only)
- **MinIO API**: 9000 (internal) → https://minio-lobe.alimunee.com
- **MinIO Console**: 9001 (internal) → https://minio-console-lobe.alimunee.com

## Dependencies

### Required Services
- **PostgreSQL with pgvector**: Stores user data, conversations, and AI embeddings
- **Zitadel**: SSO authentication provider
- **MinIO**: S3-compatible file storage for uploads and attachments
- **Traefik**: Reverse proxy for external access

### Required Networks
- `proxy`: External access via Traefik
- `lobe_chat_internal`: Internal communication between services
- `db_network`: Database connectivity

### Required Docker Images
- **Lobe Chat**: `lobehub/lobe-chat-database:latest`
- **PostgreSQL**: `pgvector/pgvector:pg16` (includes vector extension)
- **MinIO**: `minio/minio:latest`

## Setup

### 1. Generate Secure Keys

```bash
# Generate database password
openssl rand -base64 32

# Generate KEY_VAULTS_SECRET (32-byte base64)
openssl rand -base64 32

# Generate NEXT_AUTH_SECRET
openssl rand -base64 32
```

### 2. Configure Zitadel Application

1. Access Zitadel admin console: https://zitadel.alimunee.com
2. Create new application:
   - **Name**: Lobe Chat
   - **Type**: Web Application
   - **Authentication Method**: Client Secret Basic/Post
   - **Grant Types**: Authorization Code
3. Configure redirect URIs:
   - **Redirect URI**: `https://chat.alimunee.com/api/auth/callback/zitadel`
   - **Post Logout URI**: `https://chat.alimunee.com`
   - **Allowed Origins**: `https://chat.alimunee.com`
4. Configure scopes:
   - ✅ `openid` (required)
   - ✅ `profile` (required)
   - ✅ `email` (required)
   - ✅ `offline_access` (for refresh tokens)
5. Note the Client ID and Client Secret

### 3. Configure MinIO Storage

MinIO is deployed as part of the service stack and automatically configured:
- **Bucket Name**: `lobe-chat` (created automatically)
- **Access Policy**: Public read access for uploaded files
- **Internal Endpoint**: `http://lobe-chat-minio:9000`
- **External Access**: https://minio-lobe.alimunee.com (API) and https://minio-console-lobe.alimunee.com (Console)

### 4. Update Environment Variables

Edit `.env` file with generated values:

```bash
# Service Configuration
NEXT_PUBLIC_SERVICE_MODE=server
APP_URL=https://chat.alimunee.com
DATABASE_DRIVER=node

# Database Configuration
DB_PASSWORD=<generated-password>
DATABASE_URL=postgresql://lobe_chat:<url-encoded-password>@lobe-chat-db:5432/lobe_chat

# Authentication Configuration
KEY_VAULTS_SECRET=<generated-key>
NEXT_AUTH_SECRET=<generated-secret>

# NextAuth Configuration
NEXT_PUBLIC_ENABLE_NEXT_AUTH=1
NEXT_AUTH_SSO_PROVIDERS=zitadel
NEXTAUTH_URL=https://chat.alimunee.com/api/auth

# Zitadel SSO Configuration
AUTH_ZITADEL_ID=<from-zitadel>
AUTH_ZITADEL_SECRET=<from-zitadel>
AUTH_ZITADEL_ISSUER=https://zitadel.alimunee.com

# MinIO Configuration
MINIO_ROOT_USER=<generated-username>
MINIO_ROOT_PASSWORD=<generated-password>

# S3 Storage Configuration (MinIO)
S3_ACCESS_KEY_ID=<generated-access-key>
S3_SECRET_ACCESS_KEY=<generated-secret-key>
S3_ENDPOINT=http://lobe-chat-minio:9000
S3_BUCKET=lobe-chat
S3_PUBLIC_DOMAIN=https://minio-lobe.alimunee.com
S3_ENABLE_PATH_STYLE=1

# OpenAI Configuration (optional)
OPENAI_API_KEY=sk-...
OPENAI_PROXY_URL=

# Optional: Additional AI Providers
# ANTHROPIC_API_KEY=
# GOOGLE_API_KEY=
# AZURE_API_KEY=
# AZURE_ENDPOINT=
```

### 5. Deploy Service

```bash
cd services/lobe-chat
docker compose up -d
```

### 6. Verify Deployment

```bash
# Check container status
docker compose ps

# Check logs for successful database migration
docker compose logs lobe-chat | grep -E "(migration|Ready)"

# Test database connectivity with vector extension
docker exec lobe_chat_db psql -U lobe_chat -d lobe_chat -c "SELECT version(); SELECT * FROM pg_extension WHERE extname='vector';"

# Test MinIO bucket setup
docker exec lobe_chat_minio mc ls local/lobe-chat

# Test web interface
curl -I https://chat.alimunee.com
```

## Usage

### Access Points

- **Web Interface**: https://chat.alimunee.com
- **Admin Panel**: Available through web interface after login
- **API Endpoints**: https://chat.alimunee.com/api/*

### Initial Setup

1. Navigate to https://chat.alimunee.com
2. You'll be redirected to Zitadel for authentication
3. Log in with your Zitadel credentials
4. After successful authentication, you'll be redirected back to Lobe Chat
5. Configure AI providers in settings:
   - Add OpenAI API key for GPT models
   - Add Anthropic API key for Claude models
   - Configure other providers as needed
6. Start chatting with AI models
7. Upload files and images for multi-modal conversations

### Key Features

- **Multi-Provider Support**: OpenAI, Anthropic, Google, Azure, and more
- **Conversation Management**: Persistent chat history and organization
- **File Uploads**: Support for images, documents, and other files
- **Plugin System**: Extensible functionality with community plugins
- **Team Collaboration**: Share conversations and collaborate
- **Multi-Modal**: Text, image, and voice interactions
- **Custom Models**: Support for local and custom AI models

## Integration

### SSO Integration

Lobe Chat integrates with Zitadel for single sign-on:

- **Authentication Flow**: OAuth 2.0 / OpenID Connect
- **User Management**: Automatic user creation on first login
- **Session Management**: Secure session handling via NextAuth.js
- **Role-Based Access**: Supports Zitadel role assignments

### File Storage Integration

Files are stored in S3/MinIO with automatic management:

- **Upload Handling**: Direct uploads to S3 bucket
- **File Processing**: Automatic image optimization and processing
- **Access Control**: Secure file access with signed URLs
- **Cleanup**: Automatic cleanup of unused files

### Monitoring Integration

Add to Uptime Kuma monitoring:

```bash
# Health check endpoint
https://chat.alimunee.com/api/health

# Expected response: 200 OK
```

## Troubleshooting

### Common Issues

#### 1. Authentication Failures

**Problem**: Users cannot log in via Zitadel SSO

**Solutions**:
```bash
# Check Zitadel configuration
curl -f https://zitadel.alimunee.com/.well-known/openid-configuration

# Verify environment variables
docker exec lobe_chat env | grep -E "(ZITADEL|AUTH)"

# Check redirect URI configuration in Zitadel
```

#### 2. Database Migration Issues

**Problem**: Service fails to start with "vector extension not available" error

**Solutions**:
```bash
# Ensure using pgvector image
grep "image.*postgres" docker-compose.yml
# Should show: pgvector/pgvector:pg16

# Check vector extension installation
docker exec lobe_chat_db psql -U lobe_chat -d lobe_chat -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Check database logs for migration status
docker compose logs lobe-chat | grep -E "(migration|vector)"

# Reset database if needed
docker compose down
sudo rm -rf /storage/data/lobe-chat/db/*
docker compose up -d
```

#### 3. File Upload Failures

**Problem**: File uploads fail or files are not accessible

**Solutions**:
```bash
# Test MinIO connectivity
docker exec lobe_chat curl -f http://lobe-chat-minio:9000/minio/health/live

# Check MinIO bucket setup
docker exec lobe_chat_minio mc ls local/lobe-chat

# Verify bucket permissions
docker exec lobe_chat_minio mc anonymous get local/lobe-chat

# Test external MinIO access
curl -I https://minio-lobe.alimunee.com

# Recreate bucket if needed
docker exec lobe_chat_minio mc rb local/lobe-chat --force
docker exec lobe_chat_minio mc mb local/lobe-chat
docker exec lobe_chat_minio mc anonymous set public local/lobe-chat
```

#### 4. Health Check Failures

**Problem**: Container shows unhealthy status

**Solutions**:
```bash
# Test health endpoint directly
docker exec lobe_chat curl -f http://localhost:3210/api/health

# If 404, remove health check temporarily
# Check application logs for startup issues
docker compose logs lobe-chat
```

### Debug Commands

```bash
# Check all container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"

# View application logs
docker compose logs -f lobe-chat

# Check database connectivity
docker exec lobe_chat_db psql -U lobe_chat -d lobe_chat -c "SELECT version();"

# Test Traefik routing
curl -H "Host: chat.alimunee.com" http://localhost/api/health

# Check environment variables
docker exec lobe_chat env | grep -v PASSWORD | grep -v SECRET
```

### Performance Optimization

```bash
# Monitor resource usage
docker stats lobe_chat lobe_chat_db

# Check database performance
docker exec lobe_chat_db psql -U lobe_chat -d lobe_chat -c "
  SELECT schemaname,tablename,attname,n_distinct,correlation
  FROM pg_stats WHERE tablename NOT LIKE 'pg_%';"

# Optimize database if needed
docker exec lobe_chat_db psql -U lobe_chat -d lobe_chat -c "VACUUM ANALYZE;"
```

## Backup

### Database Backup

```bash
# Create database backup
docker exec lobe_chat_db pg_dump -U lobe_chat -d lobe_chat > lobe_chat_backup_$(date +%Y%m%d).sql

# Automated backup script
#!/bin/bash
BACKUP_DIR="/storage/backups/lobe-chat"
mkdir -p $BACKUP_DIR
docker exec lobe_chat_db pg_dump -U lobe_chat -d lobe_chat | gzip > $BACKUP_DIR/lobe_chat_$(date +%Y%m%d_%H%M%S).sql.gz

# Keep only last 7 days of backups
find $BACKUP_DIR -name "lobe_chat_*.sql.gz" -mtime +7 -delete
```

### File Storage Backup

```bash
# S3/MinIO files are backed up through MinIO's backup system
# Ensure S3 bucket has versioning enabled for file recovery
```

### Configuration Backup

```bash
# Backup service configuration
cp -r /storage/data/lobe-chat /storage/backups/lobe-chat-config-$(date +%Y%m%d)

# Backup environment variables (excluding secrets)
grep -v -E "(PASSWORD|SECRET|KEY)" services/lobe-chat/.env > lobe-chat-config.env
```

### Restore Procedures

```bash
# Restore database from backup
docker exec -i lobe_chat_db psql -U lobe_chat -d lobe_chat < lobe_chat_backup.sql

# Restore from compressed backup
gunzip -c lobe_chat_backup.sql.gz | docker exec -i lobe_chat_db psql -U lobe_chat -d lobe_chat

# Restore configuration
docker compose down
cp -r /storage/backups/lobe-chat-config-YYYYMMDD/* /storage/data/lobe-chat/
docker compose up -d
```
