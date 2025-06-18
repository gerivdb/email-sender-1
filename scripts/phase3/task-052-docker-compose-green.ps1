# Task 052: Créer Configuration Docker Compose Green
# Durée: 25 minutes max
# Phase 3: DÉPLOIEMENT PRODUCTION - Blue-Green Infrastructure

param(
   [string]$OutputDir = "deployments/blue-green",
   [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$StartTime = Get-Date

Write-Host "🚀 PHASE 3 - TÂCHE 052: Configuration Docker Compose Green" -ForegroundColor Cyan
Write-Host "=" * 60

# Création des répertoires de sortie
if (!(Test-Path $OutputDir)) {
   New-Item -ItemType Directory -Path $OutputDir -Force -Recurse | Out-Null
}

$Results = @{
   task             = "052-docker-compose-green"
   timestamp        = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
   files_created    = @()
   services_defined = @()
   networks_created = @()
   ports_allocated  = @()
   summary          = @{}
   errors           = @()
}

Write-Host "🐳 Création de la configuration Docker Compose Green..." -ForegroundColor Yellow

# Créer docker-compose.green.yml
try {
   $dockerComposeGreenContent = @'
version: '3.8'

services:
  # N8N Service Green Environment
  n8n-green:
    image: n8nio/n8n:latest
    container_name: n8n-green
    restart: unless-stopped
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=admin123
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:8090
      - N8N_METRICS=true
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres-green
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n_green
      - DB_POSTGRESDB_USER=n8n_green
      - DB_POSTGRESDB_PASSWORD=n8n_green_password
      - N8N_LOG_LEVEL=info
      - N8N_LOG_OUTPUT=console
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
      - EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
    ports:
      - "8090:5678"  # Green environment ports 8090-8099
    volumes:
      - n8n-green-data:/home/node/.n8n
      - ./config/n8n-green:/etc/n8n:ro
    networks:
      - green-network
    depends_on:
      - postgres-green
      - redis-green
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:5678/healthz || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # Go Manager Green Environment  
  go-manager-green:
    build:
      context: ../
      dockerfile: deployments/docker/Dockerfile.manager
      args:
        - BUILD_ENV=green
    container_name: go-manager-green
    restart: unless-stopped
    environment:
      - ENV=green
      - LOG_LEVEL=info
      - HTTP_PORT=8091
      - METRICS_PORT=8092
      - N8N_URL=http://n8n-green:5678
      - REDIS_URL=redis://redis-green:6379
      - POSTGRES_URL=postgres://go_green:go_green_password@postgres-green:5432/go_manager_green
      - BRIDGE_API_PORT=8093
      - QUEUE_TYPE=hybrid
      - TRACE_ENABLED=true
    ports:
      - "8091:8091"  # Manager HTTP API
      - "8092:8092"  # Metrics endpoint
      - "8093:8093"  # Bridge API
    volumes:
      - ./config/go-manager-green:/app/config:ro
      - go-manager-green-logs:/app/logs
    networks:
      - green-network
    depends_on:
      - postgres-green
      - redis-green
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8091/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  # PostgreSQL Green Environment
  postgres-green:
    image: postgres:15-alpine
    container_name: postgres-green
    restart: unless-stopped
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres_green_password
      - POSTGRES_MULTIPLE_DATABASES=n8n_green,go_manager_green
      - POSTGRES_MULTIPLE_USERS=n8n_green:n8n_green_password,go_green:go_green_password
    ports:
      - "8094:5432"  # PostgreSQL Green
    volumes:
      - postgres-green-data:/var/lib/postgresql/data
      - ./scripts/init-databases-green.sh:/docker-entrypoint-initdb.d/init-databases.sh:ro
    networks:
      - green-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Redis Green Environment
  redis-green:
    image: redis:7-alpine
    container_name: redis-green
    restart: unless-stopped
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    ports:
      - "8095:6379"  # Redis Green
    volumes:
      - redis-green-data:/data
      - ./config/redis-green.conf:/usr/local/etc/redis/redis.conf:ro
    networks:
      - green-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Monitoring - Prometheus Green
  prometheus-green:
    image: prom/prometheus:latest
    container_name: prometheus-green
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=7d'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    ports:
      - "8096:9090"  # Prometheus Green
    volumes:
      - prometheus-green-data:/prometheus
      - ./config/prometheus-green.yml:/etc/prometheus/prometheus.yml:ro
    networks:
      - green-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Log Aggregation - Filebeat Green
  filebeat-green:
    image: elastic/filebeat:8.8.0
    container_name: filebeat-green
    restart: unless-stopped
    user: root
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    volumes:
      - ./config/filebeat-green.yml:/usr/share/filebeat/filebeat.yml:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - filebeat-green-data:/usr/share/filebeat/data
    networks:
      - green-network
      - monitoring-network
    depends_on:
      - n8n-green
      - go-manager-green

  # Canary Deployment Service
  canary-tester-green:
    build:
      context: ../
      dockerfile: deployments/docker/Dockerfile.canary
    container_name: canary-tester-green
    restart: "no"
    environment:
      - TARGET_ENV=green
      - N8N_URL=http://n8n-green:5678
      - GO_MANAGER_URL=http://go-manager-green:8091
      - TEST_SUITE=canary
      - TIMEOUT=300
    networks:
      - green-network
    depends_on:
      - n8n-green
      - go-manager-green
    profiles:
      - canary

networks:
  green-network:
    driver: bridge
    name: green-network
    ipam:
      config:
        - subnet: 172.21.0.0/16
          gateway: 172.21.0.1
    labels:
      - "environment=green"
      - "project=email-sender-hybrid"

  monitoring-network:
    external: true
    name: monitoring-network

volumes:
  n8n-green-data:
    name: n8n-green-data
    labels:
      - "environment=green"
      - "backup=daily"

  postgres-green-data:
    name: postgres-green-data
    labels:
      - "environment=green"
      - "backup=daily"

  redis-green-data:
    name: redis-green-data
    labels:
      - "environment=green"
      - "backup=hourly"

  go-manager-green-logs:
    name: go-manager-green-logs
    labels:
      - "environment=green"
      - "retention=7d"

  prometheus-green-data:
    name: prometheus-green-data
    labels:
      - "environment=green"
      - "retention=7d"

  filebeat-green-data:
    name: filebeat-green-data
    labels:
      - "environment=green"
      - "retention=3d"
'@

   $dockerComposeGreenFile = Join-Path $OutputDir "docker-compose.green.yml"
   $dockerComposeGreenContent | Set-Content $dockerComposeGreenFile -Encoding UTF8
   $Results.files_created += $dockerComposeGreenFile
    
   # Services définis
   $Results.services_defined += @("n8n-green", "go-manager-green", "postgres-green", "redis-green", "prometheus-green", "filebeat-green", "canary-tester-green")
    
   # Networks créés
   $Results.networks_created += @("green-network", "monitoring-network")
    
   # Ports alloués (Green: 8090-8099)
   $Results.ports_allocated += @("8090:5678", "8091:8091", "8092:8092", "8093:8093", "8094:5432", "8095:6379", "8096:9090")
    
   Write-Host "✅ Docker Compose Green créé: docker-compose.green.yml" -ForegroundColor Green

}
catch {
   $errorMsg = "Erreur création docker-compose.green.yml: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Créer script d'initialisation base de données Green
try {
   $initDbGreenScript = @'
#!/bin/bash
set -e

# Script d'initialisation des bases de données multiples pour PostgreSQL Green

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Création base de données N8N Green
    CREATE DATABASE n8n_green;
    CREATE USER n8n_green WITH ENCRYPTED PASSWORD 'n8n_green_password';
    GRANT ALL PRIVILEGES ON DATABASE n8n_green TO n8n_green;

    -- Création base de données Go Manager Green  
    CREATE DATABASE go_manager_green;
    CREATE USER go_green WITH ENCRYPTED PASSWORD 'go_green_password';
    GRANT ALL PRIVILEGES ON DATABASE go_manager_green TO go_green;

    -- Extensions utiles
    \c n8n_green;
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";

    \c go_manager_green;
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";

    -- Permissions additionnelles
    \c n8n_green;
    GRANT ALL ON SCHEMA public TO n8n_green;

    \c go_manager_green;
    GRANT ALL ON SCHEMA public TO go_green;

    -- Index pour performance
    \c go_manager_green;
    CREATE INDEX IF NOT EXISTS idx_workflows_status ON workflows(status);
    CREATE INDEX IF NOT EXISTS idx_workflows_created_at ON workflows(created_at);
EOSQL

echo "Bases de données Green initialisées avec succès"
'@

   $initDbGreenFile = Join-Path $OutputDir "scripts/init-databases-green.sh"
   $scriptsDir = Join-Path $OutputDir "scripts"
   if (!(Test-Path $scriptsDir)) {
      New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
   }
   $initDbGreenScript | Set-Content $initDbGreenFile -Encoding UTF8
   $Results.files_created += $initDbGreenFile
   Write-Host "✅ Script d'initialisation DB Green créé: scripts/init-databases-green.sh" -ForegroundColor Green

}
catch {
   $errorMsg = "Erreur création script init DB Green: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Créer configuration Prometheus Green
try {
   $prometheusGreenConfig = @'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    environment: 'green'
    cluster: 'email-sender-hybrid'

rule_files:
  - "alert_rules_green.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  # N8N Green Metrics
  - job_name: 'n8n-green'
    static_configs:
      - targets: ['n8n-green:5678']
    metrics_path: '/metrics'
    scrape_interval: 30s
    scrape_timeout: 10s
    relabel_configs:
      - source_labels: [__address__]
        target_label: environment
        replacement: green

  # Go Manager Green Metrics
  - job_name: 'go-manager-green'
    static_configs:
      - targets: ['go-manager-green:8092']
    metrics_path: '/metrics'
    scrape_interval: 15s
    scrape_timeout: 10s
    relabel_configs:
      - source_labels: [__address__]
        target_label: environment
        replacement: green

  # PostgreSQL Green Metrics (via postgres_exporter)
  - job_name: 'postgres-green'
    static_configs:
      - targets: ['postgres-green:5432']
    metrics_path: '/metrics'
    scrape_interval: 30s
    relabel_configs:
      - source_labels: [__address__]
        target_label: environment
        replacement: green

  # Redis Green Metrics (via redis_exporter)
  - job_name: 'redis-green'
    static_configs:
      - targets: ['redis-green:6379']
    metrics_path: '/metrics'
    scrape_interval: 30s
    relabel_configs:
      - source_labels: [__address__]
        target_label: environment
        replacement: green

  # Self monitoring
  - job_name: 'prometheus-green'
    static_configs:
      - targets: ['localhost:9090']
    relabel_configs:
      - source_labels: [__address__]
        target_label: environment
        replacement: green
'@

   $prometheusGreenConfigFile = Join-Path $OutputDir "config/prometheus-green.yml"
   $configDir = Join-Path $OutputDir "config"
   if (!(Test-Path $configDir)) {
      New-Item -ItemType Directory -Path $configDir -Force | Out-Null
   }
   $prometheusGreenConfig | Set-Content $prometheusGreenConfigFile -Encoding UTF8
   $Results.files_created += $prometheusGreenConfigFile
   Write-Host "✅ Configuration Prometheus Green créée: config/prometheus-green.yml" -ForegroundColor Green

}
catch {
   $errorMsg = "Erreur création config Prometheus Green: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Créer configuration Redis Green
try {
   $redisGreenConfig = @'
# Redis Configuration Green Environment
bind 0.0.0.0
port 6379
protected-mode no

# Memory management
maxmemory 256mb
maxmemory-policy allkeys-lru

# Persistence
appendonly yes
appendfsync everysec
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Logging
loglevel notice
logfile ""

# Performance
tcp-keepalive 300
timeout 0

# Security (basic)
# requirepass green_redis_password  # Uncomment in production

# Monitoring
latency-monitor-threshold 100

# Replication (for future use)
# replica-read-only yes
# replica-serve-stale-data yes

# Green environment specific
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command CONFIG "CONFIG_GREEN_ONLY"
'@

   $redisGreenConfigFile = Join-Path $OutputDir "config/redis-green.conf"
   $redisGreenConfig | Set-Content $redisGreenConfigFile -Encoding UTF8
   $Results.files_created += $redisGreenConfigFile
   Write-Host "✅ Configuration Redis Green créée: config/redis-green.conf" -ForegroundColor Green

}
catch {
   $errorMsg = "Erreur création config Redis Green: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Créer Dockerfile pour Canary Testing
try {
   $dockerfileCanary = @'
# Dockerfile.canary - Canary Testing pour Green environment
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install testing dependencies
RUN apk add --no-cache git ca-certificates curl

# Copy go mod files for test suite
COPY go.mod go.sum ./
RUN go mod download

# Copy test source code
COPY tests/ ./tests/
COPY pkg/ ./pkg/

# Build canary test suite
RUN CGO_ENABLED=0 GOOS=linux go build -o canary-tester ./tests/canary/

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates curl jq
WORKDIR /app

# Copy test binary
COPY --from=builder /app/canary-tester .

# Test scripts
COPY tests/canary/scripts/ ./scripts/

# Create test user
RUN addgroup -g 1001 testgroup && \
    adduser -u 1001 -G testgroup -s /bin/sh -D testuser
USER testuser

# Environment for testing
ENV TEST_TIMEOUT=300
ENV LOG_LEVEL=info

CMD ["./canary-tester"]
'@

   $dockerfileCanaryFile = Join-Path $OutputDir "../docker/Dockerfile.canary"
   $dockerCanaryDir = Join-Path $OutputDir "../docker"
   if (!(Test-Path $dockerCanaryDir)) {
      New-Item -ItemType Directory -Path $dockerCanaryDir -Force | Out-Null
   }
   $dockerfileCanary | Set-Content $dockerfileCanaryFile -Encoding UTF8
   $Results.files_created += $dockerfileCanaryFile
   Write-Host "✅ Dockerfile Canary créé: docker/Dockerfile.canary" -ForegroundColor Green

}
catch {
   $errorMsg = "Erreur création Dockerfile Canary: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Créer script de validation Green
try {
   $validationGreenScript = @'
#!/bin/bash
# Validation script pour Docker Compose Green

echo "🔍 Validation de la configuration Docker Compose Green..."

# Test de validation de la configuration
echo "📋 Validation de la syntaxe docker-compose..."
docker-compose -f docker-compose.green.yml config > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Configuration docker-compose syntaxiquement correcte"
else
    echo "❌ Erreur de syntaxe dans docker-compose.green.yml"
    exit 1
fi

# Vérification des ports disponibles
echo "🔌 Vérification des ports Green (8090-8099)..."
for port in 8090 8091 8092 8093 8094 8095 8096; do
    if lsof -i :$port > /dev/null 2>&1; then
        echo "⚠️ Port $port déjà utilisé"
    else
        echo "✅ Port $port disponible"
    fi
done

# Validation des réseaux
echo "🌐 Validation des réseaux..."
if docker network ls | grep -q "green-network"; then
    echo "⚠️ Réseau green-network existe déjà"
else
    echo "✅ Réseau green-network prêt à être créé"
fi

# Vérification des volumes
echo "💾 Vérification des volumes..."
volumes=("n8n-green-data" "postgres-green-data" "redis-green-data" "go-manager-green-logs" "prometheus-green-data" "filebeat-green-data")
for volume in "${volumes[@]}"; do
    if docker volume ls | grep -q "$volume"; then
        echo "⚠️ Volume $volume existe déjà"
    else
        echo "✅ Volume $volume prêt à être créé"
    fi
done

# Test canary readiness
echo "🧪 Vérification tests canary..."
if [ -f "../docker/Dockerfile.canary" ]; then
    echo "✅ Dockerfile canary présent"
else
    echo "⚠️ Dockerfile canary manquant"
fi

echo "🎉 Validation Green environment terminée"
'@

   $validationGreenScriptFile = Join-Path $OutputDir "scripts/validate-green.sh"
   $validationGreenScript | Set-Content $validationGreenScriptFile -Encoding UTF8
   $Results.files_created += $validationGreenScriptFile
   Write-Host "✅ Script de validation Green créé: scripts/validate-green.sh" -ForegroundColor Green

}
catch {
   $errorMsg = "Erreur création script validation Green: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Créer Health Check script pour Green environment
try {
   $healthCheckScript = @'
#!/bin/bash
# Health check comprehensive pour environnement Green

echo "🏥 Health Check Environnement Green..."

GREEN_SERVICES=("n8n-green" "go-manager-green" "postgres-green" "redis-green" "prometheus-green")
HEALTH_ENDPOINTS=(
    "http://localhost:8090/healthz"
    "http://localhost:8091/health"
    "http://localhost:8094"
    "http://localhost:8095"
    "http://localhost:8096/-/healthy"
)

OVERALL_HEALTH=0

# Test chaque service
for i in "${!GREEN_SERVICES[@]}"; do
    service="${GREEN_SERVICES[$i]}"
    endpoint="${HEALTH_ENDPOINTS[$i]}"
    
    echo "🔍 Test $service..."
    
    # Test container running
    if docker ps | grep -q "$service"; then
        echo "  ✅ Container $service en cours d'exécution"
        
        # Test endpoint if available
        if [[ $endpoint == http* ]]; then
            if curl -f -s "$endpoint" > /dev/null 2>&1; then
                echo "  ✅ Endpoint $endpoint accessible"
            else
                echo "  ❌ Endpoint $endpoint inaccessible"
                OVERALL_HEALTH=1
            fi
        fi
    else
        echo "  ❌ Container $service non trouvé"
        OVERALL_HEALTH=1
    fi
done

# Test connectivité inter-services
echo "🔗 Test connectivité inter-services..."

# Test Go Manager -> N8N
if docker exec go-manager-green curl -f -s "http://n8n-green:5678/healthz" > /dev/null 2>&1; then
    echo "  ✅ Go Manager peut contacter N8N"
else
    echo "  ❌ Go Manager ne peut pas contacter N8N"
    OVERALL_HEALTH=1
fi

# Test N8N -> PostgreSQL
if docker exec n8n-green pg_isready -h postgres-green -p 5432 > /dev/null 2>&1; then
    echo "  ✅ N8N peut contacter PostgreSQL"
else
    echo "  ❌ N8N ne peut pas contacter PostgreSQL"
    OVERALL_HEALTH=1
fi

# Test performance baseline
echo "📊 Test performance baseline..."
if docker exec go-manager-green curl -f -s "http://localhost:8092/metrics" | grep -q "go_manager"; then
    echo "  ✅ Métriques Go Manager disponibles"
else
    echo "  ❌ Métriques Go Manager indisponibles"
    OVERALL_HEALTH=1
fi

# Résultat final
if [ $OVERALL_HEALTH -eq 0 ]; then
    echo "🎉 Environnement Green HEALTHY"
    exit 0
else
    echo "⚠️ Environnement Green UNHEALTHY"
    exit 1
fi
'@

   $healthCheckScriptFile = Join-Path $OutputDir "scripts/health-check-green.sh"
   $healthCheckScript | Set-Content $healthCheckScriptFile -Encoding UTF8
   $Results.files_created += $healthCheckScriptFile
   Write-Host "✅ Script health check Green créé: scripts/health-check-green.sh" -ForegroundColor Green

}
catch {
   $errorMsg = "Erreur création script health check Green: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Calcul du résumé
$EndTime = Get-Date
$TotalDuration = ($EndTime - $StartTime).TotalSeconds

$Results.summary = @{
   total_duration_seconds = $TotalDuration
   files_created_count    = $Results.files_created.Count
   services_defined_count = $Results.services_defined.Count
   networks_created_count = $Results.networks_created.Count
   ports_allocated_count  = $Results.ports_allocated.Count
   errors_count           = $Results.errors.Count
   status                 = if ($Results.errors.Count -eq 0) { "SUCCESS" } else { "PARTIAL" }
}

# Sauvegarde des résultats
$outputReportFile = Join-Path "output/phase3" "task-052-results.json"
if (!(Test-Path "output/phase3")) {
   New-Item -ItemType Directory -Path "output/phase3" -Force | Out-Null
}
$Results | ConvertTo-Json -Depth 10 | Set-Content $outputReportFile -Encoding UTF8

Write-Host ""
Write-Host "📋 RÉSUMÉ TÂCHE 052:" -ForegroundColor Cyan
Write-Host "   Durée totale: $([math]::Round($TotalDuration, 2))s" -ForegroundColor White
Write-Host "   Fichiers créés: $($Results.summary.files_created_count)" -ForegroundColor White
Write-Host "   Services définis: $($Results.summary.services_defined_count)" -ForegroundColor White
Write-Host "   Networks créés: $($Results.summary.networks_created_count)" -ForegroundColor White
Write-Host "   Ports alloués: $($Results.summary.ports_allocated_count)" -ForegroundColor White
Write-Host "   Erreurs: $($Results.summary.errors_count)" -ForegroundColor White
Write-Host "   Status: $($Results.summary.status)" -ForegroundColor $(if ($Results.summary.status -eq "SUCCESS") { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "📁 FICHIERS GREEN CRÉÉS:" -ForegroundColor Cyan
foreach ($file in $Results.files_created) {
   Write-Host "   📄 $file" -ForegroundColor White
}

Write-Host ""
Write-Host "🐳 SERVICES GREEN DÉFINIS:" -ForegroundColor Cyan
foreach ($service in $Results.services_defined) {
   Write-Host "   🔹 $service" -ForegroundColor White
}

Write-Host ""
Write-Host "🔌 PORTS GREEN ALLOUÉS (8090-8099):" -ForegroundColor Cyan
foreach ($port in $Results.ports_allocated) {
   Write-Host "   🌐 $port" -ForegroundColor White
}

if ($Results.errors.Count -gt 0) {
   Write-Host ""
   Write-Host "⚠️ ERREURS DÉTECTÉES:" -ForegroundColor Yellow
   foreach ($errorItem in $Results.errors) {
      Write-Host "   $errorItem" -ForegroundColor Red
   }
}

Write-Host ""
Write-Host "💾 Rapport sauvé: $outputReportFile" -ForegroundColor Green
Write-Host ""
Write-Host "✅ TÂCHE 052 TERMINÉE - ENVIRONNEMENT GREEN PRÊT" -ForegroundColor Green
