# {{ServiceName}} - {{One-line role}}

## Purpose
{{Two or three sentences: what it does, why it is here, what it replaced or
enables. Write for someone who has forgotten why they installed it.}}

## Configuration

### Environment Variables
| Variable | Description | Default | Required |
| -------- | ----------- | ------- | -------- |
| TZ       | Timezone    | Asia/Kuala_Lumpur | Yes |

### Ports
- **{{port}}**: {{what it serves}}

### Domains
- **External**: https://{{subdomain}}.alimunee.com
- **Internal**: http://{{container}}:{{port}}

## Dependencies
- **Networks**: proxy (Traefik routing){{, <name>_internal (database isolation)}}
- **Storage**: {{/storage/data/<service>/...}}
- **External Services**: {{Zitadel SSO, Postfix SMTP, or None}}

## Setup

### 1. Create Storage Directories
```bash
sudo mkdir -p /storage/data/{{service}}/config
sudo chown -R 1000:1000 /storage/data/{{service}}/
```

### 2. Deploy Service
```bash
cd /HOMELAB/services/{{service}}
docker compose up -d
```

### 3. Initial Configuration
1. Access https://{{subdomain}}.alimunee.com
2. {{Create the admin account / complete the setup wizard}}
3. {{Any settings that are not obvious from the UI}}

## Usage
{{The two or three things you will actually come back to look up. Not a feature
list copied from the vendor's homepage.}}

## Integration
{{How this connects to the rest of the homelab: SSO, notifications via ntfy,
shared storage, or which other services consume it. Omit if genuinely standalone.}}

## Troubleshooting

### Common Issues

#### {{Symptom someone would actually search for}}
```bash
docker logs {{container}}
```
{{What the fix is, and why the obvious first guess is wrong if it is.}}

### Health Check
```bash
docker compose ps
curl -f http://localhost:{{port}}/
```

## Backup

### Data to Backup
- **Configuration**: `/storage/data/{{service}}/config/`

### Restore Process
1. Stop the service: `docker compose down`
2. Restore the configuration directory
3. Start the service: `docker compose up -d`
4. Verify {{the thing that proves it actually came back}}
