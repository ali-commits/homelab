# Immich

**Purpose**: Self-hosted photo and video management solution

**Components**:

1. **Immich Server**:

   - Primary service for the web interface and API
   - Port: 2283
   - Handles user authentication and file serving

2. **Machine Learning Service**:

   - Provides AI features like facial recognition and object detection
   - Uses a model cache for improved performance

3. **PostgreSQL Database with pgvecto-rs**:

   - Stores metadata, user information, and vector embeddings
   - Optimized for image similarity search

4. **Redis**:
   - Session management
   - Caching layer

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | https://photos.alimunee.com                 |
| Cookie Domain   | Not explicitly configured                   |
| TLS             | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin | Not applicable                              |

**Data Storage**:

- Uploads: `/storage/Immich/uploads`
- Database: `/storage/Immich/database`
- Model Cache: `/storage/Immich/model-cache`

**Machine Learning Configuration**:

Immich's machine learning capabilities are enhanced with custom models:

- **Face Recognition Model**: XLM-Roberta-Large-Vit-B-16Plus (upgraded from default)
- **Object Detection Model**: AntelopeV2 (upgraded from default)

These models provide improved accuracy for:

- Facial recognition
- Person detection
- Object and scene classification
- Image search capabilities

**Authentication**: Integrated with Zitadel using OAuth 2.0

**OAuth Integration with Zitadel**:

Immich is configured to use Zitadel as an OAuth provider with the following settings:

- OAuth Enabled: Yes
- OAuth Auto Register: Yes
- OAuth Auto Register Admin: No
- OAuth Issuer URL: https://auth.alimunee.com/application/o/immich/
- Client ID: .env
- OAuth Client Secret: .env
- Authentication flow: Authorization Code
- Redirect URI: `https://photos.alimunee.com/auth/login`
- Scope configuration: `openid profile email`
- OAuth Storage Label: Zitadel

**User Management**:

Users are provisioned through Zitadel's invitation system:

1. Administrator creates a user in Zitadel
2. User is added to the "Immich Users" group
3. An invitation is generated and sent to the user
4. User sets up their own password through the invitation link
5. User can then access Immich through SSO

**Import Methods**:

Several methods are available for importing photos into Immich:

1. **Web Interface Upload**: Direct upload through the Immich web UI
2. **Mobile App Backup**: Configure the Immich mobile app to back up photos
3. **Google Takeout Import**: Using Google Takeout to export photos and import them into Immich
4. **Immich CLI**: Command-line tool for bulk imports

**Maintenance Procedures**:

### Backup Procedures

Immich data is backed up through the Btrfs snapshot system:

- Daily snapshots of the Immich subvolume
- Snapshot retention: 7 daily, 4 weekly, 2 monthly
- Maximum snapshot space: 25% of volume

**Mobile App Configuration**:

The Immich mobile app can be configured to connect to the server:

1. Download the app from Google Play Store or Apple App Store
2. Enter server URL: https://photos.alimunee.com
3. Log in with Zitadel credentials
4. Configure backup settings:
   - Select albums to back up
   - Set backup conditions (Wi-Fi only, charging only, etc.)
   - Configure background backup frequency

**Network Configuration**:

- Web Interface: Port 2283
- Two networks:
  - `proxy` - For external access through Traefik
  - `immich_internal` - Private network for inter-service communication

**Features**:

- Photo and video backup
- Facial recognition and object detection
- Timeline view
- Albums and sharing
- Mobile app support
- Metadata extraction
