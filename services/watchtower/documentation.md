# Watchtower

**Purpose**: Automated container updates

📖 **For notification setup, see [System Notifications Guide](/HOMELAB/docs/system/notifications.md#watchtower-notifications)**

**Configuration Details**:

| Configuration      | Details                        |
| ------------------ | ------------------------------ |
| Schedule           | Daily at 4:00 AM (0 0 4 * * *) |
| Notification Topic | `watchtower`                   |
| External Access    | Not applicable                 |
| Cookie Domain      | Not applicable                 |
| TLS                | Not applicable                 |
| Bootstrap Admin    | Not applicable                 |

**Update Configuration**:

- Schedule: "0 0 4 * * *" (Daily at 4:00 AM)
- Cleanup: Enabled for old images
- Rolling updates: Enabled
- Monitor Only: Zitadel-server, Zitadel-worker, Zitadel-redis, Zitadel-postgresql, traefik, database, redis, immich-database
- Notifications: Integrated with NTFY → `watchtower` topic

**Exclusions**:

- Zitadel-server
- Zitadel-worker
- Zitadel-redis
- Zitadel-postgresql
- traefik

**Monitoring**:

- Sends notifications via NTFY
- Custom notification templates
- Update status reporting
