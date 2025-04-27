#Requires -Version 5.1
<#
.SYNOPSIS
    Script pour exÃ©cuter les tests dans un environnement CI/CD.
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires et gÃ©nÃ¨re des rapports de couverture
    et de rÃ©sultats au format compatible avec les systÃ¨mes CI/CD.
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

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# VÃ©rifier si Pester est installÃ©
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

# Configuration des rÃ©sultats de test
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'
$pesterConfig.TestResult.OutputPath = "$OutputPath\TestResults.xml"

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s : $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis  : $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s  : $($testResults.FailedCount)" -ForegroundColor ($testResults.FailedCount -gt 0 ? "Red" : "Green")
Write-Host "  Tests ignorÃ©s  : $($testResults.SkippedCount)" -ForegroundColor Yellow

# VÃ©rifier la couverture de code
if ($pesterConfig.CodeCoverage.Enabled) {
    $coveragePercent = [Math]::Round($testResults.CodeCoverage.CoveragePercent, 2)
    
    Write-Host "`nCouverture de code :" -ForegroundColor Cyan
    Write-Host "  Couverture totale : $coveragePercent%" -ForegroundColor ($coveragePercent -ge $ThresholdPercent ? "Green" : "Red")
    Write-Host "  Seuil minimal     : $ThresholdPercent%" -ForegroundColor White
    Write-Host "  Rapport de couverture : $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor White
    
    # VÃ©rifier si la couverture est suffisante
    if ($coveragePercent -lt $ThresholdPercent) {
        Write-Host "`nAttention : La couverture de code est infÃ©rieure au seuil minimal." -ForegroundColor Red
        
        # Afficher les lignes non couvertes
        Write-Host "`nLignes non couvertes :" -ForegroundColor Yellow
        foreach ($file in $testResults.CodeCoverage.MissedCommands) {
            Write-Host "  $($file.File) : Ligne $($file.Line)" -ForegroundColor Yellow
        }
        
        # En environnement CI, on pourrait vouloir Ã©chouer le build
        # exit 1
    }
}

# VÃ©rifier si tous les tests ont rÃ©ussi
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nAttention : Certains tests ont Ã©chouÃ©." -ForegroundColor Red
    
    # Afficher les tests qui ont Ã©chouÃ©
    Write-Host "`nTests Ã©chouÃ©s :" -ForegroundColor Yellow
    foreach ($test in $testResults.Failed) {
        Write-Host "  $($test.Name)" -ForegroundColor Yellow
        Write-Host "    $($test.ErrorRecord.Exception.Message)" -ForegroundColor Red
    }
    
    # En environnement CI, on pourrait vouloir Ã©chouer le build
    # exit 1
}

# Retourner les rÃ©sultats
return $testResults
