# Jellyfin

**Purpose**: Self-hosted media streaming server

| Configuration Setting | Value                         |
| --------------------- | ----------------------------- |
| Image                 | `linuxserver/jellyfin:latest` |
| Hardware Acceleration | `AMD GPU enabled`             |
| Memory Limits         | `6GB max, 1GB minimum`        |
| Timezone              | `Asia/Kuala_Lumpur`           |
| PUID/PGID             | `1000`                        |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | tv.alimunee.com                       |
| Cookie Domain     | Not explicitly configured             |
| TLS               | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin   | Not applicable                                |

**Volume Mappings**:

| Volume        | Path                     |
| ------------- | ------------------------ |
| Configuration | `/storage/data/jellyfin` |
| Movies        | `/storage/media/movies`  |
| TV Shows      | `/storage/media/tv`      |
| Anime         | `/storage/media/anime`   |
| GPU Access    | `/dev/dri`               |

**Network Settings**:

| Setting            | Value             |
| ------------------ | ----------------- |
| Web Interface Port | `8096`            |
| Domain             | `tv.alimunee.com` |
| Network            | `proxy`           |

**Configured Libraries**:

- Movies: `/movies`
- TV Shows: `/tv`
- Anime: `/anime`

Each library is properly configured with metadata agents and scanning enabled.

**Plugin Repositories**:

| Plugin Name       | URL                                                                                      |
| ----------------- | ---------------------------------------------------------------------------------------- |
| Skip Intro        | https://manifest.intro-skipper.org/manifest.json                                         |
| SSO Plugin        | https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json |
| Ani-Sync          | https://raw.githubusercontent.com/vosmicc/jellyfin-ani-sync/master/manifest.json         |
| danieladov's Repo | https://raw.githubusercontent.com/danieladov/JellyfinPluginManifest/master/manifest.json |
| Themerr           | https://app.lizardbyte.dev/jellyfin-plugin-repo/manifest.json                            |

**Jellyfin Plugins**

The following plugins are integrated with Jellyfin to enhance its functionality:

| Plugin Name          | Description                                         |
| -------------------- | --------------------------------------------------- |
| `AniDB`              | Integrates AniDB metadata for anime content.        |
| `Anilist`            | Syncs your anime watchlist with Anilist.            |
| `AudioDB`            | Fetches metadata for music files from AudioDB.      |
| `Chapter Creator`    | Automatically creates chapters for media files.     |
| `Intro Skipper`      | Skips intros in TV shows and movies.                |
| `MusicBrainz`        | Fetches metadata for music files from MusicBrainz.  |
| `OMDb`               | Fetches metadata for movies and TV shows from OMDb. |
| `Open Subtitles`     | Downloads subtitles from Open Subtitles.            |
| `Playback Reporting` | Tracks and reports playback statistics.             |
| `Reports`            | Generates various reports for your media library.   |
| `SSO Authentication` | Integrates Single Sign-On (SSO) for authentication. |
| `Skin Manager`       | Manages and applies different skins/themes.         |
| `Studio Images`      | Fetches studio logos and images.                    |
| `Subtitle Extract`   | Extracts subtitles from media files.                |
| `TMDb`               | Fetches metadata for movies and TV shows from TMDb. |
| `Theme Songs`        | Plays theme songs for TV shows and movies.          |
| `Themerr`            | Manages and applies themes for Jellyfin.            |
| `Webhook`            | Sends webhook notifications for various events.     |
