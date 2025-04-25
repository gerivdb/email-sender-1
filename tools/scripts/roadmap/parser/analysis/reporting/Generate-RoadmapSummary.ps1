# Generate-RoadmapSummary.ps1
# Script pour générer un résumé de la structure d'un fichier markdown de roadmap

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\analysis\roadmap-summary.md"
)

# Importer le module RoadmapAnalyzer
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapAnalyzer.psm1"
Import-Module $modulePath -Force

# Vérifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de sortie créé: $outputDir" -ForegroundColor Green
}

# Analyser la structure du fichier
Write-Host "Analyse de la structure du fichier: $RoadmapFilePath" -ForegroundColor Cyan
$structure = Get-MarkdownStructure -FilePath $RoadmapFilePath

# Lire le contenu du fichier
$content = Get-Content -Path $RoadmapFilePath -Encoding UTF8 -Raw

# Calculer des statistiques générales
$lines = ($content -split "`n").Length
$words = ($content -split '\s+').Length
$chars = $content.Length

# Calculer le nombre total de tâches
$totalTasks = $structure.StatusMarkers.Incomplete + $structure.StatusMarkers.Complete
foreach ($customCount in $structure.StatusMarkers.Custom.Values) {
    $totalTasks += $customCount
}

# Calculer le pourcentage de complétion
$completionPercentage = if ($totalTasks -gt 0) {
    [Math]::Round(($structure.StatusMarkers.Complete / $totalTasks) * 100, 2)
} else {
    0
}

# Générer le rapport de synthèse
$summary = @"
# Résumé de la Roadmap

**Fichier:** `$RoadmapFilePath`  
**Date d'analyse:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Statistiques Générales

- **Lignes:** $lines
- **Mots:** $words
- **Caractères:** $chars
- **Profondeur maximale:** $($structure.TaskHierarchy.MaxDepth) niveaux

## Progression

- **Tâches totales:** $totalTasks
- **Tâches terminées:** $($structure.StatusMarkers.Complete)
- **Tâches en cours:** $($structure.StatusMarkers.Incomplete)
- **Pourcentage de complétion:** $completionPercentage%

## Structure

- **Marqueur de liste principal:** $(if ($structure.ListMarkers.Count -gt 0) { ($structure.ListMarkers.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1).Key } else { "Aucun" })
- **Espaces d'indentation par niveau:** $($structure.Indentation.SpacesPerLevel)
- **Style de titre principal:** $(if ($structure.Headers.HashHeaders.Count -gt $structure.Headers.UnderlineHeaders.Count) { "# (hash)" } else { "Soulignement" })
- **Style d'emphase principal:** $(if ($structure.Emphasis.Bold.Asterisks -gt $structure.Emphasis.Bold.Underscores) { "** (astérisques)" } else { "__ (underscores)" })

## Conventions de Numérotation

"@

if ($structure.TaskHierarchy.NumberingConventions.Count -eq 0) {
    $summary += "Aucune convention de numérotation détectée.`n`n"
} else {
    $summary += "`n"
    foreach ($convention in $structure.TaskHierarchy.NumberingConventions.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 3) {
        $summary += "- `$($convention.Key)`: $($convention.Value) occurrences`n"
    }
    $summary += "`n"
}

# Analyser les conventions spécifiques au projet
$conventions = Get-ProjectConventions -Content $content

$summary += @"
## Conventions Spécifiques au Projet

"@

if ($null -ne $conventions.TaskIdentifiers.Pattern) {
    $summary += "- **Format d'identifiant de tâche:** Détecté (ex: $($conventions.TaskIdentifiers.Examples[0]))`n"
} else {
    $summary += "- **Format d'identifiant de tâche:** Non détecté`n"
}

if ($null -ne $conventions.PriorityIndicators.Pattern) {
    $summary += "- **Indicateurs de priorité:** Détectés (ex: $($conventions.PriorityIndicators.Examples[0]))`n"
} else {
    $summary += "- **Indicateurs de priorité:** Non détectés`n"
}

if ($null -ne $conventions.StatusIndicators.Pattern) {
    $summary += "- **Indicateurs de statut personnalisés:** Détectés (ex: $($conventions.StatusIndicators.Examples[0]))`n"
} else {
    $summary += "- **Indicateurs de statut personnalisés:** Non détectés`n"
}

if ($conventions.SpecialSections.Count -gt 0) {
    $summary += "- **Sections spéciales:** Détectées (ex: $($conventions.SpecialSections[0]))`n"
} else {
    $summary += "- **Sections spéciales:** Non détectées`n"
}

# Enregistrer le rapport de synthèse dans un fichier
$summary | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "Rapport de synthèse généré: $OutputPath" -ForegroundColor Green
Write-Host "Analyse terminée." -ForegroundColor Cyan
