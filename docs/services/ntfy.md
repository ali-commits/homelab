# NTFY Docker Compose Standardization

This document outlines the changes made to the `ntfy` Docker Compose configuration as part of the migration from Portainer to file-based management, with revisions based on feedback to only store sensitive data in `.env` files.

## Changes Made

1.  **Environment Variables:** The `TZ` environment variable has been moved back into the `docker-compose.yml` file as it is not considered sensitive data. The `.env` file for this service has been removed.
    -   **Action:** Removed `services/ntfy/.env` and updated `services/ntfy/docker-compose.yml`.
    -   **Variables Affected:** `TZ`.

2.  **Database Network:** No database service is present in this stack, so no `db_network` was added.

3.  **Image Selection:** The existing official image (`binwiederhier/ntfy`) was retained as it is the appropriate image for this service and no `linuxserver.io` alternative was used.

4.  **File Structure:** The `docker-compose.yml` file was not split as it is a simple configuration.

## Files Modified

- `services/ntfy/docker-compose.yml`
- `services/ntfy/.env` (removed)
- `docs/services/ntfy.md` (this file)

## Next Steps

The `ntfy` Docker Compose file has been standardized according to the revised plan. I will now proceed to review and revise the standardization for the other services based on the feedback.
