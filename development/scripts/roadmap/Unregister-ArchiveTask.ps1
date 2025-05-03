# Unregister-ArchiveTask.ps1
# Script pour supprimer la tâche planifiée d'archivage automatique
# Version: 1.0
# Date: 2025-05-03

[CmdletBinding()]
param ()

# Nom de la tâche planifiée
$taskName = "ArchiveRoadmapTasks"

# Vérifier si la tâche existe
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if (-not $existingTask) {
    Write-Warning "La tâche planifiée '$taskName' n'existe pas."
    exit 0
}

# Supprimer la tâche
try {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Tâche planifiée '$taskName' supprimée avec succès."
} catch {
    Write-Error "Erreur lors de la suppression de la tâche planifiée: $_"
    exit 1
}
