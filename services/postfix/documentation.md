# Postfix SMTP Relay

**Purpose**: Self-hosted SMTP relay server using Brevo (Sendinblue) as upstream provider

**Status**: 🚧 **DEPLOYMENT READY** -Brevo credentials configuration

| Configuration Setting | Value                      |
| --------------------- | -------------------------- |
| Image                 | `boky/postfix:latest`      |
| Upstream Provider     | `Brevo (Sendinblue)`       |
| Internal SMTP Port    | `587`                      |
| Memory Limits         | `512MB max, 128MB minimum` |
| Timezone              | `Asia/Kuala_Lumpur`        |

**Configuration Details**:

| Configuration   | Details               |
| --------------- | --------------------- |
| SMTP Hostname   | mail.alimunee.com     |
| Internal Port   | 587 (SMTP Submission) |
| External Port   | 25, 587               |
| Allowed Domains | alimunee.com          |
| TLS Security    | Required (encrypt)    |

**Volume Mappings**:

| Volume     | Path                          | Purpose            |
| ---------- | ----------------------------- | ------------------ |
| Mail Spool | `/storage/data/postfix/spool` | Postfix mail queue |
| Logs       | `/storage/data/postfix/logs`  | Mail server logs   |

**Network Settings**:

| Setting    | Value                   |
| ---------- | ----------------------- |
| SMTP Ports | `25`, `587`             |
| Networks   | `proxy`, `mail_network` |
| Hostname   | `mail.alimunee.com`     |

## 🔧 Initial Setup

### **1. Brevo Account Configuration**

1. **Create Brevo Account**:
   - Sign up at https://app.brevo.com
   - Verify your account and domain

2. **Generate SMTP Credentials**:
   - Go to https://app.brevo.com/settings/keys/smtp
   - Create new SMTP key
   - Note down the login (your email) and SMTP key

3. **Domain Verification**:
   - Add your domain `alimunee.com` in Brevo
   - Configure SPF, DKIM, and DMARC records
   - Verify domain ownership


### **3. Environment Configuration**

Update `.env` file with your Brevo credentials:

```bash
# Get these from Brevo SMTP settings
BREVO_SMTP_USERNAME=your-email@brevo.com
BREVO_SMTP_PASSWORD=your-brevo-smtp-key
```

### **4. Storage Preparation**

```bash
# Create required directories
sudo mkdir -p /storage/data/postfix/{spool,logs}
sudo chown -R 1000:1000 /storage/data/postfix/
```

### **5. Deployment**

```bash
cd /HOMELAB/services/postfix
docker compose up -d
```

## 📧 Service Configuration for Other Applications

Once Postfix is running, configure your other services to use it as SMTP relay:

### **Standard SMTP Settings for Services**

```bash
SMTP_HOST=postfix_relay  # or mail.alimunee.com
SMTP_PORT=587
SMTP_USERNAME=  # Leave empty (no auth required for internal services)
SMTP_PASSWORD=  # Leave empty
SMTP_FROM_ADDRESS=noreply@alimunee.com
SMTP_FROM_NAME=Your Service Name
SMTP_TLS=true
SMTP_STARTTLS=true
```


### **Mail Queue Management**

```bash
# View mail queue
docker exec postfix_relay postqueue -p

# Flush mail queue (retry sending)
docker exec postfix_relay postfix flush

# Remove all mail from queue
docker exec postfix_relay postsuper -d ALL

# View mail statistics
docker exec postfix_relay pflogsumm /var/log/mail.log
```

### **Testing Email Delivery**

```bash
# Test SMTP connectivity
telnet mail.alimunee.com 587

# Send test email via command line
docker exec postfix_relay sendmail -f noreply@alimunee.com recipient@example.com << EOF
Subject: Test Email
From: noreply@alimunee.com
To: recipient@example.com

This is a test email from your Postfix relay.
EOF

# Test with swaks (if available)
swaks --to recipient@example.com --from noreply@alimunee.com --server mail.alimunee.com:587
```

## 📊 Monitoring & Alerts

**Health Checks**:
- SMTP port connectivity (587)
- Brevo upstream connectivity
- Mail queue size monitoring
- Log file monitoring for errors

**Key Metrics to Monitor**:
- Mail queue size and processing time
- Delivery success/failure rates
- Connection errors to Brevo
- Disk usage for mail spool

**Integration Points**:
- Uptime Kuma monitoring for SMTP port
- ntfy notifications for mail delivery issues
- Log monitoring for authentication failures
- Watchtower for automated updates

## 🔐 Security Configuration

**TLS/SSL Security**:
- Enforced TLS encryption for upstream connections
- SASL authentication with Brevo
- Secure cipher suites only
- Certificate validation enabled

**Access Control**:
- Restricted to allowed sender domains
- Internal network access only
- No open relay configuration
- Rate limiting via Brevo

**Network Security**:
- Isolated mail network for internal services
- No direct external access (behind Cloudflare)
- Proper firewall rules

