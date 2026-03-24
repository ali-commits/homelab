#!/bin/bash
# revert-docker-nodatacow.sh
# Reverts /var/lib/docker from nodatacow back to normal btrfs CoW.
# Inverse of migrate-docker-nodatacow.sh.
#
# Does NOT start services — only restores Docker daemon.

set -e

DOCKER_DIR="/var/lib/docker"
BACKUP_DIR="/tmp/docker-restore"

# ── Colours ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}▶ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $*${NC}"; }
error()   { echo -e "${RED}✗ $*${NC}"; exit 1; }
ok()      { echo -e "${GREEN}✓ $*${NC}"; }

# ── Pre-flight checks ──────────────────────────────────────────────────────────
echo "========================================"
echo "  Revert Docker nodatacow → CoW"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

[[ $EUID -ne 0 ]] && error "Run as root: sudo $0"

# Verify nodatacow is currently set
ATTR=$(lsattr -d "$DOCKER_DIR" 2>/dev/null | awk '{print $1}')
if [[ "$ATTR" != *C* ]]; then
    error "$DOCKER_DIR does not have nodatacow set — nothing to revert"
fi
info "Current flags: $ATTR (nodatacow confirmed)"

# Check no containers are running
if docker ps -q 2>/dev/null | grep -q .; then
    error "Containers are still running. Stop all services first."
fi

info "Checking available space..."
FREE_GB=$(df /tmp --output=avail -BG | tail -1 | tr -d 'G ')
DOCKER_GB=$(du -s "$DOCKER_DIR" | awk '{print int($1/1024/1024)+1}')
info "  Docker dir: ~${DOCKER_GB}GB  |  Free: ~${FREE_GB}GB"
[[ $FREE_GB -lt $((DOCKER_GB + 10)) ]] && error "Not enough free space. Need $((DOCKER_GB + 10))GB, have ${FREE_GB}GB"
ok "Pre-flight checks passed"
echo ""

# ── Step 1: Stop Docker ─────────────────────────────────────────────────────
info "Step 1/5 — Stopping Docker daemon..."
systemctl stop docker docker.socket 2>/dev/null
sleep 2
pgrep -x dockerd > /dev/null && error "Docker is still running"
ok "Docker stopped"
echo ""

# ── Step 2: Copy data to temp (regular cp, no reflink — nodatacow can't reflink) ─
info "Step 2/5 — Copying data to $BACKUP_DIR..."
info "  (nodatacow files cannot use reflink — this will be a full copy)"
[ -d "$BACKUP_DIR" ] && rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -a "$DOCKER_DIR/." "$BACKUP_DIR/"
ok "Backup created"
echo ""

# ── Step 3: Empty directory and remove nodatacow ────────────────────────────
info "Step 3/5 — Clearing $DOCKER_DIR and removing nodatacow flag..."
find "$DOCKER_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
chattr -C "$DOCKER_DIR"
ATTR=$(lsattr -d "$DOCKER_DIR" | awk '{print $1}')
echo "  lsattr: $ATTR"
[[ "$ATTR" == *C* ]] && error "nodatacow flag still set — removal failed"
ok "nodatacow removed — back to normal CoW"
echo ""

# ── Step 4: Restore data (now with CoW, reflink-capable) ───────────────────
info "Step 4/5 — Restoring data..."
cp -a "$BACKUP_DIR/." "$DOCKER_DIR/"
ok "Data restored"
echo ""

info "  Removing backup..."
rm -rf "$BACKUP_DIR"
ok "Backup removed"
echo ""

# ── Step 5: Start Docker ────────────────────────────────────────────────────
info "Step 5/5 — Starting Docker..."
systemctl start docker
sleep 3
systemctl is-active docker > /dev/null || error "Docker failed to start"
ok "Docker running"
echo ""

echo "========================================"
echo "  Revert complete"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "  Verify CoW restored:"
echo "    lsattr -d /var/lib/docker"
echo ""
echo "  Services NOT started — run manually:"
echo "    bash /HOMELAB/scripts/start-all.sh"
echo "========================================"
