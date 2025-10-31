# Storage & Volume

## Overview

Cove storage architecture using Btrfs filesystem with Docker volumes for persistent data management across all homelab services.

## Storage Architecture

### Host Storage Structure
```
/storage/
├── data/               → System & service data (NVMe SSD)
│   ├── jellyfin/      → Jellyfin config & metadata
│   ├── immich/        → Immich ML models & cache
│   ├── dockge/        → Container management data
│   ├── booklore/      → BookLore config & database
│   ├── karakeep/      → Karakeep data & search index
│   ├── paperless-ngx/ → Paperless config & database
│   ├── stirling-pdf/  → PDF processing config
│   ├── kavita/        → Digital library config
│   └── [services]/    → Individual service data
├── media/             → Media library (HDD)
│   ├── movies/        → Movie collection
│   ├── tv/            → TV show collection
│   ├── anime/         → Anime collection
│   ├── books/         → Book collection (BookLore, Kavita)
│   ├── comics/        → Comic collection (Kavita)
│   ├── manga/         → Manga collection (Kavita)
│   └── downloads/     → qBittorrent downloads
├── Immich/            → Photo storage (HDD)
│   └── uploads/       → Photo & video uploads
├── nextcloud/         → Nextcloud storage (HDD)
│   ├── data/          → User files
│   └── config/        → Nextcloud configuration
└── shared/            → Shared between services (HDD)
```

## Volume Mapping Strategy

### Storage Tiers
| Volume Type          | Host Path                  | Storage Type | Purpose                           |
| -------------------- | -------------------------- | ------------ | --------------------------------- |
| **System Data**      | `/storage/data/service`    | NVMe SSD     | Service configuration & databases |
| **Media Files**      | `/storage/media/*`         | HDD          | Media library storage             |
| **Photo Storage**    | `/storage/Immich/*`        | HDD          | Photo & video uploads             |
| **Cloud Storage**    | `/storage/nextcloud/*`     | HDD          | Nextcloud files                   |
| **Document Storage** | `/storage/paperless-ngx/*` | HDD          | Document archive                  |
| **Shared Data**      | `/storage/shared/*`        | HDD          | Cross-service data                |

### Common Volume Patterns
| Container Path                | Purpose                   | Example Host Path              |
| ----------------------------- | ------------------------- | ------------------------------ |
| `/config`                     | Service configuration     | `/storage/data/service/config` |
| `/data`                       | Application data          | `/storage/data/service/data`   |
| `/app/data`                   | Application-specific data | `/storage/data/service/data`   |
| `/var/lib/[database]`         | Database files            | `/storage/data/service/db`     |
| `/movies`, `/tv`, `/anime`    | Media library             | `/storage/media/movies`, etc.  |
| `/books`, `/comics`, `/manga` | Digital library           | `/storage/media/books`, etc.   |

## Database Storage

### Database Storage Locations

| Service           | Database Type         | Storage Location                   |
| ----------------- | --------------------- | ---------------------------------- |
| **Immich**        | PostgreSQL (pgvector) | `/storage/data/immich/database`    |
| **Nextcloud**     | PostgreSQL            | `/storage/data/nextcloud/db`       |
| **Paperless-ngx** | PostgreSQL            | `/storage/data/paperless-ngx/db`   |
| **Zitadel**       | PostgreSQL            | `/storage/data/zitadel/zitadel-db` |
| **Karakeep**      | PostgreSQL            | `/storage/data/karakeep/db`        |
| **Firefly III**   | PostgreSQL            | `/storage/data/firefly-iii/db`     |
| **Infisical**     | PostgreSQL            | `/storage/data/infisical/db`       |
| **OnlyOffice**    | PostgreSQL            | `/storage/data/onlyoffice/db`      |
| **N8N**           | PostgreSQL            | `/storage/data/n8n/db`             |
| **Cloudreve**     | PostgreSQL            | `/storage/data/cloudreve/database` |
| **AFFiNE**        | PostgreSQL            | `/storage/data/affine/db`          |
| **Linkwarden**    | PostgreSQL            | `/storage/data/linkwarden/db`      |
| **BookLore**      | MariaDB               | `/storage/data/booklore/db`        |
| **Komodo**        | MongoDB               | `/storage/data/komodo/mongo`       |

### Database Volume Configuration
```yaml
# PostgreSQL example
volumes:
  - /storage/data/[service]/db:/var/lib/postgresql/data

# MariaDB example
volumes:
  - /storage/data/booklore/db:/var/lib/mysql

# MongoDB example
volumes:
  - /storage/data/komodo/mongo:/data/db
```

## Service-Specific Storage

