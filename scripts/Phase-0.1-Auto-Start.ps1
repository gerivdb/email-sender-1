#!/usr/bin/env pwsh
# Phase-0.1-Auto-Start.ps1 - Démarrage automatique Phase 0.1
# Lance toute l'infrastructure de diagnostic et réparation

param(
   [switch]$StartMonitor = $false,
   [switch]$EnableAutoRepair = $false,
   [switch]$SkipHealthCheck = $false,
   [int]$MonitorRefreshSeconds = 30
)

Write-Host "🚀 Phase 0.1 Auto-Start - Diagnostic et Réparation Infrastructure" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR

# Fonction pour vérifier et créer les répertoires nécessaires
function Initialize-ProjectStructure {
   Write-Host "`n📁 Initializing project structure..." -ForegroundColor Yellow
    
   $requiredDirs = @(
      "$PROJECT_ROOT\src\managers\infrastructure",
      "$PROJECT_ROOT\scripts",
      "$PROJECT_ROOT\logs"
   )
    
   foreach ($dir in $requiredDirs) {
      if (-not (Test-Path $dir)) {
         New-Item -ItemType Directory -Path $dir -Force | Out-Null
         Write-Host "   Created directory: $dir" -ForegroundColor Green
      }
      else {
         Write-Host "   Directory exists: $dir" -ForegroundColor Green
      }
   }
}

# Fonction pour vérifier les dépendances
function Test-Dependencies {
   Write-Host "`n🔍 Checking dependencies..." -ForegroundColor Yellow
    
   $dependencies = @(
      @{Name = "PowerShell"; Command = "pwsh"; Version = "Get-Host | Select-Object Version" },
      @{Name = "Git"; Command = "git"; Version = "git --version" },
      @{Name = "Node.js"; Command = "node"; Version = "node --version" },
      @{Name = "Docker"; Command = "docker"; Version = "docker --version" }
   )
    
   $allOK = $true
   foreach ($dep in $dependencies) {
      try {
         $null = Get-Command $dep.Command -ErrorAction Stop
         $version = Invoke-Expression $dep.Version 2>$null
         Write-Host "   ✅ $($dep.Name) - Available" -ForegroundColor Green
      }
      catch {
         Write-Host "   ❌ $($dep.Name) - Missing" -ForegroundColor Red
         $allOK = $false
      }
   }
    
   return $allOK
}

# Fonction pour exécuter le diagnostic initial
function Start-InitialDiagnostic {
   Write-Host "`n🩺 Running initial infrastructure diagnostic..." -ForegroundColor Yellow
    
   try {
      $diagnosticScript = "$SCRIPT_DIR\Phase-0.1-Integration-Test.ps1"
      if (Test-Path $diagnosticScript) {
         Write-Host "   Executing comprehensive diagnostic..." -ForegroundColor White
            
         $result = & $diagnosticScript
         $exitCode = $LASTEXITCODE
            
         if ($exitCode -eq 0) {
            Write-Host "   ✅ Initial diagnostic: PASSED" -ForegroundColor Green
            return $true
         }
         else {
            Write-Host "   ⚠️ Initial diagnostic: ISSUES FOUND" -ForegroundColor Yellow
            return $false
         }
      }
      else {
         Write-Host "   ❌ Diagnostic script not found: $diagnosticScript" -ForegroundColor Red
         return $false
      }
   }
   catch {
      Write-Host "   ❌ Error during diagnostic: $($_.Exception.Message)" -ForegroundColor Red
      return $false
   }
}

