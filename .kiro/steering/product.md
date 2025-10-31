# Product Overview

This is a comprehensive homelab infrastructure running on Fedora 42 Server, providing self-hosted services for media streaming, cloud storage, photo management, and system monitoring.

## Core Purpose
- **Media Server**: Complete *arr stack (Radarr, Sonarr, Jellyseerr, Bazarr, Prowlarr) with Jellyfin for GPU-accelerated streaming
- **Cloud Storage**: Nextcloud for file sync, Immich for AI-powered photo management, Cloudreve for additional storage
- **Security & Monitoring**: Zitadel SSO, AdGuard DNS filtering, Uptime Kuma monitoring, fail2ban intrusion prevention
- **Infrastructure**: Docker-based services with Traefik reverse proxy and Cloudflare tunnels for secure external access

## Service Categories
- **🛡️ Infrastructure**: Traefik, Zitadel, Cloudflared, Watchtower (automated updates)
- **🎬 Media Stack**: Jellyfin (GPU transcoding), Radarr, Sonarr, Jellyseerr, Bazarr, qBittorrent, Prowlarr, Flaresolverr
- **☁️ Productivity**: Nextcloud, Immich, AFFiNE (knowledge base), Linkwarden (bookmarks)
- **📊 Monitoring**: Uptime Kuma, ntfy (notifications), custom Btrfs/SMART monitoring scripts
- **🔐 Security**: AdGuard Home (DNS filtering), Zitadel (SSO), system hardening

## Key Features
- **GPU Acceleration**: NVIDIA GTX 1070 with NVENC for Jellyfin transcoding (3-5x performance) and Immich ML
- **Storage**: Multi-tier Btrfs with compression, automated snapshots via Snapper, S3 backups
- **Monitoring**: Comprehensive system monitoring with ntfy notifications, SMART health checks, Btrfs integrity
- **Security**: Multi-layered security with SSH hardening, fail2ban, SELinux, network segmentation, SSO
- **Automation**: Watchtower for container updates, automated backups, maintenance scripts

## Hardware Specifications
- **CPU**: AMD Ryzen Threadripper 2920X (12-core/24-thread @ 3.5GHz)
- **Memory**: 32GB DDR4
- **GPU**: NVIDIA GeForce GTX 1070 (8GB VRAM) with CUDA 12.9
- **Storage**: 1TB NVMe (system) + 3.6TB HDD (data) with Btrfs compression
- **Network**: Static IP (192.168.1.2/24) with Cloudflare tunnel integration

## Target Users
Self-hosted homelab for personal/family use with emphasis on automation, performance optimization, data protection, and secure remote access.
