# Productivity & Collaboration Services

## Overview

Work-focused services for productivity, document management, collaboration, and workflow automation.

## Cloud Storage & Synchronization

### Core Services

- **OpenCloud** - Primary cloud storage & file sharing with OnlyOffice collaboration ([📖](../../services/opencloud/documentation.md))
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

- **OpenCloud + OnlyOffice** - Dedicated OnlyOffice instance for OpenCloud at `onlyoffice.alimunee.com` (bundled in OpenCloud stack)

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

## Storage Architecture

### Data Storage Locations
```
/storage/
├── data/                   → Service configurations and databases
│   ├── opencloud/         → OpenCloud config & user data
│   ├── paperless-ngx/     → Document storage
│   └── syncthing/         → Synchronized files
└── shared/                → Cross-service shared data
```

## Integration Patterns

### SSO Integration

Services with Zitadel SSO support:

- **OpenCloud**: OIDC PKCE flow, auto-provisioning from Zitadel claims
- **Linkwarden**: Native Zitadel SSO integration

### Email Integration

Services using SMTP relay:

- **Paperless-ngx**: Document processing notifications
- **Stirling PDF**: Email delivery of processed PDFs

### Cross-Service Integration

#### OpenCloud + OnlyOffice

- **Document Editing**: In-browser editing via dedicated OnlyOffice at `onlyoffice.alimunee.com`
- **WOPI Protocol**: Collaboration bridge connects OpenCloud to OnlyOffice

#### Paperless-ngx + Paperless-GPT

- **AI Enhancement**: Improved OCR and metadata extraction
- **Automatic Tagging**: AI-powered document categorization

#### N8N Workflow Integrations

- **Paperless-ngx**: Document processing automation

---

*For detailed service configuration, refer to individual service documentation and [troubleshooting.md](troubleshooting.md)*
