# Ourstory Docker Compose Standardization

This document outlines the changes made to the `ourstory` Docker Compose configuration as part of the migration from Portainer to file-based management, with revisions based on feedback to only store sensitive data in `.env` files.

## Changes Made

1.  **Environment Variables:** Sensitive environment variables (`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_KEY`) have been moved from the `docker-compose.yml` file to a new `.env` file located in the `services/ourstory/` directory. The non-sensitive `NODE_ENV` variable remains in the `docker-compose.yml` file. The `docker-compose.yml` file now references the sensitive variables using the `${VAR_NAME}` syntax.
    -   **Action:** Created `services/ourstory/.env` with sensitive variables and updated `services/ourstory/docker-compose.yml` to include the non-sensitive variable and reference sensitive ones.
    -   **Sensitive Variables Moved:** `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_KEY`.

2.  **Database Network:** No database service is present in this stack, so no `db_network` was added.

3.  **Image Selection:** The existing image (`ghcr.io/ali-commits/our-story:v1.1.1`) was retained as it is the appropriate image for this service and no `linuxserver.io` alternative was used.

4.  **File Structure:** The `docker-compose.yml` file was not split as it is a simple configuration.

## Files Modified

- `services/ourstory/.env`
- `services/ourstory/docker-compose.yml`
- `docs/services/ourstory.md` (this file)

## Next Steps

The `ourstory` Docker Compose file has been standardized according to the revised plan. I will now proceed to review and revise the standardization for the other services based on the feedback.
