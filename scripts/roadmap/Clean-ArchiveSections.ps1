#Requires -Version 5.1
<#
.SYNOPSIS
    Nettoie les sections d'archive dupliquées dans le fichier roadmap.
.DESCRIPTION
    Ce script supprime les sections d'archive dupliquées dans le fichier roadmap
    et ne conserve qu'une seule section d'archive à la fin du fichier.
.PARAMETER RoadmapPath
    Chemin vers le fichier Markdown de la roadmap.
.EXAMPLE
    .\Clean-ArchiveSections.ps1 -RoadmapPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Date: 2023-07-04
    Version: 1.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$RoadmapPath
)

function Remove-ArchiveSections {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath
    )

    # Vérifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        throw "Le fichier de roadmap '$RoadmapPath' n'existe pas."
    }

    # Lire le contenu du fichier de roadmap
    $content = Get-Content -Path $RoadmapPath -Encoding UTF8

    # Approche plus simple : reconstruire le contenu en ignorant toutes les lignes d'archive
    $newContent = @()

    # Filtrer les lignes pour ne garder que celles qui ne sont pas des sections d'archive
    foreach ($line in $content) {
        if (-not ($line -match '^## Archive' -or $line -match '^\[Tâches archivées\]')) {
            $newContent += $line
        }
    }

    # Supprimer les lignes vides à la fin du fichier
    while ($newContent.Count -gt 0 -and [string]::IsNullOrWhiteSpace($newContent[-1])) {
        $newContent = $newContent[0..($newContent.Count - 2)]
    }

    # Ajouter une seule section d'archive à la fin
    $newContent += ""
    $newContent += "## Archive"
    $newContent += "[Tâches archivées](archive/roadmap_archive.md)"

    # Enregistrer les modifications
    $newContent | Out-File -FilePath $RoadmapPath -Encoding UTF8

    return @{
        roadmapPath = $RoadmapPath
    }
}

# Fonction principale
try {
    $result = Remove-ArchiveSections -RoadmapPath $RoadmapPath

    if ($result) {
        Write-Host "Nettoyage des sections d'archive réussi."
        Write-Host "Les sections d'archive dupliquées ont été supprimées dans '$($result.roadmapPath)'."
    }
} catch {
    Write-Error "Erreur lors du nettoyage des sections d'archive: $_"
}
