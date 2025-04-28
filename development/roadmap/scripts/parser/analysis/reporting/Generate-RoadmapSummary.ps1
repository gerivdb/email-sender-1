﻿# Generate-RoadmapSummary.ps1
# Script pour gÃ©nÃ©rer un rÃ©sumÃ© de la structure d'un fichier markdown de roadmap

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\analysis\roadmap-summary.md"
)

# Importer le module RoadmapAnalyzer
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapAnalyzer.psm1"
Import-Module $modulePath -Force

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de sortie crÃ©Ã©: $outputDir" -ForegroundColor Green
}

# Analyser la structure du fichier
Write-Host "Analyse de la structure du fichier: $RoadmapFilePath" -ForegroundColor Cyan
$structure = Get-MarkdownStructure -FilePath $RoadmapFilePath

# Lire le contenu du fichier
$content = Get-Content -Path $RoadmapFilePath -Encoding UTF8 -Raw

# Calculer des statistiques gÃ©nÃ©rales
$lines = ($content -split "`n").Length
$words = ($content -split '\s+').Length
$chars = $content.Length

# Calculer le nombre total de tÃ¢ches
$totalTasks = $structure.StatusMarkers.Incomplete + $structure.StatusMarkers.Complete
foreach ($customCount in $structure.StatusMarkers.Custom.Values) {
    $totalTasks += $customCount
}

# Calculer le pourcentage de complÃ©tion
$completionPercentage = if ($totalTasks -gt 0) {
    [Math]::Round(($structure.StatusMarkers.Complete / $totalTasks) * 100, 2)
} else {
    0
}

# GÃ©nÃ©rer le rapport de synthÃ¨se
$summary = @"
# RÃ©sumÃ© de la Roadmap

**Fichier:** `$RoadmapFilePath`  
**Date d'analyse:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Statistiques GÃ©nÃ©rales

- **Lignes:** $lines
- **Mots:** $words
- **CaractÃ¨res:** $chars
- **Profondeur maximale:** $($structure.TaskHierarchy.MaxDepth) niveaux

## Progression

- **TÃ¢ches totales:** $totalTasks
- **TÃ¢ches terminÃ©es:** $($structure.StatusMarkers.Complete)
- **TÃ¢ches en cours:** $($structure.StatusMarkers.Incomplete)
- **Pourcentage de complÃ©tion:** $completionPercentage%

## Structure

- **Marqueur de liste principal:** $(if ($structure.ListMarkers.Count -gt 0) { ($structure.ListMarkers.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1).Key } else { "Aucun" })
- **Espaces d'indentation par niveau:** $($structure.Indentation.SpacesPerLevel)
- **Style de titre principal:** $(if ($structure.Headers.HashHeaders.Count -gt $structure.Headers.UnderlineHeaders.Count) { "# (hash)" } else { "Soulignement" })
- **Style d'emphase principal:** $(if ($structure.Emphasis.Bold.Asterisks -gt $structure.Emphasis.Bold.Underscores) { "** (astÃ©risques)" } else { "__ (underscores)" })

## Conventions de NumÃ©rotation

"@

if ($structure.TaskHierarchy.NumberingConventions.Count -eq 0) {
    $summary += "Aucune convention de numÃ©rotation dÃ©tectÃ©e.`n`n"
} else {
    $summary += "`n"
    foreach ($convention in $structure.TaskHierarchy.NumberingConventions.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 3) {
        $summary += "- `$($convention.Key)`: $($convention.Value) occurrences`n"
    }
    $summary += "`n"
}

# Analyser les conventions spÃ©cifiques au projet
$conventions = Get-ProjectConventions -Content $content

$summary += @"
## Conventions SpÃ©cifiques au Projet

"@

if ($null -ne $conventions.TaskIdentifiers.Pattern) {
    $summary += "- **Format d'identifiant de tÃ¢che:** DÃ©tectÃ© (ex: $($conventions.TaskIdentifiers.Examples[0]))`n"
} else {
    $summary += "- **Format d'identifiant de tÃ¢che:** Non dÃ©tectÃ©`n"
}

if ($null -ne $conventions.PriorityIndicators.Pattern) {
    $summary += "- **Indicateurs de prioritÃ©:** DÃ©tectÃ©s (ex: $($conventions.PriorityIndicators.Examples[0]))`n"
} else {
    $summary += "- **Indicateurs de prioritÃ©:** Non dÃ©tectÃ©s`n"
}

if ($null -ne $conventions.StatusIndicators.Pattern) {
    $summary += "- **Indicateurs de statut personnalisÃ©s:** DÃ©tectÃ©s (ex: $($conventions.StatusIndicators.Examples[0]))`n"
} else {
    $summary += "- **Indicateurs de statut personnalisÃ©s:** Non dÃ©tectÃ©s`n"
}

if ($conventions.SpecialSections.Count -gt 0) {
    $summary += "- **Sections spÃ©ciales:** DÃ©tectÃ©es (ex: $($conventions.SpecialSections[0]))`n"
} else {
    $summary += "- **Sections spÃ©ciales:** Non dÃ©tectÃ©es`n"
}

# Enregistrer le rapport de synthÃ¨se dans un fichier
$summary | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "Rapport de synthÃ¨se gÃ©nÃ©rÃ©: $OutputPath" -ForegroundColor Green
Write-Host "Analyse terminÃ©e." -ForegroundColor Cyan
