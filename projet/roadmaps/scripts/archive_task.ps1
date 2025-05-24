# Script d'archivage des tâches terminées
# Usage: .\archive_task.ps1 -TaskId "5.1.2" -TaskName "Implémentation des modèles prédictifs"

param (
    [Parameter(Mandatory=$true)]
    [string]$TaskId,
    
    [Parameter(Mandatory=$true)]
    [string]$TaskName,
    
    [Parameter(Mandatory=$false)]
    [string]$RoadmapFile = "..\roadmap_complete_converted.md",
    
    [Parameter(Mandatory=$false)]
    [string]$ArchiveFile = "..\archive\roadmap_archive.md"
)

# Fonction pour obtenir la date actuelle au format YYYY-MM-DD
function Get-CurrentDate {
    return Get-Date -Format "yyyy-MM-dd"
}

# Fonction pour extraire le contenu d'une tâche du fichier roadmap
function Export-TaskContent {
    param (
        [string]$RoadmapContent,
        [string]$TaskId
    )
    
    # Recherche le début de la section de la tâche
    $pattern = "#### $TaskId .*?(?=####|\Z)"
    $match = [regex]::Match($RoadmapContent, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    if ($match.Success) {
        return $match.Value.Trim()
    }
    else {
        Write-Error "Tâche $TaskId non trouvée dans le fichier roadmap."
        exit 1
    }
}

# Fonction pour mettre à jour le fichier roadmap
function Update-RoadmapFile {
    param (
        [string]$RoadmapContent,
        [string]$TaskId,
        [string]$TaskName
    )
    
    # Recherche la section de la tâche
    $pattern = "#### $TaskId .*?(?=####|\Z)"
    
    # Remplace la section par une version simplifiée
    $replacement = @"
#### $TaskId $TaskName
**Progression**: 100% - *Terminé*
**Note**: Cette tâche a été archivée. Voir [Archive des tâches](archive/roadmap_archive.md) pour les détails.

"@
    
    $updatedContent = [regex]::Replace($RoadmapContent, $pattern, $replacement, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    return $updatedContent
}

# Fonction pour mettre à jour le fichier d'archive
function Update-ArchiveFile {
    param (
        [string]$ArchiveContent,
        [string]$TaskContent,
        [string]$TaskId,
        [string]$TaskName
    )
    
    # Recherche la section appropriée dans le fichier d'archive
    $sectionId = $TaskId.Split('.')[0]
    $sectionPattern = "## $sectionId\. .*?(?=##|\Z)"
    $sectionMatch = [regex]::Match($ArchiveContent, $sectionPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    if ($sectionMatch.Success) {
        # La section existe déjà, ajoute la tâche à la fin de la section
        $sectionContent = $sectionMatch.Value
        $updatedSectionContent = $sectionContent.TrimEnd() + "`n`n" + $TaskContent.Replace($TaskName, "$TaskName (ARCHIVÉ)") + "`n`n**Archived Date**: " + (Get-CurrentDate) + "`n"
        $updatedArchiveContent = $ArchiveContent.Replace($sectionContent, $updatedSectionContent)
    }
    else {
        # La section n'existe pas encore, crée une nouvelle section
        $newSection = @"
## $sectionId. Section
**Description**: Section pour les tâches archivées.
**Responsable**: Équipe
**Statut global**: Archivé

$($TaskContent.Replace($TaskName, "$TaskName (ARCHIVÉ)"))

**Archived Date**: $(Get-CurrentDate)

"@
        $updatedArchiveContent = $ArchiveContent.TrimEnd() + "`n`n" + $newSection
    }
    
    return $updatedArchiveContent
}

# Fonction pour créer un fichier d'archive individuel pour la tâche
function New-TaskArchiveFile {
    param (
        [string]$TaskContent,
        [string]$TaskId,
        [string]$TaskName
    )
    
    $fileName = "$TaskId`_$($TaskName.Replace(' ', '_')).md"
    $filePath = "..\archive\$fileName"
    
    $TaskContent | Out-File -FilePath $filePath -Encoding utf8
    
    Write-Host "Fichier d'archive individuel créé : $filePath"
}

# Lecture des fichiers
$roadmapContent = Get-Content -Path $RoadmapFile -Raw -Encoding utf8
$archiveContent = Get-Content -Path $ArchiveFile -Raw -Encoding utf8

# Extraction du contenu de la tâche
$taskContent = Export-TaskContent -RoadmapContent $roadmapContent -TaskId $TaskId

# Création du fichier d'archive individuel
New-TaskArchiveFile -TaskContent $taskContent -TaskId $TaskId -TaskName $TaskName

# Mise à jour du fichier roadmap
$updatedRoadmapContent = Update-RoadmapFile -RoadmapContent $roadmapContent -TaskId $TaskId -TaskName $TaskName
$updatedRoadmapContent | Out-File -FilePath $RoadmapFile -Encoding utf8

# Mise à jour du fichier d'archive
$updatedArchiveContent = Update-ArchiveFile -ArchiveContent $archiveContent -TaskContent $taskContent -TaskId $TaskId -TaskName $TaskName
$updatedArchiveContent | Out-File -FilePath $ArchiveFile -Encoding utf8

Write-Host "Tâche $TaskId $TaskName archivée avec succès."

