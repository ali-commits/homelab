# Firefly III

**Purpose**: Self-hosted personal finance manager using double-entry bookkeeping

| Configuration Setting | Value                    |
| --------------------- | ------------------------ |
| Image                 | `fireflyiii/core:latest` |
| Database              | `PostgreSQL 15`          |
| Memory Limits         | `1GB max, 256MB minimum` |
| Timezone              | `Asia/Kuala_Lumpur`      |

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | finance.alimunee.com                        |
| Database        | Internal access only                        |
| Trusted Proxies | All (\*\*)                                  |
| TLS             | Disabled internally (handled by Cloudflare) |

**Volume Mappings**:

| Volume   | Path                               |
| -------- | ---------------------------------- |
| Uploads  | `/storage/data/firefly-iii/upload` |
| Database | `/storage/data/firefly-iii/db`     |

**Network Settings**:

| Setting            | Value                                             |
| ------------------ | ------------------------------------------------- |
| Web Interface Port | `8080`                                            |
| Domain             | `finance.alimunee.com`                            |
| Networks           | `proxy` (external), `firefly_internal` (internal) |

**Security Considerations**:

- Database is isolated in an internal network
- Secrets should be changed before deployment:
  - APP_KEY
  - DB_PASSWORD
- Protected behind Traefik proxy
- `TRUSTED_PROXIES` set to `**` - ensure Traefik handles proxy headers correctly.

**Usage Instructions**:

1. Access the interface at finance.alimunee.com
2. Register the first user (this becomes the admin)
3. Set up accounts, budgets, and categories
4. Import transactions (using the separate Data Importer tool if needed, not included here)
5. Track expenses and income
6. Generate financial reports

**Features**:

- Double-entry bookkeeping
- Expense and income tracking
- Budgeting and categories
- Multi-currency support
- Rule engine for automation
- Charts and reports

**Maintenance**:

- Regularly backup both data volumes (uploads and database)
- Update the container for security patches and new features
- Consider setting up the optional Data Importer container for easier transaction imports
