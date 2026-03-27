# Troubleshooting Guide

## Common Issues

| Issue                    | Diagnosis                                     | Solution                                                                                      |
| ------------------------ | --------------------------------------------- | --------------------------------------------------------------------------------------------- |
| **Service won't start**  | `docker logs <service>`                       | Check logs for errors, verify configuration                                                   |
| **Network connectivity** | `docker network inspect proxy`                | Verify network configuration and service assignment                                           |
| **Database connection**  | Check database logs                           | Restart database container, verify credentials                                                |
| **SSL/TLS issues**       | Check Traefik logs                            | Verify domain/certificate config, restart Traefik                                             |
| **Permission issues**    | Check volume mounts                           | Fix ownership: `chown -R user:group /path`                                                    |
| **AI API failures**      | Check Gemini API quota                        | Verify API keys and billing in Google Cloud                                                   |
| **OCR not working**      | Check Tesseract languages                     | Install required language packs                                                               |
| **Sync conflicts**       | Check Syncthing web UI                        | Resolve conflicts manually                                                                    |
| **Out of disk space**    | `df -h /` and `sudo btrfs filesystem usage /` | `df` may show normal usage while btrfs `Used` is inflated — see btrfs CoW ghost storage below |
| **Memory issues**        | `docker stats`                                | Increase container memory limits                                                              |
| **DNS resolution fails** | Test with `nslookup`/`dig`                    | Verify DNS config (8.8.8.8, 1.1.1.1), restart container                                       |

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

## btrfs CoW Ghost Storage

btrfs `Used` can grow far beyond actual file sizes when containers crash-loop, due to CoW extent accumulation. This is invisible to `df` / `du` but visible in `btrfs filesystem usage /`.

**Symptoms:**
- `sudo btrfs filesystem usage /` shows `Used` much higher than `du -sh /*`
- Storage growing continuously (run `/HOMELAB/scripts/storage-monitor.sh` to sample, or check past logs at `/storage/data/logs/storage-monitor/`)
- A container with a database is crash-looping (each unclean shutdown triggers journal recovery = new CoW extents)

**Diagnosis:**
```bash
# Check real btrfs usage vs apparent usage
sudo btrfs filesystem usage /

# Find crash-looping containers
docker events --filter event=die --since 1h
docker inspect <container> | jq '.[0].State.ExitCode'  # 139 = SIGSEGV

# Count coredumps
coredumpctl list | grep <process>
```

**Recovery:**
```bash
# 1. Stop the offending container
# 2. Delete all snapper snapshots (they hold old extents alive)
sudo snapper -c root list
sudo snapper -c data delete <id>

# 3. Run btrfs balance to reclaim freed extents
sudo btrfs balance start -dusage=50 /
sudo btrfs balance start -musage=50 /

# 4. Remove Docker images if needed (reflinks freed = large reclaim)
docker image prune -a
```

> **Known issue:** MongoDB 8.2.5 (tcmalloc-google) SIGSEGV crash loop on kernel 6.19. See [incident report](../incidents/2026-03-20_nvme-storage-exhaustion.md).

---

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
