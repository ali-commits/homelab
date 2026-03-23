#!/bin/bash
# storage-monitor.sh
# Runs hourly to track Docker overlay2 and disk usage over time.
# Helps identify which containers are leaking space on btrfs.
# Logs to /storage/data/logs/storage-monitor/

LOG_DIR="/storage/data/logs/storage-monitor"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$LOG_DIR"

{
  echo "========================================"
  echo "  Storage Monitor — $TIMESTAMP"
  echo "========================================"

  echo ""
  echo "--- Disk Usage ---"
  df -h / | tail -1 | awk '{printf "Used: %s / %s (%s)  Free: %s\n", $3, $2, $5, $4}'

  echo ""
  echo "--- Docker Summary ---"
  docker system df 2>/dev/null

  echo ""
  echo "--- Top 15 overlay2 dirs by size (with container name) ---"
  # Build a map of overlay2 ID -> container name
  declare -A overlay_map
  while IFS= read -r line; do
    container_id=$(echo "$line" | awk '{print $1}')
    container_name=$(docker inspect --format '{{.Name}}' "$container_id" 2>/dev/null | sed 's/\///')
    merge_dir=$(docker inspect --format '{{.GraphDriver.Data.MergedDir}}' "$container_id" 2>/dev/null)
    if [ -n "$merge_dir" ]; then
      overlay_id=$(echo "$merge_dir" | awk -F'/' '{print $(NF-1)}')
      overlay_map["$overlay_id"]="$container_name"
    fi
  done < <(docker ps -q)

  du -sh /var/lib/docker/overlay2/*/ 2>/dev/null | sort -rh | head -15 | while read -r size dir; do
    overlay_id=$(basename "$dir")
    name="${overlay_map[$overlay_id]:-unknown}"
    printf "%-10s  %-40s  %s\n" "$size" "$overlay_id" "$name"
  done

  echo ""
  echo "--- Container logs > 50MB ---"
  found=0
  while IFS= read -r logfile; do
    size=$(du -sh "$logfile" 2>/dev/null | cut -f1)
    container_id=$(echo "$logfile" | awk -F'/' '{print $6}' | cut -c1-12)
    container_name=$(docker inspect --format '{{.Name}}' "$container_id" 2>/dev/null | sed 's/\///' || echo "unknown")
    echo "  $size  $container_name  ($logfile)"
    found=1
  done < <(find /var/lib/docker/containers/ -name "*.log" -size +50M 2>/dev/null)
  [ "$found" -eq 0 ] && echo "  None"

  echo ""
  echo "--- Running containers: $(docker ps -q | wc -l) ---"
  echo ""

} >> "$LOG_FILE"

# Keep only last 14 days of logs
find "$LOG_DIR" -name "*.log" -mtime +14 -delete
