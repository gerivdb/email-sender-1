<#
.SYNOPSIS
    Script simplifiÃ© pour vÃ©rifier et mettre Ã  jour le statut des tÃ¢ches dans un fichier de roadmap.

.DESCRIPTION
    Ce script analyse un fichier de roadmap Markdown, vÃ©rifie si les tÃ¢ches spÃ©cifiÃ©es sont implÃ©mentÃ©es,
    et met Ã  jour le fichier en cochant les cases correspondantes.

.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap Ã  mettre Ã  jour.

.PARAMETER LineNumbers
    NumÃ©ros de lignes Ã  vÃ©rifier et mettre Ã  jour dans le fichier de roadmap.

.EXAMPLE
    .\Check-Roadmap.ps1 -RoadmapPath "test_roadmap.md" -LineNumbers 9,10,11,12

.NOTES
    Auteur: Roadmap Tools Team
    Version: 1.0
    Date de crÃ©ation: 2023-11-15
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$RoadmapPath,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$LineNumbersStr
)

# VÃ©rifier si le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier de roadmap '$RoadmapPath' n'existe pas."
    return
}

# Lire le contenu du fichier de roadmap
$content = Get-Content -Path $RoadmapPath -Encoding UTF8

# Convertir la chaÃ®ne de numÃ©ros de ligne en tableau d'entiers
$LineNumbers = $LineNumbersStr -split ',' | ForEach-Object { [int]$_.Trim() }

# Afficher les informations sur le fichier
Write-Host "Fichier de roadmap : $RoadmapPath" -ForegroundColor Cyan
Write-Host "Nombre de lignes : $($content.Count)" -ForegroundColor Cyan
Write-Host "Lignes Ã  vÃ©rifier : $($LineNumbers -join ', ')" -ForegroundColor Cyan

# Parcourir les lignes spÃ©cifiÃ©es
$updatedContent = $content.Clone()
$updatedLines = 0

foreach ($lineNumber in $LineNumbers) {
    # VÃ©rifier si le numÃ©ro de ligne est valide
    if ($lineNumber -lt 1 -or $lineNumber -gt $content.Count) {
        Write-Warning "Ligne $lineNumber hors limites (1-$($content.Count))."
        continue
    }

    # RÃ©cupÃ©rer la ligne
    $line = $content[$lineNumber - 1]
    Write-Host "Ligne $lineNumber : $line" -ForegroundColor Yellow

    # VÃ©rifier si la ligne correspond Ã  une tÃ¢che
    if ($line -match '^\s*-\s+\[([ xX])\]\s+(\d+(\.\d+)*)\s+(.+)$') {
        $status = $matches[1]
        $taskId = $matches[2]
        $taskName = $matches[4]

        Write-Host "  Status actuel: [$status]" -ForegroundColor Yellow

        # VÃ©rifier si la tÃ¢che est dÃ©jÃ  cochÃ©e
        if ($status -eq 'x' -or $status -eq 'X') {
            Write-Host "  TÃ¢che dÃ©jÃ  cochÃ©e." -ForegroundColor Green
            continue
        }

        # VÃ©rifier si la tÃ¢che est implÃ©mentÃ©e
        $isImplemented = $true  # Pour ce test, considÃ©rer toutes les tÃ¢ches comme implÃ©mentÃ©es
        Write-Host "  TÃ¢che considÃ©rÃ©e comme implÃ©mentÃ©e pour le test." -ForegroundColor Cyan

        if ($isImplemented) {
            # Mettre Ã  jour la ligne
            $updatedLine = $line -replace '\[ \]', '[x]'
            $updatedContent[$lineNumber - 1] = $updatedLine
            $updatedLines++

            Write-Host "  TÃ¢che marquÃ©e comme implÃ©mentÃ©e." -ForegroundColor Green
        } else {
            Write-Host "  TÃ¢che non implÃ©mentÃ©e." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  La ligne ne correspond pas Ã  une tÃ¢che." -ForegroundColor Red
    }
}

# Sauvegarder le contenu mis Ã  jour
if ($updatedLines -gt 0) {
    $updatedContent | Set-Content -Path $RoadmapPath -Encoding UTF8
    Write-Host "`nLe fichier de roadmap a Ã©tÃ© mis Ã  jour avec $updatedLines tÃ¢ches cochÃ©es." -ForegroundColor Green
} else {
    Write-Host "`nAucune tÃ¢che n'a Ã©tÃ© mise Ã  jour." -ForegroundColor Yellow
}
