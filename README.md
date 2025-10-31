# RedRipper Homelab Infrastructure

**A production-grade, self-hosted ecosystem powering modern digital life with enterprise-class reliability and performance.**

---

## 🏆 Infrastructure Highlights

**RedRipper** is a comprehensive homelab infrastructure running **45 containerized services** on Fedora 42 Server, delivering enterprise-grade capabilities for media streaming, cloud storage, AI/ML workloads, and system monitoring. Built with security, performance, and automation at its core.

### ⚡ Performance Powerhouse
- **AMD Threadripper 2920X**: 12-core/24-thread @ 3.5GHz for heavy workloads
- **NVIDIA GTX 1070**: Hardware-accelerated transcoding and AI/ML inference
- **32GB DDR4**: Ample memory for containerized services
- **Dual-tier Storage**: 1TB NVMe (system) + 3.6TB HDD (data) with Btrfs compression

### 🛡️ Enterprise Security
- **Zitadel SSO**: Modern identity management with OIDC/SAML
- **Cloudflare Tunnels**: Zero-trust network access without port forwarding
- **AdGuard Home**: Network-wide DNS filtering and ad blocking
- **Multi-layered Protection**: SSH hardening, fail2ban, SELinux, automated updates

### 🚀 Production Features
- **GPU Acceleration**: 4-6x transcoding performance with NVENC hardware encoding
- **Automated Monitoring**: Comprehensive health checks with ntfy notifications
- **3-2-1 Backup Strategy**: Snapper snapshots + Kopia daily backups to S3 Glacier
- **Remote Access**: Tailscale VPN with Magic DNS and subnet routing
- **Email Delivery**: Postfix SMTP relay with Brevo upstream for notifications
- **Container Orchestration**: 45 services across 7 categories with Traefik routing

---

## 📊 Service Portfolio

| **Category**                   | **Count** | **Key Services**                          | **Purpose**                                         |
| ------------------------------ | --------- | ----------------------------------------- | --------------------------------------------------- |
| **🎬 Media & Entertainment**    | 10        | Jellyfin, *arr stack, Kavita, BookLore    | GPU-accelerated streaming & content management      |
| **☁️ Data & Productivity**      | 15        | Nextcloud, Immich, Firefly III, AFFiNE    | Cloud storage, photo AI, finance, knowledge base    |
| **🤖 AI/ML Services**           | 4         | Lobe Chat, Karakeep, Paperless-GPT        | Multi-LLM chat, AI bookmarks, document processing   |
| **🔧 Productivity Tools**       | 12        | OnlyOffice, N8N, Syncthing, IT-Tools      | Collaboration, automation, file sync, dev utilities |
| **📊 Monitoring & Management**  | 8         | Uptime Kuma, Beszel, Dockge, Komodo       | Infrastructure monitoring & container management    |
| **🛡️ Core Infrastructure**      | 4         | Traefik, Cloudflared, AdGuard, Watchtower | Routing, tunneling, DNS filtering, auto-updates     |
| **🔐 Security & Communication** | 3         | Zitadel, ntfy, Postfix                    | SSO, notifications, SMTP relay                      |

**Total: 45+ Production Services** | [📖 Complete Service Reference](docs/docker/00_README.md)

---

## 🏗️ Architecture Overview

