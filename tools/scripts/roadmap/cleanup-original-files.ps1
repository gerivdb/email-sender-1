<#
.SYNOPSIS
    Supprime les fichiers originaux après la réorganisation.

.DESCRIPTION
    Ce script supprime les fichiers originaux qui ont été copiés vers la nouvelle structure
    de dossiers lors de la réorganisation.

.NOTES
    Auteur: RoadmapTools Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Liste des fichiers à supprimer
$filesToRemove = @(
    "Add-RoadmapJournalEntry.ps1",
    "Analyze-RoadmapJournal.ps1",
    "analyze-roadmapper.cmd",
    "Archive-CompletedTasks.ps1",
    "Clean-ArchiveSections.ps1",
    "Convert-Roadmap.ps1",
    "Export-RoadmapToJSON.ps1",
    "fix_encoding_simple.py",
    "fix_encoding.py",
    "Fix-RoadmapEncoding.ps1",
    "Generate-RoadmapJournalReport.ps1",
    "Import-ExistingRoadmapToJournal.ps1",
    "Move-CompletedTasks.ps1",
    "New-RoadmapTask.ps1",
    "Register-RoadmapJournalWatcher.ps1",
    "Restore-RoadmapStructure.ps1",
    "RoadmapConverter.psm1",
    "Send-RoadmapJournalNotification.ps1",
    "Show-RoadmapJournalDashboard.ps1",
    "Sync-RoadmapWithJournal.ps1",
    "Test-RoadmapConverter.ps1",
    "Update-RoadmapJournalStatus.ps1",
    "Update-RoadmapProgress.ps1"
)

# Fonction pour supprimer un fichier
function Remove-FileIfExists {
    param (
        [string]$FilePath
    )
    
    if (Test-Path -Path $FilePath) {
        try {
            Remove-Item -Path $FilePath -Force
            Write-Host "Fichier supprimé : $FilePath" -ForegroundColor Green
        }
        catch {
            Write-Error "Erreur lors de la suppression du fichier $FilePath : $_"
        }
    }
    else {
        Write-Warning "Le fichier n'existe pas : $FilePath"
    }
}

# Demander confirmation avant de supprimer les fichiers
Write-Host "Cette opération va supprimer les fichiers originaux suivants :" -ForegroundColor Yellow
foreach ($file in $filesToRemove) {
    Write-Host "  - $file"
}

$confirmation = Read-Host "Êtes-vous sûr de vouloir supprimer ces fichiers ? (O/N)"

if ($confirmation -eq "O" -or $confirmation -eq "o") {
    # Supprimer les fichiers
    foreach ($file in $filesToRemove) {
        $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
        Remove-FileIfExists -FilePath $filePath
    }
    
    Write-Host "Nettoyage terminé. Les fichiers originaux ont été supprimés." -ForegroundColor Green
}
else {
    Write-Host "Opération annulée. Aucun fichier n'a été supprimé." -ForegroundColor Yellow
}
