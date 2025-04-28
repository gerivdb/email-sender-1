# Run-RoadmapAnalysis.ps1
# Script principal pour exÃ©cuter toutes les analyses sur un fichier markdown de roadmap

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\analysis"
)

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de sortie crÃ©Ã©: $OutputDir" -ForegroundColor Green
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
Write-Host "Analyse complÃ¨te du fichier de roadmap" -ForegroundColor Cyan
Write-Host "Fichier Ã  analyser: $RoadmapFilePath" -ForegroundColor Cyan
Write-Host "RÃ©pertoire de sortie: $OutputDir" -ForegroundColor Cyan

# Ã‰tape 1: ExÃ©cuter l'analyse de base de la structure
Write-Host "`n[1/3] ExÃ©cution de l'analyse de base de la structure..." -ForegroundColor Yellow
& $testScriptPath -RoadmapFilePath $RoadmapFilePath

# Ã‰tape 2: GÃ©nÃ©rer le rapport dÃ©taillÃ©
Write-Host "`n[2/3] GÃ©nÃ©ration du rapport dÃ©taillÃ©..." -ForegroundColor Yellow
& $reportScriptPath -RoadmapFilePath $RoadmapFilePath -OutputPath $reportFilePath
Write-Host "Rapport gÃ©nÃ©rÃ©: $reportFilePath" -ForegroundColor Green

# Ã‰tape 3: Analyser les conventions spÃ©cifiques au projet
Write-Host "`n[3/3] Analyse des conventions spÃ©cifiques au projet..." -ForegroundColor Yellow
$conventionsOutput = & $conventionsScriptPath -RoadmapFilePath $RoadmapFilePath

# Enregistrer les rÃ©sultats des conventions dans un fichier
$conventionsReport = @"
# Conventions SpÃ©cifiques au Projet

**Fichier analysÃ©:** `$RoadmapFilePath`  
**Date d'analyse:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

$($conventionsOutput -join "`n")
"@

$conventionsReport | Out-File -FilePath $conventionsFilePath -Encoding UTF8
Write-Host "Rapport des conventions gÃ©nÃ©rÃ©: $conventionsFilePath" -ForegroundColor Green

# RÃ©sumÃ©
Write-Host "`nAnalyse complÃ¨te terminÃ©e." -ForegroundColor Cyan
Write-Host "Fichiers gÃ©nÃ©rÃ©s:" -ForegroundColor Green
Write-Host "1. Rapport de structure: $reportFilePath" -ForegroundColor Green
Write-Host "2. Rapport des conventions: $conventionsFilePath" -ForegroundColor Green
