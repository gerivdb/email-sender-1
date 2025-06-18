# Smart Email Sender - Full Stack Startup Script
# Démarrage manuel complet de l'infrastructure

param(
   [Parameter(Mandatory = $false)]
   [switch]$Development = $false,
    
   [Parameter(Mandatory = $false)]
   [switch]$Production = $false,
    
   [Parameter(Mandatory = $false)]
   [switch]$EnableAutoHealing = $false,
    
   [Parameter(Mandatory = $false)]
   [switch]$Verbose = $false,
    
   [Parameter(Mandatory = $false)]
   [int]$ApiPort = 8080
)

# Configuration
$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot | Split-Path
$LogPath = Join-Path $ProjectRoot "logs"
$BinPath = Join-Path $ProjectRoot "bin"

# Créer le répertoire de logs s'il n'existe pas
if (!(Test-Path $LogPath)) {
   New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

function Write-ColorOutput {
   param([string]$Message, [string]$Color = "White")
   Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
   param([string]$Title)
   Write-Host ""
   Write-Host "=" * 70 -ForegroundColor Cyan
   Write-Host " $Title" -ForegroundColor Yellow
   Write-Host "=" * 70 -ForegroundColor Cyan
   Write-Host ""
}

function Write-Step {
   param([string]$Message)
   Write-ColorOutput "🔄 $Message" "Cyan"
}

function Write-Success {
   param([string]$Message)
   Write-ColorOutput "✅ $Message" "Green"
}

function Write-Warning {
   param([string]$Message)
   Write-ColorOutput "⚠️  $Message" "Yellow"
}

function Write-Error {
   param([string]$Message)
   Write-ColorOutput "❌ $Message" "Red"
}

function Test-Prerequisites {
   Write-Step "Checking prerequisites..."
    
   # Vérifier Go
   try {
      $goVersion = go version 2>$null
      Write-Success "Go installed: $goVersion"
   }
   catch {
      Write-Error "Go is not installed or not in PATH"
      exit 1
   }
    
   # Vérifier Docker
   try {
      $dockerVersion = docker --version 2>$null
      Write-Success "Docker installed: $dockerVersion"
        
      # Vérifier que Docker est en cours d'exécution
      docker info 2>$null | Out-Null
      Write-Success "Docker is running"
   }
   catch {
      Write-Error "Docker is not installed, not running, or not accessible"
      exit 1
   }
    
   # Vérifier PowerShell version
   $psVersion = $PSVersionTable.PSVersion
   if ($psVersion.Major -ge 5) {
      Write-Success "PowerShell version: $($psVersion.ToString())"
   }
   else {
      Write-Warning "PowerShell version is $($psVersion.ToString()). Recommended: 5.0+"
   }
    
   # Créer les répertoires nécessaires
   @($BinPath, $LogPath) | ForEach-Object {
      if (!(Test-Path $_)) {
         New-Item -ItemType Directory -Path $_ -Force | Out-Null
         Write-Success "Created directory: $_"
      }
   }
}

function Start-DockerServices {
   Write-Step "Starting Docker services..."
    
   Push-Location $ProjectRoot
   try {
      # Choisir le profil selon les paramètres
      $profile = if ($Production) { "production" } else { "development" }
      Write-ColorOutput "Using profile: $profile" "Yellow"
        
      # Arrêter les services existants d'abord
      Write-Step "Stopping existing services..."
      docker-compose down --remove-orphans 2>$null
        
      # Démarrer les nouveaux services
      Write-Step "Starting Docker Compose services with profile: $profile"
      docker-compose --profile $profile up -d
        
      Write-Success "Docker services started successfully"
        
      # Attendre que les services soient prêts
      Write-Step "Waiting for services to initialize..."
      Start-Sleep -Seconds 20
        
      # Vérifier l'état des services
      Write-Step "Checking service health..."
      $services = docker-compose ps --format json | ConvertFrom-Json
      foreach ($service in $services) {
         $status = if ($service.State -eq "running") { "✅" } else { "❌" }
         Write-ColorOutput "$status $($service.Service): $($service.State)" "White"
      }
        
   }
   catch {
      Write-Error "Failed to start Docker services: $_"
      throw
   }
   finally {
      Pop-Location
   }
}

function Build-InfrastructureComponents {
   Write-Step "Building infrastructure components..."
    
   Push-Location $ProjectRoot
   try {
      # Nettoyer les dépendances
      Write-Step "Cleaning Go dependencies..."
      go mod tidy
        
      # Build Smart Infrastructure Manager
      Write-Step "Building Smart Infrastructure Manager..."
      $smartInfraExe = Join-Path $BinPath "smart-infrastructure.exe"
      go build -ldflags "-s -w" -o $smartInfraExe ./cmd/smart-infrastructure
        
      if (Test-Path $smartInfraExe) {
         Write-Success "Smart Infrastructure Manager built"
      }
      else {
         throw "Smart Infrastructure Manager build failed"
      }
        
      # Build Infrastructure API Server
      Write-Step "Building Infrastructure API Server..."
      $apiServerExe = Join-Path $BinPath "infrastructure-api-server.exe"
      go build -ldflags "-s -w" -o $apiServerExe ./cmd/infrastructure-api-server
        
      if (Test-Path $apiServerExe) {
         Write-Success "Infrastructure API Server built"
      }
      else {
         throw "Infrastructure API Server build failed"
      }
        
      # Build autres outils si nécessaires
      $tools = @(
         @{Name = "QDrant Backup Tool"; Path = "./cmd/backup-qdrant"; Output = "qdrant-backup.exe" },
         @{Name = "QDrant Migration Tool"; Path = "./cmd/migrate-qdrant"; Output = "qdrant-migrate.exe" },
         @{Name = "Embeddings Migration Tool"; Path = "./cmd/migrate-embeddings"; Output = "embeddings-migrate.exe" }
      )
        
      foreach ($tool in $tools) {
         if (Test-Path $tool.Path) {
            Write-Step "Building $($tool.Name)..."
            $toolExe = Join-Path $BinPath $tool.Output
            go build -ldflags "-s -w" -o $toolExe $tool.Path
                
            if (Test-Path $toolExe) {
               Write-Success "$($tool.Name) built"
            }
            else {
               Write-Warning "$($tool.Name) build failed (non-critical)"
            }
         }
      }
        
   }
   catch {
      Write-Error "Failed to build components: $_"
      throw
   }
   finally {
      Pop-Location
   }
}

function Start-InfrastructureApiServer {
   Write-Step "Starting Infrastructure API Server..."
    
   $apiServerExe = Join-Path $BinPath "infrastructure-api-server.exe"
   $logFile = Join-Path $LogPath "infrastructure-api-server.log"
   $pidFile = Join-Path $LogPath "infrastructure-api-server.pid"
    
   try {
      # Vérifier si le serveur est déjà en cours d'exécution
      if (Test-Path $pidFile) {
         $existingPid = Get-Content $pidFile -Raw
         $existingProcess = Get-Process -Id $existingPid -ErrorAction SilentlyContinue
         if ($existingProcess) {
            Write-Warning "API Server already running (PID: $existingPid)"
            return $existingProcess
         }
         else {
            Remove-Item $pidFile -Force
         }
      }
        
      # Démarrer le serveur API
      $startInfo = New-Object System.Diagnostics.ProcessStartInfo
      $startInfo.FileName = $apiServerExe
      $startInfo.Arguments = "-port $ApiPort"
      $startInfo.WorkingDirectory = $ProjectRoot
      $startInfo.UseShellExecute = $false
      $startInfo.RedirectStandardOutput = $true
      $startInfo.RedirectStandardError = $true
        
      $process = New-Object System.Diagnostics.Process
      $process.StartInfo = $startInfo
        
      $process.Start() | Out-Null
        
      # Enregistrer le PID
      $process.Id | Out-File -FilePath $pidFile -Encoding ascii
        
      Write-Success "Infrastructure API Server started (PID: $($process.Id), Port: $ApiPort)"
        
      # Attendre que le serveur soit prêt
      Write-Step "Waiting for API Server to be ready..."
      $maxRetries = 15
      $retryCount = 0
      $isReady = $false
        
      do {
         Start-Sleep -Seconds 2
         try {
            $response = Invoke-RestMethod -Uri "http://localhost:$ApiPort/api/v1/infrastructure/status" -Method GET -TimeoutSec 5
            if ($response.success) {
               $isReady = $true
               Write-Success "API Server is ready and responding"
            }
         }
         catch {
            $retryCount++
            if ($Verbose) {
               Write-ColorOutput "Retry $retryCount/$maxRetries - API Server not ready yet..." "Yellow"
            }
         }
      } while (-not $isReady -and $retryCount -lt $maxRetries)
        
      if (-not $isReady) {
         throw "API Server failed to become ready after $maxRetries attempts"
      }
        
      return $process
        
   }
   catch {
      Write-Error "Failed to start Infrastructure API Server: $_"
      throw
   }
}

function Start-AdvancedMonitoring {
   Write-Step "Starting Advanced Monitoring..."
    
   try {
      $response = Invoke-RestMethod -Uri "http://localhost:$ApiPort/api/v1/monitoring/start" -Method POST -TimeoutSec 30
      if ($response.success) {
         Write-Success "Advanced Monitoring started successfully"
      }
      else {
         throw $response.error
      }
   }
   catch {
      Write-Error "Failed to start Advanced Monitoring: $_"
      throw
   }
}

function Enable-AutoHealing {
   if ($EnableAutoHealing) {
      Write-Step "Enabling Auto-Healing..."
        
      try {
         $response = Invoke-RestMethod -Uri "http://localhost:$ApiPort/api/v1/auto-healing/enable" -Method POST -TimeoutSec 30
         if ($response.success) {
            Write-Success "Auto-Healing enabled successfully"
         }
         else {
            throw $response.error
         }
      }
      catch {
         Write-Error "Failed to enable Auto-Healing: $_"
         throw
      }
   }
   else {
      Write-ColorOutput "ℹ️  Auto-Healing not enabled (use -EnableAutoHealing to enable)" "Blue"
   }
}

function Show-FinalStatus {
   Write-Header "🎉 Full Stack Startup Complete!"
    
   try {
      # Statut des services Docker
      Write-ColorOutput "🐳 Docker Services:" "Cyan"
      $dockerServices = docker-compose ps --format json | ConvertFrom-Json
      foreach ($service in $dockerServices) {
         $icon = if ($service.State -eq "running") { "✅" } else { "❌" }
         $color = if ($service.State -eq "running") { "Green" } else { "Red" }
         Write-ColorOutput "  $icon $($service.Service): $($service.State)" $color
      }
        
      Write-Host ""
        
      # Statut de l'infrastructure
      Write-ColorOutput "🏗️ Infrastructure:" "Cyan"
      $infraStatus = Invoke-RestMethod -Uri "http://localhost:$ApiPort/api/v1/infrastructure/status" -Method GET
      if ($infraStatus.success) {
         Write-ColorOutput "  ✅ Overall Status: $($infraStatus.data.overall)" "Green"
      }
        
      # Statut du monitoring
      Write-ColorOutput "📊 Monitoring:" "Cyan"
      $monitoringStatus = Invoke-RestMethod -Uri "http://localhost:$ApiPort/api/v1/monitoring/status" -Method GET
      if ($monitoringStatus.success) {
         $status = $monitoringStatus.data
         $activeIcon = if ($status.active) { "✅" } else { "❌" }
         $healingIcon = if ($status.auto_healing_enabled) { "✅" } else { "⚪" }
            
         Write-ColorOutput "  $activeIcon Advanced Monitoring: $($status.active)" "Green"
         Write-ColorOutput "  $healingIcon Auto-Healing: $($status.auto_healing_enabled)" "Green"
         Write-ColorOutput "  📈 Services Monitored: $($status.services_monitored)" "White"
      }
        
      Write-Host ""
      Write-ColorOutput "🌐 Access Points:" "Cyan"
      Write-ColorOutput "  📡 Infrastructure API: http://localhost:$ApiPort" "White"
      Write-ColorOutput "  📊 Prometheus: http://localhost:9090" "White"  
      Write-ColorOutput "  📈 Grafana: http://localhost:3000" "White"
      Write-ColorOutput "  🔍 QDrant: http://localhost:6333" "White"
        
      Write-Host ""
      Write-ColorOutput "📋 Management Commands:" "Cyan"
      Write-ColorOutput "  .\scripts\Status-FullStack.ps1     - Check detailed status" "White"
      Write-ColorOutput "  .\scripts\Stop-FullStack.ps1       - Stop all services" "White"
      Write-ColorOutput "  .\scripts\phase2-advanced-monitoring.ps1 -Action status - Phase 2 status" "White"
        
   }
   catch {
      Write-Warning "Could not retrieve final status: $_"
   }
}

# ====== EXECUTION PRINCIPALE ======

Write-Header "🚀 Smart Email Sender - Full Stack Startup"

try {
   # Étape 1: Prérequis
   Test-Prerequisites
    
   # Étape 2: Services Docker
   Start-DockerServices
    
   # Étape 3: Build des composants
   Build-InfrastructureComponents
    
   # Étape 4: API Server
   $apiProcess = Start-InfrastructureApiServer
    
   # Étape 5: Monitoring avancé
   Start-AdvancedMonitoring
    
   # Étape 6: Auto-healing (optionnel)
   Enable-AutoHealing
    
   # Étape 7: Statut final
   Show-FinalStatus
    
   Write-Header "✅ STARTUP SUCCESSFUL!"
   Write-ColorOutput "🎯 Smart Email Sender infrastructure is now fully operational!" "Green"
   Write-ColorOutput "💡 Use VS Code extension or scripts for management" "Blue"
    
}
catch {
   Write-Header "❌ STARTUP FAILED!"
   Write-Error "Error during startup: $_"
   Write-ColorOutput "🔧 Try running individual components to diagnose the issue" "Yellow"
   exit 1
}
