<#
.SYNOPSIS
    Réorganise les scripts de roadmap dans la nouvelle structure de dossiers.

.DESCRIPTION
    Ce script déplace les fichiers existants dans le dossier scripts/roadmap vers la nouvelle structure
    de dossiers organisée par catégories et sous-catégories.

.NOTES
    Auteur: RoadmapTools Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Définir les mappages de fichiers vers les nouveaux emplacements
$fileMappings = @{
    # Core - Conversion
    "Convert-Roadmap.ps1" = "core/conversion/Convert-Roadmap.ps1"
    "RoadmapConverter.psm1" = "core/conversion/RoadmapConverter.psm1"
    
    # Core - Structure
    "Restore-RoadmapStructure.ps1" = "core/structure/Restore-RoadmapStructure.ps1"
    "Clean-ArchiveSections.ps1" = "core/structure/Clean-ArchiveSections.ps1"
    
    # Core - Validation
    "Test-RoadmapConverter.ps1" = "core/validation/Test-RoadmapConverter.ps1"
    
    # Journal - Entries
    "Add-RoadmapJournalEntry.ps1" = "journal/entries/Add-RoadmapJournalEntry.ps1"
    "Import-ExistingRoadmapToJournal.ps1" = "journal/entries/Import-ExistingRoadmapToJournal.ps1"
    "Update-RoadmapJournalStatus.ps1" = "journal/entries/Update-RoadmapJournalStatus.ps1"
    
    # Journal - Notifications
    "Send-RoadmapJournalNotification.ps1" = "journal/notifications/Send-RoadmapJournalNotification.ps1"
    "Register-RoadmapJournalWatcher.ps1" = "journal/notifications/Register-RoadmapJournalWatcher.ps1"
    
    # Journal - Reports
    "Analyze-RoadmapJournal.ps1" = "journal/reports/Analyze-RoadmapJournal.ps1"
    "Generate-RoadmapJournalReport.ps1" = "journal/reports/Generate-RoadmapJournalReport.ps1"
    "Show-RoadmapJournalDashboard.ps1" = "journal/reports/Show-RoadmapJournalDashboard.ps1"
    
    # Management - Archive
    "Archive-CompletedTasks.ps1" = "management/archive/Archive-CompletedTasks.ps1"
    "Move-CompletedTasks.ps1" = "management/archive/Move-CompletedTasks.ps1"
    
    # Management - Creation
    "New-RoadmapTask.ps1" = "management/creation/New-RoadmapTask.ps1"
    
    # Management - Progress
    "Update-RoadmapProgress.ps1" = "management/progress/Update-RoadmapProgress.ps1"
    "Sync-RoadmapWithJournal.ps1" = "management/progress/Sync-RoadmapWithJournal.ps1"
    
    # Utils - Encoding
    "Fix-RoadmapEncoding.ps1" = "utils/encoding/Fix-RoadmapEncoding.ps1"
    "fix_encoding.py" = "utils/encoding/fix_encoding.py"
    "fix_encoding_simple.py" = "utils/encoding/fix_encoding_simple.py"
    
    # Utils - Export
    "Export-RoadmapToJSON.ps1" = "utils/export/Export-RoadmapToJSON.ps1"
}

# Fonction pour déplacer un fichier
function Move-FileToNewLocation {
    param (
        [string]$SourceFile,
        [string]$DestinationPath
    )
    
    $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath $SourceFile
    $destinationPath = Join-Path -Path $PSScriptRoot -ChildPath $DestinationPath
    
    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $sourcePath)) {
        Write-Warning "Le fichier source n'existe pas : $sourcePath"
        return
    }
    
    # Créer le dossier de destination s'il n'existe pas
    $destinationDir = Split-Path -Path $destinationPath -Parent
    if (-not (Test-Path -Path $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
        Write-Host "Dossier créé : $destinationDir"
    }
    
    # Déplacer le fichier
    try {
        Copy-Item -Path $sourcePath -Destination $destinationPath -Force
        Write-Host "Fichier copié : $SourceFile -> $DestinationPath"
    }
    catch {
        Write-Error "Erreur lors de la copie du fichier $SourceFile : $_"
    }
}

# Déplacer les fichiers
foreach ($file in $fileMappings.Keys) {
    Move-FileToNewLocation -SourceFile $file -DestinationPath $fileMappings[$file]
}

Write-Host "Réorganisation terminée. Les fichiers ont été copiés vers leurs nouveaux emplacements."
Write-Host "Vous pouvez maintenant vérifier que tout fonctionne correctement avant de supprimer les fichiers originaux."
