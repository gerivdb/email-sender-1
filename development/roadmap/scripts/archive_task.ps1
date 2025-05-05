# Script d'archivage des tÃ¢ches terminÃ©es
# Usage: .\archive_task.ps1 -TaskId "5.1.2" -TaskName "ImplÃ©mentation des modÃ¨les prÃ©dictifs"

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

# Fonction pour extraire le contenu d'une tÃ¢che du fichier roadmap
function Extract-TaskContent {
    param (
        [string]$RoadmapContent,
        [string]$TaskId
    )
    
    # Recherche le dÃ©but de la section de la tÃ¢che
    $pattern = "#### $TaskId .*?(?=####|\Z)"
    $match = [regex]::Match($RoadmapContent, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    if ($match.Success) {
        return $match.Value.Trim()
    }
    else {
        Write-Error "TÃ¢che $TaskId non trouvÃ©e dans le fichier roadmap."
        exit 1
    }
}

# Fonction pour mettre Ã  jour le fichier roadmap
function Update-RoadmapFile {
    param (
        [string]$RoadmapContent,
        [string]$TaskId,
        [string]$TaskName
    )
    
    # Recherche la section de la tÃ¢che
    $pattern = "#### $TaskId .*?(?=####|\Z)"
    
    # Remplace la section par une version simplifiÃ©e
    $replacement = @"
#### $TaskId $TaskName
**Progression**: 100% - *TerminÃ©*
**Note**: Cette tÃ¢che a Ã©tÃ© archivÃ©e. Voir [Archive des tÃ¢ches](archive/roadmap_archive.md) pour les dÃ©tails.

"@
    
    $updatedContent = [regex]::Replace($RoadmapContent, $pattern, $replacement, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    return $updatedContent
}

# Fonction pour mettre Ã  jour le fichier d'archive
function Update-ArchiveFile {
    param (
        [string]$ArchiveContent,
        [string]$TaskContent,
        [string]$TaskId,
        [string]$TaskName
    )
    
    # Recherche la section appropriÃ©e dans le fichier d'archive
    $sectionId = $TaskId.Split('.')[0]
    $sectionPattern = "## $sectionId\. .*?(?=##|\Z)"
    $sectionMatch = [regex]::Match($ArchiveContent, $sectionPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    if ($sectionMatch.Success) {
        # La section existe dÃ©jÃ , ajoute la tÃ¢che Ã  la fin de la section
        $sectionContent = $sectionMatch.Value
        $updatedSectionContent = $sectionContent.TrimEnd() + "`n`n" + $TaskContent.Replace($TaskName, "$TaskName (ARCHIVÃ‰)") + "`n`n**Archived Date**: " + (Get-CurrentDate) + "`n"
        $updatedArchiveContent = $ArchiveContent.Replace($sectionContent, $updatedSectionContent)
    }
    else {
        # La section n'existe pas encore, crÃ©e une nouvelle section
        $newSection = @"
## $sectionId. Section
**Description**: Section pour les tÃ¢ches archivÃ©es.
**Responsable**: Ã‰quipe
**Statut global**: ArchivÃ©

$($TaskContent.Replace($TaskName, "$TaskName (ARCHIVÃ‰)"))

**Archived Date**: $(Get-CurrentDate)

"@
        $updatedArchiveContent = $ArchiveContent.TrimEnd() + "`n`n" + $newSection
    }
    
    return $updatedArchiveContent
}

# Fonction pour crÃ©er un fichier d'archive individuel pour la tÃ¢che
function Create-TaskArchiveFile {
    param (
        [string]$TaskContent,
        [string]$TaskId,
        [string]$TaskName
    )
    
    $fileName = "$TaskId`_$($TaskName.Replace(' ', '_')).md"
    $filePath = "..\archive\$fileName"
    
    $TaskContent | Out-File -FilePath $filePath -Encoding utf8
    
    Write-Host "Fichier d'archive individuel crÃ©Ã© : $filePath"
}

# Lecture des fichiers
$roadmapContent = Get-Content -Path $RoadmapFile -Raw -Encoding utf8
$archiveContent = Get-Content -Path $ArchiveFile -Raw -Encoding utf8

# Extraction du contenu de la tÃ¢che
$taskContent = Extract-TaskContent -RoadmapContent $roadmapContent -TaskId $TaskId

# CrÃ©ation du fichier d'archive individuel
Create-TaskArchiveFile -TaskContent $taskContent -TaskId $TaskId -TaskName $TaskName

# Mise Ã  jour du fichier roadmap
$updatedRoadmapContent = Update-RoadmapFile -RoadmapContent $roadmapContent -TaskId $TaskId -TaskName $TaskName
$updatedRoadmapContent | Out-File -FilePath $RoadmapFile -Encoding utf8

# Mise Ã  jour du fichier d'archive
$updatedArchiveContent = Update-ArchiveFile -ArchiveContent $archiveContent -TaskContent $taskContent -TaskId $TaskId -TaskName $TaskName
$updatedArchiveContent | Out-File -FilePath $ArchiveFile -Encoding utf8

Write-Host "TÃ¢che $TaskId $TaskName archivÃ©e avec succÃ¨s."
