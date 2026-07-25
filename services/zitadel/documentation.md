# Zitadel

**Purpose**: Open-source identity management platform.

**Components**:

| Container       | Image                                | Role                                            |
| --------------- | ------------------------------------ | ----------------------------------------------- |
| `zitadel`       | `ghcr.io/zitadel/zitadel:latest`     | Main API and admin console                      |
| `zitadel-login` | `ghcr.io/zitadel/zitadel-login:latest` | Login v2 UI (Next.js), served at `/ui/v2/login` |
| `zitadel-db`    | `postgres:17-alpine`                 | Identity and configuration data                 |

**Configuration Details**:

| Configuration   | Details                                             |
| --------------- | --------------------------------------------------- |
| External Access | https://zitadel.alimunee.com                        |
| TLS             | Disabled internally (handled by Traefik/Cloudflare) |
| Master Key      | Stored in `.env` file                               |

## Login v2

Login v2 is **enabled** (since 2026-07-21). The `zitadel-login` container serves the new
login UI; Traefik routes it with a dedicated higher-priority router so it wins over the
main Zitadel router:

| Router          | Rule                                                        | Priority | Port |
| --------------- | ----------------------------------------------------------- | -------- | ---- |
| `zitadel-login` | `Host(zitadel.alimunee.com) && PathPrefix(/ui/v2/login)`     | 100      | 3000 |
| `zitadel`       | `Host(zitadel.alimunee.com)`                                | default  | 8080 |

Both routers share the `zitadel-headers` middleware, which sets `X-Forwarded-Proto=https`
and `X-Forwarded-Host` so Zitadel builds correct absolute URLs behind Cloudflared.

The login container authenticates to the API with a service-user PAT read from
`/current-dir/login-client.pat` (mounted read-only from `/storage/data/zitadel/config`).

> **Enabling the flag:** use the **`/v2` features API** — `/v2beta` silently accepts and
> ignores `loginV2`. See [LOGIN_V2_TROUBLESHOOTING.md](./LOGIN_V2_TROUBLESHOOTING.md) for
> the PAT elevation procedure and the full debugging history.

### Theme customization

The login UI is themed via `NEXT_PUBLIC_THEME_*` environment variables on the `login`
service (upstream reference: `apps/login/THEME_CUSTOMIZATION.md` in the zitadel repo):

| Variable                              | Value                        |
| ------------------------------------- | ---------------------------- |
| `NEXT_PUBLIC_THEME_ROUNDNESS`         | `mid`                        |
| `NEXT_PUBLIC_THEME_LAYOUT`            | `top-to-bottom`              |
| `NEXT_PUBLIC_THEME_SPACING`           | `regular`                    |
| `NEXT_PUBLIC_THEME_APPEARANCE`        | `material`                   |
| `NEXT_PUBLIC_THEME_BACKGROUND_IMAGE`  | Unsplash landscape (remote)  |

These are build-time-style Next.js public vars — the container must be **recreated**, not
just restarted, for changes to take effect:

```bash
cd /HOMELAB/services/zitadel && docker compose up -d --force-recreate login
```

> The background image is fetched from `images.unsplash.com`, so the login page depends on
> outbound internet access. The container sets explicit DNS (`8.8.8.8`, `1.1.1.1`).

**Data Persistence**:

-   `/storage/data/zitadel/config`: Stores PAT files and other initialization data.
-   `/storage/data/zitadel/db`: PostgreSQL database files.

**Network Configuration**:

-   Connected to `proxy` network for external access via Traefik.
-   Uses `zitadel_internal` network for secure communication between the Zitadel service and its database.

**SMTP Configuration**:

Email delivery is configured directly through Brevo via the Zitadel admin panel:

| Setting        | Value                    | Description                   |
| -------------- | ------------------------ | ----------------------------- |
| SMTP Host      | smtp-relay.brevo.com:587 | Brevo SMTP relay server       |
| Authentication | SMTP credentials         | Configured with Brevo API key |
| TLS            | Enabled                  | Secure connection to Brevo    |
| From Address   | noreply@alimunee.com     | Verified sender domain        |
| From Name      | Zitadel                  | Display name for emails       |

**SMTP Setup Process**:
1. Access Zitadel admin panel at https://zitadel.alimunee.com
2. Navigate to Instance Settings → SMTP Configuration
3. Configure Brevo SMTP settings:
   - Host: smtp-relay.brevo.com
   - Port: 587
   - Username: Your Brevo login email
   - Password: Your Brevo SMTP API key
   - Enable TLS/STARTTLS
4. Test email delivery from the admin panel
5. Email notifications now work for user invitations, password resets, and authentication events
