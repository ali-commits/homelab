#!/bin/bash
# migrate-docker-nodatacow.sh
# Migrates /var/lib/docker to nodatacow on btrfs.
# This eliminates CoW accumulation from Docker overlay2 upper directories,
# which was causing ~8GB/hr of hidden btrfs space growth.
#
# Safe to run: uses a reflink backup before touching anything.
# Requires: ~95GB free space, ~30min downtime for all services.

set -e

SERVICES_DIR="/HOMELAB/services"
DOCKER_DIR="/var/lib/docker"
BACKUP_DIR="/tmp/docker-restore"
INFRA_SERVICES=(traefik postfix cloudflared adguard)

# ── Colours ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}▶ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $*${NC}"; }
error()   { echo -e "${RED}✗ $*${NC}"; exit 1; }
ok()      { echo -e "${GREEN}✓ $*${NC}"; }

# ── Pre-flight checks ──────────────────────────────────────────────────────────
echo "========================================"
echo "  Docker nodatacow migration"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

[[ $EUID -ne 0 ]] && error "Run as root: sudo $0"

info "Checking available space..."
FREE_GB=$(df /tmp --output=avail -BG | tail -1 | tr -d 'G ')
DOCKER_GB=$(du -s "$DOCKER_DIR" | awk '{print int($1/1024/1024)+1}')
info "  Docker dir: ~${DOCKER_GB}GB  |  Free: ~${FREE_GB}GB"
[[ $FREE_GB -lt $((DOCKER_GB + 10)) ]] && error "Not enough free space. Need $((DOCKER_GB + 10))GB, have ${FREE_GB}GB"

info "Checking btrfs filesystem..."
btrfs filesystem usage / > /dev/null 2>&1 || error "/var/lib/docker is not on a btrfs filesystem"
ok "Pre-flight checks passed"
echo ""

# ── Step 1: Stop all services ──────────────────────────────────────────────────
info "Step 1/7 — Stopping all services..."
for dir in "$SERVICES_DIR"/*/; do
    [ -f "$dir/docker-compose.yml" ] || continue
    name=$(basename "$dir")
    cd "$dir"
    if docker compose ps -q 2>/dev/null | grep -q .; then
        echo "  Stopping $name..."
        docker compose down --remove-orphans 2>/dev/null || warn "  $name had errors stopping"
    fi
done
ok "All services stopped"
echo ""

# ── Step 2: Stop Docker ────────────────────────────────────────────────────────
info "Step 2/7 — Stopping Docker daemon..."
systemctl stop docker docker.socket 2>/dev/null
sleep 2
pgrep -x dockerd > /dev/null && error "Docker is still running, cannot proceed"
ok "Docker stopped"
echo ""

# ── Step 3: Reflink backup (instant) ──────────────────────────────────────────
info "Step 3/7 — Creating reflink backup to $BACKUP_DIR..."
[ -d "$BACKUP_DIR" ] && rm -rf "$BACKUP_DIR"
cp -a --reflink=always "$DOCKER_DIR/." "$BACKUP_DIR/"
ok "Backup created (reflink — instant, minimal extra space used)"
echo ""

# ── Step 4: Empty the docker directory ────────────────────────────────────────
info "Step 4/7 — Clearing $DOCKER_DIR..."
find "$DOCKER_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
ok "Directory cleared"
echo ""

# ── Step 5: Set nodatacow ─────────────────────────────────────────────────────
info "Step 5/7 — Setting nodatacow flag on $DOCKER_DIR..."
chattr +C "$DOCKER_DIR"
ATTR=$(lsattr -d "$DOCKER_DIR" | awk '{print $1}')
echo "  lsattr: $ATTR"
[[ "$ATTR" == *C* ]] || error "nodatacow flag not set — check filesystem support"
ok "nodatacow set"
echo ""

# ── Step 6: Restore data ──────────────────────────────────────────────────────
info "Step 6/7 — Restoring data (new inodes will inherit nodatacow)..."
info "  This will take several minutes..."
cp -a "$BACKUP_DIR/." "$DOCKER_DIR/"
ok "Data restored"
echo ""

info "  Removing backup..."
rm -rf "$BACKUP_DIR"
ok "Backup removed"
echo ""

# ── Step 7: Start Docker and all services ─────────────────────────────────────
info "Step 7/7 — Starting Docker..."
systemctl start docker
sleep 3
systemctl is-active docker > /dev/null || error "Docker failed to start"
ok "Docker running"
echo ""

info "Starting services..."
# Infrastructure first
for svc in "${INFRA_SERVICES[@]}"; do
    dir="$SERVICES_DIR/$svc"
    [ -f "$dir/docker-compose.yml" ] || continue
    echo "  Starting $svc..."
    cd "$dir" && docker compose up -d --quiet-pull 2>/dev/null
done

# Everything else
for dir in "$SERVICES_DIR"/*/; do
    [ -f "$dir/docker-compose.yml" ] || continue
    name=$(basename "$dir")
    [[ " ${INFRA_SERVICES[*]} " == *" $name "* ]] && continue
    echo "  Starting $name..."
    cd "$dir" && docker compose up -d --quiet-pull 2>/dev/null
done
ok "All services started"

echo ""
echo "========================================"
echo "  Migration complete"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "  Verify nodatacow:"
echo "    lsattr -d /var/lib/docker"
echo ""
echo "  Monitor growth (should be near zero now):"
echo "    sudo btrfs filesystem usage / | grep 'Used:'"
echo "========================================"
