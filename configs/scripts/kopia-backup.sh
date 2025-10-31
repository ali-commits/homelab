#!/bin/bash

# Kopia Backup Script for Homelab
# Daily backups with automatic retention (10 days, 12 months)

# --- Configuration ---
# Load environment variables (try system env file first, then development .env)
if [ -f "/etc/default/kopia-backup" ]; then
    set -a  # automatically export all variables
    source "/etc/default/kopia-backup"
    set +a
elif [ -f "/HOMELAB/configs/defaults/kopia-backup.env" ]; then
    set -a  # automatically export all variables
    source "/HOMELAB/configs/defaults/kopia-backup.env"
    set +a
elif [ -f "/HOMELAB/.env" ]; then
    set -a  # automatically export all variables
    source "/HOMELAB/.env"
    set +a
else
    echo "ERROR: No environment file found"
    exit 1
fi

# Validate required environment variables
if [ -z "$KOPIA_PASSWORD" ]; then
    echo "ERROR: KOPIA_PASSWORD not set in environment"
    exit 1
fi

LOG_FILE="/var/log/kopia-backup.log"

# Subvolumes to backup
SUBVOLUMES_TO_BACKUP=(
    "/storage/data"
    "/storage/Immich"
    "/storage/nextcloud"
)

# Load notification settings
if [ -f /etc/default/notification-settings ]; then
    source /etc/default/notification-settings
    NTFY_TOPIC="${NTFY_DEFAULT_TOPIC:-homelab-alerts}"
elif [ -f "/HOMELAB/configs/defaults/notification-settings" ]; then
    source "/HOMELAB/configs/defaults/notification-settings"
    NTFY_TOPIC="${NTFY_DEFAULT_TOPIC:-homelab-alerts}"
else
    NTFY_URL="http://homelab.local:8080"
    NTFY_TOPIC="homelab-alerts"
fi

# --- Functions ---
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_notification() {
    local title="$1"
    local message="$2"
    local priority="${3:-3}"
    if [ -n "$NTFY_URL" ] && [ -n "$NTFY_TOPIC" ]; then
        curl -s -X POST "$NTFY_URL/$NTFY_TOPIC" \
            -H "Title: $title" \
            -H "Priority: $priority" \
            -H "Tags: backup,kopia,homelab" \
            -d "$message" || log_message "WARNING: Failed to send notification"
    fi
    log_message "NOTIFICATION: $title - $message"
}

backup_subvolume() {
    local subvolume_path="$1"
    local subvolume_name=$(basename "$subvolume_path")

    log_message "Starting backup of $subvolume_path"

    # Create snapshot with tags (key:value format)
    if KOPIA_PASSWORD="$KOPIA_PASSWORD" kopia snapshot create "$subvolume_path" \
        --tags "type:daily" \
        --tags "month:$(date +%Y-%m)" \
        --tags "source:homelab" \
        --tags "volume:$subvolume_name" \
        --description "Daily backup of $subvolume_name - $(date '+%Y-%m-%d %H:%M:%S')"; then
        log_message "Successfully backed up $subvolume_path"
        return 0
    else
        log_message "ERROR: Failed to backup $subvolume_path"
        return 1
    fi
}

# --- Main Function ---
main() {
    log_message "Starting Kopia backup job"

    # Ensure log directory exists and has proper permissions
    if [ ! -f "$LOG_FILE" ]; then
        mkdir -p "$(dirname "$LOG_FILE")"
        touch "$LOG_FILE"
        chmod 644 "$LOG_FILE"
    fi

    local overall_success=true
    local backup_count=0

    # Backup all subvolumes
    for subvolume in "${SUBVOLUMES_TO_BACKUP[@]}"; do
        if [ -d "$subvolume" ]; then
            if backup_subvolume "$subvolume"; then
                ((backup_count++))
            else
                overall_success=false
            fi
        else
            log_message "WARNING: Subvolume $subvolume does not exist, skipping"
        fi
    done

    # Run maintenance (cleanup old snapshots according to retention policy)
    log_message "Running maintenance and cleanup"
    if sudo -u ali -E KOPIA_PASSWORD="$KOPIA_PASSWORD" kopia maintenance run --full; then
        log_message "Maintenance completed successfully"
    else
        log_message "WARNING: Maintenance had issues"
        overall_success=false
    fi

    # Send final notification
    if [[ "$overall_success" == "true" ]]; then
        send_notification "Kopia Backup Completed" \
            "Successfully backed up $backup_count subvolume(s). Data will transition to Glacier in 24 hours." 2
        log_message "Backup job completed successfully"
    else
        send_notification "Kopia Backup FAILED" \
            "One or more backups failed. Check log: $LOG_FILE" 5
        log_message "Backup job completed with errors"
        exit 1
    fi
}

# Run main function
main "$@"
