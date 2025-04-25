# Joplin Server

**Purpose**: Self-hosted synchronization server for Joplin note-taking applications

| Configuration Setting | Value                    |
| --------------------- | ------------------------ |
| Image                 | `joplin/server:latest`   |
| Database              | `PostgreSQL 15`          |
| Memory Limits         | `1GB max, 256MB minimum` |
| Timezone              | `Asia/Kuala_Lumpur`      |

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | joplin.alimunee.com                         |
| Server Port     | 22300                                       |
| Email           | Not configured (optional)                   |
| TLS             | Disabled internally (handled by Cloudflare) |

**Volume Mappings**:

| Volume        | Path                      |
| ------------- | ------------------------- |
| Joplin Data   | `/storage/data/joplin`    |
| Database Data | `/storage/data/joplin-db` |

**Network Settings**:

| Setting            | Value                                            |
| ------------------ | ------------------------------------------------ |
| Web Interface Port | `22300`                                          |
| Domain             | `joplin.alimunee.com`                            |
| Networks           | `proxy` (external), `joplin_internal` (internal) |

**Security Considerations**:

- Database is isolated in an internal network
- Database password should be changed before deployment
- Protected behind Traefik proxy
- End-to-end encryption available in Joplin clients

**Usage Instructions**:

1. First, create a user account through the web interface at joplin.alimunee.com
2. In your Joplin desktop or mobile app, set up synchronization:
   - Select "Joplin Server" as the synchronization target
   - Enter https://joplin.alimunee.com as the server URL
   - Enter your user credentials
3. Your notes will now synchronize across all your devices

**Features**:

- Secure synchronization of notes and attachments
- Support for multiple users/devices
- End-to-end encryption support with Joplin clients
- Web clipper compatibility

**Maintenance**:

- Regularly backup both the Joplin data volume and database volume
- Update the containers for security patches and new features
- Monitor database performance for large note collections
