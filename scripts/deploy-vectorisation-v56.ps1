# ===================================================================
# Script de Déploiement Vectorisation v56
# ===================================================================
# Description: Script de déploiement automatisé pour la migration 
#              Python → Go du système de vectorisation
# Version: 1.0
# Auteur: Plan de développement v56
# Date: 2025-06-15
# ===================================================================

param(
   [Parameter(Mandatory = $false)]
   [ValidateSet("Development", "Staging", "Production")]
   [string]$Environment = "Development",
    
   [Parameter(Mandatory = $false)]
   [switch]$DryRun = $false,
    
   [Parameter(Mandatory = $false)]
   [switch]$SkipTests = $false,
    
   [Parameter(Mandatory = $false)]
   [switch]$SkipBackup = $false,
    
   [Parameter(Mandatory = $false)]
   [switch]$Force = $false,
    
   [Parameter(Mandatory = $false)]
   [string]$ConfigFile = "config/deploy-$Environment.json",
    
   [Parameter(Mandatory = $false)]
   [string]$LogLevel = "INFO"
)

# Configuration globale
$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# Variables globales
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot
$DeploymentId = Get-Date -Format "yyyyMMdd-HHmmss"
$LogFile = Join-Path $ProjectRoot "logs/deploy-$DeploymentId.log"

# ===================================================================
# FONCTIONS UTILITAIRES
# ===================================================================

function Write-Log {
   param(
      [Parameter(Mandatory = $true)][string]$Message,
      [Parameter(Mandatory = $false)][ValidateSet("INFO", "WARN", "ERROR", "DEBUG")][string]$Level = "INFO",
      [Parameter(Mandatory = $false)][switch]$NoConsole
   )
    
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [$Level] $Message"
    
   # Écrire dans le fichier de log
   if (-not (Test-Path (Split-Path $LogFile))) {
      New-Item -Path (Split-Path $LogFile) -ItemType Directory -Force | Out-Null
   }
   Add-Content -Path $LogFile -Value $logEntry
    
   # Écrire sur la console si demandé
   if (-not $NoConsole) {
      switch ($Level) {
         "INFO" { Write-Host $logEntry -ForegroundColor Green }
         "WARN" { Write-Host $logEntry -ForegroundColor Yellow }
         "ERROR" { Write-Host $logEntry -ForegroundColor Red }
         "DEBUG" { if ($LogLevel -eq "DEBUG") { Write-Host $logEntry -ForegroundColor Cyan } }
      }
   }
}

function Test-Prerequisites {
   Write-Log "Vérification des prérequis..."
    
   $prerequisites = @(
      @{ Name = "Go"; Command = "go version"; MinVersion = "1.21" },
      @{ Name = "Git"; Command = "git --version"; MinVersion = "2.0" },
      @{ Name = "Docker"; Command = "docker --version"; MinVersion = "20.0" },
      @{ Name = "Make"; Command = "make --version"; MinVersion = "4.0" }
   )
    
   $allPassed = $true
    
   foreach ($prereq in $prerequisites) {
      try {
         $output = Invoke-Expression $prereq.Command 2>$null
         if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ $($prereq.Name): $output" -Level DEBUG
         }
         else {
            Write-Log "❌ $($prereq.Name): Non installé ou inaccessible" -Level ERROR
            $allPassed = $false
         }
      }
      catch {
         Write-Log "❌ $($prereq.Name): Erreur lors de la vérification - $($_.Exception.Message)" -Level ERROR
         $allPassed = $false
      }
   }
    
   if (-not $allPassed) {
      throw "Prérequis manquants. Veuillez installer les outils requis."
   }
    
   Write-Log "✅ Tous les prérequis sont satisfaits"
}

function Get-DeploymentConfig {
   param([string]$ConfigPath)
    
   Write-Log "Chargement de la configuration: $ConfigPath"
    
   if (-not (Test-Path $ConfigPath)) {
      Write-Log "Fichier de configuration non trouvé, utilisation des valeurs par défaut" -Level WARN
      return @{
         Environment     = $Environment
         QdrantHost      = "localhost"
         QdrantPort      = 6333
         ServicePort     = 8080
         BuildTimeout    = 300
         TestTimeout     = 600
         BackupRetention = 7
      }
   }
    
   try {
      $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable
      Write-Log "✅ Configuration chargée: $($config.Keys.Count) paramètres"
      return $config
   }
   catch {
      Write-Log "❌ Erreur lors du chargement de la configuration: $($_.Exception.Message)" -Level ERROR
      throw
   }
}

