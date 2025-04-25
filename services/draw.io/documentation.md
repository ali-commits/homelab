# Draw.io

**Purpose**: Comprehensive diagramming tool for flowcharts, UML, network diagrams, and more

| Configuration Setting | Value                     |
| --------------------- | ------------------------- |
| Image                 | `jgraph/drawio:latest`    |
| Memory Limits         | `1GB max, 128MB minimum`  |
| Timezone              | `Asia/Kuala_Lumpur`       |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | diagram.alimunee.com                  |
| TLS               | Disabled internally (handled by Cloudflare) |

**Network Settings**:

| Setting            | Value                  |
| ------------------ | ---------------------- |
| Web Interface Port | `8080`                 |
| Domain             | `diagram.alimunee.com` |
| Network            | `proxy`                |

**Security Considerations**:
- Client-side application with minimal security requirements
- Protected behind Traefik proxy
- No server-side storage of diagrams by default

**Usage Instructions**:
1. Access the diagramming tool at diagram.alimunee.com
2. Create flowcharts, UML diagrams, network diagrams, and more
3. Use the extensive template and shape libraries
4. Generate diagrams from text (PlantUML, Mermaid, CSV, SQL)
5. Export diagrams in various formats (PNG, SVG, PDF, etc.)
6. Save diagrams locally or integrate with cloud storage

**Features**:
- Extensive template and shape libraries
- Support for various diagram types (flowcharts, UML, ER diagrams, etc.)
- Text-based diagram generation
- Customizable editor
- Export and import capabilities

**Maintenance**:
- Low maintenance requirements
- Update the container for security patches and new features
