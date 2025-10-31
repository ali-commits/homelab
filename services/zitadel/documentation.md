# Zitadel

**Purpose**: Open-source identity management platform.

**Components**:

1.  **Zitadel**: The main application service.
2.  **Login**: The user-facing login interface.
3.  **Database (PostgreSQL)**: Stores all identity and configuration data.

**Configuration Details**:

| Configuration   | Details                                             |
| --------------- | --------------------------------------------------- |
| External Access | https://zitadel.alimunee.com                        |
| TLS             | Disabled internally (handled by Traefik/Cloudflare) |
| Master Key      | Stored in `.env` file                               |

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