# Fonction pour démarrer les services de base
function Start-BaseServices {
   Write-Host "`n⚙️ Starting base services..." -ForegroundColor Yellow
    
   # Vérifier si l'API Server est déjà en cours d'exécution
   $apiProcess = Get-Process | Where-Object { $_.ProcessName -match "api-server" }
   if (-not $apiProcess) {
      Write-Host "   Starting API Server..." -ForegroundColor White
      try {
         $apiServerPath = "$PROJECT_ROOT\cmd\simple-api-server-fixed\api-server-fixed.exe"
         if (Test-Path $apiServerPath) {
            Start-Process -FilePath $apiServerPath -WindowStyle Hidden
            Start-Sleep -Seconds 3
                
            $newApiProcess = Get-Process | Where-Object { $_.ProcessName -match "api-server" }
            if ($newApiProcess) {
               Write-Host "   ✅ API Server started successfully (PID: $($newApiProcess.Id))" -ForegroundColor Green
            }
            else {
               Write-Host "   ❌ Failed to start API Server" -ForegroundColor Red
            }
         }
         else {
            Write-Host "   ⚠️ API Server executable not found: $apiServerPath" -ForegroundColor Yellow
         }
      }
      catch {
         Write-Host "   ❌ Error starting API Server: $($_.Exception.Message)" -ForegroundColor Red
      }
   }
   else {
      Write-Host "   ✅ API Server already running (PID: $($apiProcess.Id))" -ForegroundColor Green
   }
}

# Fonction pour appliquer les optimisations mémoire
function Apply-MemoryOptimizations {
   Write-Host "`n🧠 Applying memory optimizations..." -ForegroundColor Yellow
    
   try {
      # Vérifier si le gestionnaire mémoire est déjà actif
      $memoryManager = Get-Process | Where-Object { $_.CommandLine -match "Smart-Memory-Manager" }
        
      if (-not $memoryManager) {
         $memoryScript = "$PROJECT_ROOT\Smart-Memory-Manager.ps1"
         if (Test-Path $memoryScript) {
            Write-Host "   Starting Smart Memory Manager..." -ForegroundColor White
            Start-Process -FilePath "pwsh" -ArgumentList "-File", $memoryScript -WindowStyle Hidden
            Write-Host "   ✅ Memory Manager started" -ForegroundColor Green
         }
         else {
            Write-Host "   ⚠️ Memory Manager script not found" -ForegroundColor Yellow
         }
      }
      else {
         Write-Host "   ✅ Memory Manager already active" -ForegroundColor Green
      }
        
      # Nettoyage mémoire immédiat        Write-Host "   Performing immediate memory cleanup..." -ForegroundColor White
      [System.GC]::Collect()
      [System.GC]::WaitForPendingFinalizers()
      [System.GC]::Collect()
      Write-Host "   ✅ Memory cleanup completed" -ForegroundColor Green
        
   }
   catch {
      Write-Host "   ❌ Error applying memory optimizations: $($_.Exception.Message)" -ForegroundColor Red
   }
}

# Fonction pour démarrer le monitoring temps réel
function Start-RealTimeMonitor {
   Write-Host "`n📊 Starting real-time infrastructure monitor..." -ForegroundColor Yellow
    
   try {
      $monitorScript = "$SCRIPT_DIR\Infrastructure-Real-Time-Monitor.ps1"
      if (Test-Path $monitorScript) {
         $args = @("-RefreshIntervalSeconds", $MonitorRefreshSeconds)
         if ($EnableAutoRepair) {
            $args += "-EnableAutoRepair"
         }
            
         Write-Host "   Monitor parameters:" -ForegroundColor Info            Write-Host "     - Refresh interval: $MonitorRefreshSeconds seconds" -ForegroundColor White
         Write-Host "     - Auto-repair: $EnableAutoRepair" -ForegroundColor White
         Write-Host ""
         Write-Host "   🔄 Starting monitor (use Ctrl+C to stop)..." -ForegroundColor Green
            
         & $monitorScript @args
      }
      else {
         Write-Host "   ❌ Monitor script not found: $monitorScript" -ForegroundColor Red
      }
   }
   catch {
      Write-Host "   ❌ Error starting monitor: $($_.Exception.Message)" -ForegroundColor Red
   }
}

