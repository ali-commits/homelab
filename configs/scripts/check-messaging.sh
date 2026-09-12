#!/usr/bin/env bash
# Reachability check for the public messaging endpoints.
#
# Every request goes out through Cloudflare exactly as a friend's phone does, so a
# failure covers the whole path: DNS, the tunnel, TLS, Traefik routing, and the
# container itself. It runs from cron every 5 minutes and alerts only on a state
# CHANGE - one notification when an endpoint falls over and one when it returns -
# so a long outage does not spam anyone.
set -uo pipefail

STATE_DIR="${STATE_DIR:-/var/lib/messaging-check}"
LOG_FILE="${LOG_FILE:-/var/log/messaging-check.log}"
UA='curl/8.9.1'   # this zone answers Cloudflare 1010 to python-urllib

# shellcheck source=/dev/null
# An explicit NTFY_URL in the environment wins, which is what makes this script
# testable against a throwaway endpoint instead of the real notification service.
if [ -z "${NTFY_URL:-}" ] && [ -f /etc/default/notification-settings ]; then
    . /etc/default/notification-settings
fi
NTFY_URL="${NTFY_URL:-}"
NTFY_TOPIC="${NTFY_TOPIC:-${NTFY_DEFAULT_TOPIC:-system-alerts}}"

# name|url|substring that must appear in a healthy response
CHECKS=(
    "matrix|https://matrix.alimunee.com/_matrix/client/versions|versions"
    "element|https://element.alimunee.com/|Element"
)

install -d -m 755 "${STATE_DIR}"
FAILED=0

notify() {  # title, message, priority
    local title="$1" msg="$2" prio="${3:-3}"
    if [ -n "${NTFY_URL}" ]; then
        curl -sS --max-time 15 -X POST "${NTFY_URL}/${NTFY_TOPIC}" \
            -H "Title: ${title}" \
            -H "Priority: ${prio}" \
            -H "Tags: warning,messaging" \
            -d "${msg}" >/dev/null 2>&1 \
            || echo "[$(date '+%F %T')] ntfy POST failed" >> "${LOG_FILE}"
    fi
    echo "[$(date '+%F %T')] ALERT ${title} - ${msg}" >> "${LOG_FILE}"
}

for entry in "${CHECKS[@]}"; do
    IFS='|' read -r name url marker <<< "${entry}"
    response="$(curl -sS --max-time 20 -A "${UA}" -o - -w $'\n%{http_code}' "${url}" 2>/dev/null)"
    code="${response##*$'\n'}"
    payload="${response%$'\n'*}"

    state=up
    [ "${code}" = "200" ] || state=down
    grep -q -- "${marker}" <<< "${payload}" || state=down
    [ "${state}" = down ] && FAILED=1

    state_file="${STATE_DIR}/${name}"
    previous="$(cat "${state_file}" 2>/dev/null || echo unknown)"
    if [ "${state}" = up ] && [ "${previous}" = unknown ]; then
        # First run after install: record the state without announcing good news.
        printf '%s\n' "${state}" > "${state_file}"
    elif [ "${state}" != "${previous}" ]; then
        if [ "${state}" = down ]; then
            notify "Messaging endpoint DOWN: ${name}" \
                "${url} returned HTTP ${code:-none} without '${marker}'. Check the tuwunel/element containers and the Cloudflare tunnel." 4
        else
            notify "Messaging endpoint recovered: ${name}" "${url} returned HTTP ${code}." 3
        fi
        printf '%s\n' "${state}" > "${state_file}"
    fi
done

# Keep the log bounded; only transitions are written, but it is never rotated.
if [ -f "${LOG_FILE}" ] && [ "$(stat -c %s "${LOG_FILE}")" -gt 1048576 ]; then
    tail -n 200 "${LOG_FILE}" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "${LOG_FILE}"
fi

exit "${FAILED}"
