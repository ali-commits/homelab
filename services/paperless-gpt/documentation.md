# Paperless-GPT Documentation

## Purpose
Paperless-GPT is an AI-pred enhancement for paperless-ngx that provides:
- **LLM-Enhanced OCR**: Uses Google Gemini for superior text extraction from scanned documents
- **Automatic Title Generation**: AI-generated document titles based on content
- **Smart Tagging**: Automatic tag suggestions and assignment
- **Correspondent Detection**: Automatic identification of document senders/recipients
- **Custom Field Population**: Extract and populate custom metadata fields
- **Searchable PDFs**: Generate PDFs with transparent text layers for better searchability

## Configuration

### Environment Variables

| Variable             | Description                           | Default                   | Required |
| -------------------- | ------------------------------------- | ------------------------- | -------- |
| PAPERLESS_BASE_URL   | Internal URL to paperless-ngx         | http://paperless-ngx:8000 | Yes      |
| PAPERLESS_API_TOKEN  | API token from paperless-ngx          | -                         | Yes      |
| PAPERLESS_PUBLIC_URL | External URL to paperless-ngx         | https://docs.alimunee.com | No       |
| GEMINI_API_KEY       | Google Gemini API key                 | -                         | Yes      |
| LLM_PROVIDER         | LLM provider (openai for Gemini)      | openai                    | Yes      |
| LLM_MODEL            | Gemini model to use                   | gemini-1.5-pro            | Yes      |
| VISION_LLM_MODEL     | Gemini vision model for OCR           | gemini-1.5-pro-vision     | Yes      |
| OCR_PROVIDER         | OCR provider (llm for Gemini)         | llm                       | Yes      |
| OCR_PROCESS_MODE     | OCR processing mode                   | image                     | No       |
| OCR_LIMIT_PAGES      | Max pages to OCR (0 = no limit)       | 10                        | No       |
| MANUAL_TAG           | Tag for manual processing             | paperless-gpt             | No       |
| AUTO_TAG             | Tag for auto processing               | paperless-gpt-auto        | No       |
| PDF_UPLOAD           | Upload enhanced PDFs to paperless-ngx | true                      | No       |
| LOG_LEVEL            | Logging level                         | info                      | No       |

### Access Information
- **Web Interface**: https://aidocs.alimunee.com
- **Internal Port**: 8080
- **Paperless-ngx Integration**: Connects to existing paperless-ngx instance

## Dependencies

### Required Services
- **paperless-ngx**: Main document management system
- **paperless_internal network**: For communication with paperless-ngx
- **proxy network**: For Traefik routing

### External Dependencies
- **Google Gemini API**: For AI processing and OCR
- **Internet Access**: Required for Gemini API calls

## Setup

### 1. Generate Paperless-ngx API Token
1. Access paperless-ngx at https://docs.alimunee.com
2. Go to Settings > API Tokens
3. Create a new token with appropriate permissions
4. Update the `PAPERLESS_API_TOKEN` in `.env` file

### 2. Configure Gemini API
The Gemini API key is already configured in the `.env` file. Ensure you have:
- Valid Google Cloud Project with Generative AI API enabled
- Sufficient API quota for your document processing needs

### 3. Create Required Directories
```bash
sudo mkdir -p /storage/data/paperless-gpt/{prompts,pdf}
sudo chown -R 1000:1000 /storage/data/paperless-gpt/
```

### 4. Deploy the Service
```bash
cd services/paperless-gpt
docker compose up -d
```

### 5. Verify Deployment
```bash
# Check container status
docker compose ps

# Check logs
docker compose logs -f paperless-gpt

# Test web interface
curl -I https://aidocs.alimunee.com
```

## Usage

### Manual Document Processing
1. Access the web interface at https://aidocs.alimunee.com
2. Select documents from your paperless-ngx library
3. Review AI-generated suggestions for titles, tags, and metadata
4. Approve or modify suggestions before applying

### Automatic Processing
1. Tag documents in paperless-ngx with `paperless-gpt-auto`
2. Paperless-GPT will automatically process these documents
3. Check the results in the web interface or paperless-ngx

