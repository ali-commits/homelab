# Immich Setup and Configuration Documentation

## Overview

This document details the setup and configuration of Immich, a self-hosted photo and video management solution, integrated with the existing homelab infrastructure. The deployment uses Docker containers managed through Portainer, with Traefik as the reverse proxy and Authentik for authentication.

## System Architecture

Immich consists of multiple components working together:

1. **Immich Server**: Main application handling the web interface and API
2. **Machine Learning Service**: Provides AI features like facial recognition and object detection
3. **PostgreSQL Database**: Stores metadata and user information
4. **Redis**: Provides caching and session management

## Deployment Configuration

### Docker Compose Configuration

```yaml
name: immich
services:
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:release
    volumes:
      - /storage/Immich/uploads:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    environment:
      - DB_DATABASE_NAME=immich
      - DB_USERNAME=postgres
      - DB_PASSWORD=immich123
      - DB_HOSTNAME=database
      - REDIS_HOSTNAME=redis
      - UPLOAD_LOCATION=/storage/Immich/uploads
      - JWT_SECRET=7f75d9074fcdbcc2a85b83160e3967de77fc6d8e2bb3edc131811033b0862c240f29936e85ffdd33a2c85b8fadb0bf23be16c6f7af371dc78a58c09a7461beb4a1bb7331c682a3da2da730b1f9b124b2a3fced0e400357c4c2772d0077ef81def374469d465c53a65edd303a2c9fb5e0ed89bccf3fc1cb924c1e19b6257034f7
      - SERVER_ENDPOINT=https://photos.alimunee.com
    depends_on:
      - redis
      - database
    restart: unless-stopped
    ports:
      - '2283:2283'
    networks:
      - proxy
      - immich_internal
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.immich.rule=Host(`photos.alimunee.com`)'
      - 'traefik.http.services.immich.loadbalancer.server.port=2283'
      - 'traefik.docker.network=proxy'
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:2283/server-info/ping']
      interval: 30s
      timeout: 10s
      retries: 3

  immich-machine-learning:
    container_name: immich_machine_learning
    image: ghcr.io/immich-app/immich-machine-learning:release
    volumes:
      - /storage/Immich/model-cache:/cache
    environment:
      - MACHINE_LEARNING_WORKERS=1
      - MACHINE_LEARNING_CACHE_FOLDER=/cache
    restart: unless-stopped
    networks:
      - immich_internal
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:3003']
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    container_name: redis
    image: docker.io/redis:6.2-alpine@sha256:905c4ee67b8e0aa955331960d2aa745781e6bd89afc44a8584bfd13bc890f0ae
    networks:
      - immich_internal
    healthcheck:
      test: redis-cli ping || exit 1
    restart: unless-stopped

  database:
    container_name: database
    image: docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0
    environment:
      - POSTGRES_PASSWORD=immich123
      - POSTGRES_USER=postgres
      - POSTGRES_DB=immich
      - POSTGRES_INITDB_ARGS=--data-checksums
    volumes:
      - /storage/Immich/database:/var/lib/postgresql/data
    networks:
      - immich_internal
    healthcheck:
      test: >-
        pg_isready --dbname="$${POSTGRES_DB}" --username="$${POSTGRES_USER}" || exit 1;
        Chksum="$$(psql --dbname="$${POSTGRES_DB}" --username="$${POSTGRES_USER}" --tuples-only --no-align
        --command='SELECT COALESCE(SUM(checksum_failures), 0) FROM pg_stat_database')";
        echo "checksum failure count is $$Chksum";
        [ "$$Chksum" = '0' ] || exit 1
      interval: 5m
      start_interval: 30s
      start_period: 5m
    command: >-
      postgres
      -c shared_preload_libraries=vectors.so
      -c 'search_path="$$user", public, vectors'
      -c logging_collector=on
      -c max_wal_size=2GB
      -c shared_buffers=512MB
      -c wal_compression=on
    restart: unless-stopped

networks:
  proxy:
    external: true
  immich_internal:
    name: immich_internal
```

### Storage Configuration

Immich data is stored on the Btrfs subvolume at `/storage/Immich` with the following structure:

- `/storage/Immich/uploads`: Photo and video storage
- `/storage/Immich/database`: PostgreSQL database
- `/storage/Immich/model-cache`: ML model cache for face recognition and object detection

## Integration with Authentik

Immich is integrated with Authentik for Single Sign-On (SSO) authentication, providing centralized user management.

### Authentik Provider Configuration

1. **OAuth2/OpenID Provider**:

   - Name: Immich OAuth
   - Client Type: Confidential
   - Client ID: [Client ID configured in Authentik]
   - Redirect URIs: https://photos.alimunee.com/auth/login
   - Scopes: openid, profile, email

2. **Application Configuration**:
   - Name: Immich
   - Provider: Immich OAuth
   - Launch URL: https://photos.alimunee.com

### Immich OAuth Configuration

In Immich, OAuth is configured with the following settings:

- OAuth Enabled: Yes
- OAuth Auto Register: Yes
- OAuth Auto Register Admin: No
- OAuth Issuer URL: https://auth.alimunee.com/application/o/immich/
- OAuth Client ID: [Client ID from Authentik]
- OAuth Client Secret: [Client Secret from Authentik]
- OAuth Scope: openid profile email
- OAuth Storage Label: authentik

### Group-Based Access Control

Access to Immich is restricted to members of the "Immich Users" group in Authentik. This is configured by:

1. Creating an "Immich Users" group in Authentik
2. Adding authorized users to this group
3. Binding the group directly to the Immich application

## Machine Learning Configuration

Immich's machine learning capabilities are enhanced with custom models:

- **Face Recognition Model**: XLM-Roberta-Large-Vit-B-16Plus (upgraded from default)
- **Object Detection Model**: AntelopeV2 (upgraded from default)

These models provide improved accuracy for:

- Facial recognition
- Person detection
- Object and scene classification
- Image search capabilities

## User Management

Users are provisioned through Authentik's invitation system:

1. Administrator creates a user in Authentik
2. User is added to the "Immich Users" group
3. An invitation is generated and sent to the user
4. User sets up their own password through the invitation link
5. User can then access Immich through SSO

## Import Methods

Several methods are available for importing photos into Immich:

1. **Web Interface Upload**: Direct upload through the Immich web UI
2. **Mobile App Backup**: Configure the Immich mobile app to back up photos
3. **Google Takeout Import**: Using Google Takeout to export photos and import them into Immich
4. **Immich CLI**: Command-line tool for bulk imports

## Maintenance Procedures

### Backup Procedures

Immich data is backed up through the Btrfs snapshot system:

- Daily snapshots of the Immich subvolume
- Snapshot retention: 7 daily, 4 weekly, 2 monthly
- Maximum snapshot space: 25% of volume

### Monitoring

The Immich stack is monitored through:

- Container health checks
- Integration with Uptime Kuma for availability monitoring
- Traefik for HTTP status monitoring

## Mobile App Configuration

The Immich mobile app can be configured to connect to the server:

1. Download the app from Google Play Store or Apple App Store
2. Enter server URL: https://photos.alimunee.com
3. Log in with Authentik credentials
4. Configure backup settings:
   - Select albums to back up
   - Set backup conditions (Wi-Fi only, charging only, etc.)
   - Configure background backup frequency
