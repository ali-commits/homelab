#!/bin/sh
WEBHOOK_URL="https://automate.alimunee.com/webhook/bbc07a2c-a77b-4308-b428-cd30e32ac710"

# Get logs from watchtower (last 30 minutes)
LOGS=$(docker logs --since 30m watchtower 2>&1 | tail -50)

if [ -n "$LOGS" ]; then
  # Escape for JSON - simple approach
  MESSAGE=$(echo "$LOGS" | jq -Rs .)
  
  # Send to webhook
  curl -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"Watchtower Update\",\"message\":$MESSAGE,\"timestamp\":\"$(date -Iseconds)\"}" \
    --silent --show-error
fi
