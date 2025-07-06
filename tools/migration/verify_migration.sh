#!/bin/bash

echo "=== Exécution des tests unitaires et d'intégration ==="
go test ./...
if [ $? -ne 0 ]; then
  echo "❌ Les tests unitaires et d'intégration ont échoué."
  exit 1
fi
echo "✅ Les tests unitaires et d'intégration ont réussi."

echo ""
echo "=== Exécution du linting Go (golangci-lint) ==="
golangci-lint run --issues-exit-code=0
if [ $? -ne 0 ]; then
  echo "❌ Le linting Go a détecté des problèmes."
  exit 1
fi
echo "✅ Le linting Go a réussi (pas de problèmes détectés)."

echo ""
echo "=== Exécution de la validation YAML (yamllint) ==="
# Trouver tous les fichiers YAML et exécuter yamllint sur chacun
find . -type f -name "*.yaml" -print0 | xargs -0 yamllint -f colored
if [ $? -ne 0 ]; then
  echo "❌ La validation YAML a détecté des problèmes."
  exit 1
fi
echo "✅ La validation YAML a réussi (pas de problèmes détectés)."

echo ""
echo "=== Toutes les vérifications ont réussi ! ==="
