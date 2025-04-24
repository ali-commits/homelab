# Immich Docker Compose Standardization

This document outlines the changes made to the `immich` Docker Compose configuration as part of the migration from Portainer to file-based management, with revisions based on feedback to only store sensitive data in `.env` files.

## Changes Made

1.  **Environment Variables:** Sensitive environment variables (`DB_PASSWORD`, `JWT_SECRET`, `POSTGRES_PASSWORD`, `POSTGRES_USER`, `POSTGRES_DB`) have been moved from the `docker-compose.yml` file to a new `.env` file located in the `services/immich/` directory. All variables in the `.env` file for this service are considered sensitive. The `docker-compose.yml` file now references these variables using the `${VAR_NAME}` syntax.
    -   **Action:** Created `services/immich/.env` with sensitive variables and updated `services/immich/docker-compose.yml` to reference them.
    -   **Sensitive Variables Moved:** `DB_PASSWORD`, `JWT_SECRET`, `POSTGRES_PASSWORD`, `POSTGRES_USER`, `POSTGRES_DB`.

2.  **Database Network:** A dedicated network named `db_network` has been added to the `database` service to isolate database traffic.
    -   **Action:** Added `db_network` definition and assigned it to `database` service in `services/immich/docker-compose.yml`.

3.  **Image Selection:** The existing official images (`ghcr.io/immich-app/immich-server:release`, `ghcr.io/immich-app/immich-machine-learning:release`, `docker.io/redis:6.2-alpine`, `docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0`) were retained as they are appropriate for this service and no `linuxserver.io` alternatives were used.

4.  **File Structure:** The `docker-compose.yml` file was not split, keeping all Immich services within a single file for easier management of this interconnected stack.

## Files Modified

- `services/immich/.env`
- `services/immich/docker-compose.yml`
- `docs/services/immich.md` (this file)

## Next Steps

The `immich` Docker Compose file has been standardized according to the revised plan. I will now proceed to review and revise the standardization for the remaining service based on the feedback.
