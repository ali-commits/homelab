# Khoj

**Purpose**: Self-hosted personal AI assistant that connects to your documents and the web

| Configuration Setting | Value                    |
| --------------------- | ------------------------ |
| Image                 | `khoj/khoj:latest`       |
| Memory Limits         | `2GB max, 512MB minimum` |
| Timezone              | `Asia/Kuala_Lumpur`      |

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | khoj.alimunee.com                           |
| Data Directory  | /data                                       |
| OpenAI API      | Not configured (optional)                   |
| TLS             | Disabled internally (handled by Cloudflare) |

**Volume Mappings**:

| Volume | Path                 |
| ------ | -------------------- |
| Data   | `/storage/data/khoj` |

**Network Settings**:

| Setting            | Value               |
| ------------------ | ------------------- |
| Web Interface Port | `8000`              |
| Domain             | `khoj.alimunee.com` |
| Network            | `proxy`             |

**Security Considerations**:

- Protected behind Traefik proxy
- Consider whether to add API keys for external AI services
- Data is stored locally for privacy

**Usage Instructions**:

1. Access Khoj at khoj.alimunee.com
2. Set up connections to your document sources (notes, PDFs, etc.)
3. Chat with your personal AI assistant about your documents
4. Use Khoj to search through your knowledge base
5. Set up integrations with tools like Obsidian or Emacs if needed

**Features**:

- AI-powered search across personal documents
- Chat interface for questions about your data
- Integration with local or cloud LLMs
- Context-aware summaries and insights
- Custom agent capabilities
- Offline-first design

**Maintenance**:

- Regularly backup the data volume
- Update the container for security patches and new features
- Monitor memory usage when processing large document collections
