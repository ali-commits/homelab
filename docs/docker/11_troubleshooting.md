# Troubloting Guide

## Common Issues

| Issue                    | Diagnosis                      | Solution                                                |
| ------------------------ | ------------------------------ | ------------------------------------------------------- |
| **Service won't start**  | `docker logs <service>`        | Check logs for errors, verify configuration             |
| **Network connectivity** | `docker network inspect proxy` | Verify network configuration and service assignment     |
| **Database connection**  | Check database logs            | Restart database container, verify credentials          |
| **SSL/TLS issues**       | Check Traefik logs             | Verify domain/certificate config, restart Traefik       |
| **Permission issues**    | Check volume mounts            | Fix ownership: `chown -R user:group /path`              |
| **AI API failures**      | Check Gemini API quota         | Verify API keys and billing in Google Cloud             |
| **OCR not working**      | Check Tesseract languages      | Install required language packs                         |
| **Sync conflicts**       | Check Syncthing web UI         | Resolve conflicts manually                              |
| **Out of disk space**    | `df -h /storage/`              | Clean up old data, expand storage                       |
| **Memory issues**        | `docker stats`                 | Increase container memory limits                        |
| **DNS resolution fails** | Test with `nslookup`/`dig`     | Verify DNS config (8.8.8.8, 1.1.1.1), restart container |

## Diagnostic Commands

### Service Health Check
```bash
# Check all containers with health status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"

# Service health overview
for service in $(docker ps --format "{{.Names}}"); do
    echo "=== $service ==="
    docker inspect $service --format '{{.State.Health.Status}}'
done
```

### Network Diagnostics
```bash
# Check networks
docker network ls
docker network inspect proxy db_network mail_network

# Test connectivity
docker exec [service] nc -zv [target] [port]

# DNS resolution testing
docker exec [service] nslookup google.com
docker exec [service] dig @8.8.8.8 example.com

# Check DNS configuration
docker inspect [service] | jq '.[0].HostConfig.Dns'
```

### Performance Diagnostics
```bash
# System resources
docker stats --no-stream
df -h /storage/
free -h

# Log analysis
docker logs --since 1h $(docker ps -q) 2>&1 | grep -i "error\|failed\|exception"
```

## Service-Specific Issues

For detailed troubleshooting of individual services, refer to their documentation:

- **Core Infrastructure**: [03_core-infrastructure.md](03_core-infrastructure.md)
- **Authentication**: [04_authentication.md](04_authentication.md)
- **AI/ML Services**: [05_ai-ml-services.md](05_ai-ml-services.md)
- **Notifications**: [06_notifications-smtp.md](06_notifications-smtp.md)
- **Data Services**: [07_data-services.md](07_data-services.md)
- **Media Services**: [08_media-entertainment.md](08_media-entertainment.md)
- **Productivity**: [09_productivity-collaboration.md](09_productivity-collaboration.md)
- **Monitoring**: [10_monitoring-management.md](10_monitoring-management.md)

## Emergency Procedures

### Service Recovery
```bash
# Emergency service restart
SERVICE="traefik"  # or any critical service
docker compose -f /HOMELAB/services/$SERVICE/docker-compose.yml down
docker compose -f /HOMELAB/services/$SERVICE/docker-compose.yml up -d
```

### Complete Infrastructure Recovery
```bash
# Stop all services
cd /HOMELAB/services
find . -name "docker-compose.yml" -execdir docker-compose down \;

# Start core services first
docker compose -f traefik/docker-compose.yml up -d
docker compose -f zitadel/docker-compose.yml up -d
docker compose -f postfix/docker-compose.yml up -d

# Wait and start others
sleep 30
find . -name "docker-compose.yml" -not -path "./traefik/*" -not -path "./zitadel/*" -not -path "./postfix/*" -execdir docker-compose up -d \;
```

---

*For detailed troubleshooting procedures, refer to [12_operations.md](12_operations.md) and individual service documentation.*
