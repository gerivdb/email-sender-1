# Unregister-ArchiveTask.ps1
# Script pour supprimer la tÃ¢che planifiÃ©e d'archivage automatique
# Version: 1.0
# Date: 2025-05-03

[CmdletBinding()]
param ()

# Nom de la tÃ¢che planifiÃ©e
$taskName = "ArchiveRoadmapTasks"

# VÃ©rifier si la tÃ¢che existe
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if (-not $existingTask) {
    Write-Warning "La tÃ¢che planifiÃ©e '$taskName' n'existe pas."
    exit 0
}

# Supprimer la tÃ¢che
try {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "TÃ¢che planifiÃ©e '$taskName' supprimÃ©e avec succÃ¨s."
} catch {
    Write-Error "Erreur lors de la suppression de la tÃ¢che planifiÃ©e: $_"
    exit 1
}