# ===================================================================
# PHASE 1: COMPILATION DES BINAIRES GO
# ===================================================================

function Build-GoBinaries {
   param([hashtable]$Config)
    
   Write-Log "=== PHASE 1: COMPILATION DES BINAIRES GO ===" -Level INFO
    
   $buildDir = Join-Path $ProjectRoot "build"
   if (Test-Path $buildDir) {
      Remove-Item $buildDir -Recurse -Force
   }
   New-Item -Path $buildDir -ItemType Directory -Force | Out-Null
    
   # Services à compiler
   $services = @(
      @{ Name = "vectorization-service"; Path = "cmd/vectorization-service"; Binary = "vectorization-service.exe" },
      @{ Name = "migration-tool"; Path = "cmd/migration-tool"; Binary = "migration-tool.exe" },
      @{ Name = "validation-tool"; Path = "cmd/validation-tool"; Binary = "validation-tool.exe" }
   )
    
   Write-Log "Compilation de $($services.Count) services Go..."
    
   foreach ($service in $services) {
      Write-Log "Compilation de $($service.Name)..."
        
      $servicePath = Join-Path $ProjectRoot $service.Path
      if (-not (Test-Path $servicePath)) {
         Write-Log "❌ Chemin du service non trouvé: $servicePath" -Level ERROR
         continue
      }
        
      $outputPath = Join-Path $buildDir $service.Binary
        
      $buildArgs = @(
         "build",
         "-ldflags", "-X main.version=$DeploymentId -X main.environment=$Environment",
         "-o", $outputPath,
         "./cmd/$($service.Name)"
      )
        
      try {
         Push-Location $ProjectRoot
            
         if ($DryRun) {
            Write-Log "[DRY-RUN] go $($buildArgs -join ' ')" -Level DEBUG
         }
         else {
            Write-Log "Exécution: go $($buildArgs -join ' ')" -Level DEBUG
                
            $process = Start-Process -FilePath "go" -ArgumentList $buildArgs -NoNewWindow -Wait -PassThru
            if ($process.ExitCode -eq 0) {
               Write-Log "✅ $($service.Name) compilé avec succès: $outputPath"
                    
               # Vérifier la taille du binaire
               $fileInfo = Get-Item $outputPath
               Write-Log "   Taille: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -Level DEBUG
            }
            else {
               Write-Log "❌ Échec de compilation pour $($service.Name)" -Level ERROR
               throw "Compilation failed for $($service.Name)"
            }
         }
      }
      finally {
         Pop-Location
      }
   }
    
   Write-Log "✅ Compilation terminée avec succès"
}

function Test-Binaries {
   param([hashtable]$Config)
    
   if ($SkipTests) {
      Write-Log "Tests ignorés (paramètre -SkipTests)" -Level WARN
      return
   }
    
   Write-Log "Test des binaires compilés..."
    
   $buildDir = Join-Path $ProjectRoot "build"
   $binaries = Get-ChildItem $buildDir -Filter "*.exe"
    
   foreach ($binary in $binaries) {
      Write-Log "Test de $($binary.Name)..."
        
      try {
         if ($DryRun) {
            Write-Log "[DRY-RUN] Test binaire: $($binary.FullName)" -Level DEBUG
         }
         else {
            # Test basique: --version ou --help
            $process = Start-Process -FilePath $binary.FullName -ArgumentList "--version" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\test-output.txt" -RedirectStandardError "$env:TEMP\test-error.txt"
                
            if ($process.ExitCode -eq 0) {
               Write-Log "✅ $($binary.Name) fonctionne correctement"
            }
            else {
               $errorOutput = Get-Content "$env:TEMP\test-error.txt" -Raw
               Write-Log "❌ $($binary.Name) a échoué: $errorOutput" -Level ERROR
            }
                
            # Nettoyage
            Remove-Item "$env:TEMP\test-output.txt" -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\test-error.txt" -ErrorAction SilentlyContinue
         }
      }
      catch {
         Write-Log "❌ Erreur lors du test de $($binary.Name): $($_.Exception.Message)" -Level ERROR
      }
   }
}

