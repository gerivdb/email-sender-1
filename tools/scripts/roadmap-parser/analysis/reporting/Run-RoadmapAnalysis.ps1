# Run-RoadmapAnalysis.ps1
# Script principal pour exécuter toutes les analyses sur un fichier markdown de roadmap

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\analysis"
)

# Vérifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de sortie créé: $OutputDir" -ForegroundColor Green
}

# Chemins des scripts
$scriptDir = $PSScriptRoot
$testScriptPath = Join-Path -Path $scriptDir -ChildPath "Test-RoadmapStructure.ps1"
$reportScriptPath = Join-Path -Path $scriptDir -ChildPath "Export-RoadmapStructureReport.ps1"
$conventionsScriptPath = Join-Path -Path $scriptDir -ChildPath "Get-ProjectSpecificConventions.ps1"

# Chemins des fichiers de sortie
$reportFilePath = Join-Path -Path $OutputDir -ChildPath "roadmap-structure-report.md"
$conventionsFilePath = Join-Path -Path $OutputDir -ChildPath "project-conventions.md"

# Afficher les informations
Write-Host "Analyse complète du fichier de roadmap" -ForegroundColor Cyan
Write-Host "Fichier à analyser: $RoadmapFilePath" -ForegroundColor Cyan
Write-Host "Répertoire de sortie: $OutputDir" -ForegroundColor Cyan

# Étape 1: Exécuter l'analyse de base de la structure
Write-Host "`n[1/3] Exécution de l'analyse de base de la structure..." -ForegroundColor Yellow
& $testScriptPath -RoadmapFilePath $RoadmapFilePath

# Étape 2: Générer le rapport détaillé
Write-Host "`n[2/3] Génération du rapport détaillé..." -ForegroundColor Yellow
& $reportScriptPath -RoadmapFilePath $RoadmapFilePath -OutputPath $reportFilePath
Write-Host "Rapport généré: $reportFilePath" -ForegroundColor Green

# Étape 3: Analyser les conventions spécifiques au projet
Write-Host "`n[3/3] Analyse des conventions spécifiques au projet..." -ForegroundColor Yellow
$conventionsOutput = & $conventionsScriptPath -RoadmapFilePath $RoadmapFilePath

# Enregistrer les résultats des conventions dans un fichier
$conventionsReport = @"
# Conventions Spécifiques au Projet

**Fichier analysé:** `$RoadmapFilePath`  
**Date d'analyse:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

$($conventionsOutput -join "`n")
"@

$conventionsReport | Out-File -FilePath $conventionsFilePath -Encoding UTF8
Write-Host "Rapport des conventions généré: $conventionsFilePath" -ForegroundColor Green

# Résumé
Write-Host "`nAnalyse complète terminée." -ForegroundColor Cyan
Write-Host "Fichiers générés:" -ForegroundColor Green
Write-Host "1. Rapport de structure: $reportFilePath" -ForegroundColor Green
Write-Host "2. Rapport des conventions: $conventionsFilePath" -ForegroundColor Green
