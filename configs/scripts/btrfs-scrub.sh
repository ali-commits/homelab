#!/bin/bash

# Btrfs Scrub Script for Homelab
# Performs data integrity checks on Btrfs filesystems

# Load notification settings
if [ -f /etc/default/notification-settings ]; then
    source /etc/default/notification-settings
else
    NTFY_URL="http://homelab.local:8080"
    NTFY_TOPIC="homelab-alerts"
fi

LOG_FILE="/var/log/btrfs-scrub.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send notifications
send_notification() {
    local title="$1"
    local message="$2"
    local priority="${3:-3}"
    
    if [ -n "$NTFY_URL" ] && [ -n "$NTFY_TOPIC" ]; then
        curl -s -X POST "$NTFY_URL/$NTFY_TOPIC" \
            -H "Title: $title" \
            -H "Priority: $priority" \
            -H "Tags: maintenance,storage" \
            -d "$message"
    fi
    
    log_message "NOTIFICATION: $title - $message"
}

# Function to scrub filesystem
scrub_filesystem() {
    local mount_point="$1"
    local fs_name="$2"
    
    log_message "Starting scrub for $fs_name ($mount_point)"
    send_notification "Btrfs Scrub Started" "Starting data integrity check for $fs_name" 2
    
    # Start scrub
    if btrfs scrub start "$mount_point"; then
        log_message "Scrub started successfully for $mount_point"
        
        # Wait for completion and monitor progress
        while btrfs scrub status "$mount_point" | grep -q "running"; do
            sleep 300  # Check every 5 minutes
        done
        
        # Get final status
        local scrub_result=$(btrfs scrub status "$mount_point")
        log_message "Scrub completed for $mount_point"
        
        # Check for errors
        if echo "$scrub_result" | grep -q "unrecoverable"; then
            send_notification "Btrfs Scrub Failed" "Unrecoverable errors found on $fs_name:\n$scrub_result" 5
        elif echo "$scrub_result" | grep -q "corrected"; then
            send_notification "Btrfs Scrub Corrected Errors" "Correctable errors found and fixed on $fs_name:\n$scrub_result" 4
        else
            send_notification "Btrfs Scrub Completed" "Data integrity check completed successfully for $fs_name" 2
        fi
        
        log_message "Scrub result: $scrub_result"
    else
        log_message "Failed to start scrub for $mount_point"
        send_notification "Btrfs Scrub Failed" "Failed to start scrub for $fs_name" 4
    fi
}

# Main function
main() {
    log_message "Starting scheduled Btrfs scrub"
    
    # Scrub SSD filesystem (root)
    scrub_filesystem "/" "SSD Root"
    
    # Scrub HDD RAID filesystem
    scrub_filesystem "/storage/media" "HDD RAID Storage"
    
    log_message "Scheduled Btrfs scrub completed"
}

main "$@"
