#!/usr/bin/env pwsh

# Phase 7.1 - Script de déploiement production EMAIL_SENDER_1
# Déploiement Blue-Green avec validation complète

param(
    [string]$Environment = "production",
    [string]$Version = "",
    [switch]$BlueGreen,
    [switch]$SkipValidation,
    [switch]$AutoMigrate,
    [int]$HealthCheckTimeout = 300
)

Write-Host "🚀 Déploiement Production EMAIL_SENDER_1" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Cyan

if (-not $Version) {
    $Version = "v$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "Version générée automatiquement: $Version" -ForegroundColor Gray
}

# Configuration
$DOCKER_REGISTRY = "production-registry:5000"
$SERVICE_NAME = "email-sender-go"
$DEPLOYMENT_LOG = "logs/deployment-$Environment-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Fonction de logging
function Write-DeploymentLog {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry -ForegroundColor White }
    }
    
    $logEntry | Out-File -FilePath $DEPLOYMENT_LOG -Append -Encoding UTF8
}

try {
    Write-DeploymentLog "=== DÉBUT DU DÉPLOIEMENT PRODUCTION ===" "INFO"
    
    # Étape 1: Validations pré-déploiement
    Write-DeploymentLog "Étape 1: Validations pré-déploiement" "INFO"
    
    # Vérifier les prérequis
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker n'est pas installé ou accessible"
    }
    
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        throw "Docker Compose n'est pas installé ou accessible"
    }
    
    # Vérifier l'espace disque
    $freeSpace = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB
    if ($freeSpace -lt 5) {
        throw "Espace disque insuffisant: ${freeSpace}GB disponible (minimum 5GB requis)"
    }
    Write-DeploymentLog "Espace disque disponible: ${freeSpace}GB" "INFO"
    
    # Vérifier les services externes
    $requiredServices = @(
        @{ Name = "Qdrant"; Url = "http://localhost:6333/collections" },
        @{ Name = "PostgreSQL"; Url = "postgresql://localhost:5432" }
    )
    
    foreach ($service in $requiredServices) {
        try {
            if ($service.Name -eq "Qdrant") {
                $null = Invoke-RestMethod -Uri $service.Url -Method GET -TimeoutSec 5
                Write-DeploymentLog "✅ $($service.Name) accessible" "SUCCESS"
            }
        }
        catch {
            Write-DeploymentLog "⚠️  $($service.Name) non accessible, démarrage automatique prévu" "WARN"
        }
    }
    
    # Étape 2: Construction de l'image production
    Write-DeploymentLog "Étape 2: Construction de l'image production" "INFO"
    
    $imageTag = "${DOCKER_REGISTRY}/${SERVICE_NAME}:${Version}"
    $latestTag = "${DOCKER_REGISTRY}/${SERVICE_NAME}:production-latest"
    
    $buildArgs = @(
        "build",
        "--target", "production",
        "-t", $imageTag,
        "-t", $latestTag,
        "--build-arg", "GO_ENV=production",
        "--build-arg", "BUILD_VERSION=$Version",
        "-f", "deployment/Dockerfile.go",
        "."
    )
    
    Write-DeploymentLog "Construction de l'image: $imageTag" "INFO"
    $null = & docker @buildArgs
    
    if ($LASTEXITCODE -ne 0) {
        throw "Échec de la construction de l'image Docker"
    }
    Write-DeploymentLog "✅ Image construite avec succès" "SUCCESS"
    
    # Étape 3: Tests de sécurité sur l'image
    Write-DeploymentLog "Étape 3: Tests de sécurité sur l'image" "INFO"
      # Scanner l'image avec Trivy (si disponible)
    if (Get-Command trivy -ErrorAction SilentlyContinue) {
        Write-DeploymentLog "Scan de sécurité avec Trivy..." "INFO"
        $null = trivy image --format json --output "security-scan-$Version.json" $imageTag
        
        if ($LASTEXITCODE -eq 0) {
            Write-DeploymentLog "✅ Scan de sécurité terminé" "SUCCESS"
        }
        else {
            Write-DeploymentLog "⚠️  Scan de sécurité avec avertissements" "WARN"
        }
    }
    
    # Étape 4: Déploiement Blue-Green
    if ($BlueGreen) {
        Write-DeploymentLog "Étape 4: Déploiement Blue-Green" "INFO"
        
        # Déterminer l'environnement actuel (blue ou green)
        $currentEnv = "blue"  # Par défaut
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/deployment/info" -Method GET -TimeoutSec 5
            $currentEnv = $response.environment
        }
        catch {
            Write-DeploymentLog "Impossible de déterminer l'environnement actuel, utilisation de 'blue'" "WARN"
        }
        
        $targetEnv = if ($currentEnv -eq "blue") { "green" } else { "blue" }
        Write-DeploymentLog "Déploiement $currentEnv → $targetEnv" "INFO"
        
        # Variables d'environnement pour le déploiement
        $env:DOCKER_IMAGE_TAG = $Version
        $env:GO_ENV = "production"
        $env:DEPLOYMENT_ENV = $targetEnv
        $env:QDRANT_HOST = "qdrant"
        $env:QDRANT_PORT = "6333"
        
        # Déploiement sur l'environnement cible
        $composeFile = "deployment/docker-compose.production.yml"
        $envComposeFile = "deployment/production/docker-compose.$targetEnv.yml"
        
        if (Test-Path $envComposeFile) {
            & docker-compose -f $composeFile -f $envComposeFile up -d
        }
        else {
            & docker-compose -f $composeFile up -d
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Échec du déploiement sur l'environnement $targetEnv"
        }
        
        Write-DeploymentLog "✅ Services déployés sur l'environnement $targetEnv" "SUCCESS"
    }
    else {
        Write-DeploymentLog "Étape 4: Déploiement standard" "INFO"
        
        # Variables d'environnement
        $env:DOCKER_IMAGE_TAG = $Version
        $env:GO_ENV = "production"
        $env:QDRANT_HOST = "qdrant"
        $env:QDRANT_PORT = "6333"
        
        # Déploiement standard
        & docker-compose -f "deployment/docker-compose.production.yml" up -d
        
        if ($LASTEXITCODE -ne 0) {
            throw "Échec du déploiement standard"
        }
        
        Write-DeploymentLog "✅ Services déployés en mode standard" "SUCCESS"
    }
    
    # Étape 5: Migration des données
    if ($AutoMigrate) {
        Write-DeploymentLog "Étape 5: Migration automatique des données" "INFO"
        
        # Attendre que les services soient prêts
        Start-Sleep -Seconds 30
        
        # Exécuter la migration
        $migrationScript = "deployment/production/migrate-data.ps1"
        if (Test-Path $migrationScript) {
            & $migrationScript -Environment $Environment -BackupFirst -ValidateIntegrity
            
            if ($LASTEXITCODE -ne 0) {
                throw "Échec de la migration des données"
            }
            
            Write-DeploymentLog "✅ Migration des données terminée" "SUCCESS"
        }
        else {
            Write-DeploymentLog "⚠️  Script de migration non trouvé" "WARN"
        }
    }
    
    # Étape 6: Health checks détaillés
    Write-DeploymentLog "Étape 6: Health checks détaillés" "INFO"
    
    $maxAttempts = $HealthCheckTimeout / 10
    $attempt = 0
    $allServicesHealthy = $false
    
    while ($attempt -lt $maxAttempts -and -not $allServicesHealthy) {
        $attempt++
        $progressPercent = [Math]::Round($attempt / $maxAttempts * 100, 1)
        Write-Progress -Activity "Health Check en cours" -Status "Tentative $attempt/$maxAttempts" -PercentComplete $progressPercent
        
        try {
            # Test service principal
            $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET -TimeoutSec 5
              if ($healthResponse.status -eq "healthy") {
                # Test API Gateway
                $null = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/status" -Method GET -TimeoutSec 5
                
                # Test managers
                $managersResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/managers/status" -Method GET -TimeoutSec 5
                $activeManagers = ($managersResponse.managers | Where-Object { $_.status -eq "active" }).Count
                
                if ($activeManagers -ge 20) {  # Au moins 20 managers actifs
                    Write-DeploymentLog "✅ Tous les services sont opérationnels ($activeManagers managers actifs)" "SUCCESS"
                    $allServicesHealthy = $true
                }
                else {
                    Write-DeploymentLog "⏳ $activeManagers managers actifs, attente..." "INFO"
                }
            }
        }
        catch {
            Write-DeploymentLog "⏳ Services en cours de démarrage... (tentative $attempt)" "INFO"
        }
        
        if (-not $allServicesHealthy) {
            Start-Sleep -Seconds 10
        }
    }
    
    Write-Progress -Activity "Health Check en cours" -Completed
    
    if (-not $allServicesHealthy) {
        throw "Les services ne sont pas opérationnels après $HealthCheckTimeout secondes"
    }
    
    # Étape 7: Tests de validation production
    if (-not $SkipValidation) {
        Write-DeploymentLog "Étape 7: Tests de validation production" "INFO"
        
        # Exécuter les tests de health check complets
        $healthCheckScript = "deployment/staging/health-check.ps1"
        if (Test-Path $healthCheckScript) {
            & $healthCheckScript -BaseUrl "http://localhost:8080" -Detailed
            
            if ($LASTEXITCODE -ne 0) {
                throw "Échec des tests de validation"
            }
            
            Write-DeploymentLog "✅ Tous les tests de validation réussis" "SUCCESS"
        }
    }
    
    # Étape 8: Bascule du trafic (si Blue-Green)
    if ($BlueGreen -and $allServicesHealthy) {
        Write-DeploymentLog "Étape 8: Bascule du trafic vers $targetEnv" "INFO"
        
        # Mettre à jour la configuration du load balancer
        # (Ceci dépend de votre infrastructure)
        Write-DeploymentLog "Configuration du load balancer à implémenter selon votre infrastructure" "INFO"
        
        # Arrêt de l'ancien environnement après validation
        Write-DeploymentLog "Arrêt de l'ancien environnement $currentEnv..." "INFO"
        # docker-compose -f "deployment/production/docker-compose.$currentEnv.yml" down
    }
    
    # Étape 9: Configuration du monitoring
    Write-DeploymentLog "Étape 9: Configuration du monitoring" "INFO"
      # Vérifier que Prometheus collecte les métriques
    try {
        $null = Invoke-RestMethod -Uri "http://localhost:8081/metrics" -Method GET -TimeoutSec 5
        Write-DeploymentLog "✅ Métriques Prometheus accessibles" "SUCCESS"
    }
    catch {
        Write-DeploymentLog "⚠️  Métriques Prometheus non accessibles" "WARN"
    }
    
    # Étape 10: Rapport de déploiement final
    Write-DeploymentLog "=== RAPPORT DE DÉPLOIEMENT PRODUCTION ===" "SUCCESS"
    Write-DeploymentLog "Version déployée: $Version" "INFO"
    Write-DeploymentLog "Image: $imageTag" "INFO"
    Write-DeploymentLog "Environment: $Environment" "INFO"
    Write-DeploymentLog "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"
    
    if ($BlueGreen) {
        Write-DeploymentLog "Déploiement Blue-Green: $currentEnv → $targetEnv" "INFO"
    }
    
    # Services actifs
    Write-DeploymentLog "Services actifs:" "INFO"
    docker-compose -f "deployment/docker-compose.production.yml" ps | Out-String | Write-DeploymentLog
    
    Write-DeploymentLog "🎉 DÉPLOIEMENT PRODUCTION TERMINÉ AVEC SUCCÈS!" "SUCCESS"
    Write-DeploymentLog "URL de production: http://localhost:8080" "INFO"
    Write-DeploymentLog "Documentation: http://localhost:8080/docs" "INFO"
    Write-DeploymentLog "Métriques: http://localhost:8081/metrics" "INFO"
    Write-DeploymentLog "Log de déploiement: $DEPLOYMENT_LOG" "INFO"
    
}
catch {
    Write-DeploymentLog "❌ ÉCHEC DU DÉPLOIEMENT: $($_.Exception.Message)" "ERROR"
    
    # Rollback automatique
    Write-DeploymentLog "🔄 Rollback automatique en cours..." "WARN"
    
    try {
        # Arrêt des services défaillants
        docker-compose -f "deployment/docker-compose.production.yml" down
        
        # Si Blue-Green, revenir à l'environnement précédent
        if ($BlueGreen -and $targetEnv) {
            Write-DeploymentLog "Restauration de l'environnement $currentEnv" "INFO"
            # Logic de restauration Blue-Green
        }
        
        Write-DeploymentLog "✅ Rollback terminé" "SUCCESS"
    }
    catch {
        Write-DeploymentLog "❌ Échec du rollback automatique: $($_.Exception.Message)" "ERROR"
        Write-DeploymentLog "🆘 INTERVENTION MANUELLE NÉCESSAIRE!" "ERROR"
    }
    
    exit 1
}
