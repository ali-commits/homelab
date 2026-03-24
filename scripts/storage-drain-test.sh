#!/bin/bash
# storage-drain-test.sh
# Stops services one by one, measuring btrfs Used after each to find CoW accumulators.

SERVICES_DIR="/HOMELAB/services"
LOG_FILE="/storage/data/logs/storage-monitor/drain-test-$(date +%Y-%m-%d_%H-%M).log"

btrfs_used() {
    sudo btrfs filesystem usage / 2>/dev/null | awk '/^    Used:/ {print $2}'
}

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Build ordered list: services with running containers first, sorted by name
SERVICES=()
for dir in "$SERVICES_DIR"/*/; do
    [ -f "$dir/docker-compose.yml" ] || continue
    name=$(basename "$dir")
    # Check if any container from this service is running
    running=$(cd "$dir" && docker compose ps -q 2>/dev/null | wc -l)
    [ "$running" -gt 0 ] && SERVICES+=("$name")
done

log "========================================"
log "  Storage Drain Test — $(date '+%Y-%m-%d %H:%M:%S')"
log "========================================"
log "Services to drain: ${#SERVICES[@]}"
log ""

BASELINE=$(btrfs_used)
log "Baseline btrfs Used: $BASELINE"
log ""
log "%-25s %-15s %-15s %-10s" "SERVICE" "BEFORE" "AFTER" "FREED"
log "$(printf '%.0s-' {1..65})"

declare -A RESULTS

for name in "${SERVICES[@]}"; do
    dir="$SERVICES_DIR/$name"
    before=$(btrfs_used)

    cd "$dir"
    docker compose down --remove-orphans -v=false 2>/dev/null

    after=$(btrfs_used)

    # Calculate freed (handle GiB values)
    freed=$(awk -v b="${before%GiB}" -v a="${after%GiB}" 'BEGIN {
        diff = b - a
        if (diff < 0) diff = 0
        printf "%.2f GiB", diff
    }')

    RESULTS["$name"]="$freed"
    log "$(printf '%-25s %-15s %-15s %-10s' "$name" "$before" "$after" "$freed")"
done

log ""
log "========================================"
log "  All services stopped"
log "  Final btrfs Used: $(btrfs_used)"
log "  Started at:       $BASELINE"
log "========================================"
log ""
log "Top space releasers:"
for name in "${!RESULTS[@]}"; do
    echo "${RESULTS[$name]} $name"
done | sort -rh | head -15 | tee -a "$LOG_FILE"

log ""
log "Done. Full log at: $LOG_FILE"
