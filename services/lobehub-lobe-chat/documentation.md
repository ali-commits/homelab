# Lobe Chat

**Purpose**: Open-source AI chat framework and personal LLM productivity tool

| Configuration Setting | Value                      |
| --------------------- | -------------------------- |
| Image                 | `lobehub/lobe-chat:latest` |
| Memory Limits         | `1GB max, 256MB minimum`   |
| Timezone              | `Asia/Kuala_Lumpur`        |

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | chat.alimunee.com                           |
| Access Code     | Required (set in environment)               |
| API Keys        | Optional (set in environment)               |
| Ollama URL      | Optional (set in environment)               |
| TLS             | Disabled internally (handled by Cloudflare) |

**Volume Mappings**:

| Volume | Path                      |
| ------ | ------------------------- |
| Data   | `/storage/data/lobe-chat` |

**Network Settings**:

| Setting            | Value               |
| ------------------ | ------------------- |
| Web Interface Port | `3210`              |
| Domain             | `chat.alimunee.com` |
| Network            | `proxy`             |

**Security Considerations**:

- **Access Code is mandatory** for security. Change `yoursecureaccesscode`.
- API keys for external services should be kept secret.
- Protected behind Traefik proxy.

**Usage Instructions**:

1. Access the interface at chat.alimunee.com
2. Enter the configured Access Code.
3. Configure connections to AI providers (OpenAI, Ollama, etc.) using API keys or URLs.
4. Start chatting with various AI models.
5. Utilize features like knowledge base, plugins, and multi-modal capabilities.

**Features**:

- Supports multiple AI providers (OpenAI, Ollama, Gemini, Claude, etc.)
- Knowledge Base (RAG)
- Multi-modal capabilities
- Plugin system and Agent Market
- Speech synthesis

**Maintenance**:

- Regularly backup the data volume.
- Update the container for security patches and new features.
- Manage API keys securely.
