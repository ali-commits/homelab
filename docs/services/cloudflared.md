# Cloudflared Docker Compose Standardization

This document outlines the changes made to the `cloudflared` Docker Compose configuration as part of the migration from Portainer to file-based management.

## Changes Made

1.  **Environment Variables:** The Cloudflare tunnel token has been moved from the `command` in the `docker-compose.yml` file to a new `.env` file located in the `services/cloudflared/` directory. The `docker-compose.yml` file now references this variable using the `${CLOUDFLARED_TUNNEL_TOKEN}` syntax.
    -   **Action:** Created `services/cloudflared/.env` and moved the tunnel token.

2.  **Image Selection:** The existing official image (`cloudflare/cloudflared:latest`) was retained as it is the appropriate image for this service and no `linuxserver.io` alternative was used.

3.  **File Structure:** The `docker-compose.yml` file was not split as it is a simple configuration.

4.  **Database Network:** No database service is present in this stack, so no `db_network` was added.

## Files Modified

- `services/cloudflared/.env`
- `services/cloudflared/docker-compose.yml`

## Next Steps

The `cloudflared` Docker Compose file has been standardized. The next service in the `services/` directory will be processed.
