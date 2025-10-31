# Authentication Infrastructure

## Overview

Centralized authentication and identity management using Zitadel for SSO capabilities across homelab services.

## Service

### Zitadel - Modern SSO & Identity Management
- **Purpose**: Centralized authentication and identity management
- **Ports**: 8081, 3001
- **Domain**: zitadel.alimunee.com
- **Network**: proxy, zitadel_internal
- **Documentation**: [📖](../../services/zitadel/documentation.md)

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
  - OAUTH_WELLKNOWN_URL=https://zitadel.alimunee.com/.well-known/openid_configuration
  - OAUTH_CLIENT_ID=${ZITADEL_CLIENT_ID}
  - OAUTH_CLIENT_SECRET=${ZITADEL_CLIENT_SECRET}
  - OAUTH_SCOPE=openid email profile
```

#### Services with SSO Integration
- **Lobe Chat**: NextAuth.js with Zitadel provider integration
- **Karakeep**: OIDC via generic OAuth configuration
- **Infisical**: Native Zitadel integration
- **Nextcloud**: OIDC app integration
- **Paperless-ngx**: OIDC configuration available
- **Komodo**: Built-in OIDC support

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
     - OAUTH_WELLKNOWN_URL=https://zitadel.alimunee.com/.well-known/openid_configuration
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