### Media Services
```yaml
# Jellyfin
volumes:
  - /storage/data/jellyfin:/config
  - /storage/media/movies:/movies:ro
  - /storage/media/tv:/tv:ro
  - /storage/media/anime:/anime:ro

# *arr Services (Radarr, Sonarr)
volumes:
  - /storage/data/[service]:/config
  - /storage/media:/media

# qBittorrent
volumes:
  - /storage/data/qbit:/config
  - /storage/media/downloads:/downloads
```

### Productivity Services
```yaml
# Nextcloud
volumes:
  - /storage/nextcloud/data:/var/www/html
  - /storage/nextcloud/config:/var/www/html/config

# Paperless-ngx
volumes:
  - /storage/data/paperless-ngx:/usr/src/paperless/data
  - /storage/paperless-ngx/media:/usr/src/paperless/media
  - /storage/paperless-ngx/consume:/usr/src/paperless/consume
  - /storage/paperless-ngx/export:/usr/src/paperless/export

# Syncthing
volumes:
  - /storage/data/syncthing/config:/var/syncthing/config
  - /storage/syncthing:/var/syncthing/data
```

### AI/ML Services
```yaml
# Immich
volumes:
  - /storage/data/immich:/usr/src/app/upload
  - /storage/Immich:/usr/src/app/external

# Karakeep
volumes:
  - /storage/data/karakeep:/app/data

# Paperless-GPT
volumes:
  - /storage/data/paperless-gpt/prompts:/app/prompts
  - /storage/data/paperless-gpt/pdf:/app/pdf
```

## Filesystem Configuration

### Btrfs Features
- **Compression**: Transparent compression (zstd) for space efficiency
- **Snapshots**: Automated snapshots via Snapper for data protection
- **Subvolumes**: Separate subvolumes for different data types
- **RAID**: No RAID (single disk setup)

### Storage Performance
- **NVMe SSD**: `/storage/data/` - High-performance storage for databases and configs
- **HDD**: `/storage/media/`, `/storage/nextcloud/`, etc. - Large capacity for media and documents
- **Compression**: Reduces storage usage by 20-40% depending on data type

### Permissions Management
```bash
# Standard ownership for most services
sudo chown -R 1000:1000 /storage/data/[service]/

# Media files (readable by media services)
sudo chown -R 1000:1000 /storage/media/

# Specific service permissions
sudo chown -R 999:999 /storage/data/[service]/db/  # PostgreSQL
sudo chown -R 1001:1001 /storage/data/komodo/mongo/  # MongoDB
```

## Backup Strategy

### Data Classification
| Data Type         | Backup Priority | Backup Method                 | Retention |
| ----------------- | --------------- | ----------------------------- | --------- |
| **Databases**     | Critical        | Daily dumps + Btrfs snapshots | 30 days   |
| **Configuration** | High            | Weekly tar archives           | 90 days   |
| **Media Files**   | Medium          | Periodic rsync to external    | 1 year    |
| **Cache/Temp**    | Low             | No backup                     | -         |

### Backup Locations
```bash
# Database backups
/storage/backups/databases/YYYYMMDD/

# Configuration backups
/storage/backups/configs/YYYYMMDD/

# Btrfs snapshots
/.snapshots/
```

## Volume Management

### Creating Storage Directories
```bash
# Create service data directories
sudo mkdir -p /storage/data/[service]/{config,data,db}

# Create media directories
sudo mkdir -p /storage/media/{movies,tv,anime,books,comics,manga,downloads}

# Set proper ownership
sudo chown -R 1000:1000 /storage/data/[service]/
sudo chown -R 1000:1000 /storage/media/
```

### Volume Cleanup
```bash
# Remove unused volumes
docker volume prune

# Check volume usage
docker system df -v

# Remove specific volumes (when service is down)
docker volume rm [service]_[volume_name]
```

### Storage Monitoring
```bash
# Check storage usage
df -h /storage/

# Btrfs filesystem usage
sudo btrfs fi usage /storage/

# Service-specific usage
du -sh /storage/data/*/
du -sh /storage/media/*/
```

## Troubleshooting Storage Issues

### Common Issues
| Issue                   | Diagnosis                         | Solution                                  |
| ----------------------- | --------------------------------- | ----------------------------------------- |
| **Permission denied**   | `ls -la /storage/data/[service]/` | Fix ownership: `chown -R 1000:1000 /path` |
| **Disk full**           | `df -h /storage/`                 | Clean up old data, expand storage         |
| **Database corruption** | Check database logs               | Restore from backup                       |
| **Slow performance**    | `iotop`, `btrfs fi usage`         | Check disk I/O, defragment if needed      |

### Diagnostic Commands
```bash
# Storage health
df -h /storage/
sudo btrfs fi show
sudo btrfs fi usage /storage/

# Permission check
ls -la /storage/data/[service]/

# Volume inspection
docker volume ls
docker volume inspect [volume_name]

# Service storage usage
docker exec [service] df -h
```

---

*For service-specific storage configuration, refer to individual service documentation in `/services/[service-name]/documentation.md`*
