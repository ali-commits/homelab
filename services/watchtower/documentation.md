# Watchtower

**Purpose**: Automated container updates

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | Not applicable                                |
| Cookie Domain     | Not applicable                                |
| TLS               | Not applicable                                |
| Bootstrap Admin   | Not applicable                                |

**Update Configuration**:

- Schedule: "0 0 4 * * *" (Daily at 4:00 AM)
- Cleanup: Enabled for old images
- Rolling updates: Enabled
- Monitor Only: authentik-server, authentik-worker, authentik-redis, authentik-postgresql, traefik, database, redis, immich-database
- Notifications: Integrated with NTFY

**Exclusions**:

- authentik-server
- authentik-worker
- authentik-redis
- authentik-postgresql
- traefik

**Monitoring**:

- Sends notifications via NTFY
- Custom notification templates
- Update status reporting
