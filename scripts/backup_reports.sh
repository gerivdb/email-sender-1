#!/bin/bash
# Sauvegarde tous les rapports d’audit en .bak avant écrasement

REPORTS_DIR="projet/roadmaps/audit-reports"
BACKUP_DIR="projet/roadmaps/audit-reports/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

for f in "$REPORTS_DIR"/*.md; do
  cp "$f" "$BACKUP_DIR/$(basename "$f").bak"
done

echo "Sauvegarde terminée dans $BACKUP_DIR"