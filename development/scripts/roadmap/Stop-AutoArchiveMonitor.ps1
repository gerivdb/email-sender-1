# Stop-AutoArchiveMonitor.ps1
# Script pour arrêter le moniteur d'archivage automatique
# Version: 1.0
# Date: 2025-05-03

[CmdletBinding()]
param ()

# Obtenir le chemin du fichier PID
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFilePath = Join-Path -Path $scriptPath -ChildPath "auto_archive_monitor.pid"

if (-not (Test-Path -Path $pidFilePath)) {
    Write-Error "Fichier PID introuvable: $pidFilePath. Le moniteur n'est peut-être pas en cours d'exécution."
    exit 1
}

# Lire l'ID du processus
$processId = Get-Content -Path $pidFilePath -ErrorAction SilentlyContinue

if (-not $processId) {
    Write-Error "Impossible de lire l'ID du processus depuis le fichier: $pidFilePath"
    exit 1
}

# Vérifier si le processus existe
$process = Get-Process -Id $processId -ErrorAction SilentlyContinue

if (-not $process) {
    Write-Warning "Le processus avec l'ID $processId n'existe pas ou a déjà été arrêté."
    Remove-Item -Path $pidFilePath -Force
    exit 0
}

# Arrêter le processus
try {
    Stop-Process -Id $processId -Force
    Write-Host "Moniteur d'archivage automatique (PID: $processId) arrêté avec succès."
    
    # Supprimer le fichier PID
    Remove-Item -Path $pidFilePath -Force
} catch {
    Write-Error "Erreur lors de l'arrêt du processus: $_"
    exit 1
}
