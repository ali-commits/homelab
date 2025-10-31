# Network Configuration

## 📁 Configuration Files Location
- **Source**: `/HOMELAB/configs/network/interfaces`
- **System Location**: `/etc/network/interfaces`

## 🌐 Network Settings Overview

| Setting           | Value            | Description               |
| ----------------- | ---------------- | ------------------------- |
| **Interface**     | `enp3s0`         | Primary network interface |
| **IP Address**    | `192.168.1.2/24` | Static IP configuration   |
| **Subnet Mask**   | `255.255.255.0`  | /24 network               |
| **Gateway**       | `192.168.1.1`    | Default route             |
| **DNS Primary**   | `1.1.1.1`        | Cloudflare DNS            |
| **DNS Secondary** | `8.8.8.8`        | Google DNS                |

## 🔧 Interface Configuration
- **Type**: NetworkManager/systemd-networkd (Fedora default)
- **Mode**: Static IP (no DHCP)
- **Loopback**: Enabled (`lo`)
- **Auto-start**: Yes (`auto enp3s0`)

## 🚀 Management Commands

### View Current Network Status
```bash
# Show all interfaces
ip addr show

# Show specific interface
ip addr show enp2s0

# Show routing table
ip route show

# Test connectivity
ping 192.168.1.1  # Gateway
ping 1.1.1.1      # External DNS
```

### Apply Network Changes
```bash
# Restart specific interface (Fedora/NetworkManager)
sudo nmcli connection down enp3s0 && sudo nmcli connection up enp3s0

# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check interface status
sudo systemctl status NetworkManager
```

## 📋 DNS Configuration
- **Primary**: `1.1.1.1` (Cloudflare - fast, privacy-focused)
- **Secondary**: `8.8.8.8` (Google - reliable fallback)
- **AdGuard Home**: Available at `192.168.1.2` (this server)

## 🌐 Remote Access (Tailscale)
- **Homelab IP**: `100.102.64.99`
- **Short Domain**: `redripper`
- **Magic DNS**: `redripper.taila7b279.ts.net`
- **Subnet Routing**: On-demand access to `192.168.1.0/24` network

### Tailscale Management
```bash
# Enable subnet routing (when needed)
sudo tailscale up --advertise-routes=192.168.1.0/24 --accept-routes

# Disable subnet routing (for security)
sudo tailscale up --advertise-routes="" --accept-routes=false

# Check status
tailscale status
```

## 🔍 Troubleshooting

### Common Network Issues
| Issue               | Command               | Expected Result        |
| ------------------- | --------------------- | ---------------------- |
| Interface down      | `ip link show enp2s0` | `state UP`             |
| No IP assigned      | `ip addr show enp2s0` | Shows `192.168.1.2/24` |
| Gateway unreachable | `ping 192.168.1.1`    | Response packets       |
| DNS not working     | `nslookup google.com` | Resolves to IP         |

### Network Diagnostics
```bash
# Check interface status
sudo ethtool enp2s0

# Monitor network traffic
sudo tcpdump -i enp2s0

# Test DNS resolution
dig @1.1.1.1 google.com
```
