#!/bin/sh
WEBHOOK_URL="https://automate.alimunee.com/webhook/bbc07a2c-a77b-4308-b428-cd30e32ac710"

# Get logs from watchtower (last 30 minutes)
LOGS=$(docker logs --since 30m watchtower 2>&1)

# Parse logs and format as requested
FORMATTED=""

# Look for update messages
echo "$LOGS" | grep -E "Updating|Updated|Failed to update" | while read -r line; do
    if echo "$line" | grep -q "Updated"; then
        # Extract container/image info
        CONTAINER=$(echo "$line" | grep -oP '(?<=container )[^ ]+' || echo "unknown")
        FORMATTED="$FORMATTED[Updated] image_name:$CONTAINER\n"
    elif echo "$line" | grep -q "Failed"; then
        CONTAINER=$(echo "$line" | grep -oP '(?<=container )[^ ]+' || echo "unknown")
        FORMATTED="$FORMATTED[Failed] image_name:$CONTAINER\n"
    fi
done

# If no formatted output, just send raw logs
if [ -z "$FORMATTED" ]; then
    MESSAGE=$(echo "$LOGS" | jq -Rs .)
    TITLE="Watchtower Update"
else
    MESSAGE=$(echo -e "$FORMATTED" | jq -Rs .)
    TITLE="Watchtower Update Report"
fi

# Send to webhook
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"$TITLE\",\"message\":$MESSAGE,\"timestamp\":\"$(date -Iseconds)\"}" \
  --silent --show-error
