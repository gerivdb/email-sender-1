# Analyze-RoadmapFile.ps1
# Script pour analyser un fichier markdown de roadmap et gÃ©nÃ©rer un rapport

# Chemin vers le fichier de roadmap Ã  analyser
$roadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $roadmapFilePath)) {
    Write-Error "Le fichier '$roadmapFilePath' n'existe pas."
    exit 1
}

# Chemin du rÃ©pertoire de sortie pour les rapports
$outputDir = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\analysis"

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de sortie crÃ©Ã©: $outputDir" -ForegroundColor Green
}

# Chemin du fichier de rapport
$reportFilePath = Join-Path -Path $outputDir -ChildPath "roadmap-structure-report.md"

# ExÃ©cuter l'analyse et gÃ©nÃ©rer le rapport
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Export-RoadmapStructureReport.ps1"
& $scriptPath -RoadmapFilePath $roadmapFilePath -OutputPath $reportFilePath

# Afficher les rÃ©sultats de l'analyse
$testScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-RoadmapStructure.ps1"
& $testScriptPath -RoadmapFilePath $roadmapFilePath

Write-Host "`nRapport dÃ©taillÃ© gÃ©nÃ©rÃ©: $reportFilePath" -ForegroundColor Green
Write-Host "Analyse terminÃ©e." -ForegroundColor Cyan
