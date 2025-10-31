# BookLore - Personal Book Collection Manager

## Purpose
BookLore is a self-hosted w application for organizing and managing your personal book collection. It provides an intuitive interface to browse, read, and track your progress across PDFs and eBooks with robust metadata management, multi-user support, and a modern UI for building and exploring your personal library.

## Configuration

### Environment Variables
| Variable            | Description                   | Default                                  | Required |
| ------------------- | ----------------------------- | ---------------------------------------- | -------- |
| USER_ID             | User ID for file permissions  | 1000                                     | Yes      |
| GROUP_ID            | Group ID for file permissions | 1000                                     | Yes      |
| TZ                  | Timezone setting              | Asia/Kuala_Lumpur                        | Yes      |
| DATABASE_URL        | MariaDB connection string     | jdbc:mariadb://booklore-db:3306/booklore | Yes      |
| DATABASE_USERNAME   | Database username             | booklore                                 | Yes      |
| DATABASE_PASSWORD   | Database password             | From .env file                           | Yes      |
| BOOKLORE_PORT       | Application port              | 6060                                     | Yes      |
| MYSQL_ROOT_PASSWORD | MariaDB root password         | From .env file                           | Yes      |

### Ports
- **6060**: Web interface port

### Domains
- **External**: https://books.alimunee.com
- **Internal**: http://booklore:6060

## Dependencies
- **Networks**: proxy (Traefik routing), booklore_internal (database), mail_network (notifications)
- **Database**: MariaDB 11.4.5 (included in stack)
- **Storage**: /storage/media/books for book files
- **External Services**: Postfix (for email notifications)

## Setup

### 1. Create Storage Directories
```bash
sudo mkdir -p /storage/data/booklore/{data,db,bookdrop}
sudo mkdir -p /storage/media/books
sudo chown -R 1000:1000 /storage/data/booklore/
sudo chown -R 1000:1000 /storage/media/books/
```

### 2. Configure Environment
```bash
cd /HOMELAB/services/booklore
# Edit .env file to set secure passwords
nano .env
```

### 3. Deploy Service
```bash
cd /HOMELAB/services/booklore
docker compose up -d
```

### 4. Initial Configuration
1. Access https://library.alimunee.com
2. Create admin account on first visit
3. Configure library settings:
   - Set up book directories
   - Configure metadata providers (Goodreads, Google Books, etc.)
   - Enable desired features (OPDS, Kobo sync, etc.)
4. Set up user permissions and access controls

## Usage

### Web Interface
- **URL**: https://books.alimunee.com
- **Features**:
  - Smart organization with custom shelves and filters
  - Built-in reader for PDFs, EPUBs, and comics
  - Progress tracking and reading statistics
  - Multi-user management with granular permissions
  - Magic Shelves (dynamic, rule-based collections)
  - Auto metadata fetching from multiple sources

### BookDrop Auto-Import
Drop files into `/storage/data/booklore/bookdrop/` for automatic import:
- Supported formats: PDF, EPUB, CBZ, CBR, MOBI, AZW3
- Automatic metadata extraction and enrichment
- Bulk import capabilities

### Supported Features
- **Reading**: Built-in reader with customizable themes
- **Organization**: Custom shelves, tags, and smart collections
- **Sync**: Kobo device integration and KOReader sync
- **Sharing**: Email delivery and OPDS feeds
- **Social**: Community reviews and ratings integration

## Integration

### OPDS Feed
- **URL**: https://books.alimunee.com/opds
- Compatible with reading apps and e-readers

### Kobo Integration
- Seamless sync with Kobo devices
- Automatic EPUB to KEPUB conversion
- Reading progress synchronization

### KOReader Sync
- Track reading progress across devices
- Sync annotations and bookmarks

### Email Delivery
Configure SMTP for sending books to devices:
- **SMTP Server**: postfix
- **Port**: 25
- **From Address**: books@alimunee.com

### SSO Integration (Optional)
Supports external OIDC providers:
- Compatible with Zitadel
- Flexible authentication options

## Troubleshooting

### Common Issues

#### Database Connection Errors
```bash
# Check database container status
docker logs booklore-db

# Verify database connectivity
docker exec booklore-db mariadb-admin ping -h localhost

# Check network connectivity
docker exec booklore nc -zv booklore-db 3306
```

#### BookDrop Not Processing Files
```bash
# Check bookdrop directory permissions
ls -la /storage/data/booklore/bookdrop/
sudo chown -R 1000:1000 /storage/data/booklore/bookdrop/

# Check container logs for processing errors
docker logs booklore
```

#### Metadata Fetching Issues
```bash
# Verify internet connectivity from container
docker exec booklore curl -I https://www.goodreads.com

# Check API configuration in web interface
# Verify rate limiting and API keys if required
```

#### Performance Issues
```bash
# Check database performance
docker exec booklore-db mariadb -u booklore -p -e "SHOW PROCESSLIST;"

# Monitor resource usage
docker stats booklore booklore-db

# Check disk space
df -h /storage/data/booklore/
```

### Health Check
```bash
# Test service health
curl -f http://localhost:6060/health

# Check container status
docker compose ps

# Verify database health
docker exec booklore-db mariadb-admin ping -h localhost
```

## Backup

### Data to Backup
- **Application Data**: `/storage/data/booklore/data/`
- **Database**: `/storage/data/booklore/db/`
- **Book Files**: `/storage/media/books/`
- **Configuration**: `.env` file

### Backup Commands
```bash
# Stop services for consistent backup
docker compose down

# Backup application data and database
sudo tar -czf booklore-backup-$(date +%Y%m%d).tar.gz -C /storage/data booklore/

# Backup book files (if needed)
sudo tar -czf booklore-books-$(date +%Y%m%d).tar.gz -C /storage/media books/

# Restart services
docker compose up -d
```

### Restore Process
1. Stop the services: `docker compose down`
2. Restore data: `sudo tar -xzf booklore-backup.tar.gz -C /storage/data/`
3. Restore books: `sudo tar -xzf booklore-books-backup.tar.gz -C /storage/media/`
4. Fix permissions: `sudo chown -R 1000:1000 /storage/data/booklore/ /storage/media/books/`
5. Start services: `docker compose up -d`
6. Verify database integrity and re-scan library if needed

## Performance Optimization
- Use SSD storage for database and application data
- Configure MariaDB memory settings based on available RAM
- Regular database maintenance and optimization
- Monitor and adjust container resource limits
- Consider separate storage tiers for frequently vs. rarely accessed books

## Security Considerations
- Change default passwords in .env file
- Configure user permissions appropriately
- Enable HTTPS through Traefik
- Regular security updates via Watchtower
- Consider enabling two-factor authentication if supported
