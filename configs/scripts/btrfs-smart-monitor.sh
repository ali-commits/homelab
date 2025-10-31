#!/bin/bash

# Btrfs and SMART Monitoring Script for Homelab
# Replaces bcache monitoring with Btrfs-specific monitoring
# Created: $(date)

# Load notification settings
if [ -f /etc/default/notification-settings ]; then
    source /etc/default/notification-settings
else
    # Default settings if file doesn't exist
    NTFY_URL="http://homelab.local:8080"
    NTFY_TOPIC="homelab-alerts"
    ALERT_EMAIL=""
fi

LOG_FILE="/var/log/btrfs-smart-monitor.log"
TEMP_DIR="/tmp/btrfs-monitor"
mkdir -p "$TEMP_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send notifications
send_notification() {
    local title="$1"
    local message="$2"
    local priority="${3:-3}"  # Default priority 3 (normal)

    # Send to ntfy if configured
    if [ -n "$NTFY_URL" ] && [ -n "$NTFY_TOPIC" ]; then
        curl -s -X POST "$NTFY_URL/$NTFY_TOPIC" \
            -H "Title: $title" \
            -H "Priority: $priority" \
            -H "Tags: warning,storage" \
            -d "$message" || log_message "Failed to send ntfy notification"
    fi

    # Send email if configured
    if [ -n "$ALERT_EMAIL" ] && command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "$title" "$ALERT_EMAIL" || log_message "Failed to send email"
    fi

    log_message "ALERT: $title - $message"
}

# Function to check Btrfs filesystem health
check_btrfs_health() {
    local mount_point="$1"
    local fs_name="$2"

    log_message "Checking Btrfs health for $fs_name ($mount_point)"

    # Check filesystem usage
    local usage_info=$(btrfs filesystem usage "$mount_point" 2>/dev/null)
    if [ $? -ne 0 ]; then
        send_notification "Btrfs Error" "Cannot get filesystem usage for $fs_name" 4
        return 1
    fi

    # Extract space usage percentages
    local used_percent=$(echo "$usage_info" | grep -oP 'Overall:\s+\K\d+\.\d+%' | head -1 | sed 's/%//')

    if [ -n "$used_percent" ]; then
        if (( $(echo "$used_percent > 90" | bc -l) )); then
            send_notification "Btrfs Space Warning" "$fs_name is ${used_percent}% full" 4
        elif (( $(echo "$used_percent > 80" | bc -l) )); then
            send_notification "Btrfs Space Notice" "$fs_name is ${used_percent}% full" 3
        fi
    fi

    # Check for filesystem errors
    local device_stats=$(btrfs device stats "$mount_point" 2>/dev/null)
    if echo "$device_stats" | grep -qv '\b0$'; then
        send_notification "Btrfs Device Errors" "Device errors detected on $fs_name:\n$device_stats" 5
    fi

    # Check scrub status (if available)
    local scrub_status=$(btrfs scrub status "$mount_point" 2>/dev/null)
    if echo "$scrub_status" | grep -q "unrecoverable"; then
        send_notification "Btrfs Scrub Errors" "Unrecoverable errors found during scrub on $fs_name" 5
    fi
}

# Function to check SMART status
check_smart_status() {
    local device="$1"
    local device_name=$(basename "$device")

    log_message "Checking SMART status for $device"

    # Check if SMART is available
    if ! smartctl -i "$device" >/dev/null 2>&1; then
        log_message "SMART not available for $device"
        return 1
    fi

    # Get SMART health status
    local smart_health=$(smartctl -H "$device" 2>/dev/null)
    if echo "$smart_health" | grep -q "FAILED"; then
        send_notification "SMART Health Failed" "Drive $device_name has SMART health check FAILED" 5
    fi

    # Check for reallocated sectors
    local reallocated=$(smartctl -A "$device" | grep -i "reallocated.*sector" | awk '{print $10}')
    if [ -n "$reallocated" ] && [ "$reallocated" -gt 0 ]; then
        send_notification "SMART Warning" "Drive $device_name has $reallocated reallocated sectors" 4
    fi

    # Check for pending sectors
    local pending=$(smartctl -A "$device" | grep -i "current.*pending.*sector" | awk '{print $10}')
    if [ -n "$pending" ] && [ "$pending" -gt 0 ]; then
        send_notification "SMART Warning" "Drive $device_name has $pending pending sectors" 4
    fi

    # Check temperature
    local temp=$(smartctl -A "$device" | grep -i "temperature" | head -1 | awk '{print $10}')
    if [ -n "$temp" ] && [ "$temp" -gt 50 ]; then
        if [ "$temp" -gt 60 ]; then
            send_notification "Drive Temperature Critical" "Drive $device_name temperature is ${temp}°C" 5
        elif [ "$temp" -gt 55 ]; then
            send_notification "Drive Temperature Warning" "Drive $device_name temperature is ${temp}°C" 4
        fi
    fi
}

# Function to check system resources
check_system_resources() {
    log_message "Checking system resources"

    # Check memory usage
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    if (( $(echo "$mem_usage > 90" | bc -l) )); then
        send_notification "High Memory Usage" "Memory usage is ${mem_usage}%" 4
    fi

    # Check CPU load
    local load_avg=$(uptime | grep -oP 'load average:\s+\K[\d.]+')
    local cpu_cores=$(nproc)
    local load_percent=$(echo "scale=1; $load_avg / $cpu_cores * 100" | bc)

    if (( $(echo "$load_percent > 80" | bc -l) )); then
        send_notification "High CPU Load" "CPU load is ${load_percent}% (${load_avg})" 4
    fi

    # Check root filesystem space
    local root_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$root_usage" -gt 90 ]; then
        send_notification "Root Filesystem Full" "Root filesystem is ${root_usage}% full" 4
    fi
}

# Main monitoring logic
main() {
    log_message "Starting Btrfs and SMART monitoring"

    # Check Btrfs filesystems (updated for new system layout)
    check_btrfs_health "/" "NVMe System"
    check_btrfs_health "/storage/media" "HDD Storage"

    # Check SMART status for all drives (updated for new hardware)
    for device in /dev/nvme* /dev/sd[a-z]; do
        if [ -b "$device" ]; then
            check_smart_status "$device"
        fi
    done

    # Check system resources
    check_system_resources

    log_message "Monitoring check completed"
}

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}

# Set up cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"
