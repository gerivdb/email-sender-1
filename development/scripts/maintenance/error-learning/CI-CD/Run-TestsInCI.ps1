<#
.SYNOPSIS
    Script pour exÃ©cuter les tests dans un pipeline CI/CD.
.DESCRIPTION
    Ce script exÃ©cute tous les tests qui fonctionnent correctement du systÃ¨me d'apprentissage des erreurs
    dans un pipeline CI/CD et gÃ©nÃ¨re un rapport des rÃ©sultats.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats des tests. Par dÃ©faut, utilise le rÃ©pertoire courant.
.EXAMPLE
    .\Run-TestsInCI.ps1
    ExÃ©cute tous les tests qui fonctionnent correctement et gÃ©nÃ¨re un rapport XML des rÃ©sultats.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestResults")
)

# VÃ©rifier que Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# DÃ©finir le chemin des tests qui fonctionnent correctement
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$testFiles = @(
    (Join-Path -Path $scriptRoot -ChildPath "Tests\VeryBasic.Tests.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Tests\Basic.Tests.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Tests\SimpleIntegration.Tests.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Tests\ErrorFunctions.Tests.ps1")
)

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# DÃ©finir la configuration Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testFiles
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "TestResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = @(
    (Join-Path -Path $scriptRoot -ChildPath "ErrorLearningSystem.psm1"),
    (Join-Path -Path $scriptRoot -ChildPath "Analyze-ScriptForErrors.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Auto-CorrectErrors.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Adaptive-ErrorCorrection.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Validate-ErrorCorrections.ps1")
)
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "CodeCoverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests..." -ForegroundColor Cyan
$totalTests = 0
$passedTests = 0
$failedTests = 0
$skippedTests = 0

# ExÃ©cuter chaque test individuellement
foreach ($testFile in $testFiles) {
    Write-Host "  ExÃ©cution de $([System.IO.Path]::GetFileName($testFile))..." -ForegroundColor Yellow
    
    # ExÃ©cuter le test
    $testConfig = New-PesterConfiguration
    $testConfig.Run.Path = $testFile
    $testConfig.Output.Verbosity = "Detailed"
    
    $result = Invoke-Pester -Configuration $testConfig -PassThru
    
    # Mettre Ã  jour les rÃ©sultats
    $totalTests += $result.TotalCount
    $passedTests += $result.PassedCount
    $failedTests += $result.FailedCount
    $skippedTests += $result.SkippedCount
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $totalTests" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $passedTests" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $failedTests" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $skippedTests" -ForegroundColor Yellow
Write-Host

# GÃ©nÃ©rer un rapport XML des rÃ©sultats
$testResults = [PSCustomObject]@{
    TotalCount = $totalTests
    PassedCount = $passedTests
    FailedCount = $failedTests
    SkippedCount = $skippedTests
}

# Convertir les rÃ©sultats en XML
$xmlWriter = New-Object System.Xml.XmlTextWriter((Join-Path -Path $OutputPath -ChildPath "TestResults.xml"), $null)
$xmlWriter.Formatting = "Indented"
$xmlWriter.Indentation = 4
$xmlWriter.IndentChar = " "
$xmlWriter.WriteStartDocument()
$xmlWriter.WriteStartElement("testsuites")
$xmlWriter.WriteAttributeString("name", "ErrorLearningSystem")
$xmlWriter.WriteAttributeString("tests", $testResults.TotalCount)
$xmlWriter.WriteAttributeString("failures", $testResults.FailedCount)
$xmlWriter.WriteAttributeString("skipped", $testResults.SkippedCount)
$xmlWriter.WriteEndElement()
$xmlWriter.WriteEndDocument()
$xmlWriter.Flush()
$xmlWriter.Close()

# Afficher le chemin des rÃ©sultats
Write-Host "RÃ©sultats des tests enregistrÃ©s dans: $OutputPath" -ForegroundColor Cyan
Write-Host "  RÃ©sultats des tests: $(Join-Path -Path $OutputPath -ChildPath "TestResults.xml")" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basÃ© sur les rÃ©sultats des tests
exit $failedTests
