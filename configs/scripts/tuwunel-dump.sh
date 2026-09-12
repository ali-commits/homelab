#!/usr/bin/env bash
# Nightly consistent backup of the Tuwunel database, plus a copy of the service
# .env, into /storage/data/tuwunel/dumps.
#
# This deliberately does NOT copy the database directory. It asks the running
# server to create a managed RocksDB backup (admin_signal_execute on SIGUSR2,
# configured in compose.yml), so the result is consistent, the server keeps
# running, and RocksDB itself enforces the 7-backup retention. Kopia then carries
# /storage/data - this repository included - to Backblaze B2.
#
# Restore: services/tuwunel/documentation.md (tuwunel --restore-backup).
set -euo pipefail

DUMPS=/storage/data/tuwunel/dumps
ENV_FILE=/HOMELAB/services/tuwunel/.env
CONTAINER=tuwunel
TIMEOUT=120

install -d -o 1000 -g 1000 -m 750 "${DUMPS}"

# The invite token and the permanent server name exist only in this gitignored
# .env, which lives in /HOMELAB - outside the Kopia snapshot scope. Keep a copy
# beside the dumps so a rebuild needs nothing that is not in the backup.
if [ -f "${ENV_FILE}" ]; then
    install -o 1000 -g 1000 -m 600 "${ENV_FILE}" "${DUMPS}/tuwunel.env"
else
    echo "WARNING: ${ENV_FILE} not found; backup continues without the env copy" >&2
fi

newest_backup_id() {
    ls -1 "${DUMPS}/private" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -1
}

# Epoch seconds, not an ISO string: docker reads a bare RFC3339 value as local time,
# which made an earlier version of this script "find" a backup from the previous run.
SINCE="$(date +%s)"
before="$(newest_backup_id)"
docker kill -s SIGUSR2 "${CONTAINER}"

after=""
for _ in $(seq 1 $((TIMEOUT / 2))); do
    after="$(newest_backup_id)"
    [ -n "${after}" ] && [ "${after:-0}" -gt "${before:-0}" ] && break
    sleep 2
done

if [ -z "${after}" ] || [ "${after:-0}" -le "${before:-0}" ]; then
    echo "FAILED: no new backup in ${DUMPS}/private within ${TIMEOUT}s (still at id ${before:-none})." >&2
    echo "The SIGUSR2 handler is probably missing - check the admin_signal_execute --option in compose.yml." >&2
    exit 1
fi

result="$(docker logs --since "${SINCE}" "${CONTAINER}" 2>&1 | grep -m1 'Created database backup' || true)"
echo "Tuwunel backup OK: backup_id ${after} (was ${before:-none})"
[ -n "${result}" ] && echo "Server log: ${result#*backup: }"
echo "Repository: $(du -sh "${DUMPS}" | cut -f1) in ${DUMPS} (retention 7, enforced by RocksDB)"