### OCR Enhancement
- Documents tagged with `paperless-gpt-ocr-auto` will undergo enhanced OCR
- Original documents are preserved; enhanced versions are uploaded separately
- Enhanced PDFs include searchable text layers positioned over original content

### Custom Prompts
- Custom prompts can be configured via the web interface
- Prompts are stored in `/storage/data/paperless-gpt/prompts/`
- Modify prompts to suit your specific document types and requirements

## Integration

### Paperless-ngx Integration
- **API Connection**: Uses paperless-ngx REST API for document access
- **Tag-based Processing**: Uses tags to identify documents for processing
- **Metadata Updates**: Updates document titles, tags, correspondents, and custom fields
- **PDF Enhancement**: Uploads improved PDFs back to paperless-ngx

### Gemini API Integration
- **Text Analysis**: Uses Gemini for content understanding and metadata extraction
- **Vision OCR**: Uses Gemini Vision for superior OCR on scanned documents
- **Multi-language Support**: Supports multiple languages through Gemini's capabilities

### Monitoring Integration
- **Health Checks**: HTTP health endpoint for monitoring
- **Logging**: Configurable log levels for troubleshooting
- **Watchtower**: Automatic container updates enabled

## Troubleshooting

### Common Issues

#### API Token Issues
```bash
# Test API token
curl -H "Authorization: Token your_token_here" https://docs.alimunee.com/api/documents/

# Check paperless-gpt logs for authentication errors
docker compose logs paperless-gpt | grep -i auth
```

#### Gemini API Issues
```bash
# Check API quota and billing in Google Cloud Console
# Verify API key permissions and project configuration

# Test Gemini API directly
curl -H "Authorization: Bearer $GEMINI_API_KEY" \
  "https://generativelanguage.googleapis.com/v1beta/models"
```

#### Network Connectivity
```bash
# Test paperless-ngx connectivity from paperless-gpt container
docker exec paperless-gpt curl -f http://paperless-ngx:8000/api/

# Check network configuration
docker network inspect paperless_internal
```

#### Processing Issues
```bash
# Check processing logs
docker compose logs paperless-gpt | grep -i process

# Verify document tags in paperless-ngx
# Ensure documents have correct tags for processing
```

### Performance Optimization
- **OCR Limits**: Adjust `OCR_LIMIT_PAGES` based on document sizes and API costs
- **Batch Processing**: Process documents in batches to manage API rate limits
- **Model Selection**: Use appropriate Gemini models based on accuracy vs. cost requirements

## Backup

### Data to Backup
- **Prompts**: `/storage/data/paperless-gpt/prompts/` - Custom prompt configurations
- **Enhanced PDFs**: `/storage/data/paperless-gpt/pdf/` - Locally saved enhanced PDFs
- **Configuration**: `.env` file and `docker-compose.yml`

### Backup Commands
```bash
# Backup prompts and configuration
tar -czf paperless-gpt-backup-$(date +%Y%m%d).tar.gz \
  /storage/data/paperless-gpt/prompts/ \
  services/paperless-gpt/.env \
  services/paperless-gpt/docker-compose.yml

# Backup enhanced PDFs (if CREATE_LOCAL_PDF is enabled)
tar -czf paperless-gpt-pdfs-$(date +%Y%m%d).tar.gz \
  /storage/data/paperless-gpt/pdf/
```

### Restore Procedure
1. Stop the service: `docker compose down`
2. Restore backed up files to their original locations
3. Verify file permissions: `sudo chown -R 1000:1000 /storage/data/paperless-gpt/`
4. Start the service: `docker compose up -d`
5. Verify functionality through the web interface

## Security Considerations
- **API Keys**: Gemini API key is stored in environment file - ensure proper file permissions
- **Network Isolation**: Service communicates only with paperless-ngx and external Gemini API
- **Data Privacy**: Documents are sent to Google's Gemini API for processing - ensure compliance with data policies
- **Access Control**: Web interface should be secured through Traefik and authentication if needed
