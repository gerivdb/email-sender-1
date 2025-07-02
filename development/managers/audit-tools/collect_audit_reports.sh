#!/bin/bash
# Collecte tous les rapports d’audit générés dans les managers et les centralise

DEST="../../projet/roadmaps/audit-reports/"
mkdir -p "$DEST"

for dir in ../*/; do
  if [ -d "$dir/audit-tools" ]; then
    cp "$dir/audit-tools/"*.md "$DEST" 2>/dev/null || true
  fi
done

echo "Rapports d’audit centralisés dans $DEST"