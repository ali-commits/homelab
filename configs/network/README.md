# Network Configuration for Fedora Homelab

## Files in this directory

### NetworkManager Configuration (Fedora/Modern Linux)
- **`NetworkManager.conf`** - Main NetworkManager configuration
- **`wired-connection.nmconnection`** - Static IP connection profile for enp3s0

### Legacy Configuration (Debian/Traditional)
- **`interfaces`** - Traditional /etc/network/interfaces format (deprecated on Fedora)
- **`networkmanager-setup.sh`** - Alternative setup commands

## Current Network Configuration

| Setting | Value | Description |
|---------|-------|-------------|
| **Interface** | `enp3s0` | Primary ethernet interface |
| **IP Address** | `192.168.1.2/24` | Static IP configuration |
| **Gateway** | `192.168.1.1` | Default route |
| **DNS** | `1.1.1.1` | Cloudflare DNS |
| **Method** | Manual (static) | No DHCP |
| **Connection ID** | "Wired connection 1" | NetworkManager connection name |

## Deployment Instructions

### For Fedora Systems (Current)
```bash
# Copy NetworkManager configuration
sudo cp NetworkManager.conf /etc/NetworkManager/NetworkManager.conf

# Copy connection profile
sudo cp wired-connection.nmconnection "/etc/NetworkManager/system-connections/Wired connection 1.nmconnection"
sudo chmod 600 "/etc/NetworkManager/system-connections/Wired connection 1.nmconnection"
sudo chown root:root "/etc/NetworkManager/system-connections/Wired connection 1.nmconnection"

# Restart NetworkManager
sudo systemctl restart NetworkManager

# Verify connection
nmcli connection show
ip addr show enp3s0
```

### Manual Configuration (Alternative)
```bash
# Configure static IP using nmcli
nmcli connection modify "Wired connection 1" ipv4.method manual
nmcli connection modify "Wired connection 1" ipv4.addresses 192.168.1.2/24
nmcli connection modify "Wired connection 1" ipv4.gateway 192.168.1.1
nmcli connection modify "Wired connection 1" ipv4.dns 1.1.1.1
nmcli connection up "Wired connection 1"
```

## File Details

### NetworkManager.conf
Standard Fedora NetworkManager configuration with:
- Default plugins enabled
- Debug logging configuration available
- Standard security settings

### wired-connection.nmconnection
Connection profile containing:
- Static IP: 192.168.1.2/24
- Gateway: 192.168.1.1
- DNS: 1.1.1.1
- Auto-connect enabled
- Interface: enp3s0

## Troubleshooting

### Check Connection Status
```bash
nmcli connection show
nmcli device status
ip addr show enp3s0
```

### Restart Networking
```bash
sudo systemctl restart NetworkManager
nmcli connection up "Wired connection 1"
```

### View Logs
```bash
journalctl -u NetworkManager -f
```

## Notes

- Fedora uses NetworkManager by default, not traditional interfaces file
- Connection files are stored in `/etc/NetworkManager/system-connections/`
- Connection files must have 600 permissions and root ownership
- IPv6 is configured for auto (SLAAC) alongside manual IPv4

---
*Updated: August 5, 2025 for Fedora 42 homelab system*
