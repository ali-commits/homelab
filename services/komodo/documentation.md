# Komodo

**Purpose**: A self-hostable, open-source, and feature-rich DevOps platform.

**Components**:

1.  **Core**:
    *   The main web interface and API.
    *   Handles user authentication, resource management, and serves the frontend.
    *   Port: 9120

2.  **Periphery**:
    *   The agent that runs on managed servers.
    *   Collects system stats, manages containers, and executes tasks.

3.  **Database (MongoDB)**:
    *   Stores all application data, including users, resources, and configurations.

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | https://komodo.alimunee.com           |
| TLS               | Disabled internally (handled by Traefik/Cloudflare) |
| Authentication    | Local authentication enabled.         |

**Data Persistence**:

-   `/storage/data/komodo/mongo/data`: MongoDB data files.
-   `/storage/data/komodo/mongo/config`: MongoDB configuration.
-   `/storage/data/komodo/core/repo-cache`: Cache for Git repositories.
-   `/storage/data/komodo/periphery/ssl`: SSL certificates for Periphery.
-   `/storage/data/komodo/periphery/repos`: Git repository management.
-   `/storage/data/komodo/periphery/stacks`: Docker stack files.

**Network Configuration**:

-   Connected to `proxy` network for external access via Traefik.
-   Uses `komodo_internal` network for communication between the Core, Periphery, and MongoDB containers.
