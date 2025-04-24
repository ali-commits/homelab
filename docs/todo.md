# Homelab Setup Checklist

## Prerequisites

### Hardware Verification

- [x] Test RAM stability (using Memtest86+)
- [x] Check SSD/HDD SMART status and perform thorough diagnostics
- [x] Verify all motherboard ports are functioning
- [x] Ensure proper cooling (clean fans, fresh thermal paste)

### BIOS/UEFI Setup

- [x] Enable virtualization support (SVM for AMD)
- [x] Configure optimal RAM timings
- [x] Set up proper boot order
- [x] Disable unnecessary peripherals to save resources

### Pre-Installation Planning

- [x] Download installation media (debian)
- [x] Prepare a backup solution for existing data
- [x] Document network details (IP ranges, DNS settings)
- [x] Create bootable USB with installation media (ventoy)

## OS setup

### Base System Installation

- [x] OS installation with proper partition scheme
- [x] Initial system configuration
- [x] Network setup (static IP, DNS, etc.)
- [x] Install essential packages (`sudo`, `htop`, `vim`, etc.)
- [x] Set up SSH access with key-based authentication

### Storage Configuration

- [x] Implement planned btrfs setup
- [x] Configure bcache
- [x] Set up snapshots and cleanup policies
- [x] Set up snapshots for / on apt upgrade
- [x] Configure storage maintenance timers:
  - [x] btrfs-scrub.timer (monthly full scrub)
  - [x] btrfs-balance.timer (weekly balance)
  - [x] btrfs-trim.timer (weekly TRIM)
- [x] Configure storage monitoring:
  - [x] smartd for drive health
  - [x] btrfs device stats
  - [x] Space usage alerts (80% threshold)
  - [x] SMART attribute monitoring
  - [x] Scrub results monitoring
  - [x] Cache temperature monitoring
  - [x] SSD wear level monitoring
  - [x] Dirty data percentage tracking
- [x] Set up bcache monitoring with performance metrics
- [x] Configure bcache alerts
- [x] Set up per-subvolume snapshot policies
- [x] Configure snapshot quota management

## System Security

- [x] Set up SSH access with key-based authentication
- [x] Configure SSH hardening:
  - [x] Rate limiting
  - [x] Disable root login
- [x] System hardening:
  - [x] Install and configure fail2ban
  - [x] Configure unattended-upgrades
  - [x] Set up needrestart

## Scheduled Tasks

##### Daily Tasks

- [x] SMART status check
- [x] Snapshot cleanup
- [x] System logs check
- [ ] Backup verification

##### Weekly Tasks

- [x] btrfs balance check
- [x] TRIM operation
- [x] Docker cleanup (watchtower)

##### Monthly Tasks

- [x] Full system scrub
- [x] Security audit
- [x] Performance review
- [ ] Backup test restore

### Documentation and Backup

- [x] Document all configurations
  - [x] System layout documented
  - [x] Storage configuration documented
  - [x] Network configuration documented
  - [x] Services configuration documented
  - [ ] Backup procedures
  - [ ] Recovery procedures
- [ ] Set up automated backups
- [x] Create recovery procedures for:
  - [x] Service failures
  - [x] Network issues
  - [x] Container management
  - [ ] Data corruption
  - [ ] Hardware failures

### Monitoring and Maintenance

- [x] Implement monitoring and alerts solutions
  - [x] bcache monitoring (logs)
  - [x] test bcache monitoring (logs)
  - [x] bcache monitoring (ntfy)
  - [x] test bcache monitoring (ntfy)
  - [x] Other system monitoring (Prometheus + Node Exporter)
- [x] Configure automated maintenance tasks

### Monitoring Enhancements

- [ ] Set up Grafana dashboards
- [ ] Configure custom alerting rules
- [ ] Create monitoring documentation
- [ ] Set up log aggregation

## Network Setup

- [x] Configure DNS settings
  - [x] Set up local DNS server (AdGuard)
  - [x] Configure static IP (192.168.1.2/24)
  - [x] Set up interface configuration (enp2s0)
  - [x] Configure default gateway (192.168.1.1)
- [x] Set up secure remote access
  - [x] Configure Cloudflare DNS
  - [x] Set up Cloudflare tunnel
  - [x] Configure SSL/TLS termination
- [ ] Set up network segmentation
  - [x] Create proxy network
  - [x] Create database network
  - [x] Configure container network isolation
  - [ ] Document network dependencies
  - [ ] Create network diagram
- [ ] Configure intrusion detection system (IDS)
- [x] Set up domain (alimunee.com)
  - [x] Configure DNS records in Cloudflare
  - [x] Set up subdomains for services
  - [x] Verify DNS propagation
- [ ] Set up Twingate for secure access
- [ ] Set up Tailscale for secure access

