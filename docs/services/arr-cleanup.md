# 'Arr' Stack Directory Cleanup and Splitting

This document details the cleanup and splitting of the original 'arr' stack directories as part of the migration from Portainer to file-based management.

## Actions Taken

1.  **Split Services:** The individual services (`radarr`, `sonarr`, `prowlarr`, `bazarr`, `jellyseerr`, `flaresolverr`) from the original 'arr' stack in `services/arr-25/docker-compose.yml` were split into their own directories and `docker-compose.yml` files within the `services/` directory.
    -   **Action:** Created directories and `docker-compose.yml` files for each service.

2.  **Standardized Individual Services:** Each of the split service configurations was standardized according to the revised plan, including moving sensitive environment variables to `.env` files (where applicable) and updating documentation.

3.  **Deleted original directories:** The original directories containing the 'arr' stack (`services/arr-25` and `services/arr-26`) were deleted.
    -   **Action:** Executed `rm -r services/arr-25 services/arr-26`.

## Next Steps

The original 'arr' stack directories have been removed, and the individual services have been split and standardized. The standardization process will continue with the remaining services in the `services/` directory.
