# Stop-FullStack.ps1
# Script PowerShell pour arrêter proprement toute la stack EMAIL_SENDER_1
# Partie de la Phase 3 : Intégration IDE et Expérience Développeur

param(
   [switch]$Force,
   [switch]$KeepData,
   [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Configuration
$PROJECT_ROOT = Split-Path -Parent $PSScriptRoot
$DOCKER_COMPOSE_FILE = Join-Path $PROJECT_ROOT "docker-compose.yml"
$GO_BINARIES = @(
   "cmd\smart-infrastructure\main.exe",
   "cmd\infrastructure-api-server\main.exe",
   "cmd\backup-qdrant\main.exe",
   "cmd\migrate-qdrant\main.exe"
)

function Write-StatusMessage {
   param([string]$Message, [string]$Type = "INFO")
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $color = switch ($Type) {
      "INFO" { "Cyan" }
      "SUCCESS" { "Green" }
      "WARNING" { "Yellow" }
      "ERROR" { "Red" }
      default { "White" }
   }
   Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $color
}

function Stop-DockerServices {
   Write-StatusMessage "Arrêt des services Docker..." "INFO"
    
   try {
      if (Test-Path $DOCKER_COMPOSE_FILE) {
         # Arrêt des conteneurs
         if ($Force) {
            Write-StatusMessage "Arrêt forcé des conteneurs Docker..." "WARNING"
            docker-compose -f $DOCKER_COMPOSE_FILE kill
         }
         else {
            Write-StatusMessage "Arrêt gracieux des conteneurs Docker..." "INFO"
            docker-compose -f $DOCKER_COMPOSE_FILE stop
         }
            
         # Suppression des conteneurs si demandé
         if (-not $KeepData) {
            Write-StatusMessage "Suppression des conteneurs..." "INFO"
            docker-compose -f $DOCKER_COMPOSE_FILE down
                
            if ($Force) {
               Write-StatusMessage "Suppression des volumes Docker..." "WARNING"
               docker-compose -f $DOCKER_COMPOSE_FILE down -v
            }
         }
            
         Write-StatusMessage "Services Docker arrêtés avec succès" "SUCCESS"
      }
      else {
         Write-StatusMessage "Fichier docker-compose.yml introuvable" "WARNING"
      }
   }
   catch {
      Write-StatusMessage "Erreur lors de l'arrêt des services Docker: $($_.Exception.Message)" "ERROR"
      if (-not $Force) {
         throw
      }
   }
}

function Stop-GoProcesses {
   Write-StatusMessage "Arrêt des processus Go..." "INFO"
    
   try {
      # Arrêt des processus Go par nom
      $goProcesses = Get-Process | Where-Object { 
         $_.ProcessName -like "*email*sender*" -or 
         $_.ProcessName -like "*smart*infrastructure*" -or
         $_.ProcessName -like "*qdrant*" -or
         $_.Path -like "*EMAIL_SENDER_1*"
      }
        
      if ($goProcesses) {
         foreach ($process in $goProcesses) {
            Write-StatusMessage "Arrêt du processus: $($process.ProcessName) (PID: $($process.Id))" "INFO"
                
            if ($Force) {
               $process.Kill()
            }
            else {
               $process.CloseMainWindow()
               Start-Sleep -Seconds 2
                    
               if (-not $process.HasExited) {
                  $process.Kill()
               }
            }
         }
         Write-StatusMessage "Processus Go arrêtés avec succès" "SUCCESS"
      }
      else {
         Write-StatusMessage "Aucun processus Go trouvé" "INFO"
      }
   }
   catch {
      Write-StatusMessage "Erreur lors de l'arrêt des processus Go: $($_.Exception.Message)" "ERROR"
      if (-not $Force) {
         throw
      }
   }
}

function Stop-NetworkServices {
   Write-StatusMessage "Vérification des ports utilisés..." "INFO"
    
   try {
      $ports = @(8080, 8081, 6333, 6334, 5432, 6379, 9090, 3000)
        
      foreach ($port in $ports) {
         $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
         if ($connection) {
            $processId = $connection.OwningProcess
            $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                
            if ($process) {
               Write-StatusMessage "Port $port utilisé par: $($process.ProcessName) (PID: $processId)" "INFO"
                    
               if ($Force) {
                  Write-StatusMessage "Arrêt forcé du processus sur le port $port" "WARNING"
                  Stop-Process -Id $processId -Force
               }
            }
         }
      }
   }
   catch {
      Write-StatusMessage "Erreur lors de la vérification des ports: $($_.Exception.Message)" "WARNING"
   }
}

function Cleanup-TempFiles {
   Write-StatusMessage "Nettoyage des fichiers temporaires..." "INFO"
    
   try {
      # Nettoyage des logs temporaires
      $tempPaths = @(
         Join-Path $PROJECT_ROOT "*.log",
         Join-Path $PROJECT_ROOT "logs\*.tmp",
         Join-Path $PROJECT_ROOT "tmp\*"
      )
        
      foreach ($path in $tempPaths) {
         if (Test-Path $path) {
            Remove-Item $path -Force -Recurse -ErrorAction SilentlyContinue
         }
      }
        
      Write-StatusMessage "Nettoyage terminé" "SUCCESS"
   }
   catch {
      Write-StatusMessage "Erreur lors du nettoyage: $($_.Exception.Message)" "WARNING"
   }
}

function Show-StopSummary {
   Write-StatusMessage "=== RÉSUMÉ DE L'ARRÊT ===" "INFO"
   Write-StatusMessage "Branche Git: $(git branch --show-current)" "INFO"
   Write-StatusMessage "Projet: EMAIL_SENDER_1" "INFO"
   Write-StatusMessage "Mode: $(if ($Force) { 'Forcé' } else { 'Gracieux' })" "INFO"
   Write-StatusMessage "Conservation des données: $(if ($KeepData) { 'Oui' } else { 'Non' })" "INFO"
   Write-StatusMessage "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"
   Write-StatusMessage "================================" "INFO"
}

# Script principal
try {
   Write-StatusMessage "DÉBUT DE L'ARRÊT DE LA STACK EMAIL_SENDER_1" "INFO"
    
   # Vérification du répertoire de travail
   Set-Location $PROJECT_ROOT
    
   # Arrêt des différents composants
   Stop-GoProcesses
   Stop-DockerServices
   Stop-NetworkServices
    
   # Nettoyage optionnel
   if (-not $KeepData) {
      Cleanup-TempFiles
   }
    
   # Résumé final
   Show-StopSummary
    
   Write-StatusMessage "STACK ARRÊTÉE AVEC SUCCÈS" "SUCCESS"
    
}
catch {
   Write-StatusMessage "ERREUR LORS DE L'ARRÊT: $($_.Exception.Message)" "ERROR"
   Write-StatusMessage "Utilisez -Force pour un arrêt forcé" "WARNING"
   exit 1
}