### Complete Infrastructure Architecture
```
                                ┌─────────────────┐
                                │    Internet     │
                                └─────────┬───────┘
                                          │
                        ┌─────────────────┼─────────────────┐
                        │                 │                 │
              ┌─────────▼─────────┐       │       ┌─────────▼─────────┐
              │   Cloudflare      │       │       │   Tailscale       │
              │   (CDN + WAF)     │       │       │   (VPN Mesh)      │
              └─────────┬─────────┘       │       └─────────┬─────────┘
                        │                 │                 │
              ┌─────────▼─────────┐       │       ┌─────────▼─────────┐
              │   Cloudflared     │       │       │ redripper.tail... │
              │   (Tunnel)        │       │       │ (Magic DNS)       │
              └─────────┬─────────┘       │       └─────────┬─────────┘
                        │                 │                 │
                        └─────────────────┼─────────────────┘
                                          │
                     ┌────────────────────▼───────────────────┐
                     │              RedRipper Host            │
                     │              192.168.1.2/24            │
                     │                                        │
                     │  ┌──────────────────────────────────┐  │
                     │  │           Traefik Proxy          │  │
                     │  │          (Reverse Proxy)         │  │
                     │  └─────────────────┬────────────────┘  │
                     │                    │                   │
                     │  ┌─────────────────▼────────────────┐  │
                     │  │          Docker Networks         │  │
                     │  │                                  │  │
                     │  │ ┌─────┐ ┌──────────┐ ┌─────────┐ │  │
                     │  │ │proxy│ │ db_      │ │ mail_   │ │  │
                     │  │ │     │ │ network  │ │ network │ │  │
                     │  │ └──┬──┘ └────┬─────┘ └────┬────┘ │  │            ┌─────────────────┐
                     │  └────┼─────────┼────────────┼──────┘  │            │   Brevo (SMTP)  │
                     │       │         │            │         │            │ 3rd party Email │
                     └───────┼─────────┼────────────┼─────────┘            └─────────▲───────┘
                             │         │            │                                │
        ┌────────────────────┼─────────┼────────────┼───────────────────┐            │
        │                    │         │            │                   │            │
┌───────▼───────┐ ┌──────────▼─────────▼────────────▼─────────┐ ┌───────▼───────┐    │
│ Web Services  │ │             Backend Services              │ │Infrastructure │    │
│               │ │                                           │ │               │    │
│• Jellyfin     │ │• PostgreSQL        • Internal Networks    │ │• Zitadel (SSO)│    │
│• Nextcloud    │ │• Redis             • Service Databases    │ │• AdGuard DNS  │    │
│• Immich       │ │• MongoDB           • Cache Systems        │ │• Postfix SMTP ─────┘
│• Uptime Kuma  │ │• Search Engines    • Message Queues       │ │• ntfy Notify  │
│• Lobe Chat    │ │• File Systems      • Background Jobs      │ │• Watchtower   │
│• 40+ Services │ │• Volume Mounts     • Health Checks        │ │• Dockage      │
└───────────────┘ └───────────────────────────────────────────┘ └───────┬───────┘
        │                                                               │
        └───────────────────────────────┬───────────────────────────────┘
                                        │
       ┌────────────────────────────────▼─────────────────────────────────┐
       │                             Storage                              │
       │                                                                  │
       │ ┌─────────────────────────────┬─────────────────────────────────┐│
       │ │           NVMe (1TB)        │  HDD (3.6TB)                    ││
       │ │ ┌─────────────────────────┐ │ ┌─────────────────────────────┐ ││
       │ │ │ /             (snapper) │ │ │ /storage/media              │ ││
       │ │ │ /storage/data (snapper) │ │ │ /storage/Immich    (snapper)│ ││
       │ │ │ /var/lib/docker         │ │ │ /storage/nextcloud (snapper)│ ││
       │ │ │ /var/logs               │ │ │ /storage/share     (snapper)│ ││
       │ │ └─────────────────────────┘ │ └─────────────────────────────┘ ││
       │ └─────────────────────────────┴─────────────────────────────────┘│
       └───────────────────────────────┬──────────────────────────────────┘
                                       │
                          ┌────────────▼─────────────┐                     ┌───────────────┐
                          │ Backup Strategy (Kopia)  │─────────────────────▶  S3 Glacier  │
                          │                          │                     └───────────────┘
                          │ • /sotrage/data          │
                          │ • /storage/Immich        │
                          │ • /storage/nextcloud     │
                          │                          │
                          └──────────────────────────┘


```
---

## 🎯 Key Capabilities

### 🎬 Media Streaming Excellence
- **Jellyfin**: GPU-accelerated transcoding with NVENC (4-6x performance boost)
- **Complete *arr Stack**: Automated content acquisition and management
- **Multi-format Support**: 4K transcoding, subtitle management, mobile streaming
- **Smart Organization**: Automated metadata, artwork, and library management

### ☁️ Personal Cloud Platform
- **Nextcloud**: Full-featured cloud storage with mobile/desktop sync
- **Immich**: AI-powered photo management with facial recognition and object detection
- **Document Management**: OCR processing, AI enhancement, collaborative editing
- **Cross-device Sync**: Seamless file access across all devices

### 🤖 AI/ML Integration
- **Multi-LLM Chat**: Lobe Chat with support for OpenAI, Anthropic, local models
- **Intelligent Bookmarking**: AI-powered link categorization and search
- **Document Intelligence**: Automated OCR, classification, and content extraction
- **Photo AI**: Advanced facial recognition, object detection, and smart albums