## Services Setup

### Container Infrastructure

- [x] Docker installation and configuration
- [x] Set up Docker Compose
- [x] Create Docker networks (proxy, database)
- [x] Configure Docker logging (json-file with rotation)
- [x] Set up storage driver (btrfs)
- [ ] Create service dependencies map
- [ ] Plan service rollout order
- [ ] Configure container resource limits
- [ ] Container management tools setup
- [x] Network configuration for containers
- [x] Set up portainer
<!-- - [ ] Set up CasaOS?
- [ ] Set up Casmos Cloud? -->

### Services Deployment

- [x] Setup authentication system first
- [x] Deploy core infrastructure (reverse proxy, monitoring):

  - [x] Set up Traefik reverse proxy:

    - [x] Configure Docker integration
    - [x] Set up HTTP endpoints
    - [x] Configure dashboard access
    - [x] Setup Cloudflare integration
    - [ ] ~~Enable HTTPS with Cloudflare~~
    - [ ] Set up middleware chains

  - [x] Set up Cloudflared:

    - [x] Configure tunnel connection
    - [x] Set up tunnel token
    - [x] Set up DNS routing
    - [x] Verify secure access
    - [x] Configure automatic restart
    - [x] Set no-autoupdate flag

  - [x] Deploy Portainer:

    - [x] Configure persistent storage
    - [x] Set up reverse proxy access
    - [x] Enable container management
    - [x] Integrate with authentik for SSO
    - [ ] Configure backup strategy

  - [x] Set up Authentik:

    - [x] Configure PostgreSQL backend
    - [x] Set up Redis cache
    - [x] Configure persistent storage
    - [x] Set up initial admin account
    - [x] Configure proxy settings
    - [x] Set up SSO integrations
    - [ ] Configure backup strategy
    - [ ] customise login page
    - [ ] test 2FA
    - [ ] Set up login with security key (mobile)

  - [ ] Set up AdGuard Home:

    - [x] Configure Docker container with persistent storage
    - [ ] Set up DNS over HTTPS (DoH) upstream servers
    - [x] Configure DNS blacklists and whitelists
    - [x] Enable DNSSEC validation
    - [x] Configure DNS query logging
    - [ ] Integrate with authentication system
    - [ ] Configure automatic updates
    - [x] Document DNS configuration for local network (setup each device)

  - [x] Set up NTFY:

    - [x] Configure Docker container
    - [x] Set up persistent storage
    - [ ] Configure authentication
    - [x] Set up topics for different alerts
    - [x] Integrate with other services
    - [x] download ntfy on phone
    - [x] Test notification delivery
    - [x] setup ntfy for bcache monitoring
    - [x] setup ntfy for system status monitoring (reboot, update, snapshot)

  - [x] Set up Uptime Kuma: (needs to add more endpoints)

    - [x] Configure Docker container
    - [x] Set up persistent storage
    - [x] Configure monitoring endpoints
    - [x] Set up status page
    - [x] Configure notification channels
    - [x] Integrate with NTFY
    - [x] Configure healthcheck
    - [x] Set up no-new-privileges security
    - [x] Set up authentication

  - [ ] Deploy Watchtower:

    - [x] Configure Docker container
    - [x] Set up update schedule (24 hours)
    - [x] Configure container inclusions/exclusions
    - [x] Set up notification settings
    - [x] Set timezone configuration
    - [ ] Configure cleanup policies
    - [x] Enable container health checks
    - [x] Set up logging
    - [ ] Configure restart policies
    - [ ] Document update procedures

