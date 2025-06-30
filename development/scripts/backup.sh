#!/bin/bash
# Script de backup des logs et contextes CacheManager v74

BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

cp -r development/managers/cache-manager/*.go "$BACKUP_DIR"/ 2>/dev/null
cp -r projet/roadmaps/plans/consolidated/*.json "$BACKUP_DIR"/ 2>/dev/null
cp -r projet/roadmaps/plans/consolidated/*.md "$BACKUP_DIR"/ 2>/dev/null

echo "Backup effectué dans $BACKUP_DIR"