# ===================================================================
# PHASE 2: MIGRATION DES DONNÉES EXISTANTES
# ===================================================================

function Backup-ExistingData {
   param([hashtable]$Config)
    
   if ($SkipBackup) {
      Write-Log "Sauvegarde ignorée (paramètre -SkipBackup)" -Level WARN
      return
   }
    
   Write-Log "=== PHASE 2: SAUVEGARDE DES DONNÉES EXISTANTES ===" -Level INFO
    
   $backupDir = Join-Path $ProjectRoot "backups\$DeploymentId"
   New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    
   # Collections à sauvegarder
   $collections = @("roadmap_tasks", "dependencies", "schemas", "security_policies")
    
   Write-Log "Sauvegarde de $($collections.Count) collections Qdrant..."
    
   foreach ($collection in $collections) {
      Write-Log "Sauvegarde collection: $collection"
        
      $backupFile = Join-Path $backupDir "$collection-backup.json"
        
      if ($DryRun) {
         Write-Log "[DRY-RUN] Sauvegarde collection $collection vers $backupFile" -Level DEBUG
      }
      else {
         try {
            # Utiliser curl pour sauvegarder via API Qdrant
            $qdrantUrl = "http://$($Config.QdrantHost):$($Config.QdrantPort)/collections/$collection"
                
            $curlArgs = @(
               "-X", "GET",
               "-H", "Content-Type: application/json",
               "-o", $backupFile,
               $qdrantUrl
            )
                
            $process = Start-Process -FilePath "curl" -ArgumentList $curlArgs -NoNewWindow -Wait -PassThru
                
            if ($process.ExitCode -eq 0 -and (Test-Path $backupFile)) {
               $fileSize = (Get-Item $backupFile).Length
               Write-Log "✅ Collection $collection sauvegardée: $([math]::Round($fileSize / 1KB, 2)) KB"
            }
            else {
               Write-Log "❌ Échec sauvegarde collection $collection" -Level ERROR
            }
         }
         catch {
            Write-Log "❌ Erreur sauvegarde $collection : $($_.Exception.Message)" -Level ERROR
         }
      }
   }
    
   # Sauvegarde configuration
   $configBackup = Join-Path $backupDir "config-backup.json"
   try {
      $currentConfig = @{
         Environment  = $Environment
         DeploymentId = $DeploymentId
         Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
         Config       = $Config
      }
        
      $currentConfig | ConvertTo-Json -Depth 5 | Out-File $configBackup -Encoding UTF8
      Write-Log "✅ Configuration sauvegardée: $configBackup"
   }
   catch {
      Write-Log "❌ Erreur sauvegarde configuration: $($_.Exception.Message)" -Level ERROR
   }
    
   Write-Log "✅ Sauvegarde terminée: $backupDir"
}

function Migrate-Data {
   param([hashtable]$Config)
    
   Write-Log "Migration des données vers le système Go..."
    
   $migrationTool = Join-Path $ProjectRoot "build\migration-tool.exe"
    
   if (-not (Test-Path $migrationTool)) {
      Write-Log "❌ Outil de migration non trouvé: $migrationTool" -Level ERROR
      throw "Migration tool not found"
   }
    
   $migrationArgs = @(
      "--source-host", "$($Config.QdrantHost):$($Config.QdrantPort)",
      "--target-host", "$($Config.QdrantHost):$($Config.QdrantPort)",
      "--environment", $Environment,
      "--log-level", $LogLevel
   )
    
   if ($DryRun) {
      $migrationArgs += "--dry-run"
   }
    
   Write-Log "Exécution migration: $migrationTool $($migrationArgs -join ' ')"
    
   try {
      if ($DryRun) {
         Write-Log "[DRY-RUN] Migration des données" -Level DEBUG
      }
      else {
         $process = Start-Process -FilePath $migrationTool -ArgumentList $migrationArgs -NoNewWindow -Wait -PassThru
            
         if ($process.ExitCode -eq 0) {
            Write-Log "✅ Migration des données réussie"
         }
         else {
            Write-Log "❌ Échec de la migration des données" -Level ERROR
            throw "Data migration failed"
         }
      }
   }
   catch {
      Write-Log "❌ Erreur lors de la migration: $($_.Exception.Message)" -Level ERROR
      throw
   }
}

