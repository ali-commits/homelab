# AFFiNE Service Documentation

## Overview

This document provides details for the AFFiNE service deployment using Docker Compose in this homelab environment. AFFiNE is a knowledge base application that serves as an alternative to tools like Notion and Miro.

## Docker Compose Configuration

The AFFiNE service is defined in `services/AFFiNE/docker-compose.yml`. It includes the following services:

- `affine`: The main AFFiNE GraphQL server.
- `affine_migration`: A job to perform database migrations for AFFiNE.
- `redis`: A Redis instance used by AFFiNE.
- `postgres`: A PostgreSQL database instance used by AFFiNE.

## Dependencies

The `affine` service depends on the `redis`, `postgres`, and `affine_migration` services. The `affine_migration` service depends on `redis` and `postgres`.

## Volumes

The following volumes are used for persistent data:

- `${UPLOAD_LOCATION}`: Maps to `/root/.affine/storage` in the `affine` and `affine_migration` containers. Used for storing uploaded files.
- `${CONFIG_LOCATION}`: Maps to `/root/.affine/config` in the `affine` and `affine_migration` containers. Used for storing custom configurations.
- `${DB_DATA_LOCATION}`: Maps to `/var/lib/postgresql/data` in the `postgres` container. Used for storing PostgreSQL database files.

These locations are defined in the `.env` file and should be configured to point to appropriate persistent storage on the host machine.

## Environment Variables

The following environment variables are configured via the `.env` file located in the `services/AFFiNE/` directory:

- `PORT`: The port the `affine` service will listen on (default: 3010).
- `AFFINE_REVISION`: The Docker image tag for the AFFiNE GraphQL server (default: `stable`).
- `UPLOAD_LOCATION`: The host path for uploaded files storage.
- `CONFIG_LOCATION`: The host path for configuration storage.
- `DB_USERNAME`: The username for the PostgreSQL database.
- `DB_PASSWORD`: The password for the PostgreSQL database. **Ensure this is changed from the default placeholder.**
- `DB_DATABASE`: The name of the PostgreSQL database (default: `affine`).
- `DB_DATA_LOCATION`: The host path for PostgreSQL data storage.
- `REDIS_SERVER_HOST`: The hostname for the Redis server (set to `redis` to connect to the Redis service within the Docker network).
- `DATABASE_URL`: The connection URL for the PostgreSQL database.

## Network Configuration

The AFFiNE services are connected to the `proxy` network, which is an external network managed by Traefik. This allows Traefik to route external traffic to the `affine` service based on the configured labels.

## Traefik Configuration

The `affine` service is configured with Traefik labels to enable routing:

- `traefik.enable=true`: Enables Traefik for this service.
- `traefik.http.routers.affine.rule=Host(\`notes.alimunee.com\`)`: Defines the routing rule based on the hostname.
- `traefik.http.services.affine.loadbalancer.server.port=3010`: Specifies the internal port of the container that Traefik should forward traffic to.
- `traefik.docker.network=proxy`: Specifies the Docker network Traefik should use to connect to the service.

## Resource Limits

Resource limits and reservations are configured for the `affine` service:

- `limits.memory: 4G`: Limits the memory usage to 4GB.
- `reservations.memory: 512M`: Reserves 512MB of memory for the service.

## Setup and Deployment

1. Ensure the `proxy` Docker network exists (`docker network create proxy`).
2. Create the `.env` file in the `services/AFFiNE/` directory based on the provided `.env.example` and update the placeholder values, especially the database password and volume locations.
3. Navigate to the `services/AFFiNE/` directory in your terminal.
4. Run `docker-compose up -d` to deploy the services.

## Maintenance and Troubleshooting

Refer to the main `docs/Docker_Doc.md` for general maintenance procedures, monitoring, and troubleshooting steps for the Docker infrastructure.
