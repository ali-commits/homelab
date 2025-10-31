# Karakeep

## Purpose
Karakeep is a self-hosted, AI-powered bookmark manr that allows you to save links, notes, images, and PDFs with automatic tagging and summarization. It features full-text search, OCR capabilities, browser extensions, and intelligent content organization using AI.

## Configuration

| Variable              | Description                               | Default                                          | Required |
| --------------------- | ----------------------------------------- | ------------------------------------------------ | -------- |
| KARAKEEP_VERSION      | Docker image version                      | release                                          | No       |
| DB_PASSWORD           | PostgreSQL database password              | -                                                | Yes      |
| NEXTAUTH_SECRET       | NextAuth.js secret for session encryption | -                                                | Yes      |
| MEILI_MASTER_KEY      | Meilisearch master key                    | -                                                | Yes      |
| OPENAI_BASE_URL       | Gemini API base URL                       | https://generativelanguage.googleapis.com/v1beta | Yes      |
| OPENAI_API_KEY        | Gemini API key for AI features            | -                                                | Yes      |
| INFERENCE_TEXT_MODEL  | Gemini model for text processing          | gemini-2.5-flash-lite                            | No       |
| INFERENCE_IMAGE_MODEL | Gemini model for image processing         | gemini-2.5-flash-image                           | No       |
| ZITADEL_CLIENT_ID     | Zitadel OAuth client ID                   | -                                                | Yes      |
| ZITADEL_CLIENT_SECRET | Zitadel OAuth client secret               | -                                                | Yes      |

### OAuth Configuration (Docker Compose)
| Variable                                    | Description                      | Default              | Required |
| ------------------------------------------- | -------------------------------- | -------------------- | -------- |
| OAUTH_WELLKNOWN_URL                         | Zitadel OIDC discovery endpoint  | -                    | Yes      |
| OAUTH_CLIENT_ID                             | References ZITADEL_CLIENT_ID     | -                    | Yes      |
| OAUTH_CLIENT_SECRET                         | References ZITADEL_CLIENT_SECRET | -                    | Yes      |
| OAUTH_PROVIDER_NAME                         | SSO provider display name        | Zitadel              | No       |
| OAUTH_SCOPE                                 | OAuth scopes                     | openid email profile | No       |
| OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING | Allow email account linking      | true                 | No       |

### Ports
- **3000**: Web interface (HTTPS via Traefik)

### Domains
- **External**: https://keep.alimunee.com
- **Internal**: http://karakeep:3000

## Dependencies
- **Database**: PostgreSQL 16 (karakeep-db)
- **Search**: Meilisearch v1.12.8 (karakeep-meilisearch)
- **AI**: Google Gemini API for automatic tagging and summarization
- **SSO**: Zitadel OIDC provider
- **Networks**: proxy, karakeep_internal, db_network
- **Storage**: /storage/data/karakeep/ (app data, database, search index)

## Setup

### 1. Configure Gemini API

1. **Gemini API Configuration**:
   - API key is configured in `.env` file
   - Base URL: `https://generativelanguage.googleapis.com/v1beta`
   - Current models: `gemini-2.5-flash-lite` (text) and `gemini-2.5-flash-image` (image)

2. **Alternative Gemini Models** (Optional):
   - `gemini-2.0-flash-exp` - Experimental model
   - `gemini-2.0-flash` - Standard Gemini model
   - `gemini-1.5-pro` - More capable but slower
   - `gemini-1.5-flash` - Faster alternative
   - Update `.env` if you want to use different models

### 2. Configure Zitadel OIDC Application

1. **Access Zitadel Console**:
   - Navigate to https://zitadel.alimunee.com
   - Login as administrator

2. **Create New Application**:
   - Go to Projects → Default Project → Applications
   - Click "New Application"
   - Name: "Karakeep"
   - Type: "Web Application"
   - Authentication Method: "PKCE"

3. **Configure Application Settings**:
   - **Redirect URIs**:
     - `https://keep.alimunee.com/api/auth/callback/custom`
   - **Post Logout Redirect URIs**:
     - `https://keep.alimunee.com`
   - **Scopes**: `openid`, `profile`, `email`

4. **Client Credentials**:
   - The Zitadel application is already configured with the correct credentials
   - Client ID and Secret are set in the `.env` file

### 3. Deploy the Service

```bash
cd services/karakeep
docker compose up -d
```

### 4. Initial Setup

1. **Access the application**: https://keep.alimunee.com
2. **Create admin account**: Use password authentication for initial setup
3. **Test SSO**: Click "Sign in with Zitadel" to verify SSO integration
4. **Configure settings**: Set up collections, tags, and AI preferences

### 5. Secure the System (Optional)

Once SSO is working and you have an admin account, you can disable password authentication:

