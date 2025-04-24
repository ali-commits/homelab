# Nextcloud Docker Compose Standardization

This document outlines the changes made to the `nextcloud` Docker Compose configuration as part of the migration from Portainer to file-based management.

## Changes Made

1.  **Environment Variables:** Sensitive environment variables have been moved from the `docker-compose.yml` file to a new `.env` file located in the `services/nextcloud/` directory. The `docker-compose.yml` file now references these variables using the `${VAR_NAME}` syntax.
    -   **Action:** Created `services/nextcloud/.env` and moved variables.
    -   **Variables Moved:** `POSTGRES_PASSWORD`, `REDIS_HOST_PASSWORD`, `NEXTCLOUD_ADMIN_USER`, `NEXTCLOUD_ADMIN_PASSWORD`.

2.  **Database Network:** A dedicated network named `db_network` has been added to the `nextcloud-db` service to isolate database traffic.
    -   **Action:** Added `db_network` definition and assigned it to `nextcloud-db` service in `services/nextcloud/docker-compose.yml`.

3.  **Image Selection:** The existing official images (`nextcloud:latest`, `postgres:16-alpine`, `redis:alpine`) were retained as they are appropriate for this service and no `linuxserver.io` alternatives were used.

4.  **File Structure:** The `docker-compose.yml` file was not split, keeping all Nextcloud services within a single file for easier management of this interconnected stack.

## Files Modified

- `services/nextcloud/.env`
- `services/nextcloud/docker-compose.yml`

## Next Steps

The `nextcloud` Docker Compose file has been standardized. The next service in the `services/` directory will be processed.
