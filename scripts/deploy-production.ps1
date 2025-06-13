# Script de Déploiement Production
# Déploie le système Planning Ecosystem Sync en production

param(
   [Parameter(Mandatory = $true)]
   [ValidateSet("staging", "production")]
   [string]$Environment,
    
   [string]$Version = "latest",
   [switch]$DryRun,
   [switch]$SkipBackup,
   [switch]$Force
)

$ErrorActionPreference = "Stop"

# Configuration par environnement
$config = @{
   staging    = @{
      server           = "staging.planning-ecosystem.com"
      database         = "planning_sync_staging"
      port             = "8080"
      workers          = 2
      backup_retention = 7
   }
   production = @{
      server           = "prod.planning-ecosystem.com"
      database         = "planning_sync_prod"
      port             = "8080"
      workers          = 4
      backup_retention = 30
   }
}

$envConfig = $config[$Environment]

Write-Host "🚀 Déploiement Planning Ecosystem Sync" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Version: $Version" -ForegroundColor Cyan
Write-Host "Server: $($envConfig.server)" -ForegroundColor Cyan

if ($DryRun) {
   Write-Host "🧪 MODE DRY-RUN - Aucun changement sera appliqué" -ForegroundColor Yellow
}

# Fonction de validation pré-déploiement
function Test-PreDeployment {
   Write-Host "`n🔍 Validation pré-déploiement..." -ForegroundColor Green
    
   # 1. Vérifier version
   if ($Version -ne "latest") {
      $versionPattern = "^v\d+\.\d+\.\d+$"
      if ($Version -notmatch $versionPattern) {
         throw "Format de version invalide: $Version (attendu: vX.Y.Z)"
      }
   }
    
   # 2. Vérifier connectivité serveur
   Write-Host "📡 Test connectivité serveur..."
   $ping = Test-Connection -ComputerName $envConfig.server -Count 1 -Quiet
   if (!$ping) {
      throw "Serveur $($envConfig.server) injoignable"
   }
    
   # 3. Vérifier version Git
   Write-Host "📋 Vérification version Git..."
   $gitStatus = git status --porcelain
   if ($gitStatus -and !$Force) {
      throw "Modifications non commitées détectées. Utilisez -Force pour ignorer."
   }
    
   # 4. Vérifier tests
   Write-Host "🧪 Exécution tests..."
   if (!$DryRun) {
      $testResult = go test ./... -short
      if ($LASTEXITCODE -ne 0) {
         throw "Tests échoués. Déploiement annulé."
      }
   }
    
   # 5. Vérifier build
   Write-Host "🔨 Vérification build..."
   if (!$DryRun) {
      $buildResult = go build -o planning-sync-server-$Version ./cmd/server
      if ($LASTEXITCODE -ne 0) {
         throw "Build échoué. Déploiement annulé."
      }
   }
    
   Write-Host "✅ Validation pré-déploiement réussie" -ForegroundColor Green
}

# Fonction de backup pré-déploiement
function New-PreDeploymentBackup {
   if ($SkipBackup) {
      Write-Host "⏭️  Backup ignoré (--SkipBackup)" -ForegroundColor Yellow
      return
   }
    
   Write-Host "`n📦 Création backup pré-déploiement..." -ForegroundColor Green
    
   $backupName = "pre-deploy-$Environment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
   $backupPath = "backups/$backupName"
    
   if (!$DryRun) {
      New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        
      # Backup base de données
      Write-Host "🗄️  Backup base de données..."
      pg_dump -h $envConfig.server -U sync_user $envConfig.database > "$backupPath/database.sql"
        
      # Backup configuration
      Write-Host "⚙️  Backup configuration..."
      Copy-Item "config/$Environment.yaml" "$backupPath/config.yaml" -Force
        
      # Backup plans
      Write-Host "📝 Backup plans..."
      Copy-Item "roadmaps/plans/*" "$backupPath/plans/" -Recurse -Force
        
      # Compresser backup
      Compress-Archive -Path "$backupPath/*" -DestinationPath "$backupPath.zip" -Force
      Remove-Item -Path $backupPath -Recurse -Force
        
      Write-Host "✅ Backup créé: $backupPath.zip" -ForegroundColor Green
   }
   else {
      Write-Host "🧪 [DRY-RUN] Backup serait créé: $backupPath.zip"
   }
}

