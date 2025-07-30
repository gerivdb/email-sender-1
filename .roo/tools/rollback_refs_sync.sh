#!/bin/bash
# Script de restauration des fichiers .md depuis les backups .bak

cd "$(dirname "$0")/../rules"

for f in *.md; do
  if [ -f "$f.bak" ]; then
    cp "$f.bak" "$f"
    echo "Restauré : $f depuis $f.bak"
  fi
done

echo "Rollback terminé."
