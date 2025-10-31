# Kavita - Digital Library Management

## Purpose
Kavita is a lightning-fast, self-hosted dil library server designed for managing comics, manga, and ebooks. It provides a modern web interface for organizing, reading, and tracking your digital reading collection with support for various file formats including CBZ, CBR, PDF, EPUB, and more.

## Configuration

### Environment Variables
| Variable | Description                   | Default           | Required |
| -------- | ----------------------------- | ----------------- | -------- |
| PUID     | User ID for file permissions  | 1000              | Yes      |
| PGID     | Group ID for file permissions | 1000              | Yes      |
| TZ       | Timezone setting              | Asia/Kuala_Lumpur | Yes      |

### Ports
- **5000**: Web interface port

### Domains
- **External**: https://comics.alimunee.com
- **Internal**: http://kavita:5000

## Dependencies
- **Networks**: proxy (for Traefik routing)
- **Storage**: /storage/media/ directories for books, comics, manga
- **External Services**: None

## Setup

### 1. Create Storage Directories
```bash
sudo mkdir -p /storage/data/kavita/config
sudo mkdir -p /storage/media/{books,comics,manga}
sudo chown -R 1000:1000 /storage/data/kavita/
sudo chown -R 1000:1000 /storage/media/{books,comics,manga}
```

### 2. Deploy Service
```bash
cd /HOMELAB/services/kavita
docker compose up -d
```

### 3. Initial Configuration
1. Access https://comics.alimunee.com
2. Create admin account on first visit
3. Add libraries pointing to:
   - Books: `/books`
   - Comics: `/comics`
   - Manga: `/manga`
4. Configure metadata providers (optional)
5. Set up reading preferences

## Usage

### Web Interface
- **URL**: https://comics.alimunee.com
- **Features**:
  - Browse library by series, collections, or reading lists
  - Built-in reader with customizable settings
  - Progress tracking and bookmarks
  - User management and permissions
  - OPDS feed support for external readers

### Supported Formats
- **Comics/Manga**: CBZ, CBR, CB7, CBT
- **Books**: PDF, EPUB
- **Archives**: ZIP, RAR, 7Z, TAR

### Library Organization
Organize files in the following structure:
```
/storage/media/
├── books/
│   ├── Author Name/
│   │   └── Book Title/
│   │       └── book.pdf
├── comics/
│   ├── Series Name/
│   │   ├── Volume 01/
│   │   │   └── issue001.cbz
└── manga/
    ├── Manga Title/
    │   ├── Volume 01/
    │   │   └── chapter001.cbz
```

## Integration

### OPDS Feed
- **URL**: https://comics.alimunee.com/api/opds
- Compatible with reading apps like Chunky Reader, ComicRack, etc.

### User Management
- Create users with different permission levels
- Set library access restrictions per user
- Configure age ratings and content filtering

## Troubleshooting

### Common Issues

#### Library Not Scanning
```bash
# Check file permissions
ls -la /storage/media/books/
sudo chown -R 1000:1000 /storage/media/{books,comics,manga}

# Check container logs
docker logs kavita
```

#### Web Interface Not Accessible
```bash
# Verify container is running
docker ps | grep kavita

# Check Traefik routing
curl -I http://localhost:5000/
```

#### Slow Performance
- Ensure files are on fast storage (SSD preferred)
- Check available memory and CPU resources
- Consider enabling thumbnail generation limits

### Health Check
```bash
# Test service health
curl -f http://localhost:5000/

# Check container status
docker compose ps
```

## Backup

### Data to Backup
- **Configuration**: `/storage/data/kavita/config/`
- **Database**: Included in config directory
- **Media Files**: `/storage/media/{books,comics,manga}/`

### Backup Commands
```bash
# Backup configuration
sudo tar -czf kavita-config-$(date +%Y%m%d).tar.gz -C /storage/data/kavita config/

# Backup media (if needed)
sudo rsync -av /storage/media/ /backup/location/media/
```

### Restore Process
1. Stop the service: `docker compose down`
2. Restore configuration: `sudo tar -xzf kavita-config-backup.tar.gz -C /storage/data/kavita/`
3. Restore media files if needed
4. Start the service: `docker compose up -d`
5. Verify library scanning completes

## Performance Optimization
- Use SSD storage for configuration and database
- Enable hardware acceleration if available
- Configure appropriate memory limits
- Regular database maintenance through web interface
