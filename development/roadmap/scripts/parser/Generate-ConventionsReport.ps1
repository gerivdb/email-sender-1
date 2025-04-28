# Generate-ConventionsReport.ps1
# Script pour gÃ©nÃ©rer un rapport sur les conventions spÃ©cifiques au projet

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\analysis\conventions-report.md"
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

# Lire le contenu du fichier
$content = Get-Content -Path $RoadmapFilePath -Encoding UTF8 -Raw

# Analyser les conventions spÃ©cifiques au projet
Write-Host "Analyse des conventions spÃ©cifiques au projet dans: $RoadmapFilePath" -ForegroundColor Cyan
$conventions = Get-ProjectConventions -Content $content

# GÃ©nÃ©rer le rapport
$report = "# Conventions SpÃ©cifiques au Projet`r`n`r`n"
$report += "**Fichier analysÃ©:** $RoadmapFilePath`r`n"
$report += "**Date d'analyse:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n`r`n"
$report += "## 1. Identifiants de TÃ¢ches`r`n`r`n"

if ($null -eq $conventions.TaskIdentifiers.Pattern) {
    $report += "Aucun format d'identifiant de tÃ¢che spÃ©cifique dÃ©tectÃ©.`r`n`r`n"
} else {
    $report += "**Format dÃ©tectÃ©:** $($conventions.TaskIdentifiers.Pattern)`r`n`r`n"
    $report += "**Exemples:**`r`n`r`n"
    foreach ($example in $conventions.TaskIdentifiers.Examples) {
        $report += "- $example`r`n"
    }
    $report += "`r`n"
}

$report += "## 2. Indicateurs de PrioritÃ©`r`n`r`n"

if ($null -eq $conventions.PriorityIndicators.Pattern) {
    $report += "Aucun indicateur de prioritÃ© spÃ©cifique dÃ©tectÃ©.`r`n`r`n"
} else {
    $report += "**Format dÃ©tectÃ©:** $($conventions.PriorityIndicators.Pattern)`r`n`r`n"
    $report += "**Exemples:**`r`n`r`n"
    foreach ($example in $conventions.PriorityIndicators.Examples) {
        $report += "- $example`r`n"
    }
    $report += "`r`n"
}

$report += "## 3. Indicateurs de Statut`r`n`r`n"

if ($null -eq $conventions.StatusIndicators.Pattern) {
    $report += "Aucun indicateur de statut spÃ©cifique dÃ©tectÃ©.`r`n`r`n"
} else {
    $report += "**Format dÃ©tectÃ©:** $($conventions.StatusIndicators.Pattern)`r`n`r`n"
    $report += "**Exemples:**`r`n`r`n"
    foreach ($example in $conventions.StatusIndicators.Examples) {
        $report += "- $example`r`n"
    }
    $report += "`r`n"
}

$report += "## 4. Sections SpÃ©ciales`r`n`r`n"

if ($conventions.SpecialSections.Count -eq 0) {
    $report += "Aucune section spÃ©ciale dÃ©tectÃ©e.`r`n`r`n"
} else {
    $report += "**Sections dÃ©tectÃ©es:**`r`n`r`n"
    foreach ($section in $conventions.SpecialSections) {
        $report += "- $section`r`n"
    }
    $report += "`r`n"
}

$report += "## 5. Format des MÃ©tadonnÃ©es`r`n`r`n"

if ($null -eq $conventions.MetadataFormat) {
    $report += "Aucun format de mÃ©tadonnÃ©es spÃ©cifique dÃ©tectÃ©.`r`n`r`n"
} else {
    $report += "**Format dÃ©tectÃ©:** $($conventions.MetadataFormat)`r`n`r`n"
}

$report += "## 6. Recommandations`r`n`r`n"
$report += "BasÃ© sur l'analyse des conventions spÃ©cifiques au projet, voici quelques recommandations:`r`n`r`n"

# GÃ©nÃ©rer des recommandations basÃ©es sur l'analyse
$recommendations = @()

# Recommandation pour les identifiants de tÃ¢ches
if ($null -ne $conventions.TaskIdentifiers.Pattern) {
    $recommendations += "- **Identifiants de tÃ¢ches:** Continuer Ã  utiliser le format de numÃ©rotation hiÃ©rarchique (ex: $($conventions.TaskIdentifiers.Examples[0])) pour maintenir la cohÃ©rence."
} else {
    $recommendations += "- **Identifiants de tÃ¢ches:** Envisager d'adopter un format de numÃ©rotation hiÃ©rarchique (ex: 1.2.3) pour faciliter le suivi et la rÃ©fÃ©rence des tÃ¢ches."
}

# Recommandation pour les indicateurs de prioritÃ©
if ($null -ne $conventions.PriorityIndicators.Pattern) {
    $recommendations += "- **Indicateurs de prioritÃ©:** Continuer Ã  utiliser le format actuel pour indiquer les prioritÃ©s."
} else {
    $recommendations += "- **Indicateurs de prioritÃ©:** Envisager d'adopter un systÃ¨me d'indicateurs de prioritÃ© (ex: [PRIORITY: HIGH], (P1), !!!) pour faciliter la gestion des tÃ¢ches importantes."
}

# Recommandation pour les indicateurs de statut
if ($null -ne $conventions.StatusIndicators.Pattern) {
    $recommendations += "- **Indicateurs de statut:** Continuer Ã  utiliser le format actuel pour indiquer les statuts spÃ©cifiques."
} else {
    $recommendations += "- **Indicateurs de statut:** Envisager d'adopter des indicateurs de statut supplÃ©mentaires (ex: @in-progress, [STATUS: BLOCKED]) pour mieux reflÃ©ter l'Ã©tat des tÃ¢ches."
}

# Recommandation pour les sections spÃ©ciales
if ($conventions.SpecialSections.Count -gt 0) {
    $recommendations += "- **Sections spÃ©ciales:** Continuer Ã  utiliser les sections spÃ©ciales pour organiser le contenu."
} else {
    $recommendations += "- **Sections spÃ©ciales:** Envisager d'ajouter des sections spÃ©ciales (ex: TODO, BACKLOG, NOTES) pour mieux organiser le contenu de la roadmap."
}

# Ajouter les recommandations au rapport
if ($recommendations.Count -gt 0) {
    $report += $recommendations -join "`n"
} else {
    $report += "Aucune recommandation spÃ©cifique. Les conventions actuelles semblent cohÃ©rentes."
}

# Enregistrer le rapport dans un fichier
$report | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "Rapport gÃ©nÃ©rÃ©: $OutputPath" -ForegroundColor Green
Write-Host "Analyse terminÃ©e." -ForegroundColor Cyan