- [ ] Deploy Media Server Stack:

  - [x] Set up Jellyfin:

    - [x] Configure Docker container
    - [x] Set up media directories
    - [x] Configure hardware transcoding
    - [x] Set up GPU passthrough
    - [ ] Set up user accounts
    - [x] Configure collections
    - [x] set up chapter image extraction
    - [x] set up trickplay image extraction
    - [x] set up intro auto skip
    - [ ] Integrate with Authentik SSO
    - [x] Set up automatic library scanning

  - [ ] ~~Configure Tdarr:~~

    - [x] ~~Set up Tdarr Server~~
    - [x] ~~Configure GPU access~~
    - [ ] ~~Configure Tdarr Node~~
    - [ ] ~~Set up transcoding workflows~~
    - [ ] ~~Set up health checks~~
    - [ ] ~~Configure notification alerts~~

  - [x] Configure qBittorrent:

    - [x] Set up container
    - [x] change password
    - [x] Configure bandwidth limits
    - [ ] Configure authentication

  - [ ] Deploy \*Arr Stack:

    - [x] Set up Radarr for movies
    - [x] Set up Sonarr for TV shows
    - [x] Configure Prowlarr for indexers
    - [x] Set up Bazarr for subtitles (not fully working)
    - [x] Configure Flaresolverr
    - [x] Set up cross-service communication
    - [x] Configure quality profiles
    - [x] Set up download paths
    - [x] Configure notifications
    - [x] Implement automated library organization

    - [x] Media Storage Configuration:

      - [x] Plan directory structure
      - [x] Set up permissions
      - [x] Configure shared mounts
      - [x] Implement file monitoring

    - [x] Media Stack Integration:
      - [x] Configure service networks
      - [x] Set up access controls
      - [x] Configure service dependencies
      - [x] Set up reverse proxy rules
      - [x] Implement SSO authentication
      - [x] Set up monitoring

  - [x] Deploy File Storage Stack:

    - [x] Set up Nextcloud:

      - [x] Configure Docker container
      - [x] Set up persistent storage
      - [x] Configure database backend
      - [x] Set up admin account
      - [x] Configure reverse proxy
      - [x] Integrate with Authentik SSO
      - [x] Set up automatic updates
      - [x] Configure backup strategy

    - [x] Deploy Immich:
      - [x] Configure Docker container
      - [x] Set up storage volumes
      - [x] Configure database
      - [x] Set up machine learning
      - [x] Configure backup strategy
      - [x] Set up photo import automation
      - [x] Configure face recognition
      - [x] Set up mobile app sync
      - [x] integrate with Authentik SSO (OAuth)

  - [ ] Deploy Document Management Stack:

    - [ ] Set up Paperless-ngx:

      - [ ] Configure container and storage
      - [ ] Set up OCR processing
      - [ ] Configure document categories
      - [ ] Set up backup strategy
      - [ ] Configure notifications
      - [ ] Set up automated filing rules

    - [ ] Deploy Vaultwarden:

      - [ ] Configure container setup
      - [ ] Set up persistent storage
      - [ ] Configure SSL/TLS
      - [ ] Set up backup strategy
      - [ ] Configure emergency access
      - [ ] Set up SSO integration
      - [ ] Configure email notifications

    - [ ] Deploy AFFiNE:
      - [ ] Configure Docker container
      - [ ] Set up persistent storage
      - [ ] Configure authentication
      - [ ] Set up backup strategy
      - [ ] Integrate with Authentik SSO

  - [ ] Deploy IT Tools Stack:

    - [x] Set up Linkwarden:

      - [x] Configure Docker container
      - [x] Set up bookmark storage
      - [ ] Configure authentication
      - [ ] Configure tag management
      - [ ] Set up collections
      - [ ] Organize bookmarks by category
      - [ ] Configure browser extension
      - [ ] Set up automatic backups
      - [x] Intgrate with Authentik SSO (not working yet)

    - [ ] Deploy Scrutiny:

      - [ ] Set up Docker container
      - [ ] Configure SMART monitoring
      - [ ] Set up alert notifications
      - [ ] Configure disk health checks
      - [ ] Set up dashboard access

    - [ ] Set up IT-Tools:

      - [ ] Configure Docker container
      - [ ] Set up required modules
      - [ ] Configure access control
      - [ ] Set up backup strategy

    - [ ] Deploy Stirling-PDF:
      - [ ] Configure Docker container
      - [ ] Set up processing options
      - [ ] Configure storage
      - [ ] Set up backup strategy
    - [ ] Deploy ConvertX:
      - [ ] Configure Docker container
      - [ ] Set up media conversion options
      - [ ] Configure storage volumes
      - [ ] Set up resource limits
      - [ ] Integrate with Authentik SSO
      - [ ] Configure backup strategy
    - [ ] Deploy Excalidraw:
      - [ ] Configure Docker container
      - [ ] Set up persistent storage
      - [ ] Set up authentication
      - [ ] Configure sharing features
      - [ ] Integrate with Authentik SSO
      - [ ] Set up backup strategy
    - [ ] Deploy Draw.io:
      - [ ] Configure Docker container
      - [ ] Set up persistent storage
      - [ ] Configure authentication
      - [ ] Set up custom libraries
      - [ ] Integrate with Authentik SSO
      - [ ] Set up backup strategy
    - [ ] Deploy Dozzle:
      - [ ] Configure Docker container
      - [ ] Set up access controls
      - [ ] Configure log retention
      - [ ] Set up filtering rules
      - [ ] Integrate with Authentik SSO
      - [ ] Configure notification alerts
    - [ ] Deploy Hoarder:
      - [ ] Configure Docker container
      - [ ] Set up persistent storage
      - [ ] Configure collection categories
      - [ ] Set up indexing
      - [ ] Configure search functionality
      - [ ] Integrate with Authentik SSO
      - [ ] Set up backup strategy
    - [ ] Set up Joplin:

      - [ ] Configure Docker container
      - [ ] Set up sync server
      - [ ] Configure storage
      - [ ] Set up backup strategy
      - [ ] Configure authentication
      - [ ] Integrate with Authentik SSO

    - [ ] Deploy Khoj:
      - [ ] Configure Docker container
      - [ ] Set up persistent storage
      - [ ] Configure authentication
      - [ ] Set up backup strategy
      - [ ] Integrate with Authentik SSO
      - [ ] Configure scaling options (on-device vs cloud)

    - [x] Deploy ntfy:
      - [x] Configure Docker container
      - [x] Set up notification topics
      - [x] Configure authentication
      - [ ] Set up retention policies
      - [ ] Configure authentication with Authentik

  - [x] Deploy Network Management Stack:

    - [x] Set up AdGuard Home:

      - [x] Configure Docker container
      - [x] Set up DNS filtering
      - [x] Set up statistics collection

    - [x] Deploy Cloudflare Tunnel:

      - [x] Set up tunnel configuration
      - [x] Configure DNS routing

  - [ ] Deploy Monitoring Stack:

    - [x] Set up Uptime Kuma:

      - [x] Configure endpoints
      - [x] Set up notifications
      - [x] Configure status pages

    - [ ] Deploy Prometheus + Grafana:
      - [ ] Configure Prometheus
      - [ ] Set up data retention
      - [ ] Configure alert rules
      - [ ] Set up Grafana dashboards

  - [ ] Deploy Dashboard:

    - [x] Set up Homarr:
      - [x] Configure Docker container
      - [ ] Set up service integration
      - [ ] Configure widgets
      - [ ] Set up user preferences

  - [ ] Deploy Remote Access:

    - [ ] Set up RustDesk:
      - [ ] Configure relay server
      - [ ] Set up authentication
      - [ ] Configure access controls
      - [ ] Set up monitoring

  - [ ] Deploy Financial Management Stack:
    - [ ] Set up Firefly III:
      - [ ] Configure Docker container
      - [ ] Set up persistent storage
      - [ ] Configure database backend
      - [ ] Set up admin account
      - [ ] Configure categories and budgets
      - [ ] Set up initial accounts
      - [ ] Configure automatic import
      - [ ] Integrate with Authentik SSO
      - [ ] Set up backup strategy
      - [ ] Configure recurring transactions
      - [ ] Set up rules for transaction categorization