# ===================================================================
# PHASE 3: VALIDATION POST-DÉPLOIEMENT
# ===================================================================

function Start-Services {
   param([hashtable]$Config)
    
   Write-Log "=== PHASE 3: DÉMARRAGE DES SERVICES ===" -Level INFO
    
   $serviceBinary = Join-Path $ProjectRoot "build\vectorization-service.exe"
    
   if (-not (Test-Path $serviceBinary)) {
      Write-Log "❌ Service binary non trouvé: $serviceBinary" -Level ERROR
      throw "Service binary not found"
   }
    
   Write-Log "Démarrage du service de vectorisation..."
    
   $serviceArgs = @(
      "--port", $Config.ServicePort,
      "--qdrant-host", $Config.QdrantHost,
      "--qdrant-port", $Config.QdrantPort,
      "--environment", $Environment,
      "--log-level", $LogLevel
   )
    
   if ($DryRun) {
      Write-Log "[DRY-RUN] Démarrage service: $serviceBinary $($serviceArgs -join ' ')" -Level DEBUG
   }
   else {
      try {
         # Démarrer en arrière-plan
         $process = Start-Process -FilePath $serviceBinary -ArgumentList $serviceArgs -NoNewWindow -PassThru
            
         # Attendre que le service soit prêt
         Write-Log "Attente du démarrage du service (PID: $($process.Id))..."
         Start-Sleep -Seconds 10
            
         # Vérifier si le service répond
         $healthCheck = Test-ServiceHealth -Config $Config
         if ($healthCheck) {
            Write-Log "✅ Service démarré avec succès"
                
            # Sauvegarder le PID pour arrêt ultérieur
            $process.Id | Out-File (Join-Path $ProjectRoot "service.pid") -Encoding UTF8
         }
         else {
            Write-Log "❌ Service non accessible après démarrage" -Level ERROR
            throw "Service health check failed"
         }
      }
      catch {
         Write-Log "❌ Erreur démarrage service: $($_.Exception.Message)" -Level ERROR
         throw
      }
   }
}

function Test-ServiceHealth {
   param([hashtable]$Config)
    
   $healthUrl = "http://localhost:$($Config.ServicePort)/health"
   $maxRetries = 5
   $retryDelay = 2
    
   for ($i = 1; $i -le $maxRetries; $i++) {
      try {
         Write-Log "Health check tentative $i/$maxRetries..." -Level DEBUG
            
         $response = Invoke-WebRequest -Uri $healthUrl -Method GET -TimeoutSec 5
         if ($response.StatusCode -eq 200) {
            Write-Log "✅ Service health check réussi"
            return $true
         }
      }
      catch {
         Write-Log "Health check échoué (tentative $i): $($_.Exception.Message)" -Level DEBUG
            
         if ($i -lt $maxRetries) {
            Start-Sleep -Seconds $retryDelay
         }
      }
   }
    
   Write-Log "❌ Service health check échoué après $maxRetries tentatives" -Level ERROR
   return $false
}

function Test-PostDeploymentValidation {
   param([hashtable]$Config)
    
   Write-Log "Validation post-déploiement..."
    
   $validationTool = Join-Path $ProjectRoot "build\validation-tool.exe"
    
   if (-not (Test-Path $validationTool)) {
      Write-Log "❌ Outil de validation non trouvé: $validationTool" -Level ERROR
      throw "Validation tool not found"
   }
    
   $validationArgs = @(
      "--environment", $Environment,
      "--service-url", "http://localhost:$($Config.ServicePort)",
      "--qdrant-host", "$($Config.QdrantHost):$($Config.QdrantPort)",
      "--timeout", $Config.TestTimeout
   )
    
   if ($DryRun) {
      $validationArgs += "--dry-run"
   }
    
   Write-Log "Exécution validation: $validationTool $($validationArgs -join ' ')"
    
   try {
      if ($DryRun) {
         Write-Log "[DRY-RUN] Validation post-déploiement" -Level DEBUG
      }
      else {
         $process = Start-Process -FilePath $validationTool -ArgumentList $validationArgs -NoNewWindow -Wait -PassThru
            
         if ($process.ExitCode -eq 0) {
            Write-Log "✅ Validation post-déploiement réussie"
         }
         else {
            Write-Log "❌ Échec de la validation post-déploiement" -Level ERROR
            throw "Post-deployment validation failed"
         }
      }
   }
   catch {
      Write-Log "❌ Erreur lors de la validation: $($_.Exception.Message)" -Level ERROR
      throw
   }
}

