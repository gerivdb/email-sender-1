# build-and-run-dashboard.ps1
# Script PowerShell pour compiler et lancer le dashboard de synchronisation

param(
   [string]$Port = "8080",
   [string]$HostAddress = "localhost",
   [int]$CleanupDays = 30,
   [switch]$Debug = $false
)

# Configuration
$ProjectRoot = $PSScriptRoot
$BuildDir = Join-Path $ProjectRoot "build"
$DashboardBinary = Join-Path $BuildDir "dashboard.exe"
$LogDir = Join-Path $ProjectRoot "logs"
$DbPath = Join-Path $LogDir "sync_logs.db"

# Fonctions d'affichage coloré
function Write-Status {
   param([string]$Message)
   Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
   param([string]$Message)
   Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
   param([string]$Message)
   Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
   param([string]$Message)
   Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Fonction de nettoyage
function Stop-Dashboard {
   if ($global:DashboardProcess -and !$global:DashboardProcess.HasExited) {
      Write-Status "Arrêt du dashboard (PID: $($global:DashboardProcess.Id))..."
      try {
         $global:DashboardProcess.Kill()
         $global:DashboardProcess.WaitForExit(5000)
         Write-Success "Dashboard arrêté proprement"
      }
      catch {
         Write-Warning "Impossible d'arrêter le processus proprement: $_"
      }
   }
}

# Gestionnaire d'événements pour nettoyage
Register-ObjectEvent -InputObject ([System.Console]) -EventName CancelKeyPress -Action {
   Stop-Dashboard
   exit 0
}

try {
   Write-Host "🎯 Phase 6.1.1 - Build et lancement du Dashboard de Synchronisation" -ForegroundColor Magenta
   Write-Host "================================================================" -ForegroundColor Magenta
   Write-Host ""

   # Étape 1: Vérification de l'environnement
   Write-Status "Vérification de l'environnement Go..."
    
   try {
      $goVersion = go version
      Write-Success "Go détecté: $goVersion"
   }
   catch {
      Write-Error "Go n'est pas installé ou pas dans le PATH"
      exit 1
   }

   # Étape 2: Création des répertoires
   Write-Status "Création des répertoires nécessaires..."
    
   $directories = @(
      $BuildDir,
      $LogDir,
        (Join-Path $ProjectRoot "web\static\css"),
        (Join-Path $ProjectRoot "web\static\js"),
        (Join-Path $ProjectRoot "web\templates")
   )

   foreach ($dir in $directories) {
      if (!(Test-Path $dir)) {
         New-Item -ItemType Directory -Path $dir -Force | Out-Null
      }
   }

   # Étape 3: Vérification des fichiers requis
   Write-Status "Vérification des fichiers du projet..."
    
   $requiredFiles = @(
      "web\dashboard\sync_dashboard.go",
      "web\templates\dashboard.html",
      "web\static\js\conflict-resolution.js",
      "web\static\css\dashboard.css",
      "tools\sync-logger.go",
      "cmd\dashboard\main.go"
   )

   $missingFiles = @()
   foreach ($file in $requiredFiles) {
      $fullPath = Join-Path $ProjectRoot $file
      if (!(Test-Path $fullPath)) {
         $missingFiles += $file
      }
   }

   if ($missingFiles.Count -gt 0) {
      Write-Error "Fichiers manquants:"
      foreach ($file in $missingFiles) {
         Write-Host "  - $file" -ForegroundColor Red
      }
      exit 1
   }

   Write-Success "Tous les fichiers requis sont présents"

   # Étape 4: Installation des dépendances
   Write-Status "Gestion des dépendances Go..."
    
   Push-Location $ProjectRoot
    
   if (!(Test-Path "go.mod")) {
      Write-Status "Initialisation du module Go..."
      go mod init sync-dashboard
   }

   Write-Status "Mise à jour des dépendances..."
   go mod tidy
   go mod download

   Write-Success "Dépendances installées"

   # Étape 5: Compilation
   Write-Status "Compilation du dashboard..."
    
   $env:CGO_ENABLED = "1"  # Requis pour SQLite
   $buildArgs = @(
      "build",
      "-v",
      "-ldflags",
      "-s -w",
      "-o", $DashboardBinary,
      "./cmd/dashboard"
   )

   $buildProcess = Start-Process -FilePath "go" -ArgumentList $buildArgs -Wait -PassThru -NoNewWindow

   if ($buildProcess.ExitCode -eq 0) {
      Write-Success "Compilation réussie: $DashboardBinary"
        
      if (Test-Path $DashboardBinary) {
         $binarySize = [math]::Round((Get-Item $DashboardBinary).Length / 1MB, 2)
         Write-Success "Binaire créé: $binarySize MB"
      }
   }
   else {
      Write-Error "Échec de la compilation (code: $($buildProcess.ExitCode))"
      exit 1
   }

   # Étape 6: Configuration de lancement
   Write-Status "Préparation du lancement..."
   Write-Host "Configuration:" -ForegroundColor Cyan
   Write-Host "  - Port: $Port" -ForegroundColor White
   Write-Host "  - Host: $HostAddress" -ForegroundColor White
   Write-Host "  - Base de données: $DbPath" -ForegroundColor White
   Write-Host "  - Logs: $LogDir" -ForegroundColor White
   Write-Host "  - Rétention: $CleanupDays jours" -ForegroundColor White
   Write-Host "  - Debug: $Debug" -ForegroundColor White
   Write-Host ""

   # Étape 7: Lancement du dashboard
   Write-Status "Lancement du dashboard..."
   $dashboardArgs = @(
      "-port", $Port,
      "-host", $HostAddress,
      "-db", $DbPath,
      "-log", (Join-Path $LogDir "dashboard.log"),
      "-cleanup-days", $CleanupDays
   )

   if ($Debug) {
      $dashboardArgs += "-debug"
   }

   $global:DashboardProcess = Start-Process -FilePath $DashboardBinary -ArgumentList $dashboardArgs -PassThru

   # Attente du démarrage
   Start-Sleep -Seconds 3

   if (!$global:DashboardProcess.HasExited) {
      Write-Success "Dashboard démarré avec succès (PID: $($global:DashboardProcess.Id))"
      Write-Host ""        Write-Host "🌐 Accès au dashboard:" -ForegroundColor Green
      Write-Host "   http://$HostAddress`:$Port" -ForegroundColor Yellow
      Write-Host ""
      Write-Host "📊 API Endpoints:" -ForegroundColor Green
      Write-Host "   - Status: http://$HostAddress`:$Port/api/sync/status" -ForegroundColor Yellow
      Write-Host "   - Conflits: http://$HostAddress`:$Port/api/sync/conflicts" -ForegroundColor Yellow
      Write-Host "   - Health: http://$HostAddress`:$Port/health" -ForegroundColor Yellow
      Write-Host ""
      Write-Host "📝 Logs en temps réel:" -ForegroundColor Green
      Write-Host "   Get-Content `"$(Join-Path $LogDir "dashboard.log")`" -Wait" -ForegroundColor Yellow
      Write-Host ""
      Write-Warning "Appuyez sur Ctrl+C pour arrêter le dashboard"
      # Ouverture automatique du navigateur
      try {
         Start-Process "http://$HostAddress`:$Port"
         Write-Success "Navigateur ouvert automatiquement"
      }
      catch {
         Write-Warning "Impossible d'ouvrir le navigateur automatiquement"
      }
        
      # Attente jusqu'à arrêt manuel
      while (!$global:DashboardProcess.HasExited) {
         Start-Sleep -Seconds 1
      }
        
      Write-Success "Dashboard arrêté"
   }
   else {
      Write-Error "Échec du démarrage du dashboard"
      exit 1
   }
}
catch {
   Write-Error "Erreur inattendue: $_"
   exit 1
}
finally {
   Pop-Location
   Stop-Dashboard
}

# Affichage d'aide si demandé
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "-h") {
   Write-Host ""
   Write-Host "Usage: .\build-and-run-dashboard.ps1 [options]" -ForegroundColor Green
   Write-Host ""
   Write-Host "Options:" -ForegroundColor Yellow
   Write-Host "  -Port <number>        Port du serveur (défaut: 8080)" -ForegroundColor White    Write-Host "  -HostAddress <string> Adresse d'écoute (défaut: localhost)" -ForegroundColor White
   Write-Host "  -CleanupDays <number> Rétention des logs en jours (défaut: 30)" -ForegroundColor White
   Write-Host "  -Debug                Active le mode debug" -ForegroundColor White
   Write-Host ""
   Write-Host "Exemples:" -ForegroundColor Yellow
   Write-Host "  .\build-and-run-dashboard.ps1" -ForegroundColor White
   Write-Host "  .\build-and-run-dashboard.ps1 -Port 9090 -Debug" -ForegroundColor White
   Write-Host "  .\build-and-run-dashboard.ps1 -HostAddress 0.0.0.0 -CleanupDays 7" -ForegroundColor White
   Write-Host ""
}
