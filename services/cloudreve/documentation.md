# Cloudreve - Cloud Storage Platform

**Purpose**: Self-hosted cloud storage platform with web interface and multi-storage backend support

## Service Information

- **Container Image**: `cloudreve/cloudreve:latest`
- **External URL**: https://files.alimunee.com
- **Internal Port**: 5212
- **Purpose**: Personal cloud storage with file management, sharing, and multi-backend support

## Features

- 🗂️ **File Management**: Web-based file browser with upload, download, and organization
- 🔗 **File Sharing**: Share files and folders with customizable permissions
- 📱 **Multi-Platform**: Web interface with mobile-responsive design
- 💾 **Multiple Storage Backends**: Local, S3, OneDrive, Google Drive, and more
- 👥 **User Management**: Multi-user support with role-based access control
- 🎨 **Customizable**: Themes and branding customization
- 📊 **Storage Quotas**: Per-user storage limits and monitoring
- 🔐 **Security**: File encryption and secure sharing options

## Configuration

### Directory Structure
```
/storage/data/cloudreve/           # Application data and configuration
/storage/data/cloudreve/database/  # PostgreSQL database
/storage/data/cloudreve/redis/     # Redis cache data
/storage/cloudreve/uploads/        # User uploaded files
```

### Database Configuration
- **Type**: PostgreSQL 17
- **Database**: cloudreve
- **User**: cloudreve
- **Cache**: Redis 7 (Alpine)

### Volume Mounts
- `/storage/data/cloudreve:/cloudreve/data` - Application configuration and metadata
- `/storage/cloudreve/uploads:/cloudreve/uploads` - User file storage
- Database and Redis data stored in respective subdirectories

## Setup Instructions

### 1. Create Required Directories
```bash
# Create data directories
sudo mkdir -p /storage/data/cloudreve/{database,redis}
sudo mkdir -p /storage/cloudreve/uploads
sudo chown -R ali:ali /storage/data/cloudreve /storage/cloudreve
```

### 2. Configure Environment Variables
The service uses a `.env` file for database configuration:
```bash
# Cloudreve Database Configuration
POSTGRES_PASSWORD=cloudreve_secure_db_2024
```

### 3. Deploy Service
```bash
cd /HOMELAB/services/cloudreve
docker compose up -d
```

### 4. Initial Setup
1. Navigate to: https://files.alimunee.com
2. Complete the initial setup wizard:
   - Set administrator account credentials
   - Configure storage settings
   - Set site preferences

## Network Configuration

- **Web Interface**: Port 5212
- **Domain**: files.alimunee.com
- **Networks**:
  - `proxy` - Traefik reverse proxy access
  - `cloudreve_internal` - Internal service communication
  - `db_network` - Database network (shared with other services)

## Storage Configuration

### Storage Policies
Cloudreve supports multiple storage backends that can be configured through the admin panel:

1. **Local Storage** (Default):
   - Path: `/cloudreve/uploads`
   - Suitable for: Personal use, direct file access

2. **Remote Storage** (Optional):
   - S3-compatible services
   - OneDrive, Google Drive
   - FTP/SFTP servers
   - WebDAV

### File Management Features
- **File Versioning**: Track file changes and restore previous versions
- **Folder Sharing**: Share entire folders with customizable permissions
- **Download Links**: Generate temporary or permanent download links
- **File Preview**: Built-in preview for images, documents, and videos
- **Bulk Operations**: Upload, download, and manage multiple files

## User Management

### Default Admin Account
- Created during initial setup
- Full system administration privileges
- Can create and manage other users

### User Roles
- **Administrator**: Full system control
- **User**: Standard file access with quotas
- **Guest**: Limited access for shared content

### Quota Management
- Set storage limits per user or group
- Monitor usage through admin dashboard
- Automatic enforcement of limits

## Security Considerations

- **Access Control**: Role-based permissions system
- **File Encryption**: Optional client-side encryption
- **Secure Sharing**: Password-protected and time-limited shares
- **Zitadel Integration**: Can be configured for SSO (commented out in compose file)
- **Network Isolation**: Runs on isolated internal network
- **Database Security**: Separate database user and network isolation

## Integration with Homelab

### Backup Strategy
- **Application Data**: Included in `/storage/data/cloudreve` (covered by system snapshots)
- **User Files**: Stored in `/storage/cloudreve/uploads` (should be included in backup strategy)
- **Database**: PostgreSQL data automatically backed up with system

### Monitoring Integration
- **Health Checks**: Built-in health endpoints for all services
- **Uptime Kuma**: Add monitoring for https://files.alimunee.com
- **Resource Monitoring**: Monitor storage usage and database performance

### Notification Integration
Configure ntfy notifications for:
- Storage quota warnings
- Failed uploads/downloads
- System maintenance alerts

## Troubleshooting

### Common Issues

1. **Permission denied errors**:
   ```bash
   sudo chown -R ali:ali /storage/data/cloudreve /storage/cloudreve
   ```

2. **Database connection issues**:
   ```bash
   docker logs cloudreve_database
   docker logs cloudreve
   ```

3. **Storage not accessible**:
   ```bash
   # Check mount points and permissions
   ls -la /storage/cloudreve/
   df -h /storage/cloudreve/
   ```

4. **Service not starting**:
   ```bash
   # Check all service logs
   docker logs cloudreve
   docker logs cloudreve_database
   docker logs cloudreve_redis
   ```

### Useful Commands

```bash
# Check service status
docker ps | grep cloudreve

# View logs
docker logs cloudreve -f

# Access database
docker exec -it cloudreve_database psql -U cloudreve -d cloudreve

# Check Redis cache
docker exec -it cloudreve_redis redis-cli info

# Restart services
cd /HOMELAB/services/cloudreve
docker compose restart

# Update services
docker compose pull && docker compose up -d
```

## Performance Optimization

### Recommended Settings
- **Redis Cache**: Configured for session and metadata caching
- **Database**: PostgreSQL with data checksums enabled
- **File Storage**: Use SSD storage for better performance
- **Network**: Isolated networks for security and performance

### Scaling Considerations
- **Storage**: Can be expanded by adding more storage backends
- **Performance**: Redis caching improves response times
- **Backup**: Regular database and file backups recommended

## Admin Tasks

### Regular Maintenance
1. **Monitor Storage Usage**: Check user quotas and overall storage
2. **Clean Temporary Files**: Remove expired shares and temporary uploads
3. **Database Maintenance**: Regular VACUUM and ANALYZE operations
4. **Update Management**: Keep container images updated via Watchtower

### Configuration Management
- **Admin Panel**: https://files.alimunee.com/admin
- **User Management**: Create, modify, and delete user accounts
- **Storage Policies**: Configure and manage storage backends
- **System Settings**: Customize appearance and functionality

## Links

- **GitHub**: https://github.com/cloudreve/Cloudreve
- **Documentation**: https://docs.cloudreve.org/
- **Docker Hub**: https://hub.docker.com/r/cloudreve/cloudreve
- **Community**: https://github.com/cloudreve/Cloudreve/discussions