## Documentation

- [ ] Create system architecture diagram
- [x] Document network topology
- [ ] Create service dependency documentation
- [ ] Write disaster recovery procedures

## Maintenance Procedures

- [x] Set up daily operations procedures:

  - [x] Container log checking
  - [x] Container health monitoring
  - [x] Service status verification

- [x] Configure weekly maintenance:

  - [x] Network inspection
  - [x] Volume usage monitoring
  - [x] Unused volume cleanup

- [ ] Establish monthly procedures:

  - [x] Manual update procedures for excluded services
  - [ ] Vulnerability scanning
  - [ ] Backup verification

- [x] Document emergency procedures:
  - [x] Service restart procedures
  - [x] Network recreation steps
  - [x] Backup restoration process

## Security Measures

- [x] Configure container security:

  - [x] No privileged containers (except where required)
  - [x] Network isolation implementation
  - [x] Volume mount restrictions
  - [x] Resource limits planning

- [x] System Security Hardening:

  - [x] SSH configuration hardening
    - [x] Disable root login
    - [x] Key-based authentication
    - [x] Max auth tries limit
    - [x] Disable empty passwords
  - [x] Fail2ban Configuration
    - [x] SSH jail setup
    - [x] Custom ban times
    - [x] Rate limiting
  - [x] Unattended Upgrades
    - [x] Security updates automation
    - [x] Custom origin patterns
    - [x] Automated cleanup

- [x] Network Security:

  - [x] Network segmentation (proxy, database networks)
  - [x] Internal service communication
  - [x] Reverse proxy configuration
  - [x] SSL/TLS termination (Cloudflare)

- [ ] Security Auditing:
  - [ ] Regular privilege checks
  - [x] Network isolation validation
  - [ ] Volume mount audits
  - [ ] Container capability review
  - [ ] Exposed ports monitoring

## Monitoring and Alerting

- [x] bcache Monitoring

  - [x] Hit/miss ratio tracking
  - [x] Dirty data monitoring
  - [x] Device temperature alerts
  - [x] SSD wear level tracking
  - [x] SMART status integration
  - [x] Performance statistics logging
  - [x] NTFY integration

- [x] System Monitoring
  - [x] Resource usage tracking
  - [x] Disk space monitoring
  - [x] Network usage tracking
  - [x] Container health checks
  - [ ] Custom Grafana dashboards
  - [ ] Alert thresholds configuration
