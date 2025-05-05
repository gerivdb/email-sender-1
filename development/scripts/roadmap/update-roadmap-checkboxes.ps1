<#
.SYNOPSIS
    Met Ã  jour les cases Ã  cocher dans le fichier roadmap.

.DESCRIPTION
    Ce script met Ã  jour les cases Ã  cocher dans le fichier roadmap pour marquer les tÃ¢ches comme complÃ©tÃ©es.

.PARAMETER RoadmapPath
    Chemin vers le fichier roadmap.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  marquer comme complÃ©tÃ©e.

.PARAMETER Completed
    Indique si la tÃ¢che doit Ãªtre marquÃ©e comme complÃ©tÃ©e (true) ou non complÃ©tÃ©e (false).

.EXAMPLE
    .\update-roadmap-checkboxes.ps1 -RoadmapPath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.1.1" -Completed $true
    Marque la tÃ¢che 1.1.1 et ses sous-tÃ¢ches comme complÃ©tÃ©es dans le fichier roadmap.
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

# VÃ©rifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier roadmap est introuvable : $RoadmapPath"
    exit 1
}

# Lire le contenu du fichier roadmap
$content = Get-Content -Path $RoadmapPath -Encoding UTF8

# CrÃ©er un tableau pour stocker le contenu modifiÃ©
$modifiedContent = @()

# DÃ©finir les expressions rÃ©guliÃ¨res pour identifier les tÃ¢ches
$taskRegex = "^(\s*)-\s+\[([ x])\]\s+\*\*($TaskIdentifier(?:\.\d+)?)\*\*\s+(.*)$"

# Parcourir chaque ligne du fichier
foreach ($line in $content) {
    # VÃ©rifier si la ligne correspond Ã  une tÃ¢che
    if ($line -match $taskRegex) {
        $indent = $matches[1]
        $checkbox = $matches[2]
        $taskId = $matches[3]
        $taskText = $matches[4]

        # VÃ©rifier si la tÃ¢che correspond Ã  l'identifiant spÃ©cifiÃ© ou Ã  une sous-tÃ¢che
        if ($taskId -eq $TaskIdentifier -or $taskId -match "^$TaskIdentifier\.\d+$") {
            # Mettre Ã  jour la case Ã  cocher
            $newCheckbox = if ($Completed) { "x" } else { " " }
            $modifiedLine = "$indent- [$newCheckbox] **$taskId** $taskText"
            $modifiedContent += $modifiedLine
        } else {
            # Conserver la ligne inchangÃ©e
            $modifiedContent += $line
        }
    } else {
        # Conserver la ligne inchangÃ©e
        $modifiedContent += $line
    }
}

# Ã‰crire le contenu modifiÃ© dans le fichier
Set-Content -Path $RoadmapPath -Value $modifiedContent -Encoding UTF8

Write-Host "Les cases Ã  cocher pour la tÃ¢che $TaskIdentifier ont Ã©tÃ© mises Ã  jour dans le fichier $RoadmapPath."
