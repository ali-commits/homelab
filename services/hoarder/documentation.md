# Karakeep (formerly Hoarder)

**Purpose**: Self-hosted "Bookmark Everything" app with AI-powered tagging

| Configuration Setting | Value                                  |
| --------------------- | -------------------------------------- |
| Image                 | `ghcr.io/karakeep-app/karakeep:latest` |
| Memory Limits         | `1GB max, 256MB minimum`               |
| Timezone              | `Asia/Kuala_Lumpur`                    |
| Meilisearch           | Included for full-text search          |

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | bookmarks.alimunee.com                      |
| Meilisearch     | Internal access only                        |
| TLS             | Disabled internally (handled by Cloudflare) |

**Volume Mappings**:

| Volume           | Path                                 |
| ---------------- | ------------------------------------ |
| Karakeep Data    | `/storage/data/karakeep`             |
| Meilisearch Data | `/storage/data/karakeep-meilisearch` |

**Network Settings**:

| Setting            | Value                                              |
| ------------------ | -------------------------------------------------- |
| Web Interface Port | `3000`                                             |
| Domain             | `bookmarks.alimunee.com`                           |
| Networks           | `proxy` (external), `karakeep_internal` (internal) |

**Security Considerations**:

- Meilisearch is isolated in an internal network
- Meilisearch master key should be changed to a secure value
- Protected behind Traefik proxy
- Analytics disabled for privacy

**Usage Instructions**:

1. Access the interface at bookmarks.alimunee.com
2. Save bookmarks, notes, images, and PDFs
3. Enjoy automatic AI-based tagging
4. Use full-text search to find your content
5. Install the browser extension for easy bookmarking

**Features**:

- Bookmark links with automatic metadata extraction
- Take simple notes
- Store images and PDFs
- AI-powered automatic tagging
- Full-text search via Meilisearch
- Dark mode
- Chrome plugin support
- iOS app compatibility

**Maintenance**:

- Regularly backup both data volumes
- Check for updates to both containers
- Monitor memory usage of Meilisearch for large collections