# Fonction de build et packaging
function New-DeploymentPackage {
   Write-Host "`n📦 Création package de déploiement..." -ForegroundColor Green
    
   $packageName = "planning-sync-$Version-$Environment"
   $packagePath = "dist/$packageName"
    
   if (!$DryRun) {
      # Nettoyer et créer dossier
      Remove-Item -Path "dist/*" -Recurse -Force -ErrorAction SilentlyContinue
      New-Item -ItemType Directory -Path $packagePath -Force | Out-Null
        
      # Build binaires
      Write-Host "🔨 Build binaires..."
      $env:GOOS = "linux"
      $env:GOARCH = "amd64"
      $env:CGO_ENABLED = "0"
        
      go build -ldflags "-X main.version=$Version -X main.environment=$Environment" -o "$packagePath/planning-sync-server" ./cmd/server
      go build -ldflags "-X main.version=$Version" -o "$packagePath/planning-sync-cli" ./cmd/cli
        
      # Copier fichiers de déploiement
      Write-Host "📋 Copie fichiers de déploiement..."
      Copy-Item "config/$Environment.yaml" "$packagePath/config.yaml" -Force
      Copy-Item "scripts/systemd/planning-sync.service" "$packagePath/" -Force
      Copy-Item "scripts/nginx/planning-sync.conf" "$packagePath/" -Force
      Copy-Item "web/dashboard/dist/*" "$packagePath/web/" -Recurse -Force
        
      # Créer scripts de déploiement
      $deployScript = @"
#!/bin/bash
# Auto-generated deployment script for $Environment

set -e

echo "🚀 Deploying Planning Ecosystem Sync $Version to $Environment"

# Stop service
sudo systemctl stop planning-sync || true

# Backup current version
sudo cp /opt/planning-sync/planning-sync-server /opt/planning-sync/planning-sync-server.backup || true

# Install new version
sudo cp planning-sync-server /opt/planning-sync/
sudo cp planning-sync-cli /usr/local/bin/
sudo cp config.yaml /opt/planning-sync/
sudo cp -r web/* /opt/planning-sync/web/

# Set permissions
sudo chown -R planning-sync:planning-sync /opt/planning-sync/
sudo chmod +x /opt/planning-sync/planning-sync-server
sudo chmod +x /usr/local/bin/planning-sync-cli

# Install/update systemd service
sudo cp planning-sync.service /etc/systemd/system/
sudo systemctl daemon-reload

# Install/update nginx config
sudo cp planning-sync.conf /etc/nginx/sites-available/
sudo ln -sf /etc/nginx/sites-available/planning-sync.conf /etc/nginx/sites-enabled/

# Start services
sudo systemctl start planning-sync
sudo systemctl enable planning-sync
sudo systemctl reload nginx

echo "✅ Deployment completed successfully"
echo "🌐 Service available at: http://$($envConfig.server):$($envConfig.port)"
"@
        
      $deployScript | Out-File "$packagePath/deploy.sh" -Encoding UTF8
        
      # Créer package
      Write-Host "🗜️  Compression package..."
      Compress-Archive -Path "$packagePath/*" -DestinationPath "$packagePath.zip" -Force
        
      Write-Host "✅ Package créé: $packagePath.zip" -ForegroundColor Green
      return "$packagePath.zip"
   }
   else {
      Write-Host "🧪 [DRY-RUN] Package serait créé: $packagePath.zip"
      return "$packagePath.zip"
   }
}

# Fonction de déploiement
function Deploy-Package {
   param([string]$PackagePath)
    
   Write-Host "`n🚀 Déploiement sur $($envConfig.server)..." -ForegroundColor Green
    
   if (!$DryRun) {
      # Upload package
      Write-Host "📤 Upload package..."
      scp $PackagePath "deploy@$($envConfig.server):/tmp/"
        
      # Extract et déployer
      Write-Host "📦 Extraction et déploiement..."
      $remoteCommands = @"
cd /tmp
unzip -o $(Split-Path $PackagePath -Leaf)
cd $(Split-Path $PackagePath -LeafBase)
chmod +x deploy.sh
sudo ./deploy.sh
"@
        
      ssh "deploy@$($envConfig.server)" $remoteCommands
        
      # Vérifier déploiement
      Write-Host "🔍 Vérification déploiement..."
      Start-Sleep 10
        
      $healthCheck = ssh "deploy@$($envConfig.server)" "curl -s http://localhost:$($envConfig.port)/health"
      $health = $healthCheck | ConvertFrom-Json
        
      if ($health.status -eq "healthy") {
         Write-Host "✅ Déploiement vérifié avec succès" -ForegroundColor Green
      }
      else {
         throw "❌ Vérification déploiement échouée"
      }
        
   }
   else {
      Write-Host "🧪 [DRY-RUN] Package serait déployé sur $($envConfig.server)"
   }
}

# Fonction de post-déploiement
function Invoke-PostDeployment {
   Write-Host "`n🔧 Tâches post-déploiement..." -ForegroundColor Green
    
   if (!$DryRun) {
      # Tests fumée
      Write-Host "💨 Tests fumée..."
      $baseUrl = "http://$($envConfig.server):$($envConfig.port)"
        
      $endpoints = @(
         "/health",
         "/api/v1/plans",
         "/api/v1/metrics"
      )
        
      foreach ($endpoint in $endpoints) {
         $response = Invoke-RestMethod -Uri "$baseUrl$endpoint" -TimeoutSec 30
         Write-Host "✅ $endpoint - OK" -ForegroundColor Green
      }
        
      # Tests intégration
      Write-Host "🔗 Tests intégration..."
      ssh "deploy@$($envConfig.server)" "cd /opt/planning-sync && ./planning-sync-cli test --quick"
        
      # Notification déploiement
      Write-Host "📢 Notification déploiement..."
      $deploymentInfo = @{
         environment = $Environment
         version     = $Version
         timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
         deployed_by = $env:USERNAME
         status      = "success"
      } | ConvertTo-Json
        
      # Webhook notification (optionnel)
      try {
         $webhookUrl = (Get-Content "config/$Environment.yaml" | ConvertFrom-Yaml).notifications.deployment_webhook
         if ($webhookUrl) {
            Invoke-RestMethod -Uri $webhookUrl -Method POST -Body $deploymentInfo -ContentType "application/json"
         }
      }
      catch {
         Write-Host "⚠️  Notification webhook échouée: $_" -ForegroundColor Yellow
      }
        
   }
   else {
      Write-Host "🧪 [DRY-RUN] Tests post-déploiement seraient exécutés"
   }
}

# Fonction de rollback d'urgence
function Invoke-EmergencyRollback {
   Write-Host "🚨 ROLLBACK D'URGENCE ACTIVÉ" -ForegroundColor Red
    
   if (!$DryRun) {
      ssh "deploy@$($envConfig.server)" @"
sudo systemctl stop planning-sync
sudo cp /opt/planning-sync/planning-sync-server.backup /opt/planning-sync/planning-sync-server
sudo systemctl start planning-sync
echo "Emergency rollback completed"
"@
   }
   else {
      Write-Host "🧪 [DRY-RUN] Rollback d'urgence serait exécuté"
   }
}

# Execution principale
try {
   Test-PreDeployment
   New-PreDeploymentBackup
   $packagePath = New-DeploymentPackage
   Deploy-Package $packagePath
   Invoke-PostDeployment
    
   Write-Host "`n🎉 Déploiement $Environment réussi !" -ForegroundColor Green
   Write-Host "🌐 Service disponible: http://$($envConfig.server):$($envConfig.port)" -ForegroundColor Cyan
   Write-Host "📊 Dashboard: http://$($envConfig.server):$($envConfig.port)/dashboard" -ForegroundColor Cyan
    
   # Nettoyage
   if (!$DryRun) {
      Remove-Item -Path "dist/*" -Recurse -Force -ErrorAction SilentlyContinue
      Write-Host "🧹 Fichiers temporaires nettoyés" -ForegroundColor Gray
   }
    
}
catch {
   Write-Host "`n❌ ERREUR DE DÉPLOIEMENT: $_" -ForegroundColor Red
    
   if (!$DryRun -and !$SkipBackup) {
      $rollback = Read-Host "Voulez-vous effectuer un rollback d'urgence? (y/N)"
      if ($rollback -eq "y" -or $rollback -eq "Y") {
         Invoke-EmergencyRollback
      }
   }
    
   exit 1
}
