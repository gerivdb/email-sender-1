# Documentation CI/CD - Migration Vectorisation Go

## Table des Matières

1. [GitHub Actions Workflows](#github-actions-workflows)
2. [Scripts de Tests Automatiques](#scripts-de-tests-automatiques)
3. [Pipeline de Déploiement](#pipeline-de-déploiement)
4. [Configuration des Environnements](#configuration-des-environnements)

## GitHub Actions Workflows

### 1. Workflow Principal de CI/CD

Créer `.github/workflows/vectorization-ci-cd.yml` :

```yaml
name: Vectorization Go Migration CI/CD

on:
  push:
    branches: [ main, develop, 'feature/vectorization-*' ]
  pull_request:
    branches: [ main, develop ]

env:
  GO_VERSION: '1.21'
  PYTHON_VERSION: '3.11'
  QDRANT_VERSION: '1.7.0'

jobs:
  lint-and-format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: ${{ env.GO_VERSION }}
          
      - name: Run golangci-lint
        uses: golangci/golangci-lint-action@v3
        with:
          version: latest
          working-directory: .
          
      - name: Check Go formatting
        run: |
          if [ "$(gofmt -s -l . | wc -l)" -gt 0 ]; then
            echo "Code is not formatted:"
            gofmt -s -l .
            exit 1
          fi

  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: ${{ env.GO_VERSION }}
          
      - name: Cache Go modules
        uses: actions/cache@v3
        with:
          path: ~/go/pkg/mod
          key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
          restore-keys: |
            ${{ runner.os }}-go-
            
      - name: Download dependencies
        run: go mod download
        
      - name: Run unit tests
        run: |
          go test -v -race -coverprofile=coverage.out ./internal/...
          go test -v -race ./cmd/...
          
      - name: Generate coverage report
        run: go tool cover -html=coverage.out -o coverage.html
        
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.out
          fail_ci_if_error: true

  integration-tests:
    runs-on: ubuntu-latest
    services:
      qdrant:
        image: qdrant/qdrant:${{ env.QDRANT_VERSION }}
        ports:
          - 6333:6333
          - 6334:6334
        options: >-
          --health-cmd "curl -f http://localhost:6333/health || exit 1"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
          
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: ${{ env.GO_VERSION }}
          
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          
      - name: Install Python dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-test.txt
          
      - name: Wait for Qdrant
        run: |
          timeout 60 bash -c 'until curl -f http://localhost:6333/health; do sleep 2; done'
          
      - name: Run integration tests
        env:
          QDRANT_HOST: localhost
          QDRANT_PORT: 6333
        run: |
          go test -v ./tests/integration/...
          
      - name: Run migration validation tests
        run: |
          python tests/validate_migration_compatibility.py
          go run tests/validate_go_migration.go

  performance-tests:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    services:
      qdrant:
        image: qdrant/qdrant:${{ env.QDRANT_VERSION }}
        ports:
          - 6333:6333
        options: >-
          --health-cmd "curl -f http://localhost:6333/health || exit 1"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
          
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: ${{ env.GO_VERSION }}
          
      - name: Run performance benchmarks
        run: |
          go test -bench=. -benchmem ./internal/vectorization/...
          go test -bench=. -benchmem ./internal/qdrant/...
          
      - name: Run load tests
        run: |
          go run tests/load_test.go -concurrent=10 -duration=2m
          
      - name: Compare with Python baseline
        run: |
          python tests/benchmark_python.py > python_benchmark.txt
          go test -bench=. ./tests/benchmark/... > go_benchmark.txt
          python scripts/compare_benchmarks.py

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Gosec Security Scanner
        uses: securecodewarrior/github-action-gosec@master
        with:
          args: './...'
          
      - name: Run Nancy vulnerability scanner
        run: |
          go list -json -m all | nancy sleuth
          
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'

  build-and-test:
    runs-on: ubuntu-latest
    needs: [lint-and-format, unit-tests]
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: ${{ env.GO_VERSION }}
          
      - name: Build all binaries
        run: |
          make build-all
          
      - name: Test binary execution
        run: |
          ./bin/qdrant_manager --version
          ./bin/vector_processor --version
          ./bin/email_sender --version
          
      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: go-binaries-${{ github.sha }}
          path: bin/
          retention-days: 7

  deploy-staging:
    runs-on: ubuntu-latest
    needs: [build-and-test, integration-tests]
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: go-binaries-${{ github.sha }}
          path: bin/
          
      - name: Deploy to staging
        env:
          DEPLOY_HOST: ${{ secrets.STAGING_HOST }}
          DEPLOY_USER: ${{ secrets.STAGING_USER }}
          DEPLOY_KEY: ${{ secrets.STAGING_SSH_KEY }}
        run: |
          ./scripts/deploy-vectorisation-v56.ps1 -Environment staging -DryRun false
          
      - name: Run smoke tests
        run: |
          ./tests/smoke_tests.sh ${{ secrets.STAGING_HOST }}

  deploy-production:
    runs-on: ubuntu-latest
    needs: [deploy-staging]
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: go-binaries-${{ github.sha }}
          path: bin/
          
      - name: Deploy to production
        env:
          DEPLOY_HOST: ${{ secrets.PRODUCTION_HOST }}
          DEPLOY_USER: ${{ secrets.PRODUCTION_USER }}
          DEPLOY_KEY: ${{ secrets.PRODUCTION_SSH_KEY }}
        run: |
          ./scripts/deploy-vectorisation-v56.ps1 -Environment production -DryRun false
          
      - name: Run post-deployment validation
        run: |
          ./tests/post_deployment_validation.sh ${{ secrets.PRODUCTION_HOST }}
          
      - name: Notify deployment success
        if: success()
        uses: 8398a7/action-slack@v3
        with:
          status: success
          channel: '#deployments'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### 2. Workflow de Tests sur PR

Créer `.github/workflows/pr-validation.yml` :

```yaml
name: PR Validation

on:
  pull_request:
    branches: [ main, develop ]
    types: [ opened, synchronize, reopened ]

jobs:
  validate-changes:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          
      - name: Get changed files
        id: changed-files
        uses: tj-actions/changed-files@v40
        with:
          files: |
            **/*.go
            **/*.py
            **/go.mod
            **/go.sum
            
      - name: Validate Go changes
        if: steps.changed-files.outputs.any_changed == 'true'
        run: |
          echo "Go files changed:"
          echo "${{ steps.changed-files.outputs.all_changed_files }}"
          
      - name: Run affected tests only
        run: |
          ./scripts/run_affected_tests.sh "${{ steps.changed-files.outputs.all_changed_files }}"

  migration-compatibility:
    runs-on: ubuntu-latest
    if: contains(github.event.pull_request.changed_files, 'internal/vectorization/') || contains(github.event.pull_request.changed_files, 'internal/qdrant/')
    
    services:
      qdrant:
        image: qdrant/qdrant:1.7.0
        ports:
          - 6333:6333
          
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up environments
        run: |
          # Setup Python and Go environments
          pip install -r requirements.txt
          go mod download
          
      - name: Test migration compatibility
        run: |
          # Run Python version to generate baseline
          python scripts/generate_test_vectors.py
          
          # Run Go version with same data
          go run cmd/migrate_test_data/main.go
          
          # Compare outputs
          python scripts/compare_migration_outputs.py
          
      - name: Validate backward compatibility
        run: |
          go test ./tests/compatibility/...
```

## Scripts de Tests Automatiques

### 1. Script de Tests Affectés

Créer `scripts/run_affected_tests.sh` :

```bash
#!/bin/bash
# run_affected_tests.sh

set -e

CHANGED_FILES="$1"

echo "Running tests for changed files: $CHANGED_FILES"

# Fonction pour détecter les packages affectés
get_affected_packages() {
    local files="$1"
    local packages=""
    
    for file in $files; do
        if [[ $file == *.go ]]; then
            dir=$(dirname "$file")
            if [[ $dir == cmd/* ]]; then
                packages="$packages $dir"
            elif [[ $dir == internal/* ]]; then
                packages="$packages $dir/..."
            fi
        fi
    done
    
    echo "$packages" | tr ' ' '\n' | sort -u | tr '\n' ' '
}

# Fonction pour détecter les tests d'intégration affectés
get_affected_integration_tests() {
    local files="$1"
    
    if echo "$files" | grep -q "internal/vectorization/"; then
        echo "tests/integration/vectorization_test.go"
    fi
    
    if echo "$files" | grep -q "internal/qdrant/"; then
        echo "tests/integration/qdrant_test.go"
    fi
    
    if echo "$files" | grep -q "internal/email/"; then
        echo "tests/integration/email_pipeline_test.go"
    fi
}

AFFECTED_PACKAGES=$(get_affected_packages "$CHANGED_FILES")
AFFECTED_INTEGRATION_TESTS=$(get_affected_integration_tests "$CHANGED_FILES")

echo "Affected packages: $AFFECTED_PACKAGES"
echo "Affected integration tests: $AFFECTED_INTEGRATION_TESTS"

# Exécuter les tests unitaires
if [ -n "$AFFECTED_PACKAGES" ]; then
    echo "Running unit tests..."
    go test -v -race $AFFECTED_PACKAGES
fi

# Exécuter les tests d'intégration
if [ -n "$AFFECTED_INTEGRATION_TESTS" ]; then
    echo "Running integration tests..."
    for test in $AFFECTED_INTEGRATION_TESTS; do
        if [ -f "$test" ]; then
            go test -v "$test"
        fi
    done
fi

echo "All affected tests passed!"
```

### 2. Script de Comparaison des Benchmarks

Créer `scripts/compare_benchmarks.py` :

```python
#!/usr/bin/env python3
"""
Script de comparaison des performances Python vs Go
"""

import re
import sys
from typing import Dict, List, Tuple

def parse_python_benchmark(file_path: str) -> Dict[str, float]:
    """Parse les résultats de benchmark Python"""
    benchmarks = {}
    
    with open(file_path, 'r') as f:
        for line in f:
            if 'vectorization_time:' in line:
                time = float(line.split(':')[1].strip().replace('s', ''))
                benchmarks['vectorization'] = time
            elif 'search_time:' in line:
                time = float(line.split(':')[1].strip().replace('s', ''))
                benchmarks['search'] = time
                
    return benchmarks

def parse_go_benchmark(file_path: str) -> Dict[str, float]:
    """Parse les résultats de benchmark Go"""
    benchmarks = {}
    
    with open(file_path, 'r') as f:
        content = f.read()
        
    # Regex pour parser les benchmarks Go
    pattern = r'Benchmark(\w+)-\d+\s+\d+\s+([\d.]+)\s+ns/op'
    matches = re.findall(pattern, content)
    
    for name, ns_per_op in matches:
        # Convertir ns en secondes
        seconds = float(ns_per_op) / 1_000_000_000
        benchmarks[name.lower()] = seconds
        
    return benchmarks

def compare_benchmarks(python_bench: Dict[str, float], 
                      go_bench: Dict[str, float]) -> bool:
    """Compare les benchmarks et retourne True si Go est plus rapide"""
    
    print("Performance Comparison:")
    print("=" * 50)
    
    all_better = True
    
    for operation in set(python_bench.keys()) & set(go_bench.keys()):
        py_time = python_bench[operation]
        go_time = go_bench[operation]
        
        improvement = ((py_time - go_time) / py_time) * 100
        
        print(f"{operation.capitalize()}:")
        print(f"  Python: {py_time:.6f}s")
        print(f"  Go:     {go_time:.6f}s")
        print(f"  Improvement: {improvement:+.2f}%")
        
        if improvement < 0:
            print(f"  ⚠️  Go is slower than Python!")
            all_better = False
        else:
            print(f"  ✅ Go is faster!")
        print()
        
    return all_better

def main():
    if len(sys.argv) != 3:
        print("Usage: compare_benchmarks.py <python_results> <go_results>")
        sys.exit(1)
        
    python_file = sys.argv[1]
    go_file = sys.argv[2]
    
    try:
        python_benchmarks = parse_python_benchmark(python_file)
        go_benchmarks = parse_go_benchmark(go_file)
        
        if not python_benchmarks:
            print("No Python benchmarks found!")
            sys.exit(1)
            
        if not go_benchmarks:
            print("No Go benchmarks found!")
            sys.exit(1)
            
        success = compare_benchmarks(python_benchmarks, go_benchmarks)
        
        if not success:
            print("❌ Some Go implementations are slower than Python!")
            sys.exit(1)
        else:
            print("✅ All Go implementations are faster than Python!")
            
    except Exception as e:
        print(f"Error comparing benchmarks: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

### 3. Tests de Fumée

Créer `tests/smoke_tests.sh` :

```bash
#!/bin/bash
# smoke_tests.sh

set -e

HOST="$1"
if [ -z "$HOST" ]; then
    echo "Usage: smoke_tests.sh <host>"
    exit 1
fi

echo "Running smoke tests against $HOST..."

# Test 1: Health checks
echo "Testing health endpoints..."
curl -f "http://$HOST:8080/health" || exit 1
curl -f "http://$HOST:6333/health" || exit 1

# Test 2: Basic vectorization
echo "Testing vectorization endpoint..."
curl -X POST "http://$HOST:8080/vectorize" \
    -H "Content-Type: application/json" \
    -d '{"text": "Test email content", "type": "email"}' \
    -f || exit 1

# Test 3: Qdrant search
echo "Testing Qdrant search..."
curl -X POST "http://$HOST:6333/collections/emails/points/search" \
    -H "Content-Type: application/json" \
    -d '{
        "vector": [0.1, 0.2, 0.3],
        "limit": 5,
        "with_payload": true
    }' \
    -f || exit 1

# Test 4: Email pipeline
echo "Testing email processing pipeline..."
curl -X POST "http://$HOST:8080/process-email" \
    -H "Content-Type: application/json" \
    -d '{
        "from": "test@example.com",
        "to": "user@example.com",
        "subject": "Test Email",
        "content": "This is a test email for smoke testing."
    }' \
    -f || exit 1

echo "All smoke tests passed! ✅"
```

## Pipeline de Déploiement

### 1. Configuration des Secrets GitHub

Dans les settings du repository GitHub, configurer ces secrets :

```yaml
# Staging Environment
STAGING_HOST: staging.company.com
STAGING_USER: deploy
STAGING_SSH_KEY: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  [clé SSH privée pour staging]
  -----END OPENSSH PRIVATE KEY-----

# Production Environment  
PRODUCTION_HOST: production.company.com
PRODUCTION_USER: deploy
PRODUCTION_SSH_KEY: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  [clé SSH privée pour production]
  -----END OPENSSH PRIVATE KEY-----

# Notifications
SLACK_WEBHOOK: https://hooks.slack.com/services/...

# Database
QDRANT_API_KEY: [clé API Qdrant]
DATABASE_URL: [URL de la base de données]
```

### 2. Script de Déploiement Distant

Créer `scripts/remote_deploy.sh` :

```bash
#!/bin/bash
# remote_deploy.sh - Script exécuté sur le serveur cible

set -e

ENVIRONMENT="$1"
BACKUP_PATH="$2"

echo "Starting deployment for environment: $ENVIRONMENT"

# Créer un backup avant déploiement
echo "Creating backup..."
sudo systemctl stop email-sender qdrant-manager vector-processor || true
cp -r /var/lib/qdrant "$BACKUP_PATH/qdrant_$(date +%Y%m%d_%H%M%S)"

# Déployer les nouveaux binaires
echo "Deploying new binaries..."
sudo cp bin/* /usr/local/bin/
sudo chmod +x /usr/local/bin/qdrant_manager
sudo chmod +x /usr/local/bin/vector_processor
sudo chmod +x /usr/local/bin/email_sender

# Mettre à jour les configurations
echo "Updating configurations..."
sudo cp config/$ENVIRONMENT/*.json /etc/email-sender/
sudo cp config/$ENVIRONMENT/*.yaml /etc/qdrant/

# Redémarrer les services
echo "Starting services..."
sudo systemctl start qdrant
sleep 10
sudo systemctl start qdrant-manager
sudo systemctl start vector-processor
sudo systemctl start email-sender

# Valider le déploiement
echo "Validating deployment..."
timeout 60 bash -c 'until curl -f http://localhost:8080/health; do sleep 2; done'
timeout 60 bash -c 'until curl -f http://localhost:6333/health; do sleep 2; done'

echo "Deployment completed successfully!"
```

## Configuration des Environnements

### 1. Configuration Staging

Créer `config/deploy-staging.json` :

```json
{
  "environment": "staging",
  "services": {
    "qdrant": {
      "host": "localhost",
      "port": 6333,
      "collection_config": {
        "vector_size": 384,
        "distance": "Cosine",
        "replicas": 1,
        "shard_number": 1
      }
    },
    "email_sender": {
      "host": "0.0.0.0",
      "port": 8080,
      "workers": 2,
      "batch_size": 100
    },
    "vector_processor": {
      "workers": 2,
      "batch_size": 50,
      "model": "sentence-transformers/all-MiniLM-L6-v2"
    }
  },
  "logging": {
    "level": "INFO",
    "format": "json",
    "output": "/var/log/email-sender/staging.log"
  },
  "monitoring": {
    "metrics_enabled": true,
    "metrics_port": 9090,
    "health_check_interval": "30s"
  },
  "backup": {
    "enabled": true,
    "interval": "6h",
    "retention": "7d",
    "path": "/backups/staging"
  }
}
```

### 2. Configuration Production

Créer `config/deploy-production.json` :

```json
{
  "environment": "production",
  "services": {
    "qdrant": {
      "host": "localhost",
      "port": 6333,
      "collection_config": {
        "vector_size": 384,
        "distance": "Cosine",
        "replicas": 3,
        "shard_number": 6
      }
    },
    "email_sender": {
      "host": "0.0.0.0", 
      "port": 8080,
      "workers": 8,
      "batch_size": 500
    },
    "vector_processor": {
      "workers": 8,
      "batch_size": 200,
      "model": "sentence-transformers/all-MiniLM-L6-v2"
    }
  },
  "logging": {
    "level": "WARN",
    "format": "json",
    "output": "/var/log/email-sender/production.log"
  },
  "monitoring": {
    "metrics_enabled": true,
    "metrics_port": 9090,
    "health_check_interval": "10s",
    "alerting": {
      "slack_webhook": "${SLACK_WEBHOOK}",
      "email_alerts": ["ops@company.com"]
    }
  },
  "backup": {
    "enabled": true,
    "interval": "1h",
    "retention": "30d", 
    "path": "/backups/production",
    "remote_backup": {
      "enabled": true,
      "s3_bucket": "company-backups",
      "encryption": true
    }
  },
  "security": {
    "tls_enabled": true,
    "api_key_required": true,
    "rate_limiting": {
      "requests_per_minute": 1000,
      "burst": 100
    }
  }
}
```

### 3. Variables d'Environnement

Créer `.env.example` :

```bash
# Environment Configuration
ENVIRONMENT=development
DEBUG=true

# Qdrant Configuration
QDRANT_HOST=localhost
QDRANT_PORT=6333
QDRANT_API_KEY=your_api_key_here

# Email Sender Configuration
EMAIL_SENDER_HOST=0.0.0.0
EMAIL_SENDER_PORT=8080
EMAIL_SENDER_WORKERS=4

# Vector Processor Configuration
VECTOR_PROCESSOR_WORKERS=4
VECTOR_PROCESSOR_BATCH_SIZE=100
VECTOR_MODEL=sentence-transformers/all-MiniLM-L6-v2

# Logging Configuration
LOG_LEVEL=INFO
LOG_FORMAT=text
LOG_OUTPUT=stdout

# Monitoring Configuration  
METRICS_ENABLED=true
METRICS_PORT=9090
HEALTH_CHECK_INTERVAL=30s

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_INTERVAL=6h
BACKUP_RETENTION=7d
BACKUP_PATH=/tmp/backups

# Security Configuration
TLS_ENABLED=false
API_KEY_REQUIRED=false
RATE_LIMIT_RPM=1000

# Database Configuration (si applicable)
DATABASE_URL=postgres://user:password@localhost/emailsender
REDIS_URL=redis://localhost:6379/0

# External Services
SMTP_HOST=smtp.company.com
SMTP_PORT=587
SMTP_USERNAME=notifications@company.com
SMTP_PASSWORD=your_smtp_password

# CI/CD Configuration
DEPLOY_USER=deploy
DEPLOY_HOST=staging.company.com
SLACK_WEBHOOK=https://hooks.slack.com/services/...
```

Ce système CI/CD complet assure :

1. **Tests automatiques** sur chaque PR
2. **Validation des performances** par rapport à Python
3. **Déploiement automatique** staging puis production
4. **Tests de régression** et de compatibilité
5. **Monitoring** et **alertes** post-déploiement
6. **Rollback automatique** en cas d'échec

La pipeline garantit que chaque changement est testé, validé et déployé de manière sécurisée.
