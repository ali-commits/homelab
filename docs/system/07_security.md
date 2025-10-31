# System Security

## Configuration Files Location
- **SSH**: `/HOMELAB/configs/security/sshd_config` → `/etc/ssh/sshd_config`
- **Fail2ban**: `/HOMELAB/configs/security/jail.local` → `/etc/fail2ban/jail.local`

## SSH Security Configuration

### Key Security Settings
| Setting             | Value               | Description                                      |
| ------------------- | ------------------- | ------------------------------------------------ |
| **Root Login**      | `prohibit-password` | Allow key-based root login only                  |
| **Auth Tries**      | `6`                 | Maximum authentication attempts (Fedora default) |
| **Public Key Auth** | `yes`               | Enable key-based authentication                  |
| **Password Auth**   | Configurable        | Can be disabled for key-only access              |
| **X11 Forwarding**  | `yes`               | Enabled for legitimate use                       |
| **Crypto Policies** | Modern              | Enforced via system crypto policies              |

### SSH Management Commands
```bash
# Test SSH configuration
sudo sshd -t

# View effective SSH configuration
sudo sshd -T

# Restart SSH service
sudo systemctl restart sshd

# Check SSH status
sudo systemctl status sshd

# View SSH logs
sudo journalctl -u sshd --since "1 hour ago"
```

## Fail2ban Configuration

### Protection Settings
| Jail          | Status  | Ban Time | Max Retry  | Find Time  |
| ------------- | ------- | -------- | ---------- | ---------- |
| **sshd**      | Enabled | 1 hour   | 3 attempts | 10 minutes |
| **sshd-ddos** | Enabled | 2 hours  | 2 attempts | 5 minutes  |

### Advanced Features
- **Incremental Banning**: Ban time doubles for repeat offenders (max 24h)
- **Firewalld Integration**: Automatic firewall rule management
- **Local Network Exempt**: `192.168.1.0/24` network ignored

### Fail2ban Management
```bash
# Check fail2ban status
sudo fail2ban-client status

# Check specific jail
sudo fail2ban-client status sshd

# Unban IP address
sudo fail2ban-client set sshd unbanip 192.168.1.100

# View banned IPs
sudo fail2ban-client status sshd

# Test fail2ban configuration
sudo fail2ban-client -t
```

## Firewall Configuration

### Firewalld Settings
| Zone             | Status | Interface | Services                               |
| ---------------- | ------ | --------- | -------------------------------------- |
| **FedoraServer** | Active | enp3s0    | ssh, http, https, nfs, custom services |

### Custom Services Defined
- 🎬 **jellyfin**: Media streaming
- 📸 **immich**: Photo management
- 🛡️ **adguard**: DNS filtering
- 🔀 **traefik**: Reverse proxy

### Firewall Management
```bash
# Check firewall status
sudo firewall-cmd --state

# List all services
sudo firewall-cmd --list-all

# Check rich rules (fail2ban)
sudo firewall-cmd --list-rich-rules

# Add service permanently
sudo firewall-cmd --permanent --add-service=<service>
sudo firewall-cmd --reload
```

## SELinux Configuration

### Current Settings
| Setting    | Value      | Description                         |
| ---------- | ---------- | ----------------------------------- |
| **Mode**   | Permissive | Logs violations without enforcement |
| **Type**   | Targeted   | Targeted process protection         |
| **Status** | Active     | Monitoring and logging enabled      |

### SELinux Management
```bash
# Check SELinux status
getenforce
sestatus

# View SELinux denials
sudo ausearch -m AVC -ts recent

# Set file contexts
sudo restorecon -R /path/to/directory
```

## Security Monitoring

### Key Log Files
| Service      | Log Location               | Purpose                 |
| ------------ | -------------------------- | ----------------------- |
| **SSH**      | `/var/log/secure`          | Authentication attempts |
| **Fail2ban** | `journalctl -u fail2ban`   | Ban/unban activities    |
| **Firewall** | `journalctl -u firewalld`  | Firewall events         |
| **SELinux**  | `/var/log/audit/audit.log` | SELinux violations      |

### Security Monitoring Tools
- `/HOMELAB/fail2ban-status.sh` - Detailed fail2ban dashboard
- `/HOMELAB/monitoring-status.sh` - System security overview
- `/HOMELAB/verify-system.sh` - Security service verification

### Security Checks
```bash
# Check failed login attempts
sudo journalctl -u sshd | grep "Failed"

# Check successful logins
sudo journalctl -u sshd | grep "Accepted"

# Monitor real-time authentication
sudo journalctl -u sshd -f

# Check system security status
/HOMELAB/fail2ban-status.sh
```

## Remote Access Security
- **Tailscale VPN**: Secure remote access with on-demand subnet routing
- **Default State**: Subnet routing disabled for security
- **Access Control**: GitHub-authenticated devices only
- **Network Isolation**: Tailscale traffic separate from local network

## Security Alerts
Security events are monitored by the system monitoring infrastructure:
- **Config**: `/etc/default/notification-settings`
- **Notifications**: Configured for ntfy alerts
- **Integration**: Fail2ban and monitoring scripts coordinate alerting