# Fonction pour afficher le résumé de démarrage
function Show-StartupSummary {
   Write-Host "`n=================================================================" -ForegroundColor Cyan
   Write-Host "🏁 PHASE 0.1 STARTUP SUMMARY" -ForegroundColor Cyan
   Write-Host "=================================================================" -ForegroundColor Cyan
    
   # État de l'API Server
   $apiProcess = Get-Process | Where-Object { $_.ProcessName -match "api-server" }
   if ($apiProcess) {
      Write-Host "✅ API Server: RUNNING (PID: $($apiProcess.Id))" -ForegroundColor Green
   }
   else {
      Write-Host "❌ API Server: NOT RUNNING" -ForegroundColor Red
   }
    
   # État mémoire
   $memory = Get-CimInstance -ClassName Win32_OperatingSystem
   $usedRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
   $memoryColor = if ($usedRAM -le 20) { "Green" } elseif ($usedRAM -le 24) { "Yellow" } else { "Red" }
   Write-Host "🧠 Memory Usage: $usedRAM GB" -ForegroundColor $memoryColor
    
   # Services disponibles
   Write-Host "`n📋 Available Services:" -ForegroundColor Cyan    Write-Host "   • Infrastructure Health Check: http://localhost:8080/health" -ForegroundColor White
   Write-Host "   • Emergency Repair: scripts\Emergency-Repair-Fixed.ps1" -ForegroundColor White
   Write-Host "   • Memory Management: Smart-Memory-Manager.ps1" -ForegroundColor White
    
   if ($StartMonitor) {
      Write-Host "`n   • Real-time Monitor: STARTING..." -ForegroundColor Green
   }
   else {
      Write-Host "`n   • Real-time Monitor: Use -StartMonitor to enable" -ForegroundColor Info
   }
    
   Write-Host "`n🎯 Phase 0.1 Infrastructure Ready!" -ForegroundColor Green
   Write-Host "=================================================================" -ForegroundColor Cyan
}

# EXECUTION PRINCIPALE
$startTime = Get-Date

try {
   # Étape 1: Initialisation
   Initialize-ProjectStructure
    
   # Étape 2: Vérification des dépendances
   $dependenciesOK = Test-Dependencies
   if (-not $dependenciesOK) {
      Write-Host "`n⚠️ Some dependencies are missing. Continuing anyway..." -ForegroundColor Yellow
   }
    
   # Étape 3: Diagnostic initial (optionnel)
   if (-not $SkipHealthCheck) {
      $diagnosticOK = Start-InitialDiagnostic
      if (-not $diagnosticOK) {
         Write-Host "`n⚠️ Initial diagnostic found issues. Running emergency repair..." -ForegroundColor Yellow
         $repairScript = "$SCRIPT_DIR\Emergency-Repair-Fixed.ps1"
         if (Test-Path $repairScript) {
            & $repairScript
         }
      }
   }
    
   # Étape 4: Démarrage des services de base
   Start-BaseServices
    
   # Étape 5: Application des optimisations mémoire
   Apply-MemoryOptimizations
    
   # Étape 6: Résumé
   Show-StartupSummary
    
   # Étape 7: Démarrage du monitoring (optionnel)
   if ($StartMonitor) {
      Write-Host "`nPress Enter to start monitoring or Ctrl+C to exit..."
      Read-Host
      Start-RealTimeMonitor
   }
    
   $endTime = Get-Date
   $duration = $endTime - $startTime
   Write-Host "`n✅ Phase 0.1 startup completed in $([math]::Round($duration.TotalSeconds, 1)) seconds" -ForegroundColor Green
    
}
catch {
   Write-Host "`n❌ CRITICAL ERROR during Phase 0.1 startup:" -ForegroundColor Red
   Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
   exit 1
}

if (-not $StartMonitor) {
   Write-Host "`nPhase 0.1 infrastructure is now ready for use!" -ForegroundColor Green    Write-Host "Use -StartMonitor parameter to enable real-time monitoring." -ForegroundColor White
}
