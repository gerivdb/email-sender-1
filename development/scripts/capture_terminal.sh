#!/bin/bash
# Script Bash — capture_terminal.sh
# Capture stdout/stderr d'une commande et envoie à l'API CacheManager

if [ $# -lt 1 ]; then
  echo "Usage: $0 <commande> [args...]"
  exit 1
fi

output=$("$@" 2>&1)
status=$?

level="INFO"
msg="Commande exécutée avec succès"
if [ $status -ne 0 ]; then
  level="ERROR"
  msg="Erreur d'exécution"
fi

json=$(jq -n \
  --arg timestamp "$(date -Iseconds)" \
  --arg level "$level" \
  --arg source "capture_terminal.sh" \
  --arg message "$msg" \
  --arg output "$output" \
  '{timestamp: $timestamp, level: $level, source: $source, message: $message, context: {output: $output}}'
)

curl -s -X POST -H "Content-Type: application/json" -d "$json" http://localhost:8080/logs > /dev/null

echo "$output"
exit $status
