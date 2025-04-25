# AFFiNE Service Research

## Official Docker Compose Analysis

The official AFFiNE Docker Compose configuration provides a standard deployment setup including the core application, database migration job, Redis, and PostgreSQL.

Key observations from the official configuration:

- **Services:** `affine`, `affine_migration`, `redis`, `postgres`.
- **Image:** `ghcr.io/toeverything/affine-graphql` with a revision tag (defaults to `stable`).
- **Dependencies:** Services are linked with `depends_on` and `service_healthy` or `service_completed_successfully` conditions to ensure proper startup order.
- **Ports:** The main `affine` service exposes port 3010.
- **Volumes:** Uses volumes for `/root/.affine/storage` (uploads) and `/root/.affine/config` (configuration) for the `affine` and `affine_migration` services, and `/var/lib/postgresql/data` for the `postgres` service. These are mapped to host paths via environment variables.
- **Environment Variables:** Critical configuration is passed via environment variables, including database connection details and Redis host. An `.env` file is used for managing these variables.
- **Health Checks:** Redis and PostgreSQL services include health checks to ensure they are ready before dependent services start.
- **Restart Policy:** `unless-stopped` is used for persistent services.
- **Migration Job:** A dedicated `affine_migration` service runs a script (`./scripts/self-host-predeploy.js`) to handle database schema initialization or updates.

## Integration with Homelab Infrastructure

Integrating the official AFFiNE setup into the existing homelab infrastructure involves:

- **Networking:** Connecting the AFFiNE services to the `proxy` network for Traefik integration.
- **Traefik Labels:** Adding appropriate Traefik labels to the `affine` service for routing via `notes.alimunee.com`.
- **Volume Management:** Ensuring the specified volume paths in the `.env` file (`UPLOAD_LOCATION`, `CONFIG_LOCATION`, `DB_DATA_LOCATION`) are correctly configured and persistent on the host.
- **Environment Variables:** Populating the `.env` file with the necessary values, including secure passwords for the database.

This research confirms that the official Docker Compose provides a solid foundation for deployment, and the integration steps align with the established homelab practices for networking, routing, and persistent storage.
