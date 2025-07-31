#!/bin/bash
# Script d'orchestration des outils Roo-Code

set -e

echo "=== Lancement des outils Roo-Code ==="

echo "--- Validation sémantique des règles ---"
go run .roo/tools/rules-validator.go

echo "--- Vérification des verrous ---"
go run .roo/tools/refs_sync.go --check-locks

echo "--- Lancement du scan ---"
go run .roo/tools/refs_sync.go --scan

echo "--- Lancement de l'injection (dry-run) ---"
go run .roo/tools/refs_sync.go --dry-run

echo "=== Fin de l'orchestration ==="
