# Cleanup-OldArchiveScripts.ps1
# Script pour nettoyer les anciens scripts d'archivage automatique
# Version: 1.0
# Date: 2025-05-03

[CmdletBinding()]
param ()

# Obtenir le chemin du script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# ArrÃªter tous les processus PowerShell qui exÃ©cutent les anciens scripts d'archivage
$processes = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*Start-AutoArchiveMonitor.ps1*"
}

if ($processes) {
    Write-Host "ArrÃªt des processus d'archivage automatique en cours d'exÃ©cution..."
    foreach ($process in $processes) {
        try {
            Stop-Process -Id $process.Id -Force
            Write-Host "Processus arrÃªtÃ©: $($process.Id)"
        } catch {
            Write-Warning "Erreur lors de l'arrÃªt du processus $($process.Id): $_"
        }
    }
} else {
    Write-Host "Aucun processus d'archivage automatique en cours d'exÃ©cution."
}

# Supprimer le fichier PID s'il existe
$pidFilePath = Join-Path -Path $scriptPath -ChildPath "auto_archive_monitor.pid"
if (Test-Path -Path $pidFilePath) {
    try {
        Remove-Item -Path $pidFilePath -Force
        Write-Host "Fichier PID supprimÃ©: $pidFilePath"
    } catch {
        Write-Warning "Erreur lors de la suppression du fichier PID: $_"
    }
} else {
    Write-Host "Aucun fichier PID trouvÃ©."
}

Write-Host "Nettoyage terminÃ©."
