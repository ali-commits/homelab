# Fedora NetworkManager Configuration Commands
# For configuring static IP on enp3s0 interface
# This file contains the nmcli commands to replicate the current network setup

# Current Network Configuration (from nmcli):
# Interface: enp3s0
# IP: 192.168.1.2/24
# Gateway: 192.168.1.1
# DNS: 1.1.1.1
# Connection: "Wired connection 1"
# UUID: d478cecc-9cbe-32fa-865f-27d1d90af56e

# To apply this configuration on a new system:

# 1. Configure static IP
nmcli connection modify "Wired connection 1" ipv4.method manual
nmcli connection modify "Wired connection 1" ipv4.addresses 192.168.1.2/24
nmcli connection modify "Wired connection 1" ipv4.gateway 192.168.1.1
nmcli connection modify "Wired connection 1" ipv4.dns 1.1.1.1

# 2. Set connection to auto-connect
nmcli connection modify "Wired connection 1" connection.autoconnect yes

# 3. Apply the configuration
nmcli connection up "Wired connection 1"

# Alternative: Create a new connection from scratch
# nmcli connection add type ethernet con-name "homelab-static" ifname enp3s0 \
#   ipv4.method manual ipv4.addresses 192.168.1.2/24 ipv4.gateway 192.168.1.1 ipv4.dns 1.1.1.1

# To verify configuration:
# nmcli connection show "Wired connection 1"
# ip addr show enp3s0
# ping 192.168.1.1

# Note: On Fedora, NetworkManager is the primary network management tool
# Traditional /etc/network/interfaces is not used