```bash
# Update .env file
DISABLE_SIGNUPS=true
DISABLE_PASSWORD_AUTH=true

# Restart service
docker compose restart karakeep
```

## Usage

### Web Interface
- **URL**: https://keep.alimunee.com
- **Authentication**: Both password and Zitadel SSO available
- **Admin Access**: First user to register becomes admin

### Core Features

#### **AI-Powered Bookmarking**
- Automatic content summarization using OpenAI
- Intelligent tagging based on content analysis
- OCR for images and PDFs
- Smart content categorization
- Full-text search across all saved content

#### **Content Types**
- **Links**: Web pages with automatic archiving
- **Notes**: Rich text notes with AI enhancement
- **Images**: OCR text extraction and AI description
- **PDFs**: Full-text indexing and AI summarization
- **Screenshots**: Automatic capture and analysis

#### **Organization**
- **Collections**: AI-suggested groupings
- **Tags**: Automatic and manual tagging
- **Search**: Semantic search powered by Meilisearch
- **Filters**: Advanced filtering by content type, date, tags
- **Favorites**: Quick access to important items

#### **Browser Integration**
- Browser extension for quick saving
- Right-click context menu
- Automatic metadata extraction
- Bulk import from other bookmark managers

### API Access
- **REST API**: Available at https://keep.alimunee.com/api/
- **Authentication**: Bearer token authentication
- **MCP Integration**: Model Context Protocol support

## Integration

### SSO Configuration
- **Provider**: Zitadel OIDC via generic OAuth configuration
- **Authentication Flow**: Authorization Code with PKCE
- **User Mapping**: Email-based user identification
- **Key Insight**: Karakeep uses generic `OAUTH_*` variables, not Zitadel-specific ones
- **Callback URL**: `https://keep.alimunee.com/api/auth/callback/custom`
- **NEXTAUTH_URL**: Must be base domain (`https://keep.alimunee.com`), not `/api/auth`

### AI Features Configuration
- **Text Processing**: Uses OpenAI for summarization and tagging
- **Image Analysis**: OCR and content description
- **Smart Search**: Semantic search capabilities
- **Auto-categorization**: AI-powered content organization

### Browser Extensions
- Install Karakeep browser extension for quick bookmarking
- Automatic AI tagging and summarization
- Context-aware saving suggestions
- Bulk operations support

### Monitoring
- **Health Check**: HTTP endpoint at root path
- **Uptime Kuma**: Monitor https://keep.alimunee.com
- **ntfy Topic**: `homelab-alerts` for service issues

### Backup Integration
- **Database**: Included in PostgreSQL backup routines
- **Search Index**: Meilisearch data backup
- **Content**: Btrfs snapshots of /storage/data/karakeep/
- **Export**: Built-in export functionality

## Troubleshooting

### Common Issues

1. **SSO Login Problems**:
   ```bash
   # Check Zitadel OIDC discovery endpoint
   curl -s https://zitadel.alimunee.com/.well-known/openid_configuration | jq '.issuer'

   # Verify OAuth configuration
   docker exec karakeep env | grep -E "(OAUTH|ZITADEL)"

   # Check Zitadel application redirect URI
   # Ensure: https://keep.alimunee.com/api/auth/callback/custom
   ```

2. **AI Features Not Working**:
   ```bash
   # Check Gemini API configuration
   docker exec karakeep env | grep -E "(OPENAI_BASE_URL|OPENAI_API_KEY)"

   # Test Gemini API connectivity
   curl -H "x-goog-api-key: YOUR_GEMINI_API_KEY" \
        https://generativelanguage.googleapis.com/v1beta/models

   # Verify AI models are configured
   docker exec karakeep env | grep INFERENCE
   ```

3. **Database Connection Issues**:
   ```bash
   # Check database connectivity
   docker exec karakeep-db pg_isready -d karakeep -U karakeep

   # View database logs
   docker compose logs karakeep-db
   ```

4. **Search Not Working**:
   ```bash
   # Check Meilisearch status
   docker exec karakeep-meilisearch curl -f http://localhost:7700/health

   # View search logs
   docker compose logs karakeep-meilisearch
   ```

### Debug Commands
```bash
# View application logs
docker compose logs -f karakeep

# Check service status
docker compose ps

# Test database connection
docker exec karakeep-db psql -U karakeep -d karakeep -c "SELECT version();"

# Test Meilisearch
docker exec karakeep-meilisearch curl -s http://localhost:7700/health

# Check OAuth configuration
docker exec karakeep env | grep -E "(OAUTH|NEXTAUTH)"

# Check Gemini AI configuration
docker exec karakeep env | grep -E "(OPENAI|INFERENCE)"

# Test web interface
curl -f https://keep.alimunee.com/
```