### 🛡️ Security & Data Protection
- **Zero-trust Access**: Cloudflare tunnels eliminate port forwarding risks
- **Remote VPN Access**: Tailscale mesh network with Magic DNS (`redripper.taila7b279.ts.net`)
- **3-2-1 Backup Strategy**: Local Snapper snapshots + daily Kopia backups to S3 Glacier
- **Email Infrastructure**: Postfix SMTP relay → Brevo → reliable email delivery
- **Comprehensive Monitoring**: Real-time health checks with ntfy notifications
- **Intrusion Detection**: Multi-layered security with fail2ban and SELinux

---

## �  Backup & Remote Access

### 3-2-1 Backup Strategy
- **3 Copies**: Original data + Snapper snapshots + S3 Glacier backups
- **2 Media Types**: Local Btrfs storage + cloud object storage
- **1 Offsite**: Daily Kopia backups to AWS S3 Glacier for long-term retention
- **Automated Scheduling**: Snapper hourly/daily snapshots + Kopia daily cloud sync
- **Point-in-time Recovery**: Granular restore from local snapshots or cloud archives

### Remote Access Options
- **Tailscale VPN**: Secure mesh network with Magic DNS
  - **Homelab Access**: `redripper.taila7b279.ts.net` (direct machine access)
  - **Subnet Routing**: On-demand access to entire `192.168.1.0/24` network
  - **Zero Configuration**: Automatic service discovery and encrypted tunnels
- **Cloudflare Tunnels**: HTTPS access without VPN for web services
- **Local Network**: Direct access via `192.168.1.2` (RedRipper static IP)

### Email Infrastructure
- **SMTP Relay**: Postfix container handles internal service notifications
- **Upstream Provider**: Brevo (SendinBlue) for reliable email delivery
- **Notification Channels**: ntfy for real-time alerts + email for important events
- **Service Integration**: All services configured for automated email notifications

---

## 📁 Documentation Structure

### 🔧 System Configuration
| **Resource**            | **Location**                   | **Purpose**                                 |
| ----------------------- | ------------------------------ | ------------------------------------------- |
| **System Configs**      | [`configs/`](configs/)         | Centralized configuration management        |
| **Service Definitions** | [`services/`](services/)       | Docker Compose stacks and documentation     |
| **Infrastructure Docs** | [`docs/docker/`](docs/docker/) | Complete Docker architecture reference      |
| **System Docs**         | [`docs/system/`](docs/system/) | Hardware, networking, and system management |

### 📖 Quick Reference
| **Topic**                   | **Documentation**                                       | **Description**                              |
| --------------------------- | ------------------------------------------------------- | -------------------------------------------- |
| **Docker Infrastructure**   | [📖 Docker Overview](docs/docker/00_README.md)           | Complete service reference and architecture  |
| **Hardware Specifications** | [📖 Hardware Guide](docs/system/01_hardware.md)          | CPU, GPU, storage, and performance details   |
| **Network Configuration**   | [📖 Networking](docs/system/02_networking.md)            | Static IP, DNS, Tailscale remote access      |
| **Security Implementation** | [📖 Security Guide](docs/docker/04_authentication.md)    | SSO, tunneling, and access control           |
| **Monitoring & Alerts**     | [📖 Monitoring](docs/docker/10_monitoring-management.md) | Health checks, notifications, and dashboards |
| **Troubleshooting**         | [📖 Troubleshooting](docs/docker/11_troubleshooting.md)  | Common issues and diagnostic procedures      |

---


## 🏆 Infrastructure Achievements

✅ **45+ Production Services** running reliably 24/7
✅ **GPU Acceleration** delivering 4-6x transcoding performance
✅ **3-2-1 Backup Strategy** with Snapper snapshots + Kopia S3 Glacier backups
✅ **Zero Downtime** with automated health monitoring and recovery
✅ **Enterprise Security** with SSO, Tailscale VPN, and intrusion detection
✅ **Email Infrastructure** with Postfix SMTP relay and Brevo delivery
✅ **Remote Access** via Tailscale Magic DNS and Cloudflare tunnels
✅ **AI/ML Integration** with CUDA acceleration and multi-LLM support
✅ **Modern Architecture** with container orchestration and service mesh

---


*For detailed technical documentation, service-specific guides, and operational procedures, explore the comprehensive documentation in [`docs/`](docs/) and [`services/`](services/).*
