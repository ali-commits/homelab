# Bazarr Docker Compose Standardization

This document outlines the changes made to the `bazarr` Docker Compose configuration as part of splitting the 'arr' stack and migrating to file-based management.

## Changes Made

1.  **File Splitting:** The configuration for the `bazarr` service has been extracted from the original `services/arr-25/docker-compose.yml` file and placed into its own `docker-compose.yml` file in the `services/bazarr/` directory.
    -   **Action:** Created `services/bazarr/docker-compose.yml` with the `bazarr` service configuration.

2.  **Environment Variables:** No sensitive environment variables were found in the `bazarr` service configuration that needed to be moved to a `.env` file. Non-sensitive configuration variables (`PUID`, `PGID`, `TZ`) remain in the `docker-compose.yml` file.
    -   **Action:** No `.env` file was created for this service.

3.  **Database Network:** No database service is present in this stack, so no `db_network` was added.

4.  **Image Selection:** The existing `linuxserver/bazarr:latest` image was retained as it is already a `linuxserver.io` image.

## Files Created/Modified

- `services/bazarr/docker-compose.yml`
- `docs/services/bazarr.md` (this file)

## Next Steps

The `bazarr` service configuration has been extracted and standardized. I will now proceed with splitting and standardizing the next service from the original 'arr' stack.