### Common Configuration Issues

1. **Wrong Environment Variables**:
   - ❌ Using `ZITADEL_ISSUER` instead of `OAUTH_WELLKNOWN_URL`
   - ✅ Use generic `OAUTH_*` variables for Karakeep

2. **Incorrect NEXTAUTH_URL**:
   - ❌ `https://keep.alimunee.com/api/auth`
   - ✅ `https://keep.alimunee.com` (base domain only)

3. **Wrong Callback URL in Zitadel**:
   - ❌ `https://keep.alimunee.com/api/auth/callback/oauth`
   - ✅ `https://keep.alimunee.com/api/auth/callback/custom`

4. **Missing OAuth Settings**:
   - Ensure `OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING=true`
   - Verify `OAUTH_SCOPE=openid email profile`

### Performance Optimization
```bash
# Monitor resource usage
docker stats karakeep karakeep-db karakeep-meilisearch

# Check storage usage
du -sh /storage/data/karakeep/

# Monitor AI API usage
# Check Google AI Studio dashboard for usage statistics
```

## Backup

### Database Backup
```bash
# Backup database
docker exec karakeep-db pg_dump -U karakeep karakeep > karakeep-db-$(date +%Y%m%d).sql

# Restore database
docker exec -i karakeep-db psql -U karakeep karakeep < karakeep-db-YYYYMMDD.sql
```

### Search Index Backup
```bash
# Backup Meilisearch data
sudo tar -czf karakeep-meili-$(date +%Y%m%d).tar.gz -C /storage/data/karakeep meili_data/

# Restore search index (stop service first)
docker compose stop meilisearch
sudo tar -xzf karakeep-meili-YYYYMMDD.tar.gz -C /storage/data/karakeep/
docker compose start meilisearch
```

### Content Backup
```bash
# Backup all content and data
sudo tar -czf karakeep-data-$(date +%Y%m%d).tar.gz -C /storage/data karakeep/

# Export bookmarks (via web interface)
# Go to Settings → Export → Download backup
```

### Full Backup
```bash
# Complete backup including configuration
sudo tar -czf karakeep-full-$(date +%Y%m%d).tar.gz \
  -C /storage/data karakeep/ \
  -C /HOMELAB/services karakeep/
```

### Recovery Steps
1. Restore database from backup
2. Restore search index and content files
3. Restart all services
4. Verify SSO authentication
5. Test AI features and search functionality
6. Rebuild search index if necessary

## Security Considerations

### Authentication Security
- **SSO Only**: Password authentication disabled, Zitadel required
- **No Signups**: Registration disabled, admin-controlled access
- **Session Management**: Secure session handling via NextAuth.js
- **HTTPS Only**: All communication encrypted via Traefik

### API Security
- **Gemini**: API key stored securely in environment variables
- **Rate Limiting**: Built-in API rate limiting
- **Token Authentication**: Secure API token management
- **Network Isolation**: Internal networks for service communication

### Data Privacy
- **Self-Hosted**: All bookmarks and AI processing logs stored locally
- **Content Isolation**: User content stored in isolated directories
- **Database Encryption**: PostgreSQL with encrypted connections
- **AI Privacy**: Consider data sent to Google Gemini for processing

### Access Control
- **User-Based**: Each user sees only their content
- **Collection Sharing**: Granular sharing permissions
- **API Security**: Token-based API authentication
- **Audit Logging**: User activity and AI usage tracking

## Use Cases

### Personal Knowledge Management
- Research bookmark collection with AI summarization
- Automatic content categorization and tagging
- Intelligent search across all saved content
- Long-term knowledge preservation

### Content Curation
- AI-powered content discovery and organization
- Automatic duplicate detection
- Smart content recommendations
- Bulk content processing and analysis

### Research and Documentation
- Academic research bookmark management
- Automatic citation and reference extraction
- Content analysis and summarization
- Cross-reference discovery

### Team Collaboration
- Shared knowledge bases with AI enhancement
- Collaborative content curation
- Intelligent content recommendations
- Team knowledge discovery

## AI Features Deep Dive

### Automatic Tagging
- Content analysis using Google Gemini models
- Context-aware tag suggestions
- Bulk tagging operations
- Custom tag training

### Content Summarization
- Automatic article summarization
- Key point extraction
- Multi-language support
- Customizable summary length

### Image Processing
- OCR text extraction from images
- Image content description
- Visual similarity detection
- Automatic image categorization

### Search Enhancement
- Semantic search capabilities
- Natural language queries
- Content similarity matching
- AI-powered search suggestions

### Smart Organization
- Automatic collection suggestions
- Content relationship discovery
- Duplicate content detection
- Intelligent archiving recommendations
