# Script PowerShell pour la création automatique d'entrées quotidiennes dans le journal de bord
param (
    [Parameter()]
    [switch]$Weekly = $false
)

$ScriptsDir = Join-Path $PSScriptRoot "..\python\journal"
$Date = Get-Date -Format "yyyy-MM-dd"
$DayOfWeek = (Get-Date).DayOfWeek

# Déterminer le type d'entrée (quotidienne ou hebdomadaire)
if ($Weekly -and $DayOfWeek -eq "Monday") {
    $Title = "Résumé hebdomadaire - Semaine du $Date"
    $Tags = "résumé-hebdomadaire", "bilan"
    
    # Calculer la date de début de la semaine précédente (lundi dernier)
    $LastWeekStart = (Get-Date).AddDays(-7)
    $LastWeekStartStr = $LastWeekStart.ToString("yyyy-MM-dd")
    
    # Calculer la date de fin de la semaine précédente (dimanche dernier)
    $LastWeekEnd = (Get-Date).AddDays(-1)
    $LastWeekEndStr = $LastWeekEnd.ToString("yyyy-MM-dd")
    
    # Contenu spécifique pour l'entrée hebdomadaire
    $Content = @"
---
date: $Date
title: $Title
tags: [$($Tags -join ", ")]
related: []
---

# $Title

## Période couverte
- Du $LastWeekStartStr au $LastWeekEndStr

## Résumé des activités
- 

## Principales réalisations
- 

## Problèmes rencontrés
- 

## Solutions mises en œuvre
- 

## Enseignements
- 

## Objectifs pour la semaine à venir
- 

## Références
- 
"@
    
    # Chemin du fichier
    $FilePath = Join-Path (Join-Path (Join-Path (Get-Location) "docs") "journal_de_bord\entries") "$Date-resume-hebdomadaire.md"
    
    # Écriture du fichier
    Set-Content -Path $FilePath -Value $Content -Encoding UTF8
    
    Write-Host "Entrée hebdomadaire créée: $FilePath"
    
    # Mise à jour des index
    python "$ScriptsDir\journal_search_simple.py" --rebuild
    python "$ScriptsDir\journal_rag_simple.py" --rebuild --export
    
    return
}

# Entrée quotidienne standard
$Title = "Journal quotidien - $Date"
$Tags = "journal-quotidien", "activités"

# Contenu pour l'entrée quotidienne
$Content = @"
---
date: $Date
title: $Title
tags: [$($Tags -join ", ")]
related: []
---

# $Title

## Activités du jour
- 

## Problèmes rencontrés
- 

## Solutions mises en œuvre
- 

## Enseignements
- 

## Tâches pour demain
- 

## Notes diverses
- 
"@

# Chemin du fichier
$FilePath = Join-Path (Join-Path (Join-Path (Get-Location) "docs") "journal_de_bord\entries") "$Date-journal-quotidien.md"

# Vérifier si le fichier existe déjà
if (Test-Path $FilePath) {
    Write-Host "L'entrée quotidienne pour $Date existe déjà: $FilePath"
    return
}

# Écriture du fichier
Set-Content -Path $FilePath -Value $Content -Encoding UTF8

Write-Host "Entrée quotidienne créée: $FilePath"

# Mise à jour des index
python "$ScriptsDir\journal_search_simple.py" --rebuild
python "$ScriptsDir\journal_rag_simple.py" --rebuild --export
