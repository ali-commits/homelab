# Authentik

**Purpose**: Identity provider and SSO solution

**Components**:

1. **Server**:

   - Primary authentication service
   - Handles web interface and API
   - Port: 9999:9000

2. **Database (PostgreSQL)**:

   - Stores user data and configurations
   - Persistent volume for data storage

3. **Redis**:

   - Session management
   - Cache storage

4. **Worker**:
   - Background task processing
   - Email sending

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | https://auth.alimunee.com             |
| Cookie Domain     | alimunee.com                          |
| TLS               | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin   | Configured via environment variables  |

**Dependencies**:

- PostgreSQL database
- Redis cache
- Traefik for routing
