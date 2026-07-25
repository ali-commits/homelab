# Authentication Infrastructure

## Overview

Centralized authentication and identity management using Zitadel for SSO across
homelab services, plus Vaultwarden as the self-hosted credential store.

## Services

### Zitadel - Modern SSO & Identity Management
- **Purpose**: Centralized authentication and identity management
- **Ports**: 8081, 3001
- **Domain**: zitadel.alimunee.com
- **Network**: proxy, zitadel_internal
- **Documentation**: [📖](../../services/zitadel/documentation.md)

### Vaultwarden - Password & Secret Manager
- **Purpose**: Self-hosted Bitwarden-compatible vault; works with the official
  Bitwarden browser, desktop and mobile clients
- **Port**: 80
- **Domain**: vaultwarden.alimunee.com
- **Network**: proxy
- **Documentation**: [📖](../../services/vaultwarden/documentation.md)

> Vaultwarden is independent of Zitadel — it holds its own accounts rather than
> authenticating through SSO. That separation is deliberate: if it delegated
> login to Zitadel, a Zitadel outage would lock you out of the credentials needed
> to repair Zitadel.

### Credentials vs. secrets — which service to use

Vaultwarden implements Bitwarden's **Password Manager** API only. It does **not**
implement **Bitwarden Secrets Manager**, and upstream has declined to: that is a
separately licensed product needing proprietary web-vault code plus machine
accounts and RBAC that Vaultwarden does not model. `bws`, access tokens, service
accounts and the Secrets Manager SDKs therefore do not work against it.

Use [Infisical](../../services/infisical/documentation.md)
(`secrets.alimunee.com`) for machine secrets instead — it provides the machine
identities, per-environment scoping, CLI/SDK injection and audit logging that
Secrets Manager would have.

| Concern | Service |
| ------- | ------- |
| Human credentials — logins, TOTP, cards, secure notes | Vaultwarden |
| Machine secrets — API keys, service tokens, `.env` injection | Infisical |
| Break-glass — credentials needed to *repair* the homelab | Off-site (e.g. Bitwarden cloud), never only here |

That last row is the important one. Anything required to bring the homelab back
up must not live solely inside the homelab, or an outage becomes unrecoverable.

## SSO Integration

### Configuration Overview
Zitadel provides modern OIDC/OAuth2 authentication:

- **Protocol Support**: OIDC, OAuth2, SAML
- **User Management**: Self-registration, admin management
- **Multi-Factor Authentication**: TOTP, WebAuthn support
- **Session Management**: Secure session handling
- **API Access**: REST API for user management

### Service Integration Pattern

#### Standard OIDC Configuration
```yaml
environment:
  - OAUTH_WELLKNOWN_URL=https://zitadel.alimunee.com/.well-known/openid-configuration
  - OAUTH_CLIENT_ID=${ZITADEL_CLIENT_ID}
  - OAUTH_CLIENT_SECRET=${ZITADEL_CLIENT_SECRET}
  - OAUTH_SCOPE=openid email profile
```

#### Services with SSO Integration
- **OpenCloud**: OIDC PKCE flow, auto-provisioning from `preferred_username` and `email` claims
- **Lobe Chat**: NextAuth.js with Zitadel provider integration
- **Karakeep**: OIDC via generic OAuth configuration
- **Linkwarden**: Native Zitadel SSO integration

### Application Configuration in Zitadel

#### Creating New Applications
1. Access Zitadel Console: https://zitadel.alimunee.com
2. Navigate to Projects → Default Project → Applications
3. Click "New Application"
4. Configure application settings:
   - **Name**: Service name
   - **Type**: Web Application
   - **Authentication Method**: PKCE (recommended)
   - **Redirect URIs**: Service callback URLs
   - **Scopes**: openid, profile, email

#### Common Callback URL Patterns
```
https://[service].alimunee.com/api/auth/callback/custom
https://[service].alimunee.com/auth/oidc/callback
https://[service].alimunee.com/oauth/callback
```

## Integration Examples

### Adding SSO to a New Service

1. **Create Zitadel Application** via console at https://zitadel.alimunee.com

2. **Configure Service Environment**:
   ```yaml
   environment:
     - OAUTH_WELLKNOWN_URL=https://zitadel.alimunee.com/.well-known/openid-configuration
     - OAUTH_CLIENT_ID=${ZITADEL_CLIENT_ID}
     - OAUTH_CLIENT_SECRET=${ZITADEL_CLIENT_SECRET}
     - OAUTH_SCOPE=openid email profile
   ```

3. **Update Service Networks**:
   ```yaml
   networks:
     - proxy  # Required for web access
   ```

---

*For detailed SSO configuration, refer to [Zitadel documentation](../../services/zitadel/documentation.md)*
