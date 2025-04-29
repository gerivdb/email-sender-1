<#
.SYNOPSIS
    Met à jour les cases à cocher dans le fichier roadmap.

.DESCRIPTION
    Ce script met à jour les cases à cocher dans le fichier roadmap pour marquer les tâches comme complétées.

.PARAMETER RoadmapPath
    Chemin vers le fichier roadmap.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à marquer comme complétée.

.PARAMETER Completed
    Indique si la tâche doit être marquée comme complétée (true) ou non complétée (false).

.EXAMPLE
    .\update-roadmap-checkboxes.ps1 -RoadmapPath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.1.1" -Completed $true
    Marque la tâche 1.1.1 et ses sous-tâches comme complétées dans le fichier roadmap.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$RoadmapPath,

    [Parameter(Mandatory = $true)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [switch]$Completed
)

# Vérifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier roadmap est introuvable : $RoadmapPath"
    exit 1
}

# Lire le contenu du fichier roadmap
$content = Get-Content -Path $RoadmapPath -Encoding UTF8

# Créer un tableau pour stocker le contenu modifié
$modifiedContent = @()

# Définir les expressions régulières pour identifier les tâches
$taskRegex = "^(\s*)-\s+\[([ x])\]\s+\*\*($TaskIdentifier(?:\.\d+)?)\*\*\s+(.*)$"

# Parcourir chaque ligne du fichier
foreach ($line in $content) {
    # Vérifier si la ligne correspond à une tâche
    if ($line -match $taskRegex) {
        $indent = $matches[1]
        $checkbox = $matches[2]
        $taskId = $matches[3]
        $taskText = $matches[4]

        # Vérifier si la tâche correspond à l'identifiant spécifié ou à une sous-tâche
        if ($taskId -eq $TaskIdentifier -or $taskId -match "^$TaskIdentifier\.\d+$") {
            # Mettre à jour la case à cocher
            $newCheckbox = if ($Completed) { "x" } else { " " }
            $modifiedLine = "$indent- [$newCheckbox] **$taskId** $taskText"
            $modifiedContent += $modifiedLine
        } else {
            # Conserver la ligne inchangée
            $modifiedContent += $line
        }
    } else {
        # Conserver la ligne inchangée
        $modifiedContent += $line
    }
}

# Écrire le contenu modifié dans le fichier
Set-Content -Path $RoadmapPath -Value $modifiedContent -Encoding UTF8

Write-Host "Les cases à cocher pour la tâche $TaskIdentifier ont été mises à jour dans le fichier $RoadmapPath."
