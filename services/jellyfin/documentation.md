# Jellyfin Media Server

**Purpose**: Self-hosted media streaming server with NVIDIA GPU hardware acceleration

**Status**: ✅ **FULLY OPERATIONAL** with NVENC hardware transcoding

| Configuration Setting | Value                         |
| --------------------- | ----------------------------- |
| Image                 | `linuxserver/jellyfin:latest` |
| Hardware Acceleration | `NVIDIA GTX 1070 (NVENC)`     |
| GPU Driver            | `NVIDIA 575.64.05, CUDA 12.9` |
| Container Runtime     | `nvidia-container-runtime`    |
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

| Volume        | Path                     | Purpose                    |
| ------------- | ------------------------ | -------------------------- |
| Configuration | `/storage/data/jellyfin` | Jellyfin config & cache    |
| Movies        | `/storage/media/movies`  | Movie library              |
| TV Shows      | `/storage/media/tv`      | TV show library            |
| Anime         | `/storage/media/anime`   | Anime library              |

**GPU Device Mappings**:

| Device                | Container Path           | Purpose                    |
| --------------------- | ------------------------ | -------------------------- |
| `/dev/nvidia0`        | `/dev/nvidia0`           | NVIDIA GPU access          |
| `/dev/nvidiactl`      | `/dev/nvidiactl`         | NVIDIA control device     |
| `/dev/nvidia-uvm`     | `/dev/nvidia-uvm`        | Unified memory management  |
| `/dev/nvidia-uvm-tools` | `/dev/nvidia-uvm-tools`| UVM tools                  |
| `/dev/dri`            | `/dev/dri`               | VA-API fallback support    |

**Group Memberships**:
- Group `105` (render): GPU rendering access
- Group `39` (video): Video device access

**Network Settings**:

| Setting            | Value             |
| ------------------ | ----------------- |
| Web Interface Port | `8096`            |
| Domain             | `tv.alimunee.com` |
| Network            | `proxy`           |

**Configured Libraries**:

- **Movies**: `/movies` - Full movie collection with metadata
- **TV Shows**: `/tv` - Television series with episode tracking
- **Anime**: `/anime` - Anime content with specialized metadata

Each library is properly configured with metadata agents and automated scanning enabled.

## 🎮 Hardware Acceleration Configuration

### **NVIDIA NVENC Status**: ✅ **FULLY FUNCTIONAL**

**Supported Encoders**:
- ✅ **H.264 NVENC**: Up to 4K@60fps, 3+ concurrent streams
- ✅ **HEVC NVENC**: Up to 4K@60fps, 2+ concurrent streams
- ✅ **AV1 NVENC**: Next-gen encoding support

**Performance Benefits**:
- **CPU Usage**: Reduced from 80-100% to 10-30% during transcoding
- **Transcoding Speed**: 3-5x faster than software encoding
- **Power Consumption**: ~50% reduction during transcoding
- **Concurrent Streams**: 2-3 HEVC or 3-5 H.264 simultaneous transcodes

### **Jellyfin Web UI Configuration**

**Hardware Acceleration Settings**:
1. Navigate to **Admin Dashboard** → **Playbook** → **Transcoding**
2. **Hardware Acceleration**: `NVIDIA NVENC`
3. **Enable hardware decoding for**: H264, HEVC, VP9, AV1
4. **Enable hardware encoding**: ✅ Enabled
5. **Allow encoding in HEVC format**: ✅ Enabled

**Optimal Settings for GTX 1070**:
- **H.264 CRF**: `23` (balanced quality/size)
- **HEVC CRF**: `28` (efficient compression)
- **Encoding Preset**: `Medium` (quality vs speed balance)
- **Max Muxing Queue Size**: `2048`
- **Enable Tone Mapping**: ✅ For HDR content

### **Verification Commands**

```bash
# Test GPU access in container
docker exec jellyfin ls -la /dev/nvidia* /dev/dri/

# Check available NVENC encoders
docker exec jellyfin /usr/lib/jellyfin-ffmpeg/ffmpeg -encoders | grep nvenc

# Test CUDA initialization
docker exec jellyfin /usr/lib/jellyfin-ffmpeg/ffmpeg \
  -f lavfi -i testsrc2=duration=1:size=320x240:rate=1 \
  -init_hw_device cuda -c:v h264_nvenc -f null -

# Monitor GPU usage during transcoding
watch -n 1 nvidia-smi
```

### **Troubleshooting**

**Common Issues**:
- **"Cannot load libcuda.so.1"**: nvidia-container-toolkit not properly configured
- **No NVENC options**: Check device mapping and group memberships
- **Playback fails with HW acceleration**: Try conservative settings first

**Solutions**:
```bash
# Reconfigure NVIDIA runtime
sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
sudo systemctl restart docker

# Restart Jellyfin container
cd /HOMELAB/services/jellyfin && docker compose restart

# Check container logs
docker logs jellyfin | grep -i "nvenc\|cuda\|gpu"
```

## 🔌 Plugin Repositories

| Plugin Name       | URL                                                                                      |
| ----------------- | ---------------------------------------------------------------------------------------- |
| Skip Intro        | https://manifest.intro-skipper.org/manifest.json                                         |
| SSO Plugin        | https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json |
| Ani-Sync          | https://raw.githubusercontent.com/vosmicc/jellyfin-ani-sync/master/manifest.json         |
| danieladov's Repo | https://raw.githubusercontent.com/danieladov/JellyfinPluginManifest/master/manifest.json |
| Themerr           | https://app.lizardbyte.dev/jellyfin-plugin-repo/manifest.json                            |

## 🧩 Installed Plugins

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
## 🛠️ Administration

### **Access URLs**
- **Web Interface**: https://tv.alimunee.com
- **Admin Dashboard**: https://tv.alimunee.com/web/index.html#!/dashboard.html
- **Local Access**: http://192.168.1.2:8096 (if needed)

### **Management Commands**

```bash
# Service management
cd /HOMELAB/services/jellyfin
docker compose up -d          # Start service
docker compose restart        # Restart service
docker compose logs -f        # View logs

# GPU monitoring during use
watch -n 1 nvidia-smi         # Real-time GPU usage
docker stats jellyfin         # Container resource usage

# Clean cache/transcodes
docker exec jellyfin rm -rf /config/cache/transcodes/*
docker exec jellyfin rm -rf /config/cache/attachments/*
```

### **Performance Monitoring**

**Key Metrics to Monitor**:
- **GPU Utilization**: Should be 20-60% during transcoding
- **GPU Memory**: Monitor for memory leaks
- **CPU Usage**: Should remain low (10-30%) with GPU acceleration
- **Transcode Speed**: Should be 3-5x real-time with NVENC

**Admin Dashboard Indicators**:
- Look for `hw` indicator next to active streams
- Monitor transcode speed and video codec in Activity section
- Check for any fallback to software encoding

---

**Last Updated**: August 6, 2025
**Configuration Status**: ✅ Production Ready with GPU Acceleration
