# Stop-AutoArchiveMonitor.ps1
# Script pour arrÃªter le moniteur d'archivage automatique
# Version: 1.0
# Date: 2025-05-03

[CmdletBinding()]
param ()

# Obtenir le chemin du fichier PID
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFilePath = Join-Path -Path $scriptPath -ChildPath "auto_archive_monitor.pid"

if (-not (Test-Path -Path $pidFilePath)) {
    Write-Error "Fichier PID introuvable: $pidFilePath. Le moniteur n'est peut-Ãªtre pas en cours d'exÃ©cution."
    exit 1
}

# Lire l'ID du processus
$processId = Get-Content -Path $pidFilePath -ErrorAction SilentlyContinue

if (-not $processId) {
    Write-Error "Impossible de lire l'ID du processus depuis le fichier: $pidFilePath"
    exit 1
}

# VÃ©rifier si le processus existe
$process = Get-Process -Id $processId -ErrorAction SilentlyContinue

if (-not $process) {
    Write-Warning "Le processus avec l'ID $processId n'existe pas ou a dÃ©jÃ  Ã©tÃ© arrÃªtÃ©."
    Remove-Item -Path $pidFilePath -Force
    exit 0
}

# ArrÃªter le processus
try {
    Stop-Process -Id $processId -Force
    Write-Host "Moniteur d'archivage automatique (PID: $processId) arrÃªtÃ© avec succÃ¨s."
    
    # Supprimer le fichier PID
    Remove-Item -Path $pidFilePath -Force
} catch {
    Write-Error "Erreur lors de l'arrÃªt du processus: $_"
    exit 1
}
