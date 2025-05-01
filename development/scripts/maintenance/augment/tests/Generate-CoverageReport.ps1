<#
.SYNOPSIS
    Génère un rapport de couverture de code pour l'intégration avec Augment Code.

.DESCRIPTION
    Ce script génère un rapport de couverture de code pour l'intégration avec Augment Code,
    en utilisant le framework Pester et le module PSCoverage.

.PARAMETER OutputPath
    Chemin vers le répertoire de sortie pour le rapport de couverture.
    Par défaut : "reports\augment\coverage".

.EXAMPLE
    .\Generate-CoverageReport.ps1
    # Génère un rapport de couverture de code

.EXAMPLE
    .\Generate-CoverageReport.ps1 -OutputPath "C:\temp\coverage"
    # Génère un rapport de couverture de code dans le répertoire spécifié

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$OutputPath = "reports\augment\coverage"
)

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer PSCoverage si nécessaire
if (-not (Get-Module -Name PSCoverage -ListAvailable)) {
    Write-Warning "Le module PSCoverage n'est pas installé. Installation en cours..."
    Install-Module -Name PSCoverage -Force -SkipPublisherCheck
}

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Créer le répertoire de sortie s'il n'existe pas
$outputPath = Join-Path -Path $projectRoot -ChildPath $OutputPath
if (-not (Test-Path -Path $outputPath -PathType Container)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

# Obtenir la liste des fichiers de script à tester
$scriptFiles = @(
    "AugmentIntegration.psm1",
    "AugmentMemoriesManager.ps1",
    "mcp-memories-server.ps1",
    "mcp-mode-manager-adapter.ps1",
    "mode-manager-augment-integration.ps1",
    "optimize-augment-memories.ps1",
    "configure-augment-mcp.ps1",
    "start-mcp-servers.ps1",
    "analyze-augment-performance.ps1",
    "sync-memories-with-n8n.ps1",
    "generate-usage-report.ps1",
    "test-augment-integration.ps1"
)

$scriptPaths = $scriptFiles | ForEach-Object {
    Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\$_"
} | Where-Object { Test-Path -Path $_ }

# Obtenir la liste des fichiers de test
$testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "Test-*.ps1" | Select-Object -ExpandProperty FullName

# Afficher les fichiers trouvés
Write-Host "Fichiers de script trouvés :" -ForegroundColor Cyan
foreach ($file in $scriptPaths) {
    Write-Host "- $file" -ForegroundColor Gray
}

Write-Host "`nFichiers de test trouvés :" -ForegroundColor Cyan
foreach ($file in $testFiles) {
    Write-Host "- $file" -ForegroundColor Gray
}

# Configurer Pester pour la couverture de code
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testFiles
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = $scriptPaths
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $outputPath -ChildPath "coverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"

# Exécuter les tests avec couverture de code
Write-Host "`nExécution des tests avec couverture de code..." -ForegroundColor Cyan
$results = Invoke-Pester -Configuration $pesterConfig

# Générer un rapport HTML de couverture de code
Write-Host "`nGénération du rapport HTML de couverture de code..." -ForegroundColor Cyan
try {
    Import-Module PSCoverage
    $coverageXmlPath = Join-Path -Path $outputPath -ChildPath "coverage.xml"
    $coverageHtmlPath = Join-Path -Path $outputPath -ChildPath "index.html"
    
    if (Test-Path -Path $coverageXmlPath) {
        ConvertTo-CoverageReport -Path $coverageXmlPath -OutputPath $coverageHtmlPath -Format HTML
        Write-Host "Rapport HTML de couverture de code généré : $coverageHtmlPath" -ForegroundColor Green
    } else {
        Write-Warning "Fichier XML de couverture de code introuvable : $coverageXmlPath"
    }
} catch {
    Write-Warning "Erreur lors de la génération du rapport HTML de couverture de code : $_"
}

# Afficher un résumé
Write-Host "`nRésumé de la couverture de code :" -ForegroundColor Cyan
if ($results.CodeCoverage) {
    $totalCommands = $results.CodeCoverage.CommandsAnalyzedCount
    $hitCommands = $results.CodeCoverage.CommandsExecutedCount
    $missedCommands = $results.CodeCoverage.CommandsMissedCount
    $coveragePercent = if ($totalCommands -gt 0) { [math]::Round(($hitCommands / $totalCommands) * 100, 2) } else { 0 }
    
    Write-Host "Commandes analysées : $totalCommands" -ForegroundColor Gray
    Write-Host "Commandes exécutées : $hitCommands" -ForegroundColor Green
    Write-Host "Commandes non exécutées : $missedCommands" -ForegroundColor $(if ($missedCommands -eq 0) { "Green" } else { "Yellow" })
    Write-Host "Couverture de code : $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 80) { "Green" } elseif ($coveragePercent -ge 60) { "Yellow" } else { "Red" })
    
    # Afficher les fichiers avec une faible couverture
    $lowCoverageFiles = $results.CodeCoverage.CommandsMissedPerFile | Where-Object { $_.Value -gt 0 }
    if ($lowCoverageFiles) {
        Write-Host "`nFichiers avec une couverture incomplète :" -ForegroundColor Yellow
        foreach ($file in $lowCoverageFiles.GetEnumerator()) {
            $filePath = $file.Key
            $missedCommands = $file.Value
            $analyzedCommands = $results.CodeCoverage.CommandsAnalyzedPerFile[$filePath]
            $coveragePercent = if ($analyzedCommands -gt 0) { [math]::Round((($analyzedCommands - $missedCommands) / $analyzedCommands) * 100, 2) } else { 0 }
            
            Write-Host "- $filePath : $coveragePercent% ($missedCommands commandes non exécutées)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Warning "Aucune information de couverture de code disponible."
}

# Afficher le chemin du rapport
Write-Host "`nRapport de couverture de code enregistré : $outputPath" -ForegroundColor Green

# Retourner le code de sortie
exit $results.FailedCount
