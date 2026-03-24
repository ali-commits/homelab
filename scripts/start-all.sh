#!/bin/bash
# start-all.sh
# Starts all homelab services. Traefik and infrastructure go first,
# everything else follows in alphabetical order.

SERVICES_DIR="/HOMELAB/services"
FAILED=()

start() {
    local name="$1"
    local dir="$SERVICES_DIR/$name"
    echo "▶ Starting $name..."
    if cd "$dir" && docker compose up -d --quiet-pull 2>&1; then
        echo "  ✓ $name"
    else
        echo "  ✗ $name (failed)"
        FAILED+=("$name")
    fi
}

echo "========================================"
echo "  Starting all homelab services"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

# Infrastructure first — everything else depends on these
for svc in traefik postfix cloudflared adguard; do
    start "$svc"
done

echo ""
echo "--- Application services ---"
echo ""

# Everything else alphabetically
for dir in "$SERVICES_DIR"/*/; do
    name=$(basename "$dir")
    [ -f "$dir/docker-compose.yml" ] || continue
    case "$name" in
        traefik|postfix|cloudflared|adguard) continue ;;
    esac
    start "$name"
done

echo ""
echo "========================================"
if [ ${#FAILED[@]} -eq 0 ]; then
    echo "  All services started successfully"
else
    echo "  Failed services (${#FAILED[@]}):"
    for f in "${FAILED[@]}"; do
        echo "    - $f"
    done
fi
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
