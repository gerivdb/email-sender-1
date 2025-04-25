# Generate-ConventionsReport.ps1
# Script pour générer un rapport sur les conventions spécifiques au projet

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\analysis\conventions-report.md"
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

# Lire le contenu du fichier
$content = Get-Content -Path $RoadmapFilePath -Encoding UTF8 -Raw

# Analyser les conventions spécifiques au projet
Write-Host "Analyse des conventions spécifiques au projet dans: $RoadmapFilePath" -ForegroundColor Cyan
$conventions = Get-ProjectConventions -Content $content

# Générer le rapport
$report = "# Conventions Spécifiques au Projet`r`n`r`n"
$report += "**Fichier analysé:** $RoadmapFilePath`r`n"
$report += "**Date d'analyse:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n`r`n"
$report += "## 1. Identifiants de Tâches`r`n`r`n"

if ($null -eq $conventions.TaskIdentifiers.Pattern) {
    $report += "Aucun format d'identifiant de tâche spécifique détecté.`r`n`r`n"
} else {
    $report += "**Format détecté:** $($conventions.TaskIdentifiers.Pattern)`r`n`r`n"
    $report += "**Exemples:**`r`n`r`n"
    foreach ($example in $conventions.TaskIdentifiers.Examples) {
        $report += "- $example`r`n"
    }
    $report += "`r`n"
}

$report += "## 2. Indicateurs de Priorité`r`n`r`n"

if ($null -eq $conventions.PriorityIndicators.Pattern) {
    $report += "Aucun indicateur de priorité spécifique détecté.`r`n`r`n"
} else {
    $report += "**Format détecté:** $($conventions.PriorityIndicators.Pattern)`r`n`r`n"
    $report += "**Exemples:**`r`n`r`n"
    foreach ($example in $conventions.PriorityIndicators.Examples) {
        $report += "- $example`r`n"
    }
    $report += "`r`n"
}

$report += "## 3. Indicateurs de Statut`r`n`r`n"

if ($null -eq $conventions.StatusIndicators.Pattern) {
    $report += "Aucun indicateur de statut spécifique détecté.`r`n`r`n"
} else {
    $report += "**Format détecté:** $($conventions.StatusIndicators.Pattern)`r`n`r`n"
    $report += "**Exemples:**`r`n`r`n"
    foreach ($example in $conventions.StatusIndicators.Examples) {
        $report += "- $example`r`n"
    }
    $report += "`r`n"
}

$report += "## 4. Sections Spéciales`r`n`r`n"

if ($conventions.SpecialSections.Count -eq 0) {
    $report += "Aucune section spéciale détectée.`r`n`r`n"
} else {
    $report += "**Sections détectées:**`r`n`r`n"
    foreach ($section in $conventions.SpecialSections) {
        $report += "- $section`r`n"
    }
    $report += "`r`n"
}

$report += "## 5. Format des Métadonnées`r`n`r`n"

if ($null -eq $conventions.MetadataFormat) {
    $report += "Aucun format de métadonnées spécifique détecté.`r`n`r`n"
} else {
    $report += "**Format détecté:** $($conventions.MetadataFormat)`r`n`r`n"
}

$report += "## 6. Recommandations`r`n`r`n"
$report += "Basé sur l'analyse des conventions spécifiques au projet, voici quelques recommandations:`r`n`r`n"

# Générer des recommandations basées sur l'analyse
$recommendations = @()

# Recommandation pour les identifiants de tâches
if ($null -ne $conventions.TaskIdentifiers.Pattern) {
    $recommendations += "- **Identifiants de tâches:** Continuer à utiliser le format de numérotation hiérarchique (ex: $($conventions.TaskIdentifiers.Examples[0])) pour maintenir la cohérence."
} else {
    $recommendations += "- **Identifiants de tâches:** Envisager d'adopter un format de numérotation hiérarchique (ex: 1.2.3) pour faciliter le suivi et la référence des tâches."
}

# Recommandation pour les indicateurs de priorité
if ($null -ne $conventions.PriorityIndicators.Pattern) {
    $recommendations += "- **Indicateurs de priorité:** Continuer à utiliser le format actuel pour indiquer les priorités."
} else {
    $recommendations += "- **Indicateurs de priorité:** Envisager d'adopter un système d'indicateurs de priorité (ex: [PRIORITY: HIGH], (P1), !!!) pour faciliter la gestion des tâches importantes."
}

# Recommandation pour les indicateurs de statut
if ($null -ne $conventions.StatusIndicators.Pattern) {
    $recommendations += "- **Indicateurs de statut:** Continuer à utiliser le format actuel pour indiquer les statuts spécifiques."
} else {
    $recommendations += "- **Indicateurs de statut:** Envisager d'adopter des indicateurs de statut supplémentaires (ex: @in-progress, [STATUS: BLOCKED]) pour mieux refléter l'état des tâches."
}

# Recommandation pour les sections spéciales
if ($conventions.SpecialSections.Count -gt 0) {
    $recommendations += "- **Sections spéciales:** Continuer à utiliser les sections spéciales pour organiser le contenu."
} else {
    $recommendations += "- **Sections spéciales:** Envisager d'ajouter des sections spéciales (ex: TODO, BACKLOG, NOTES) pour mieux organiser le contenu de la roadmap."
}

# Ajouter les recommandations au rapport
if ($recommendations.Count -gt 0) {
    $report += $recommendations -join "`n"
} else {
    $report += "Aucune recommandation spécifique. Les conventions actuelles semblent cohérentes."
}

# Enregistrer le rapport dans un fichier
$report | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "Rapport généré: $OutputPath" -ForegroundColor Green
Write-Host "Analyse terminée." -ForegroundColor Cyan
