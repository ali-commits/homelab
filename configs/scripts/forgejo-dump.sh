#!/usr/bin/env bash
# Nightly logical backup of Forgejo into /storage/data/forgejo/dumps, keeping 7 days.
#
# Kopia already snapshots /storage/data to Backblaze B2, but copying a live Postgres
# data directory is not a consistent backup. This produces one.
set -euo pipefail

DUMPS=/storage/data/forgejo/dumps
STAMP="$(date +%F)"
KEEP_DAYS=7
OUT="${DUMPS}/forgejo-${STAMP}.zip"

install -d -o 1000 -g 1000 -m 750 "${DUMPS}"

# /dumps inside the container is bind-mounted to ${DUMPS}, and the dump must be
# written by the git user (uid 1000) so the host files stay readable.
docker exec -u git forgejo forgejo dump --quiet --file "/dumps/forgejo-${STAMP}.zip"

chmod 600 "${OUT}" 2>/dev/null || true
find "${DUMPS}" -maxdepth 1 -name 'forgejo-*.zip' -mtime "+${KEEP_DAYS}" -delete

echo "Forgejo dump written: ${OUT} ($(du -h "${OUT}" | cut -f1)), keeping ${KEEP_DAYS} days"
