#!/bin/bash
# isolate-service-growth.sh
# Starts each suspect service one at a time, monitors btrfs Used every 2 minutes
# for 15 minutes, then moves to the next service.
# Log output to stdout — redirect to file if desired.

set -e

SERVICES_DIR="/HOMELAB/services"
SUSPECTS=(kuma it-tools flood karakeep n8n stirling-pdf checkmate)
INTERVAL=120    # 2 minutes
READINGS=8      # 8 readings × 2 min = 16 min per service

get_used() {
    sudo btrfs filesystem usage / 2>/dev/null | awk '/^\s+Used:/{print $2}'
}

INFRA_SERVICES=(traefik postfix cloudflared adguard beszel)

echo "========================================"
echo "  Service Isolation Test"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

# Stop all services first
echo "▶ Stopping all services..."
for dir in "$SERVICES_DIR"/*/; do
    [ -f "$dir/docker-compose.yml" ] || continue
    (cd "$dir" && docker compose down --remove-orphans 2>/dev/null)
done
docker container prune -f 2>/dev/null > /dev/null
echo "✓ All services stopped"
echo ""

# Start infrastructure + beszel
echo "▶ Starting infrastructure + beszel..."
for svc in "${INFRA_SERVICES[@]}"; do
    cd "$SERVICES_DIR/$svc"
    docker compose up -d --quiet-pull 2>/dev/null
done
echo "✓ Infrastructure running"
echo ""

BASELINE=$(get_used)
echo "Baseline (infra only): $BASELINE"
echo ""

for svc in "${SUSPECTS[@]}"; do
    echo "========================================"
    echo "▶ Starting $svc at $(date '+%H:%M:%S')"
    echo "========================================"

    START_USED=$(get_used)
    echo "  Before start: $START_USED"

    cd "$SERVICES_DIR/$svc"
    docker compose up -d --quiet-pull 2>/dev/null

    for i in $(seq 1 $READINGS); do
        sleep $INTERVAL
        CURRENT=$(get_used)
        echo "  +$(( i * 2 ))min: $CURRENT"
    done

    END_USED=$(get_used)
    echo "  ── $svc summary: $START_USED → $END_USED"
    echo ""
done

echo "========================================"
echo "  Test complete at $(date '+%Y-%m-%d %H:%M:%S')"
echo "  Final Used: $(get_used)"
echo "========================================"
