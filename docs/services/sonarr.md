# Sonarr Docker Compose Standardization

This document outlines the changes made to the `sonarr` Docker Compose configuration as part of splitting the 'arr' stack and migrating to file-based management.

## Changes Made

1.  **File Splitting:** The configuration for the `sonarr` service has been extracted from the original `services/arr-25/docker-compose.yml` file and placed into its own `docker-compose.yml` file in the `services/sonarr/` directory.
    -   **Action:** Created `services/sonarr/docker-compose.yml` with the `sonarr` service configuration.

2.  **Environment Variables:** No sensitive environment variables were found in the `sonarr` service configuration that needed to be moved to a `.env` file. Non-sensitive configuration variables (`PUID`, `PGID`, `TZ`) remain in the `docker-compose.yml` file.
    -   **Action:** No `.env` file was created for this service.

3.  **Database Network:** No database service is present in this stack, so no `db_network` was added.

4.  **Image Selection:** The existing `linuxserver/sonarr:latest` image was retained as it is already a `linuxserver.io` image.

## Files Created/Modified

- `services/sonarr/docker-compose.yml`
- `docs/services/sonarr.md` (this file)

## Next Steps

The `sonarr` service configuration has been extracted and standardized. I will now proceed with splitting and standardizing the next service from the original 'arr' stack.
