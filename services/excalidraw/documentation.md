# Excalidraw

**Purpose**: Virtual collaborative whiteboard with hand-drawn style diagrams

| Configuration Setting | Value                         |
| --------------------- | ----------------------------- |
| Image                 | `excalidraw/excalidraw:latest` |
| Memory Limits         | `1GB max, 128MB minimum`      |
| Timezone              | `Asia/Kuala_Lumpur`           |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | draw.alimunee.com                     |
| TLS               | Disabled internally (handled by Cloudflare) |

**Network Settings**:

| Setting            | Value                |
| ------------------ | -------------------- |
| Web Interface Port | `80`                 |
| Domain             | `draw.alimunee.com`  |
| Network            | `proxy`              |

**Security Considerations**:
- Stateless application with no persistent data
- Isolated network access through Traefik proxy
- Collaboration links should be treated as sensitive

**Usage Instructions**:
1. Access the drawing board at draw.alimunee.com
2. Create diagrams, flowcharts, and sketches with the hand-drawn style
3. Share the URL for collaborative editing
4. Export drawings in various formats (PNG, SVG, etc.)
5. Import existing drawings

**Features**:
- Hand-drawn style diagrams
- Collaborative editing
- Simple and intuitive interface
- Support for shapes, text, and free-hand drawing
- Export and import capabilities

**Maintenance**:
- Low maintenance requirements
- Update the container for security patches and new features
