<#
.SYNOPSIS
    Script pour exÃ©cuter tous les tests unitaires et d'intÃ©gration du systÃ¨me d'apprentissage des erreurs.
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires et d'intÃ©gration du systÃ¨me d'apprentissage des erreurs
    et gÃ©nÃ¨re un rapport des rÃ©sultats.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats des tests. Par dÃ©faut, utilise le rÃ©pertoire courant.
.PARAMETER GenerateReport
    Si spÃ©cifiÃ©, gÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests.
.PARAMETER TestType
    Type de tests Ã  exÃ©cuter. Valeurs possibles : 'All', 'Unit', 'Integration'. Par dÃ©faut, 'All'.
.EXAMPLE
    .\Run-AllTests.ps1 -GenerateReport
    ExÃ©cute tous les tests unitaires et d'intÃ©gration et gÃ©nÃ¨re un rapport HTML des rÃ©sultats.
.EXAMPLE
    .\Run-AllTests.ps1 -TestType Unit
    ExÃ©cute uniquement les tests unitaires.
.EXAMPLE
    .\Run-AllTests.ps1 -TestType Integration
    ExÃ©cute uniquement les tests d'intÃ©gration.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [ValidateSet('All', 'Unit', 'Integration')]
    [string]$TestType = 'All'
)

# VÃ©rifier que Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# DÃ©finir le chemin des tests
$testRoot = Join-Path -Path $PSScriptRoot -ChildPath "Tests"

# Filtrer les tests en fonction du type de test demandÃ©
if ($TestType -eq 'Unit') {
    $testFiles = Get-ChildItem -Path $testRoot -Filter "*.Tests.ps1" -Recurse | Where-Object { $_.Name -notmatch '\.Integration\.Tests\.ps1$' }
    Write-Host "Tests unitaires trouvÃ©s :" -ForegroundColor Cyan
}
elseif ($TestType -eq 'Integration') {
    $testFiles = Get-ChildItem -Path $testRoot -Filter "*.Integration.Tests.ps1" -Recurse
    Write-Host "Tests d'intÃ©gration trouvÃ©s :" -ForegroundColor Cyan
}
else {
    $testFiles = Get-ChildItem -Path $testRoot -Filter "*.Tests.ps1" -Recurse
    Write-Host "Tous les tests trouvÃ©s :" -ForegroundColor Cyan
}

# Afficher les tests trouvÃ©s
foreach ($testFile in $testFiles) {
    Write-Host "  $($testFile.Name)" -ForegroundColor Yellow
}

# DÃ©finir la configuration Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = @() # Nous allons exÃ©cuter les tests un par un
$pesterConfig.Output.Verbosity = "Detailed"

if ($GenerateReport) {
    $reportPath = Join-Path -Path $OutputPath -ChildPath "TestResults"
    if (-not (Test-Path -Path $reportPath)) {
        New-Item -Path $reportPath -ItemType Directory -Force | Out-Null
    }

    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path -Path $reportPath -ChildPath "TestResults.xml"
    $pesterConfig.TestResult.OutputFormat = "NUnitXml"

    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = @(
        (Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Analyze-ScriptForErrors.ps1"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Auto-CorrectErrors.ps1"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Adaptive-ErrorCorrection.ps1"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Validate-ErrorCorrections.ps1")
    )
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $reportPath -ChildPath "CodeCoverage.xml"
    $pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"
}

# ExÃ©cuter les tests un par un
Write-Host "`nExÃ©cution des tests..." -ForegroundColor Cyan

# Initialiser les rÃ©sultats
$totalTests = 0
$passedTests = 0
$failedTests = 0
$skippedTests = 0

# ExÃ©cuter chaque test individuellement
foreach ($testFile in $testFiles) {
    Write-Host "  ExÃ©cution de $($testFile.Name)..." -ForegroundColor Yellow

    # ExÃ©cuter le test avec Invoke-Pester directement (sans utiliser le fichier de test)
    $testConfig = New-PesterConfiguration
    $testConfig.Run.Path = $testFile.FullName
    $testConfig.Output.Verbosity = "Detailed"

    if ($GenerateReport) {
        $testConfig.TestResult.Enabled = $true
        $testConfig.TestResult.OutputPath = Join-Path -Path $reportPath -ChildPath "$($testFile.BaseName).xml"
        $testConfig.TestResult.OutputFormat = "NUnitXml"
    }

    $result = Invoke-Pester -Configuration $testConfig

    # Mettre Ã  jour les rÃ©sultats
    $totalTests += $result.TotalCount
    $passedTests += $result.PassedCount
    $failedTests += $result.FailedCount
    $skippedTests += $result.SkippedCount
}

# CrÃ©er un objet de rÃ©sultats global
$testResults = [PSCustomObject]@{
    TotalCount = $totalTests
    PassedCount = $passedTests
    FailedCount = $failedTests
    SkippedCount = $skippedTests
}

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateReport) {
    Write-Host "`nGÃ©nÃ©ration du rapport HTML..." -ForegroundColor Yellow

    # VÃ©rifier si ReportUnit est installÃ©
    $reportUnitPath = Join-Path -Path $env:TEMP -ChildPath "ReportUnit.exe"

    if (-not (Test-Path -Path $reportUnitPath)) {
        Write-Host "TÃ©lÃ©chargement de ReportUnit..." -ForegroundColor Yellow
        $reportUnitUrl = "https://github.com/reportunit/reportunit/releases/download/1.2.1/ReportUnit.exe"
        Invoke-WebRequest -Uri $reportUnitUrl -OutFile $reportUnitPath
    }

    # GÃ©nÃ©rer le rapport HTML
    $reportXmlPath = Join-Path -Path $reportPath -ChildPath "TestResults.xml"
    $reportHtmlPath = Join-Path -Path $reportPath -ChildPath "TestResults.html"

    if (Test-Path -Path $reportXmlPath) {
        & $reportUnitPath $reportXmlPath $reportPath

        if (Test-Path -Path $reportHtmlPath) {
            Write-Host "Rapport HTML gÃ©nÃ©rÃ©: $reportHtmlPath" -ForegroundColor Green
            Start-Process $reportHtmlPath
        }
        else {
            Write-Warning "Ã‰chec de la gÃ©nÃ©ration du rapport HTML."
        }
    }
    else {
        Write-Warning "Fichier de rÃ©sultats XML non trouvÃ©: $reportXmlPath"
    }
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $($testResults.SkippedCount)" -ForegroundColor Yellow

# Afficher le type de tests exÃ©cutÃ©s
Write-Host "`nType de tests exÃ©cutÃ©s: $TestType" -ForegroundColor Cyan
Write-Host

# Retourner un code de sortie basÃ© sur les rÃ©sultats des tests
exit $testResults.FailedCount
