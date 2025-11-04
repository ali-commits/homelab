#!/bin/sh
# Watchtower notification script for n8n webhook

WEBHOOK_URL="https://automate.alimunee.com/webhook/bbc07a2c-a77b-4308-b428-cd30e32ac710"

# Get notification message from stdin or args
MESSAGE="${1:-$(cat)}"

# Send to n8n webhook
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{\"title\": \"Watchtower\", \"message\": \"$MESSAGE\", \"timestamp\": \"$(date -Iseconds)\"}" \
  --silent --show-error
