# FlareSolverr Docker Compose Standardization

This document outlines the changes made to the `flaresolverr` Docker Compose configuration as part of splitting the 'arr' stack and migrating to file-based management.

## Changes Made

1.  **File Splitting:** The configuration for the `flaresolverr` service has been extracted from the original `services/arr-25/docker-compose.yml` file and placed into its own `docker-compose.yml` file in the `services/flaresolverr/` directory.
    -   **Action:** Created `services/flaresolverr/docker-compose.yml` with the `flaresolverr` service configuration.

2.  **Environment Variables:** No sensitive environment variables were found in the `flaresolverr` service configuration that needed to be moved to a `.env` file. The non-sensitive `TZ` variable remains in the `docker-compose.yml` file.
    -   **Action:** No `.env` file was created for this service.

3.  **Database Network:** No database service is present in this stack, so no `db_network` was added.

4.  **Image Selection:** The existing `ghcr.io/flaresolverr/flaresolverr:latest` image was retained as it is the appropriate image for this service and no `linuxserver.io` alternative was used.

## Files Created/Modified

- `services/flaresolverr/docker-compose.yml`
- `docs/services/flaresolverr.md` (this file)

## Next Steps

The `flaresolverr` service configuration has been extracted and standardized. All services from the original 'arr' stack in `services/arr-25` have now been split and standardized. The next step is to delete the original 'arr' directories.
