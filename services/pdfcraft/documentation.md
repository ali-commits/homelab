# PDFCraft - Browser-Based PDF Toolkit

## Purpose
PDFCraft is a self-hosted, privacy-first PDF toolkit offering 90+ tools for document manipulation. All processing happens entirely client-side in the browser via WebAssembly (PDF.js, pdf-lib, PyMuPDF) — no files are ever uploaded to the server. It complements Stirling-PDF (`pdf.alimunee.com`) with a different toolset and a beta workflow editor for chaining operations.

## Configuration

### Environment Variables
| Variable | Description      | Default           | Required |
| -------- | ---------------- | ----------------- | -------- |
| TZ       | Timezone setting | Asia/Kuala_Lumpur | No       |

### Ports
- **80**: Internal Nginx port serving the static site (not published to host; routed via Traefik)

### Domains
- **External**: https://pdfcraft.alimunee.com
- **Internal**: http://pdfcraft:80

## Dependencies
- **Networks**: proxy (for Traefik routing)
- **Storage**: None — stateless static site, all processing is client-side
- **Database**: None
- **External Services**: Sablier (wake-on-demand scaling)

## Wake-on-Demand (Sablier)
PDFCraft is a low-traffic static tool, so it is scaled to zero by Sablier and woken on first HTTP request.
- **Sablier group**: `pdfcraft-stack`
- **Session duration**: 5m (container stops 5 minutes after last request)
- `restart: 'no'` so Sablier controls the lifecycle
- Added to the `SABLIER_SERVICES` array in `scripts/start-all.sh`

## Setup

### 1. Deploy Service
```bash
cd /HOMELAB/services/pdfcraft
docker compose up -d
```

### 2. Verify
```bash
docker ps | grep pdfcraft
curl -I https://pdfcraft.alimunee.com/
```

The first request after idle may take a few seconds while Sablier wakes the container.

## Usage

### Web Interface
- **URL**: https://pdfcraft.alimunee.com
- **Tool categories**:
  - **Organization**: merge, split, rotate, page management
  - **Editing**: annotations, watermarks, signatures, form creation
  - **Conversion**: to/from PDF (images, documents, ebooks)
  - **Optimization**: compression, repair, linearization
  - **Security**: encryption, decryption, metadata removal
- **Workflow Editor (beta)**: chain multiple operations into automated pipelines with 23+ preset templates

## Troubleshooting

### Web Interface Not Accessible
```bash
# Verify container is running (Sablier may have scaled it to zero — hit the URL to wake it)
docker ps | grep pdfcraft

# Check Traefik routing / Sablier middleware
docker logs pdfcraft
docker logs sablier
```

### Container Won't Stay Up
Because `restart: 'no'`, the container is expected to stop when idle — this is normal Sablier behavior, not a failure.

## Backup
None required — PDFCraft is stateless. The image is rebuilt/pulled from `ghcr.io/pdfcrafttool/pdfcraft:latest` and holds no persistent data.
