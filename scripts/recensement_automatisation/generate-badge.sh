#!/bin/sh
# Génère un badge de couverture Go pour le module recensement_automatisation
# Nécessite: go, go install github.com/t-yuki/gocover-cobertura/cmd/gocover-cobertura@latest, go install github.com/axw/gocov/gocov@latest, go install github.com/boumenot/gocover-cobertura@latest, go install github.com/owenthereal/gocov-xml@latest
# Usage: ./generate-badge.sh

set -e

# 1. Générer le fichier de couverture
go test -coverprofile=coverage.out

# 2. Convertir en XML Cobertura (pour badge ou CI)
go install github.com/boumenot/gocover-cobertura@latest
gocover-cobertura < coverage.out > coverage.xml

# 3. Générer un badge SVG localement (optionnel, nécessite go install github.com/axw/gocov/gocov@latest et github.com/owenthereal/gocov-xml@latest)
# go install github.com/axw/gocov/gocov@latest
# go install github.com/owenthereal/gocov-xml@latest
# gocov convert coverage.out | gocov-xml > coverage.xml

# 4. (Optionnel) Utiliser shields.io pour générer un badge SVG à partir du pourcentage
COVERAGE=$(go tool cover -func=coverage.out | grep total: | awk '{print substr($3, 1, length($3)-1)}')
COVERAGE_INT=$(printf "%.0f" "$COVERAGE")
curl -o coverage-badge.svg "https://img.shields.io/badge/coverage-${COVERAGE_INT}%25-brightgreen.svg"

echo "Badge de couverture généré: coverage-badge.svg"
echo "Fichier Cobertura: coverage.xml"
