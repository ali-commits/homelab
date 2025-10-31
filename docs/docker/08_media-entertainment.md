# Media & Entertainment Services

## Overview

Complete media automation, streaming, and library management stack with GPU acceleration.

## Media Automation Stack (*arr Services)

### Core Services
- **Prowlarr** - Indexer manager ([📖](../../services/prowlarr/documentation.md))
- **Radarr** - Movie collection manager ([📖](../../services/radarr/documentation.md))
- **Sonarr** - TV show collection manager ([📖](../../services/sonarr/documentation.md))
- **Bazarr** - Subtitle management ([📖](../../services/bazarr/documentation.md))
- **Jellyseerr** - Media request management ([📖](../../services/jellyseerr/documentation.md))

### Download & Processing
- **qBittorrent** - Download client ([📖](../../services/qbit/documentation.md))
- **Flood** - Modern qBittorrent web UI ([📖](../../services/flood/documentation.md))
- **Flaresolverr** - Cloudflare bypass service ([📖](../../services/flaresolverr/documentation.md))

## Media Streaming

### Jellyfin - Media Streaming Server
- **Purpose**: Self-hosted media streaming with GPU transcoding
- **Port**: 8096
- **Domain**: tv.alimunee.com
- **GPU**: NVIDIA GTX 1070 (NVENC/NVDEC)
- **Features**: Hardware transcoding, live TV, mobile apps
- **Documentation**: [📖](../../services/jellyfin/documentation.md)

#### GPU Acceleration Features
- **Hardware Transcoding**: H.264, HEVC encoding/decoding
- **Performance**: 3-5x faster than CPU transcoding
- **Concurrent Streams**: Multiple simultaneous transcodes

## Digital Libraries

### Kavita - Comics & Manga Library
- **Purpose**: Digital library for comics, manga, and ebooks
- **Domain**: comics.alimunee.com
- **Formats**: CBZ, CBR, PDF, EPUB
- **Documentation**: [📖](../../services/kavita/documentation.md)

### BookLore - Book Collection Manager
- **Purpose**: Personal book collection management with AI features
- **Domain**: books.alimunee.com
- **Database**: MariaDB
- **Features**: AI metadata, email delivery, auto-import
- **Documentation**: [📖](../../services/booklore/documentation.md)

## Media Storage Structure

```
/storage/media/
├── movies/                 → Movie collection (Radarr → Jellyfin)
├── tv/                     → TV show collection (Sonarr → Jellyfin)
├── anime/                  → Anime collection (Sonarr → Jellyfin)
├── books/                  → Book collection (BookLore, Kavita)
├── comics/                 → Comic collection (Kavita)
├── manga/                  → Manga collection (Kavita)
└── downloads/              → qBittorrent download directory
```

## Media Workflow

### Complete Media Acquisition Flow
```
1. User Request → Jellyseerr
2. Request Approval → Radarr/Sonarr
3. Indexer Search → Prowlarr
4. Download → qBittorrent
5. Processing → Radarr/Sonarr
6. Organization → Media Library
7. Subtitle Download → Bazarr
8. Streaming → Jellyfin
```

## GPU Acceleration

### Jellyfin NVENC Configuration
- **GPU**: NVIDIA GTX 1070 (8GB VRAM)
- **Driver**: NVIDIA 580.95.05 with CUDA 13.0
- **Supported Codecs**: H.264, HEVC hardware encode/decode

### Performance Benefits
- **Transcoding Speed**: 3-5x faster than CPU
- **Power Consumption**: 50% reduction vs CPU transcoding
- **Concurrent Streams**: Up to 6-8 simultaneous transcodes

---

*For detailed service configuration and troubleshooting, refer to individual service documentation and [troubleshooting.md](troubleshooting.md)*
