#!/bin/bash
# Script notification Slack pour CI/CD v74

WEBHOOK_URL="${SLACK_WEBHOOK:-}"

if [ -z "$WEBHOOK_URL" ]; then
  echo "SLACK_WEBHOOK non défini"
  exit 1
fi

MESSAGE=${1:-"Pipeline v74 terminé avec succès."}
COLOR=${2:-"#36a64f"}

payload=$(jq -n \
  --arg text "$MESSAGE" \
  --arg color "$COLOR" \
  '{attachments: [{color: $color, text: $text}]}' )

curl -X POST -H 'Content-type: application/json' --data "$payload" "$WEBHOOK_URL"
