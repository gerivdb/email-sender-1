#!/usr/bin/env pwsh

# Phase 7.1.1 - Script de rollback automatique
# Retour à l'état antérieur en cas de problème de déploiement

param(
    [string]$Environment = "staging",
    [string]$BackupPath = "",
    [switch]$Force,
    [switch]$PreserveLogs
)

Write-Host "🔄 Démarrage du rollback EMAIL_SENDER_1" -ForegroundColor Yellow
Write-Host "Environnement: $Environment" -ForegroundColor Cyan

try {
    # Étape 1: Validation des prérequis
    Write-Host "`n📋 Validation des prérequis de rollback..." -ForegroundColor Yellow
    
    if (-not $BackupPath) {
        # Trouver le backup le plus récent
        $backupDirs = Get-ChildItem -Path "backup" -Directory | 
                     Where-Object { $_.Name -like "*$Environment*" } |
                     Sort-Object LastWriteTime -Descending
        
        if ($backupDirs.Count -eq 0) {
            throw "Aucun backup trouvé pour l'environnement $Environment"
        }
        
        $BackupPath = $backupDirs[0].FullName
        Write-Host "Backup automatiquement sélectionné: $BackupPath" -ForegroundColor Gray
    }
    
    if (-not (Test-Path $BackupPath)) {
        throw "Le chemin de backup spécifié n'existe pas: $BackupPath"
    }
    
    # Étape 2: Arrêt des services actuels
    Write-Host "`n🛑 Arrêt des services actuels..." -ForegroundColor Yellow
    
    try {
        # Arrêt graduel des services
        docker-compose -f deployment/docker-compose.production.yml -f deployment/staging/docker-compose.staging.yml stop --timeout 30
        Write-Host "✅ Services arrêtés proprement" -ForegroundColor Green
    }
    catch {
        if ($Force) {
            Write-Host "⚠️  Arrêt forcé des services..." -ForegroundColor Yellow
            docker-compose -f deployment/docker-compose.production.yml -f deployment/staging/docker-compose.staging.yml kill
            docker-compose -f deployment/docker-compose.production.yml -f deployment/staging/docker-compose.staging.yml down --remove-orphans
        }
        else {
            throw "Échec de l'arrêt des services. Utilisez -Force pour un arrêt forcé."
        }
    }
    
    # Étape 3: Sauvegarde des logs actuels
    if ($PreserveLogs) {
        Write-Host "`n💾 Sauvegarde des logs actuels..." -ForegroundColor Yellow
        $logBackupDir = "backup/rollback-logs-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        New-Item -ItemType Directory -Path $logBackupDir -Force | Out-Null
        
        # Copier les logs Docker
        docker-compose -f deployment/docker-compose.production.yml -f deployment/staging/docker-compose.staging.yml logs --no-color > "$logBackupDir/docker-logs.txt"
        
        # Copier les logs applicatifs s'ils existent
        if (Test-Path "logs") {
            Copy-Item -Path "logs/*" -Destination $logBackupDir -Recurse -Force
        }
        
        Write-Host "✅ Logs sauvegardés dans: $logBackupDir" -ForegroundColor Green
    }
    
    # Étape 4: Restauration des volumes de données
    Write-Host "`n📦 Restauration des volumes de données..." -ForegroundColor Yellow
    
    # Restaurer Qdrant si backup disponible
    $qdrantBackup = Join-Path $BackupPath "qdrant_data.tar.gz"
    if (Test-Path $qdrantBackup) {
        Write-Host "Restauration des données Qdrant..." -ForegroundColor Gray
        
        # Supprimer l'ancien volume
        docker volume rm qdrant_staging_data -f 2>$null
        
        # Créer et restaurer le volume
        docker volume create qdrant_staging_data
        docker run --rm -v qdrant_staging_data:/data -v ${PWD}/${BackupPath}:/backup alpine tar xzf /backup/qdrant_data.tar.gz -C /data
        
        Write-Host "✅ Données Qdrant restaurées" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  Pas de backup Qdrant trouvé, utilisation de données vides" -ForegroundColor Yellow
    }
    
    # Restaurer PostgreSQL si backup disponible
    $postgresBackup = Join-Path $BackupPath "postgres_data.tar.gz"
    if (Test-Path $postgresBackup) {
        Write-Host "Restauration des données PostgreSQL..." -ForegroundColor Gray
        
        docker volume rm postgres_staging_data -f 2>$null
        docker volume create postgres_staging_data
        docker run --rm -v postgres_staging_data:/data -v ${PWD}/${BackupPath}:/backup alpine tar xzf /backup/postgres_data.tar.gz -C /data
        
        Write-Host "✅ Données PostgreSQL restaurées" -ForegroundColor Green
    }
    
    # Étape 5: Restauration de la configuration
    Write-Host "`n⚙️  Restauration de la configuration..." -ForegroundColor Yellow
    
    # Restaurer les fichiers de configuration si disponibles
    $configBackup = Join-Path $BackupPath "config"
    if (Test-Path $configBackup) {
        Copy-Item -Path "$configBackup/*" -Destination "deployment/config/" -Recurse -Force
        Write-Host "✅ Configuration restaurée" -ForegroundColor Green
    }
    
    # Étape 6: Restauration de l'image Docker précédente
    Write-Host "`n🐳 Restauration de l'image Docker..." -ForegroundColor Yellow
    
    # Identifier la version précédente
    $previousImages = docker images --filter "reference=*email-sender-go*" --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}" |
                     Select-String "staging" |
                     Sort-Object { [DateTime]($_ -split '\t')[1] } -Descending
    
    if ($previousImages.Count -gt 1) {
        $previousImage = ($previousImages[1] -split '\t')[0]
        Write-Host "Image précédente trouvée: $previousImage" -ForegroundColor Gray
        
        # Mettre à jour la variable d'environnement
        $env:DOCKER_IMAGE_TAG = ($previousImage -split ':')[1]
    }
    else {
        Write-Host "⚠️  Aucune image précédente trouvée, utilisation de l'image par défaut" -ForegroundColor Yellow
        $env:DOCKER_IMAGE_TAG = "staging-rollback"
    }
    
    # Étape 7: Redémarrage des services
    Write-Host "`n🚀 Redémarrage des services..." -ForegroundColor Yellow
    
    # Variables d'environnement pour le rollback
    $env:GO_ENV = $Environment
    $env:QDRANT_HOST = "qdrant"
    $env:QDRANT_PORT = "6333"
    
    # Démarrage des services
    docker-compose -f deployment/docker-compose.production.yml -f deployment/staging/docker-compose.staging.yml up -d
    
    if ($LASTEXITCODE -ne 0) {
        throw "Échec du redémarrage des services après rollback"
    }
    
    # Étape 8: Vérification de santé post-rollback
    Write-Host "`n🔍 Vérification de santé post-rollback..." -ForegroundColor Yellow
    
    $maxAttempts = 20
    $attempt = 0
    $servicesHealthy = $false
    
    while ($attempt -lt $maxAttempts -and -not $servicesHealthy) {
        $attempt++
        Write-Host "Tentative $attempt/$maxAttempts..." -ForegroundColor Gray
        
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET -TimeoutSec 5
            if ($response.status -eq "healthy") {
                Write-Host "✅ Services opérationnels après rollback" -ForegroundColor Green
                $servicesHealthy = $true
            }
        }
        catch {
            Start-Sleep -Seconds 3
        }
    }
    
    if (-not $servicesHealthy) {
        Write-Host "⚠️  Les services ne répondent pas après rollback. Vérification manuelle nécessaire." -ForegroundColor Yellow
    }
    
    # Étape 9: Tests de validation rapides
    Write-Host "`n✅ Tests de validation post-rollback..." -ForegroundColor Yellow
    
    try {
        # Test API basique
        $null = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/status" -Method GET -TimeoutSec 10
        Write-Host "✅ API opérationnelle" -ForegroundColor Green
        
        # Test base de données
        $managersResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/managers/status" -Method GET -TimeoutSec 10
        $activeManagers = ($managersResponse.managers | Where-Object { $_.status -eq "active" }).Count
        Write-Host "✅ $activeManagers managers actifs" -ForegroundColor Green
        
    }
    catch {
        Write-Host "⚠️  Validation partielle échouée: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Étape 10: Rapport de rollback
    Write-Host "`n📊 Rapport de rollback" -ForegroundColor Cyan
    Write-Host "=" * 30 -ForegroundColor Cyan
    Write-Host "Environnement: $Environment" -ForegroundColor White
    Write-Host "Backup utilisé: $BackupPath" -ForegroundColor White
    Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
    
    if ($PreserveLogs) {
        Write-Host "Logs sauvegardés: $logBackupDir" -ForegroundColor White
    }
    
    # Services actifs
    Write-Host "`nServices après rollback:" -ForegroundColor White
    docker-compose -f deployment/docker-compose.production.yml -f deployment/staging/docker-compose.staging.yml ps
    
    Write-Host "`n🎉 Rollback terminé avec succès!" -ForegroundColor Green
    Write-Host "⚠️  Vérifiez manuellement la configuration et les données si nécessaire" -ForegroundColor Yellow
    
}
catch {
    Write-Host "`n❌ Échec du rollback: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🆘 Intervention manuelle nécessaire!" -ForegroundColor Red
    
    # Informations de debug
    Write-Host "`nInformations de debug:" -ForegroundColor Gray
    Write-Host "Services Docker actuels:" -ForegroundColor Gray
    docker ps -a
    
    Write-Host "`nVolumes Docker:" -ForegroundColor Gray
    docker volume ls
    
    exit 1
}
