#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests et génère des rapports pour les fonctionnalités de détection de format.

.DESCRIPTION
    Ce script exécute tous les tests unitaires et génère des rapports de test et de couverture
    de code pour les fonctionnalités de détection de format développées dans le cadre de la
    section 2.1.2 de la roadmap.

.PARAMETER OutputDirectory
    Le répertoire où les rapports seront enregistrés. Par défaut, 'reports'.

.PARAMETER GenerateHtmlReports
    Indique si des rapports HTML doivent être générés en plus des rapports XML.

.EXAMPLE
    .\Run-AllTests.ps1 -GenerateHtmlReports

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputDirectory = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\reports",

    [Parameter()]
    [switch]$GenerateHtmlReports
)

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de sortie créé : $OutputDirectory" -ForegroundColor Green
}

# Chemins des rapports
$testResultsPath = Join-Path -Path $OutputDirectory -ChildPath "TestResults.xml"
$codeCoveragePath = Join-Path -Path $OutputDirectory -ChildPath "CodeCoverage.xml"

# Exécuter les tests unitaires
Write-Host "`nExécution des tests unitaires..." -ForegroundColor Cyan
$unitTestsScript = Join-Path -Path $PSScriptRoot -ChildPath "Run-UnitTests.ps1"
if (Test-Path -Path $unitTestsScript -PathType Leaf) {
    $params = @{
        OutputPath = $testResultsPath
    }

    if ($GenerateHtmlReports) {
        $params.Add("GenerateHtmlReport", $true)
    }

    $testResults = & $unitTestsScript @params
}
else {
    Write-Warning "Le script de tests unitaires n'existe pas : $unitTestsScript"
}

# Générer le rapport de couverture de code
Write-Host "`nGénération du rapport de couverture de code..." -ForegroundColor Cyan
$codeCoverageScript = Join-Path -Path $PSScriptRoot -ChildPath "Get-CodeCoverage.ps1"
if (Test-Path -Path $codeCoverageScript -PathType Leaf) {
    $params = @{
        OutputPath = $codeCoveragePath
    }

    if ($GenerateHtmlReports) {
        $params.Add("GenerateHtmlReport", $true)
    }

    $coverageResults = & $codeCoverageScript @params
}
else {
    Write-Warning "Le script de couverture de code n'existe pas : $codeCoverageScript"
}

# Afficher un résumé global
Write-Host "`nRésumé global des tests :" -ForegroundColor Cyan
if ($testResults) {
    Write-Host "  Tests exécutés : $($testResults.TotalCount)" -ForegroundColor White
    Write-Host "  Tests réussis  : $($testResults.PassedCount)" -ForegroundColor Green
    Write-Host "  Tests échoués  : $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -gt 0) { "Red" } else { "Green" })
    Write-Host "  Tests ignorés  : $($testResults.SkippedCount)" -ForegroundColor Yellow
}
else {
    Write-Host "  Aucun résultat de test disponible." -ForegroundColor Yellow
}

if ($coverageResults) {
    $totalCommands = $coverageResults.NumberOfCommandsAnalyzed
    $coveredCommands = $coverageResults.NumberOfCommandsExecuted
    $coveragePercent = if ($totalCommands -gt 0) { [Math]::Round(($coveredCommands / $totalCommands) * 100, 2) } else { 0 }

    Write-Host "`nRésumé de la couverture de code :" -ForegroundColor Cyan
    Write-Host "  Pourcentage de couverture : $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 80) { "Green" } elseif ($coveragePercent -ge 50) { "Yellow" } else { "Red" })
}
else {
    Write-Host "`n  Aucun résultat de couverture disponible." -ForegroundColor Yellow
}

# Afficher les chemins des rapports générés
Write-Host "`nRapports générés :" -ForegroundColor Cyan
if (Test-Path -Path $testResultsPath -PathType Leaf) {
    Write-Host "  Rapport de test : $testResultsPath" -ForegroundColor White

    if ($GenerateHtmlReports) {
        $htmlTestResultsPath = [System.IO.Path]::ChangeExtension($testResultsPath, "html")
        if (Test-Path -Path $htmlTestResultsPath -PathType Leaf) {
            Write-Host "  Rapport de test HTML : $htmlTestResultsPath" -ForegroundColor White
        }
    }
}

if (Test-Path -Path $codeCoveragePath -PathType Leaf) {
    Write-Host "  Rapport de couverture : $codeCoveragePath" -ForegroundColor White

    if ($GenerateHtmlReports) {
        $htmlCoveragePath = [System.IO.Path]::ChangeExtension($codeCoveragePath, "html")
        if (Test-Path -Path $htmlCoveragePath -PathType Leaf) {
            Write-Host "  Rapport de couverture HTML : $htmlCoveragePath" -ForegroundColor White
        }
    }
}
