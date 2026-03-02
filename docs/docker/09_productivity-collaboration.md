# Productivity & Collaboration Services

## Overview

Work-focused services for productivity, document management, collaboration, and workflow automation.

## Cloud Storage & Synchronization

### Core Services
- **Nextcloud** - Personal cloud & file sharing ([📖](../../services/nextcloud/documentation.md))
- **Syncthing** - Decentralized file synchronization ([📖](../../services/syncthing/documentation.md))

## Document Management

### Document Processing
- **Paperless-ngx** - Document management with OCR ([📖](../../services/paperless-ngx/documentation.md))
- **Stirling PDF** - PDF manipulation & processing tools ([📖](../../services/stirling-pdf/documentation.md))
- **Vert.sh** - WebAssembly file converter supporting 250+ formats ([📖](../../services/vert/documentation.md))

## Knowledge Management

### Information Organization
- **AFFiNE** - Knowledge base (Notion alternative) ([📖](../../services/affine/documentation.md))
- **Linkwarden** - Bookmark & link manager ([📖](../../services/linkwarden/documentation.md))

## Office & Collaboration

### Document Editing
- **OnlyOffice** - Document editing & collaboration ([📖](../../services/onlyoffice/documentation.md))

## Workflow Automation

### Automation Platform
- **N8N** - Workflow automation platform ([📖](../../services/n8n/documentation.md))

## Development Tools

### Developer Utilities
- **IT-Tools** - Developer utilities & online tools ([📖](../../services/it-tools/documentation.md))

## Visual Design & Diagramming

### Whiteboard & Diagrams
- **Excalidraw** - Virtual whiteboard & diagramming tool ([📖](../../services/excalidraw/documentation.md))

### Database Design Tools
- **ChartDB** - Database schema design & visualization with AI features ([📖](../../services/chartdb/documentation.md))
- **DrawDB** - Database diagram editor & SQL generator ([📖](../../services/drawdb/documentation.md))

## Financial Management

### Personal Finance
- **Firefly III** - Personal finance & budget management ([📖](../../services/firefly-iii/documentation.md))

## Storage Architecture

### Data Storage Locations
```
/storage/
├── data/                   → Service configurations and databases
├── nextcloud/             → Nextcloud user files
├── paperless-ngx/         → Document storage
├── syncthing/             → Synchronized files
└── shared/                → Cross-service shared data
```

## Integration Patterns

### SSO Integration
Services with Zitadel SSO support:
- **Nextcloud**: OIDC app integration
- **Paperless-ngx**: OIDC configuration available
- **N8N**: Built-in OIDC support
- **Firefly III**: OAuth integration

### Email Integration
Services using SMTP relay:
- **Nextcloud**: Sharing notifications, user management
- **Paperless-ngx**: Document processing notifications
- **Firefly III**: Budget alerts, transaction notifications
- **N8N**: Workflow notifications and alerts

### Cross-Service Integration

#### Nextcloud + OnlyOffice
- **Document Editing**: Seamless in-browser document editing
- **Real-time Collaboration**: Multiple users editing simultaneously

#### Paperless-ngx + Paperless-GPT
- **AI Enhancement**: Improved OCR and metadata extraction
- **Automatic Tagging**: AI-powered document categorization

#### N8N Workflow Integrations
- **Nextcloud**: File monitoring and processing workflows
- **Paperless-ngx**: Document processing automation
- **Firefly III**: Financial data import and processing

---

*For detailed service configuration, refer to individual service documentation and [troubleshooting.md](troubleshooting.md)*
