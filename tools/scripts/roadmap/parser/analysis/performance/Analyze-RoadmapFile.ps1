# Analyze-RoadmapFile.ps1
# Script pour analyser un fichier markdown de roadmap et générer un rapport

# Chemin vers le fichier de roadmap à analyser
$roadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $roadmapFilePath)) {
    Write-Error "Le fichier '$roadmapFilePath' n'existe pas."
    exit 1
}

# Chemin du répertoire de sortie pour les rapports
$outputDir = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\analysis"

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de sortie créé: $outputDir" -ForegroundColor Green
}

# Chemin du fichier de rapport
$reportFilePath = Join-Path -Path $outputDir -ChildPath "roadmap-structure-report.md"

# Exécuter l'analyse et générer le rapport
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Export-RoadmapStructureReport.ps1"
& $scriptPath -RoadmapFilePath $roadmapFilePath -OutputPath $reportFilePath

# Afficher les résultats de l'analyse
$testScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-RoadmapStructure.ps1"
& $testScriptPath -RoadmapFilePath $roadmapFilePath

Write-Host "`nRapport détaillé généré: $reportFilePath" -ForegroundColor Green
Write-Host "Analyse terminée." -ForegroundColor Cyan
