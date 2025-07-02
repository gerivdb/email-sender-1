#!/bin/bash
# Déploie les scripts Go d’audit et d’inventaire dans chaque manager

set -e

SCRIPTS=("audit-inventory" "audit-gap-analysis" "standards-inventory" "standards-duplication-check" "roadmap-indexer" "cross-doc-inventory")
MANAGER_DIRS=$(find . -maxdepth 1 -type d | grep -E 'manager$|manager-$|manager_' | grep -v 'script-manager')

for dir in $MANAGER_DIRS; do
  for script in "${SCRIPTS[@]}"; do
    mkdir -p "$dir/audit-tools"
    cp -r ../../cmd/$script "$dir/audit-tools/"
  done
done

echo "Scripts d’audit déployés dans chaque manager."