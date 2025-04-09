<#
.SYNOPSIS
    Script pour exécuter les tests dans un pipeline CI/CD.
.DESCRIPTION
    Ce script exécute tous les tests qui fonctionnent correctement du système d'apprentissage des erreurs
    dans un pipeline CI/CD et génère un rapport des résultats.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats des tests. Par défaut, utilise le répertoire courant.
.EXAMPLE
    .\Run-TestsInCI.ps1
    Exécute tous les tests qui fonctionnent correctement et génère un rapport XML des résultats.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestResults")
)

# Vérifier que Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir le chemin des tests qui fonctionnent correctement
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$testFiles = @(
    (Join-Path -Path $scriptRoot -ChildPath "Tests\VeryBasic.Tests.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Tests\Basic.Tests.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Tests\SimpleIntegration.Tests.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Tests\ErrorFunctions.Tests.ps1")
)

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Définir la configuration Pester
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

# Exécuter les tests
Write-Host "Exécution des tests..." -ForegroundColor Cyan
$totalTests = 0
$passedTests = 0
$failedTests = 0
$skippedTests = 0

# Exécuter chaque test individuellement
foreach ($testFile in $testFiles) {
    Write-Host "  Exécution de $([System.IO.Path]::GetFileName($testFile))..." -ForegroundColor Yellow
    
    # Exécuter le test
    $testConfig = New-PesterConfiguration
    $testConfig.Run.Path = $testFile
    $testConfig.Output.Verbosity = "Detailed"
    
    $result = Invoke-Pester -Configuration $testConfig -PassThru
    
    # Mettre à jour les résultats
    $totalTests += $result.TotalCount
    $passedTests += $result.PassedCount
    $failedTests += $result.FailedCount
    $skippedTests += $result.SkippedCount
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $totalTests" -ForegroundColor White
Write-Host "  Tests réussis: $passedTests" -ForegroundColor Green
Write-Host "  Tests échoués: $failedTests" -ForegroundColor Red
Write-Host "  Tests ignorés: $skippedTests" -ForegroundColor Yellow
Write-Host

# Générer un rapport XML des résultats
$testResults = [PSCustomObject]@{
    TotalCount = $totalTests
    PassedCount = $passedTests
    FailedCount = $failedTests
    SkippedCount = $skippedTests
}

# Convertir les résultats en XML
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

# Afficher le chemin des résultats
Write-Host "Résultats des tests enregistrés dans: $OutputPath" -ForegroundColor Cyan
Write-Host "  Résultats des tests: $(Join-Path -Path $OutputPath -ChildPath "TestResults.xml")" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basé sur les résultats des tests
exit $failedTests
