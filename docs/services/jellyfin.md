# Jellyfin Docker Compose Standardization

This document outlines the changes made to the `jellyfin` Docker Compose configuration as part of the migration from Portainer to file-based management, with revisions based on feedback to only store sensitive data in `.env` files.

## Changes Made

1.  **Environment Variables:** Environment variables (`PUID`, `PGID`, `TZ`) have been moved back into the `docker-compose.yml` file as they are not considered sensitive data. The `.env` file for this service has been removed.
    -   **Action:** Removed `services/jellyfin/.env` and updated `services/jellyfin/docker-compose.yml`.
    -   **Variables Affected:** `PUID`, `PGID`, `TZ`.

2.  **Database Network:** No database service is present in this stack, so no `db_network` was added.

3.  **Image Selection:** The existing `linuxserver/jellyfin:latest` image was retained as it is already a `linuxserver.io` image.

4.  **File Structure:** The `docker-compose.yml` file was not split as it is a simple configuration.

## Files Modified

- `services/jellyfin/docker-compose.yml`
- `services/jellyfin/.env` (removed)
- `docs/services/jellyfin.md` (this file)

## Next Steps

The `jellyfin` Docker Compose file has been standardized according to the revised plan. I will now proceed to review and revise the standardization for the other services based on the feedback.
