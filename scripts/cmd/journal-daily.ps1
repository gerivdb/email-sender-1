# Script PowerShell pour la crÃ©ation automatique d'entrÃ©es quotidiennes dans le journal de bord
param (
    [Parameter()]
    [switch]$Weekly = $false
)

$ScriptsDir = Join-Path $PSScriptRoot "..\python\journal"
$Date = Get-Date -Format "yyyy-MM-dd"
$Time = Get-Date -Format "HH-mm"
$DateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$DayOfWeek = (Get-Date).DayOfWeek

# DÃ©terminer le type d'entrÃ©e (quotidienne ou hebdomadaire)
if ($Weekly -and $DayOfWeek -eq "Monday") {
    $Title = "RÃ©sumÃ© hebdomadaire - Semaine du $Date"
    $Tags = "rÃ©sumÃ©-hebdomadaire", "bilan"

    # Calculer la date de dÃ©but de la semaine prÃ©cÃ©dente (lundi dernier)
    $LastWeekStart = (Get-Date).AddDays(-7)
    $LastWeekStartStr = $LastWeekStart.ToString("yyyy-MM-dd")

    # Calculer la date de fin de la semaine prÃ©cÃ©dente (dimanche dernier)
    $LastWeekEnd = (Get-Date).AddDays(-1)
    $LastWeekEndStr = $LastWeekEnd.ToString("yyyy-MM-dd")

    # Contenu spÃ©cifique pour l'entrÃ©e hebdomadaire
    $Content = @"
---
date: $Date
heure: $Time
title: $Title
tags: [$($Tags -join ", ")]
related: []
---

# $Title

## PÃ©riode couverte
- Du $LastWeekStartStr au $LastWeekEndStr

## Actions rÃ©alisÃ©es
-

## RÃ©solution des erreurs, dÃ©ductions tirÃ©es
-

## Optimisations identifiÃ©es
- Pour le systÃ¨me:
- Pour le code:
- Pour la gestion des erreurs:
- Pour les workflows:

## Enseignements techniques
-

## Impact sur le projet musical
-

## Objectifs pour la semaine Ã  venir
-

## RÃ©fÃ©rences et ressources
-
"@

    # Chemin du fichier
    $FilePath = Join-Path (Join-Path (Join-Path (Get-Location) "docs") "journal_de_bord\entries") "$Date-$Time-resume-hebdomadaire.md"

    # Ã‰criture du fichier
    [System.IO.File]::WriteAllText($FilePath, $Content, [System.Text.Encoding]::UTF8)

    Write-Host "EntrÃ©e hebdomadaire crÃ©Ã©e: $FilePath"

    # Mise Ã  jour des index
    python "$ScriptsDir\journal_search_simple.py" --rebuild
    python "$ScriptsDir\journal_rag_simple.py" --rebuild --export

    return
}

# EntrÃ©e quotidienne standard
$Title = "Journal quotidien - $Date"
$Tags = "journal-quotidien", "activitÃ©s"

# Contenu pour l'entrÃ©e quotidienne
$Content = @"
---
date: $Date
heure: $Time
title: $Title
tags: [$($Tags -join ", ")]
related: []
---

# $Title

## Actions rÃ©alisÃ©es
-

## RÃ©solution des erreurs, dÃ©ductions tirÃ©es
-

## Optimisations identifiÃ©es
- Pour le systÃ¨me:
- Pour le code:
- Pour la gestion des erreurs:
- Pour les workflows:

## Enseignements techniques
-

## Impact sur le projet musical
-

## TÃ¢ches pour demain
-

## RÃ©fÃ©rences et ressources
-
"@

# Chemin du fichier
$FilePath = Join-Path (Join-Path (Join-Path (Get-Location) "docs") "journal_de_bord\entries") "$Date-$Time-journal-quotidien.md"

# VÃ©rifier si le fichier existe dÃ©jÃ 
if (Test-Path $FilePath) {
    Write-Host "L'entrÃ©e quotidienne pour $Date existe dÃ©jÃ : $FilePath"
    return
}

# Ã‰criture du fichier
[System.IO.File]::WriteAllText($FilePath, $Content, [System.Text.Encoding]::UTF8)

Write-Host "EntrÃ©e quotidienne crÃ©Ã©e: $FilePath"

# Mise Ã  jour des index
python "$ScriptsDir\journal_search_simple.py" --rebuild
python "$ScriptsDir\journal_rag_simple.py" --rebuild --export
