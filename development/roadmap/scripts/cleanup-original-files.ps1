<#
.SYNOPSIS
    Supprime les fichiers originaux aprÃ¨s la rÃ©organisation.

.DESCRIPTION
    Ce script supprime les fichiers originaux qui ont Ã©tÃ© copiÃ©s vers la nouvelle structure
    de dossiers lors de la rÃ©organisation.

.NOTES
    Auteur: RoadmapTools Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Liste des fichiers Ã  supprimer
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
            Write-Host "Fichier supprimÃ© : $FilePath" -ForegroundColor Green
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
Write-Host "Cette opÃ©ration va supprimer les fichiers originaux suivants :" -ForegroundColor Yellow
foreach ($file in $filesToRemove) {
    Write-Host "  - $file"
}

$confirmation = Read-Host "ÃŠtes-vous sÃ»r de vouloir supprimer ces fichiers ? (O/N)"

if ($confirmation -eq "O" -or $confirmation -eq "o") {
    # Supprimer les fichiers
    foreach ($file in $filesToRemove) {
        $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
        Remove-FileIfExists -FilePath $filePath
    }
    
    Write-Host "Nettoyage terminÃ©. Les fichiers originaux ont Ã©tÃ© supprimÃ©s." -ForegroundColor Green
}
else {
    Write-Host "OpÃ©ration annulÃ©e. Aucun fichier n'a Ã©tÃ© supprimÃ©." -ForegroundColor Yellow
}
