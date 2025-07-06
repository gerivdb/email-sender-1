#!/bin/bash

# Script de vérification de la migration

# Tests unitaires et d'intégration
echo "Exécution des tests unitaires et d'intégration..."
go test ./...

# Linting Go
echo "Exécution du linting Go..."
golangci-lint run

# Validation YAML
echo "Exécution de la validation YAML..."
yamllint .

echo "Vérifications terminées."