# AdGuard

**Purpose**: DNS server and network-wide ad blocking

**Configuration Details**:

- Image: adguard/adguardhome:latest
- Data Persistence:
  - `/storage/data/adguard/work`: Working directory
  - `/storage/data/adguard/conf`: Configuration files

**Network Configuration**:

- DNS Ports: 53 (TCP/UDP)
- Web Interface: Port 8989
- Setup Interface: Port 3333
- Domain: adguard.alimunee.com

**Capabilities**:

- NET_ADMIN for DNS functionality
- Integrated with Traefik for web access

**AdGuard Settings**

- Use AdGuard browsing security web service
- Use AdGuard parental control web service
- Use Safe Search for all available websites except YouTube because it disables comments
- Using the following lists:

| Filter Name                                      | URL                                                                  | Entries | Updated           |
| ------------------------------------------------ | -------------------------------------------------------------------- | ------- | ----------------- |
| AdGuard DNS filter                               | https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt  | 55,465  | February 22, 2025 |
| AdAway Default Blocklist                         | https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt  | 0       | –                 |
| Phishing URL Blocklist (PhishTank and OpenPhish) | https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt | 1,500   | February 22, 2025 |
| uBlock₀ filters – Badware risks                  | https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt | 2,881   | February 22, 2025 |
| 1Hosts (Lite)                                    | https://adguardteam.github.io/HostlistsRegistry/assets/filter_24.txt | 92,033  | February 22, 2025 |
| AdGuard DNS Popup Hosts filter                   | https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt | 1,431   | February 22, 2025 |
