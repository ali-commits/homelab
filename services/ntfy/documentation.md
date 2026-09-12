# ntfy

**Purpose**: Self-hosted push notification service (`binwiederhier/ntfy`) — system alerts and
Matrix chat notifications.

**Topics in use**:

- `system-alerts` — system-wide alerts (backups, monitoring)
- `Docker` — container and update notifications
- `homelab-alerts`, `monitoring`, `security`, `maintenance`, `watchtower`, `media` — see the guide below
- `up*` — one private topic per chat device, created by the ntfy app as a UnifiedPush distributor

📖 **For comprehensive documentation, see the [System Notifications Guide](../../docs/system/09_notifications.md)**

**Configuration Details**:

| Configuration   | Details                                                               |
| --------------- | --------------------------------------------------------------------- |
| External Access | notification.alimunee.com                                             |
| Internal Access | http://localhost:8888                                                 |
| Config          | `/storage/data/ntfy/etc/server.yml`                                   |
| Cache           | `/storage/data/ntfy/cache/cache.db` (SQLite; safe to query read-only) |
| TLS             | Terminated by Cloudflare in front of Traefik                          |

**Two roles**:

1. **Alert fan-out** — scripts and services POST to a topic; every subscriber to that topic
   (phone app, web UI, CLI) receives it.
2. **Matrix / UnifiedPush gateway** — phones running Element X with the ntfy app register a
   pusher on the homeserver, and ntfy publishes each chat notification into that device's own
   private topic. See [Matrix Chat Notifications](../../docs/system/09_notifications.md#matrix-chat-notifications-unifiedpush).

**The one setting the Matrix path depends on**: `base-url` must equal the public hostname
(`https://notification.alimunee.com`). ntfy rejects any Matrix push whose `pushkey` does not
start with it, so a stale hostname there silently discards every chat notification.

**Quick checks**:

```bash
curl -s https://notification.alimunee.com/v1/health                  # {"healthy":true}
curl -s https://notification.alimunee.com/_matrix/push/v1/notify     # {"unifiedpush":{"gateway":"matrix"}}

# newest topics and how recently each was used
sqlite3 -readonly /storage/data/ntfy/cache/cache.db \
  "select topic, count(*), datetime(max(time),'unixepoch','localtime') from messages group by topic order by max(time) desc limit 10;"

# send one yourself
curl -H "Title: Test Alert" -H "Priority: 4" -d "ntfy test" \
  https://notification.alimunee.com/homelab-alerts
```

**Known hardening items** (open):

- Anonymous publish and read are currently allowed (`auth`/`access` in `server.yml` grant the
  admin user and an access key, but nothing *denies* anonymous access), so anyone who knows a
  topic name can publish fake alerts to it.
- The admin password is weak and was quoted in this public repository's history — deleting it
  from the docs is not enough, it must be rotated. Rotation touches every publisher:
  Watchtower, the media stack, Uptime Kuma, `/etc/default/notification-settings`, and the
  backup/monitoring scripts.
