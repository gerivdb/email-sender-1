#!/usr/bin/env pwsh

# Phase 7.1.1 - Script de déploiement staging
# Déploiement sur environnement de test avec validation complète

param(
   [string]$Environment = "staging",
   [switch]$Validate,
   [switch]$SkipBackup
)

# Définir valeurs par défaut
if (-not $PSBoundParameters.ContainsKey('Validate')) { $Validate = $true }

Write-Host "🚀 Démarrage du déploiement staging EMAIL_SENDER_1" -ForegroundColor Green
Write-Host "Environnement: $Environment" -ForegroundColor Cyan

# Configuration
$DOCKER_REGISTRY = "localhost:5000"
$SERVICE_NAME = "email-sender-go"
$IMAGE_TAG = "staging-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

try {
   # Étape 1: Validation des prérequis
   Write-Host "`n📋 Vérification des prérequis..." -ForegroundColor Yellow
    
   # Vérifier Docker
   if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
      throw "Docker n'est pas installé ou accessible"
   }
    
   # Vérifier Docker Compose
   if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
      throw "Docker Compose n'est pas installé ou accessible"
   }
   # Vérifier la connectivité Qdrant
   Write-Host "Vérification connectivité Qdrant..." -ForegroundColor Gray
   try {
      $null = Invoke-RestMethod -Uri "http://localhost:6333/collections" -Method GET -TimeoutSec 5
      Write-Host "✅ Qdrant accessible" -ForegroundColor Green
   }
   catch {
      Write-Warning "⚠️  Qdrant non accessible, démarrage automatique prévu"
   }
    
   # Étape 2: Backup si nécessaire
   if (-not $SkipBackup) {
      Write-Host "`n💾 Sauvegarde de l'environnement actuel..." -ForegroundColor Yellow
      $backupDir = "backup/staging-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
      New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        
      # Backup des volumes Docker
      if (docker volume ls -q | Where-Object { $_ -like "*qdrant*" }) {
         docker run --rm -v qdrant_data:/data -v ${PWD}/${backupDir}:/backup alpine tar czf /backup/qdrant_data.tar.gz -C /data .
         Write-Host "✅ Backup Qdrant terminé" -ForegroundColor Green
      }
   }
    
   # Étape 3: Build de l'image Go
   Write-Host "`n🔨 Construction de l'image Docker Go..." -ForegroundColor Yellow
   $buildArgs = @(
      "build",
      "-t", "${DOCKER_REGISTRY}/${SERVICE_NAME}:${IMAGE_TAG}",
      "-t", "${DOCKER_REGISTRY}/${SERVICE_NAME}:staging-latest",
      "-f", "deployment/Dockerfile.go",
      "."
   )
   $null = & docker @buildArgs
   if ($LASTEXITCODE -ne 0) {
      throw "Échec de la construction de l'image Docker"
   }
   Write-Host "✅ Image construite avec succès" -ForegroundColor Green
    
   # Étape 4: Déploiement avec Docker Compose
   Write-Host "`n🚀 Déploiement des services..." -ForegroundColor Yellow
    
   # Variables d'environnement pour le déploiement
   $env:DOCKER_IMAGE_TAG = $IMAGE_TAG
   $env:GO_ENV = "staging"
   $env:QDRANT_HOST = "qdrant"
   $env:QDRANT_PORT = "6333"
    
   # Démarrage des services
   $composeArgs = @(
      "-f", "deployment/docker-compose.production.yml",
      "-f", "deployment/staging/docker-compose.staging.yml",
      "up", "-d"
   )
    
   & docker-compose @composeArgs
   if ($LASTEXITCODE -ne 0) {
      throw "Échec du déploiement Docker Compose"
   }
    
   # Étape 5: Health checks
   Write-Host "`n🔍 Vérifications de santé..." -ForegroundColor Yellow
    
   $maxAttempts = 30
   $attempt = 0
   $servicesHealthy = $false
    
   while ($attempt -lt $maxAttempts -and -not $servicesHealthy) {
      $attempt++
      Write-Host "Tentative $attempt/$maxAttempts..." -ForegroundColor Gray
        
      # Vérifier le service principal
      try {
         $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET -TimeoutSec 5
         if ($response.status -eq "healthy") {
            Write-Host "✅ Service principal opérationnel" -ForegroundColor Green
            $servicesHealthy = $true
         }
      }
      catch {
         Write-Host "⏳ Service en cours de démarrage..." -ForegroundColor Gray
         Start-Sleep -Seconds 2
      }
   }
    
   if (-not $servicesHealthy) {
      throw "Les services ne sont pas opérationnels après $maxAttempts tentatives"
   }
    
   # Étape 6: Tests de validation
   if ($Validate) {
      Write-Host "`n✅ Exécution des tests de validation..." -ForegroundColor Yellow
      # Test de l'API Gateway
      try {
         $null = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/status" -Method GET
         Write-Host "✅ API Gateway opérationnelle" -ForegroundColor Green
      }
      catch {
         throw "Échec de validation de l'API Gateway"
      }
        
      # Test de la vectorisation
      try {
         $null = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/vectors/search" -Method POST -Body '{"query": "test", "limit": 1}' -ContentType "application/json"
         Write-Host "✅ Service de vectorisation opérationnel" -ForegroundColor Green
      }
      catch {
         throw "Échec de validation du service de vectorisation"
      }
        
      # Test des managers
      try {
         $managersResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/managers/status" -Method GET
         $activeManagers = ($managersResponse.managers | Where-Object { $_.status -eq "active" }).Count
         Write-Host "✅ $activeManagers managers actifs" -ForegroundColor Green
      }
      catch {
         throw "Échec de validation des managers"
      }
   }
    
   # Étape 7: Rapport de déploiement
   Write-Host "`n📊 Rapport de déploiement staging" -ForegroundColor Cyan
   Write-Host "================================" -ForegroundColor Cyan
   Write-Host "Image déployée: ${DOCKER_REGISTRY}/${SERVICE_NAME}:${IMAGE_TAG}" -ForegroundColor White
   Write-Host "Environnement: $Environment" -ForegroundColor White
   Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
    
   # Lister les services actifs
   Write-Host "`nServices actifs:" -ForegroundColor White
   docker-compose -f deployment/docker-compose.production.yml -f deployment/staging/docker-compose.staging.yml ps
    
   Write-Host "`n🎉 Déploiement staging terminé avec succès!" -ForegroundColor Green
   Write-Host "URL de test: http://localhost:8080" -ForegroundColor Cyan
   Write-Host "Documentation: http://localhost:8080/docs" -ForegroundColor Cyan
    
}
catch {
   Write-Host "`n❌ Échec du déploiement: $($_.Exception.Message)" -ForegroundColor Red
    
   # Rollback automatique
   Write-Host "🔄 Rollback automatique..." -ForegroundColor Yellow
   try {
      docker-compose -f deployment/docker-compose.production.yml -f deployment/staging/docker-compose.staging.yml down
      Write-Host "✅ Rollback terminé" -ForegroundColor Green
   }
   catch {
      Write-Host "❌ Échec du rollback: $($_.Exception.Message)" -ForegroundColor Red
   }
    
   exit 1
}
