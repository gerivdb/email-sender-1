#Requires -Version 5.1
<#
.SYNOPSIS
    Script pour exécuter les tests dans un environnement CI/CD.
.DESCRIPTION
    Ce script exécute tous les tests unitaires et génère des rapports de couverture
    et de résultats au format compatible avec les systèmes CI/CD.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = "$PSScriptRoot\TestResults",
    
    [Parameter()]
    [int]$ThresholdPercent = 70
)

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -MinimumVersion 5.0

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'

# Configuration de la couverture de code
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = @(
    "$PSScriptRoot\..\benchmark.ps1",
    "$PSScriptRoot\..\Optimize-ParallelBatchSize.ps1"
)
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
$pesterConfig.CodeCoverage.OutputPath = "$OutputPath\coverage.xml"

# Configuration des résultats de test
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'
$pesterConfig.TestResult.OutputPath = "$OutputPath\TestResults.xml"

# Exécuter les tests
Write-Host "Exécution des tests..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "  Tests exécutés : $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis  : $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués  : $($testResults.FailedCount)" -ForegroundColor ($testResults.FailedCount -gt 0 ? "Red" : "Green")
Write-Host "  Tests ignorés  : $($testResults.SkippedCount)" -ForegroundColor Yellow

# Vérifier la couverture de code
if ($pesterConfig.CodeCoverage.Enabled) {
    $coveragePercent = [Math]::Round($testResults.CodeCoverage.CoveragePercent, 2)
    
    Write-Host "`nCouverture de code :" -ForegroundColor Cyan
    Write-Host "  Couverture totale : $coveragePercent%" -ForegroundColor ($coveragePercent -ge $ThresholdPercent ? "Green" : "Red")
    Write-Host "  Seuil minimal     : $ThresholdPercent%" -ForegroundColor White
    Write-Host "  Rapport de couverture : $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor White
    
    # Vérifier si la couverture est suffisante
    if ($coveragePercent -lt $ThresholdPercent) {
        Write-Host "`nAttention : La couverture de code est inférieure au seuil minimal." -ForegroundColor Red
        
        # Afficher les lignes non couvertes
        Write-Host "`nLignes non couvertes :" -ForegroundColor Yellow
        foreach ($file in $testResults.CodeCoverage.MissedCommands) {
            Write-Host "  $($file.File) : Ligne $($file.Line)" -ForegroundColor Yellow
        }
        
        # En environnement CI, on pourrait vouloir échouer le build
        # exit 1
    }
}

# Vérifier si tous les tests ont réussi
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nAttention : Certains tests ont échoué." -ForegroundColor Red
    
    # Afficher les tests qui ont échoué
    Write-Host "`nTests échoués :" -ForegroundColor Yellow
    foreach ($test in $testResults.Failed) {
        Write-Host "  $($test.Name)" -ForegroundColor Yellow
        Write-Host "    $($test.ErrorRecord.Exception.Message)" -ForegroundColor Red
    }
    
    # En environnement CI, on pourrait vouloir échouer le build
    # exit 1
}

# Retourner les résultats
return $testResults