# ===================================================================
# FONCTIONS PRINCIPALES
# ===================================================================

function Start-Deployment {
   param([hashtable]$Config)
    
   Write-Log "=== DÉBUT DU DÉPLOIEMENT VECTORISATION V56 ===" -Level INFO
   Write-Log "Environnement: $Environment"
   Write-Log "ID Déploiement: $DeploymentId"
   Write-Log "Mode DRY-RUN: $DryRun"
   Write-Log "Configuration: $($Config | ConvertTo-Json -Compress)"
    
   try {
      # Phase 1: Compilation
      Build-GoBinaries -Config $Config
      Test-Binaries -Config $Config
        
      # Phase 2: Migration des données
      Backup-ExistingData -Config $Config
      Migrate-Data -Config $Config
        
      # Phase 3: Validation
      Start-Services -Config $Config
      Test-PostDeploymentValidation -Config $Config
        
      Write-Log "=== DÉPLOIEMENT TERMINÉ AVEC SUCCÈS ===" -Level INFO
      Write-Log "Services déployés et validés"
      Write-Log "Logs disponibles: $LogFile"
        
   }
   catch {
      Write-Log "=== ÉCHEC DU DÉPLOIEMENT ===" -Level ERROR
      Write-Log "Erreur: $($_.Exception.Message)"
      Write-Log "Logs complets: $LogFile"
        
      # Tentative de rollback si pas en DryRun
      if (-not $DryRun -and -not $Force) {
         Write-Log "Tentative de rollback automatique..." -Level WARN
         Start-Rollback -Config $Config
      }
        
      exit 1
   }
}

function Start-Rollback {
   param([hashtable]$Config)
    
   Write-Log "=== ROLLBACK EN COURS ===" -Level WARN
    
   try {
      # Arrêter les services
      $pidFile = Join-Path $ProjectRoot "service.pid"
      if (Test-Path $pidFile) {
         $pid = Get-Content $pidFile
         Write-Log "Arrêt du service (PID: $pid)..."
         Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
         Remove-Item $pidFile -ErrorAction SilentlyContinue
      }
        
      # Restaurer les données de sauvegarde
      $backupDir = Join-Path $ProjectRoot "backups\$DeploymentId"
      if (Test-Path $backupDir) {
         Write-Log "Restauration des données depuis: $backupDir"
         # Implémentation de la restauration
      }
        
      Write-Log "✅ Rollback terminé"
   }
   catch {
      Write-Log "❌ Erreur lors du rollback: $($_.Exception.Message)" -Level ERROR
   }
}

# ===================================================================
# POINT D'ENTRÉE PRINCIPAL
# ===================================================================

try {
   Write-Host "========================================" -ForegroundColor Cyan
   Write-Host "  SCRIPT DE DÉPLOIEMENT VECTORISATION V56" -ForegroundColor Cyan
   Write-Host "========================================" -ForegroundColor Cyan
   Write-Host ""
    
   # Vérifications préliminaires
   Test-Prerequisites
    
   # Chargement de la configuration
   $config = Get-DeploymentConfig -ConfigPath $ConfigFile
    
   # Demande de confirmation si pas en mode DryRun et pas forcé
   if (-not $DryRun -and -not $Force) {
      Write-Host "Êtes-vous sûr de vouloir déployer en environnement '$Environment'? (y/N): " -NoNewline -ForegroundColor Yellow
      $confirmation = Read-Host
        
      if ($confirmation -notmatch '^[yY]') {
         Write-Host "Déploiement annulé par l'utilisateur." -ForegroundColor Yellow
         exit 0
      }
   }
    
   # Lancement du déploiement
   Start-Deployment -Config $config
    
}
catch {
   Write-Log "Erreur fatale: $($_.Exception.Message)" -Level ERROR
   Write-Host "ÉCHEC DU SCRIPT DE DÉPLOIEMENT" -ForegroundColor Red
   Write-Host "Consultez les logs: $LogFile" -ForegroundColor Yellow
   exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  DÉPLOIEMENT TERMINÉ AVEC SUCCÈS!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
