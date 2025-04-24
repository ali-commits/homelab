# Authentik Docker Compose Standardization

This document outlines the changes made to the `authentik` Docker Compose configuration as part of the migration from Portainer to file-based management, with revisions based on feedback to only store sensitive data in `.env` files.

## Changes Made

1.  **Environment Variables:** Sensitive environment variables (`POSTGRES_PASSWORD`, `AUTHENTIK_BOOTSTRAP_PASSWORD`, `AUTHENTIK_SECRET_KEY`) have been moved from the `docker-compose.yml` file to a new `.env` file located in the `services/authentik/` directory. Non-sensitive configuration variables (`POSTGRES_USER`, `POSTGRES_DB`, `AUTHENTIK_BOOTSTRAP_EMAIL`, `AUTHENTIK_BOOTSTRAP_TOKEN`) remain in the `docker-compose.yml` file. The `docker-compose.yml` file now references the sensitive variables using the `${VAR_NAME}` syntax.
    -   **Action:** Created `services/authentik/.env` with sensitive variables and updated `services/authentik/docker-compose.yml` to include non-sensitive variables and reference sensitive ones.
    -   **Sensitive Variables Moved:** `POSTGRES_PASSWORD`, `AUTHENTIK_BOOTSTRAP_PASSWORD`, `AUTHENTIK_SECRET_KEY`.

2.  **Database Network:** A dedicated network named `db_network` has been added to the `authentik-postgresql` service to isolate database traffic.
    -   **Action:** Added `db_network` definition and assigned it to `authentik-postgresql` service in `services/authentik/docker-compose.yml`.

3.  **Image Selection:** The existing official images (`postgres:16-alpine`, `ghcr.io/goauthentik/server:2025.2`, `redis:alpine`) were retained as they are appropriate for this service and no `linuxserver.io` alternatives were used.

4.  **File Structure:** The `docker-compose.yml` file was not split, keeping all Authentik services within a single file for easier management of this interconnected stack.

## Files Modified

- `services/authentik/.env`
- `services/authentik/docker-compose.yml`
- `docs/services/authentik.md` (this file)

## Next Steps

All services that were initially standardized have been revised based on the feedback to only store sensitive data in `.env` files. The next step is to address the 'arr' stack duplication and splitting, and then continue with the remaining services in the `services/` directory.
