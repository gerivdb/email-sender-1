<#
.SYNOPSIS
    Script d'intÃ©gration des tests du cache prÃ©dictif avec TestOmnibus.
.DESCRIPTION
    Ce script intÃ¨gre les tests du cache prÃ©dictif avec le systÃ¨me TestOmnibus
    pour une exÃ©cution centralisÃ©e et des rapports unifiÃ©s.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# DÃ©finir le rÃ©pertoire des tests
$testDirectory = $PSScriptRoot
$moduleDirectory = Split-Path -Path $testDirectory -Parent
$testOmnibusPath = Join-Path -Path (Split-Path -Path $moduleDirectory -Parent) -ChildPath "TestOmnibus\TestOmnibus.psm1"

# VÃ©rifier si TestOmnibus existe
if (-not (Test-Path -Path $testOmnibusPath)) {
    Write-Warning "Le module TestOmnibus n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $testOmnibusPath"
    Write-Warning "CrÃ©ation d'un rÃ©pertoire pour TestOmnibus..."

    # CrÃ©er le rÃ©pertoire pour TestOmnibus
    $testOmnibusDir = Split-Path -Path $testOmnibusPath -Parent
    if (-not (Test-Path -Path $testOmnibusDir)) {
        New-Item -Path $testOmnibusDir -ItemType Directory -Force | Out-Null
    }

    # CrÃ©er un module TestOmnibus minimal
    $testOmnibusContent = @'
#Requires -Version 5.1
<#
.SYNOPSIS
    Module TestOmnibus pour l'exÃ©cution centralisÃ©e des tests.
.DESCRIPTION
    Ce module permet d'exÃ©cuter et de gÃ©rer les tests de maniÃ¨re centralisÃ©e.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Fonction pour exÃ©cuter les tests
function Invoke-TestOmnibus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestPattern = "*",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport
    )

    # Importer Pester si nÃ©cessaire
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }

    # Importer Pester
    Import-Module Pester -MinimumVersion 5.0

    # Configurer les options de Pester
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $TestPattern
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Output.Verbosity = 'Detailed'

    if ($OutputPath) {
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
        $pesterConfig.TestResult.OutputPath = $OutputPath
    }

    # ExÃ©cuter les tests
    $testResults = Invoke-Pester -Configuration $pesterConfig

    # GÃ©nÃ©rer un rapport si demandÃ©
    if ($GenerateReport -and $OutputPath) {
        $reportPath = $OutputPath -replace '\.xml$', '_report.html'

        # CrÃ©er un rapport HTML simple
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de tests - TestOmnibus</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        .summary { background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .good { color: green; }
        .warning { color: orange; }
        .bad { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .tests-summary { display: flex; justify-content: space-between; }
        .test-stat { flex: 1; margin: 10px; padding: 15px; border-radius: 5px; text-align: center; }
        .passed { background-color: #dff0d8; }
        .failed { background-color: #f2dede; }
        .skipped { background-color: #fcf8e3; }
    </style>
</head>
<body>
    <h1>Rapport de tests - TestOmnibus</h1>

    <div class="tests-summary">
        <div class="test-stat passed">
            <h3>Tests rÃ©ussis</h3>
            <p>$($testResults.PassedCount)</p>
        </div>
        <div class="test-stat failed">
            <h3>Tests Ã©chouÃ©s</h3>
            <p>$($testResults.FailedCount)</p>
        </div>
        <div class="test-stat skipped">
            <h3>Tests ignorÃ©s</h3>
            <p>$($testResults.SkippedCount)</p>
        </div>
    </div>

    <div class="summary">
        <h2>RÃ©sumÃ© des tests</h2>
        <p>Tests exÃ©cutÃ©s: $($testResults.TotalCount)</p>
        <p>DurÃ©e totale: $([Math]::Round($testResults.Duration.TotalSeconds, 2)) secondes</p>
    </div>

    <h2>DÃ©tails des tests</h2>
    <table>
        <tr>
            <th>Nom</th>
            <th>RÃ©sultat</th>
            <th>DurÃ©e (ms)</th>
        </tr>
"@

        foreach ($test in $testResults.Tests) {
            $resultClass = switch ($test.Result) {
                'Passed' { 'good' }
                'Failed' { 'bad' }
                default { 'warning' }
            }

            $htmlContent += @"
        <tr>
            <td>$($test.Name)</td>
            <td class="$resultClass">$($test.Result)</td>
            <td>$([Math]::Round($test.Duration.TotalMilliseconds, 2))</td>
        </tr>
"@
        }

        $htmlContent += @"
    </table>

    <p><em>Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</em></p>
</body>
</html>
"@

        # Enregistrer le rapport HTML
        $htmlContent | Out-File -FilePath $reportPath -Encoding utf8

        Write-Host "Rapport HTML gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Cyan
    }

    return $testResults
}

# Fonction pour enregistrer un test
function Register-TestOmnibusTest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$Category = "Default",

        [Parameter(Mandatory = $false)]
        [int]$Priority = 100
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier de test n'existe pas: $Path"
        return $false
    }

    # CrÃ©er un objet de test
    $test = [PSCustomObject]@{
        Name = $Name
        Path = $Path
        Category = $Category
        Priority = $Priority
        RegisteredDate = Get-Date
    }

    # Enregistrer le test dans un fichier de configuration
    $configDir = Join-Path -Path $PSScriptRoot -ChildPath "Config"
    if (-not (Test-Path -Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }

    $configPath = Join-Path -Path $configDir -ChildPath "RegisteredTests.json"

    # Charger les tests existants
    $registeredTests = @()
    if (Test-Path -Path $configPath) {
        $registeredTests = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    }

    # Ajouter le nouveau test
    $registeredTests += $test

    # Enregistrer la configuration mise Ã  jour
    $registeredTests | ConvertTo-Json | Out-File -FilePath $configPath -Encoding utf8

    Write-Host "Test enregistrÃ© avec succÃ¨s: $Name" -ForegroundColor Green
    return $true
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-TestOmnibus, Register-TestOmnibusTest
'@

    $testOmnibusContent | Out-File -FilePath $testOmnibusPath -Encoding utf8
    Write-Host "Module TestOmnibus crÃ©Ã© Ã  l'emplacement: $testOmnibusPath" -ForegroundColor Green
}

# Importer TestOmnibus
Import-Module $testOmnibusPath -Force

# Enregistrer les tests du cache prÃ©dictif
$testFiles = Get-ChildItem -Path $testDirectory -Filter "*.Tests.ps1" -Recurse

foreach ($testFile in $testFiles) {
    $testName = $testFile.BaseName
    $testPath = $testFile.FullName
    $category = "PredictiveCache"

    # DÃ©terminer la prioritÃ© en fonction du nom du test
    $priority = switch -Wildcard ($testName) {
        "*Performance*" { 200 }
        "*EdgeCases*" { 300 }
        "*ErrorCases*" { 400 }
        default { 100 }
    }

    # Enregistrer le test
    Register-TestOmnibusTest -Name $testName -Path $testPath -Category $category -Priority $priority
}

# CrÃ©er un rÃ©pertoire pour les rapports
$reportDir = Join-Path -Path $testDirectory -ChildPath "Reports"
if (-not (Test-Path -Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

# ExÃ©cuter les tests
$outputPath = Join-Path -Path $reportDir -ChildPath "PredictiveCache_TestResults.xml"
$testResults = Invoke-TestOmnibus -TestPattern "$testDirectory\*.Tests.ps1" -OutputPath $outputPath -GenerateReport

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "Tests exÃ©cutÃ©s: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Tests rÃ©ussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorÃ©s: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "DurÃ©e totale: $([Math]::Round($testResults.Duration.TotalSeconds, 2)) secondes" -ForegroundColor White

# Retourner le code de sortie en fonction des rÃ©sultats
exit $testResults.FailedCount
