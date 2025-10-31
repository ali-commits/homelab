# Excalidraw

## Purpose
Excalidraw is a virtual whiteboard tool for sketching h like diagrams, wireframes, and collaborative drawings. It provides an intuitive interface for creating flowcharts, system diagrams, mockups, and visual brainstorming sessions.

## Configuration

| Variable | Description      | Default          | Required |
| -------- | ---------------- | ---------------- | -------- |
| TZ       | Timezone setting | America/New_York | No       |

### Ports
- **Internal**: 80 (HTTP)
- **External**: Accessed via Traefik reverse proxy

### Domains
- **Primary**: https://draw.alimunee.com

## Dependencies
- **Networks**: proxy (for Traefik routing)
- **External Services**: None (standalone application)

## Setup

1. **Deploy the service**:
   ```bash
   cd services/excalidraw
   docker compose up -d
   ```

2. **Verify deployment**:
   ```bash
   docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"
   docker compose logs -f
   ```

3. **Test connectivity**:
   ```bash
   curl -f http://localhost/
   ```

## Usage

### Web Interface
- **URL**: https://draw.alimunee.com
- **Features**:
  - Hand-drawn style diagrams
  - Real-time collaboration
  - Export to PNG, SVG, or Excalidraw format
  - Import images and SVG files
  - Extensive shape and text tools
  - Dark/light theme support

### Key Features
- **Drawing Tools**: Rectangles, circles, arrows, lines, text, and freehand drawing
- **Collaboration**: Real-time multiplayer editing with shareable links
- **Export Options**: PNG, SVG, clipboard copy, or native .excalidraw format
- **Import Support**: Images, SVG files, and Excalidraw files
- **Libraries**: Access to shape libraries and custom element creation

## Integration

### No Authentication Required
Excalidraw runs as a client-side application with no user accounts or authentication system.

### Sharing and Collaboration
- Drawings are stored locally in browser storage
- Collaboration links can be shared for real-time editing
- No server-side storage of drawings (privacy-focused)

### Backup Considerations
Since Excalidraw stores data client-side:
- Users should regularly export important drawings
- No server-side backup is needed
- Consider documenting export procedures for users

## Troubleshooting

### Service Won't Start
```bash
# Check container logs
docker compose logs excalidraw

# Verify image availability
docker pull excalidraw/excalidraw:latest

# Check network connectivity
docker network ls | grep proxy
```

### 404 Errors
```bash
# Test direct container access
docker exec excalidraw curl -f http://localhost:80

# Check Traefik routing
docker logs traefik | grep excalidraw

# Verify health check
docker inspect excalidraw | grep -A 10 Health
```

### Performance Issues
```bash
# Monitor resource usage
docker stats excalidraw

# Check memory limits
docker inspect excalidraw | grep -A 5 Memory
```

## Backup

### No Server-Side Data
Excalidraw is a client-side application that stores drawings in browser local storage. No server-side backup is required.

### User Data Export
Recommend users to:
1. Export important drawings as .excalidraw files
2. Use PNG/SVG export for archival purposes
3. Save collaboration links for shared drawings

### Configuration Backup
```bash
# Backup docker-compose configuration
cp docker-compose.yml docker-compose.yml.backup
cp documentation.md documentation.md.backup
```

## Monitoring

### Health Checks
- **Endpoint**: HTTP GET to root path (/)
- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Retries**: 3

### Resource Monitoring
- **Memory Limit**: 512MB
- **Memory Reservation**: 128MB
- **Expected Usage**: Low (static web application)

### Uptime Kuma Integration
Add monitoring check:
- **Type**: HTTP
- **URL**: https://draw.alimunee.com
- **Interval**: 60 seconds
- **Expected Status**: 200

## Updates

Excalidraw is managed by Watchtower for automatic updates:
- **Update Schedule**: Automatic when new images are available
- **Rollback**: Use `docker compose down && docker compose up -d` with previous image tag if needed
- **Monitoring**: Check Watchtower logs for update status
