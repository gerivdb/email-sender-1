#!/bin/bash
# scripts/deploy-hybrid-memory.sh
# Déploiement automatisé du Hybrid Memory Manager v6.1

set -e

VERSION=${1:-latest}
ENVIRONMENT=${2:-production}

echo "🚀 Deploying Hybrid Memory Manager v6.1 - $VERSION"
echo "Environment: $ENVIRONMENT"

# Vérifications pré-déploiement
echo "📋 Pre-deployment checks..."

# Vérifier Go version
if ! go version | grep -q "go1.2[1-9]"; then
    echo "❌ Go 1.21+ required"
    exit 1
fi

# Vérifier les dépendances
echo "📦 Checking dependencies..."
go mod tidy
go mod verify

# Tests complets
echo "🧪 Running comprehensive tests..."
go test -v -race -cover ./...

# Tests de performance
echo "⚡ Running performance tests..."
go test -bench=. -benchmem ./tests/performance/

# Build optimisé pour production
echo "🏗️ Building production binaries..."
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w -X main.version=$VERSION -X main.environment=$ENVIRONMENT" \
    -o ./bin/contextual-memory-manager \
    ./cmd/contextual-memory-manager/

# Validation de la configuration
echo "✅ Validating configuration..."
./bin/contextual-memory-manager --config=./config/hybrid_production.yaml --validate-config

# Création du package de déploiement
echo "📦 Creating deployment package..."
mkdir -p ./deployment/v$VERSION
cp ./bin/contextual-memory-manager ./deployment/v$VERSION/
cp ./config/hybrid_production.yaml ./deployment/v$VERSION/
cp ./scripts/start-production.sh ./deployment/v$VERSION/
cp ./scripts/stop-production.sh ./deployment/v$VERSION/

# Création de l'archive
cd ./deployment
tar -czf "hybrid-memory-manager-v$VERSION.tar.gz" "v$VERSION/"
cd ..

echo "✅ Deployment package ready: ./deployment/hybrid-memory-manager-v$VERSION.tar.gz"

# Tests de validation du package
echo "🔍 Validating deployment package..."
cd ./deployment/v$VERSION
chmod +x contextual-memory-manager
chmod +x start-production.sh
chmod +x stop-production.sh

# Test de démarrage rapide
echo "🚦 Quick start test..."
./contextual-memory-manager --config=hybrid_production.yaml --validate-config --dry-run

cd ../../

echo "✅ Deployment validation complete"
echo "📋 Deployment Summary:"
echo "   Version: $VERSION"
echo "   Environment: $ENVIRONMENT"
echo "   Package: ./deployment/hybrid-memory-manager-v$VERSION.tar.gz"
echo "   Binary: contextual-memory-manager"
echo "   Config: hybrid_production.yaml"

echo "🚀 Ready for production deployment!"
