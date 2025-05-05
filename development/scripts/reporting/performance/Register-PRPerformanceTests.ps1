#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les tests de performance pour les modules de rapports PR dans le pipeline CI.
.DESCRIPTION
    Ce script configure les tests de performance pour qu'ils s'exÃƒÂ©cutent automatiquement
    dans le pipeline CI. Il dÃƒÂ©finit des seuils de performance acceptables et fait ÃƒÂ©chouer
    le pipeline si les performances se dÃƒÂ©gradent trop.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration des tests de performance. Par dÃƒÂ©faut: ".\performance_tests_config.json".
.PARAMETER BaselineResultsPath
    Chemin vers le fichier de rÃƒÂ©sultats de rÃƒÂ©fÃƒÂ©rence. Si non spÃƒÂ©cifiÃƒÂ©, les rÃƒÂ©sultats actuels seront utilisÃƒÂ©s comme rÃƒÂ©fÃƒÂ©rence.
.PARAMETER ThresholdPercent
    Pourcentage d'augmentation du temps d'exÃƒÂ©cution considÃƒÂ©rÃƒÂ© comme une rÃƒÂ©gression. Par dÃƒÂ©faut: 10%.
.PARAMETER OutputDir
    RÃƒÂ©pertoire oÃƒÂ¹ enregistrer les rÃƒÂ©sultats des tests. Par dÃƒÂ©faut: ".\performance_results".
.PARAMETER GenerateReport
    GÃƒÂ©nÃƒÂ¨re un rapport HTML des rÃƒÂ©sultats de la comparaison.
.PARAMETER FailOnRegression
    Fait ÃƒÂ©chouer le script si des rÃƒÂ©gressions de performance sont dÃƒÂ©tectÃƒÂ©es.
.EXAMPLE
    .\Register-PRPerformanceTests.ps1 -BaselineResultsPath ".\baseline_results.json" -ThresholdPercent 5
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = ".\performance_tests_config.json",

    [Parameter(Mandatory = $false)]
    [string]$BaselineResultsPath,

    [Parameter(Mandatory = $false)]
    [double]$ThresholdPercent = 10.0,

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = ".\performance_results",

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [switch]$FailOnRegression
)

# CrÃƒÂ©er le rÃƒÂ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

# DÃƒÂ©finir les chemins des scripts de test de performance
$scriptsPath = $PSScriptRoot
$benchmarkScript = Join-Path -Path $scriptsPath -ChildPath "Invoke-PRPerformanceBenchmark.ps1"
$regressionScript = Join-Path -Path $scriptsPath -ChildPath "Test-PRPerformanceRegression.ps1"
$loadTestScript = Join-Path -Path $scriptsPath -ChildPath "Start-PRLoadTest.ps1"
$comparisonScript = Join-Path -Path $scriptsPath -ChildPath "Compare-PRPerformanceResults.ps1"

# VÃƒÂ©rifier que les scripts existent
if (-not (Test-Path -Path $benchmarkScript)) {
    throw "Script de benchmark non trouvÃƒÂ©: $benchmarkScript"
}

if (-not (Test-Path -Path $regressionScript)) {
    throw "Script de test de rÃƒÂ©gression non trouvÃƒÂ©: $regressionScript"
}

if (-not (Test-Path -Path $loadTestScript)) {
    throw "Script de test de charge non trouvÃƒÂ©: $loadTestScript"
}

if (-not (Test-Path -Path $comparisonScript)) {
    throw "Script de comparaison non trouvÃƒÂ©: $comparisonScript"
}

# Fonction pour crÃƒÂ©er un fichier de configuration par dÃƒÂ©faut
function New-DefaultConfig {
    param (
        [string]$Path
    )

    $config = @{
        Benchmark  = @{
            Enabled      = $true
            Iterations   = 5
            DataSize     = "Medium"
            ModuleName   = $null
            FunctionName = $null
        }
        LoadTest   = @{
            Enabled      = $true
            Duration     = 30
            Concurrency  = 3
            DataSize     = "Large"
            ModuleName   = $null
            FunctionName = $null
        }
        Regression = @{
            Enabled          = $true
            ThresholdPercent = 10.0
            FailOnRegression = $true
        }
        Comparison = @{
            Enabled        = $true
            GenerateReport = $true
        }
        CI         = @{
            Enabled             = $true
            FailOnRegression    = $true
            BaselineResultsPath = $null
            OutputDir           = ".\performance_results"
        }
    }

    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8

    return $config
}

# Charger ou crÃƒÂ©er la configuration
if (Test-Path -Path $ConfigPath) {
    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
} else {
    $config = New-DefaultConfig -Path $ConfigPath
}

# Mettre ÃƒÂ  jour la configuration avec les paramÃƒÂ¨tres
if ($PSBoundParameters.ContainsKey('ThresholdPercent')) {
    $config.Regression.ThresholdPercent = $ThresholdPercent
}

if ($PSBoundParameters.ContainsKey('BaselineResultsPath')) {
    $config.CI.BaselineResultsPath = $BaselineResultsPath
}

if ($PSBoundParameters.ContainsKey('OutputDir')) {
    $config.CI.OutputDir = $OutputDir
}

if ($PSBoundParameters.ContainsKey('GenerateReport')) {
    $config.Comparison.GenerateReport = $GenerateReport
}

if ($PSBoundParameters.ContainsKey('FailOnRegression')) {
    $config.CI.FailOnRegression = $FailOnRegression
}

# Enregistrer la configuration mise ÃƒÂ  jour
$config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8

# Fonction pour exÃƒÂ©cuter les tests de performance
function Invoke-PerformanceTests {
    param (
        [object]$Config,
        [string]$OutputDir
    )

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $benchmarkResultsPath = Join-Path -Path $OutputDir -ChildPath "benchmark_results_$timestamp.json"
    $loadTestResultsPath = Join-Path -Path $OutputDir -ChildPath "load_test_results_$timestamp.json"
    $regressionResultsPath = Join-Path -Path $OutputDir -ChildPath "regression_results_$timestamp.json"
    $comparisonReportPath = Join-Path -Path $OutputDir -ChildPath "performance_comparison_$timestamp.html"

    $results = @{
        Timestamp         = $timestamp
        BenchmarkResults  = $null
        LoadTestResults   = $null
        RegressionResults = $null
        ComparisonReport  = $null
        HasRegressions    = $false
    }

    # ExÃƒÂ©cuter les tests de benchmark
    if ($Config.Benchmark.Enabled) {
        Write-Host "ExÃƒÂ©cution des tests de benchmark..."

        $benchmarkParams = @{
            Iterations = $Config.Benchmark.Iterations
            DataSize   = $Config.Benchmark.DataSize
            OutputPath = $benchmarkResultsPath
        }

        if ($Config.Benchmark.ModuleName) {
            $benchmarkParams.ModuleName = $Config.Benchmark.ModuleName
        }

        if ($Config.Benchmark.FunctionName) {
            $benchmarkParams.FunctionName = $Config.Benchmark.FunctionName
        }

        & $benchmarkScript @benchmarkParams

        if (Test-Path -Path $benchmarkResultsPath) {
            $results.BenchmarkResults = $benchmarkResultsPath
            Write-Host "RÃƒÂ©sultats de benchmark enregistrÃƒÂ©s: $benchmarkResultsPath"
        } else {
            Write-Warning "Les tests de benchmark n'ont pas gÃƒÂ©nÃƒÂ©rÃƒÂ© de rÃƒÂ©sultats."
        }
    }

    # ExÃƒÂ©cuter les tests de charge
    if ($Config.LoadTest.Enabled) {
        Write-Host "ExÃƒÂ©cution des tests de charge..."

        $loadTestParams = @{
            Duration    = $Config.LoadTest.Duration
            Concurrency = $Config.LoadTest.Concurrency
            DataSize    = $Config.LoadTest.DataSize
            OutputPath  = $loadTestResultsPath
        }

        if ($Config.LoadTest.ModuleName) {
            $loadTestParams.ModuleName = $Config.LoadTest.ModuleName
        }

        if ($Config.LoadTest.FunctionName) {
            $loadTestParams.FunctionName = $Config.LoadTest.FunctionName
        }

        & $loadTestScript @loadTestParams

        if (Test-Path -Path $loadTestResultsPath) {
            $results.LoadTestResults = $loadTestResultsPath
            Write-Host "RÃƒÂ©sultats de test de charge enregistrÃƒÂ©s: $loadTestResultsPath"
        } else {
            Write-Warning "Les tests de charge n'ont pas gÃƒÂ©nÃƒÂ©rÃƒÂ© de rÃƒÂ©sultats."
        }
    }

    # ExÃƒÂ©cuter les tests de rÃƒÂ©gression
    if ($Config.Regression.Enabled -and $results.BenchmarkResults) {
        Write-Host "ExÃƒÂ©cution des tests de rÃƒÂ©gression..."

        # Utiliser les rÃƒÂ©sultats de rÃƒÂ©fÃƒÂ©rence spÃƒÂ©cifiÃƒÂ©s ou ceux par dÃƒÂ©faut
        $baselineResults = $Config.CI.BaselineResultsPath

        if (-not $baselineResults -or -not (Test-Path -Path $baselineResults)) {
            Write-Warning "Aucun rÃƒÂ©sultat de rÃƒÂ©fÃƒÂ©rence spÃƒÂ©cifiÃƒÂ© ou trouvÃƒÂ©. Les rÃƒÂ©sultats actuels seront utilisÃƒÂ©s comme rÃƒÂ©fÃƒÂ©rence pour les prochains tests."
            $baselineResults = $results.BenchmarkResults
        }

        $regressionParams = @{
            CurrentResults   = $results.BenchmarkResults
            BaselineResults  = $baselineResults
            ThresholdPercent = $Config.Regression.ThresholdPercent
            OutputPath       = $regressionResultsPath
        }

        if ($Config.Comparison.GenerateReport) {
            $regressionParams.GenerateReport = $true
        }

        & $regressionScript @regressionParams

        if (Test-Path -Path $regressionResultsPath) {
            $results.RegressionResults = $regressionResultsPath
            Write-Host "RÃƒÂ©sultats de rÃƒÂ©gression enregistrÃƒÂ©s: $regressionResultsPath"

            # VÃƒÂ©rifier s'il y a des rÃƒÂ©gressions
            $regressionContent = Get-Content -Path $regressionResultsPath -Raw | ConvertFrom-Json
            $results.HasRegressions = $regressionContent.Summary.Regressions -gt 0

            if ($results.HasRegressions) {
                Write-Warning "Des rÃƒÂ©gressions de performance ont ÃƒÂ©tÃƒÂ© dÃƒÂ©tectÃƒÂ©es!"
            } else {
                Write-Host "Aucune rÃƒÂ©gression de performance dÃƒÂ©tectÃƒÂ©e." -ForegroundColor Green
            }
        } else {
            Write-Warning "Les tests de rÃƒÂ©gression n'ont pas gÃƒÂ©nÃƒÂ©rÃƒÂ© de rÃƒÂ©sultats."
        }
    }

    # GÃƒÂ©nÃƒÂ©rer un rapport de comparaison
    if ($Config.Comparison.Enabled -and $results.BenchmarkResults -and $Config.CI.BaselineResultsPath) {
        Write-Host "GÃƒÂ©nÃƒÂ©ration du rapport de comparaison..."

        $comparisonParams = @{
            ResultsPath = @($Config.CI.BaselineResultsPath, $results.BenchmarkResults)
            Labels      = @("Baseline", "Current")
            OutputPath  = $comparisonReportPath
        }

        & $comparisonScript @comparisonParams

        if (Test-Path -Path $comparisonReportPath) {
            $results.ComparisonReport = $comparisonReportPath
            Write-Host "Rapport de comparaison gÃƒÂ©nÃƒÂ©rÃƒÂ©: $comparisonReportPath"
        } else {
            Write-Warning "Le rapport de comparaison n'a pas ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ©."
        }
    }

    return $results
}

# ExÃƒÂ©cuter les tests de performance
$testResults = Invoke-PerformanceTests -Config $config -OutputDir $OutputDir

# Mettre ÃƒÂ  jour le fichier de rÃƒÂ©fÃƒÂ©rence si nÃƒÂ©cessaire
if ($testResults.BenchmarkResults -and (-not $config.CI.BaselineResultsPath -or -not (Test-Path -Path $config.CI.BaselineResultsPath))) {
    $config.CI.BaselineResultsPath = $testResults.BenchmarkResults
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
    Write-Host "Fichier de rÃƒÂ©fÃƒÂ©rence mis ÃƒÂ  jour: $($config.CI.BaselineResultsPath)"
}

# Faire ÃƒÂ©chouer le pipeline si des rÃƒÂ©gressions sont dÃƒÂ©tectÃƒÂ©es
if ($config.CI.FailOnRegression -and $testResults.HasRegressions) {
    Write-Error "Des rÃƒÂ©gressions de performance ont ÃƒÂ©tÃƒÂ© dÃƒÂ©tectÃƒÂ©es. Le pipeline a ÃƒÂ©chouÃƒÂ©."
    exit 1
}

# CrÃƒÂ©er un fichier de rÃƒÂ©sumÃƒÂ© pour le pipeline CI
$summaryPath = Join-Path -Path $OutputDir -ChildPath "performance_summary_$($testResults.Timestamp).md"
$summary = @"
# RÃƒÂ©sumÃƒÂ© des tests de performance

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## RÃƒÂ©sultats

- Tests de benchmark: $($null -ne $testResults.BenchmarkResults)
- Tests de charge: $($null -ne $testResults.LoadTestResults)
- Tests de rÃƒÂ©gression: $($null -ne $testResults.RegressionResults)
- Rapport de comparaison: $($null -ne $testResults.ComparisonReport)

## RÃƒÂ©gressions

Des rÃƒÂ©gressions ont ÃƒÂ©tÃƒÂ© dÃƒÂ©tectÃƒÂ©es: $($testResults.HasRegressions)

## Fichiers gÃƒÂ©nÃƒÂ©rÃƒÂ©s

"@

if ($testResults.BenchmarkResults) {
    $summary += "- [RÃƒÂ©sultats de benchmark]($($testResults.BenchmarkResults))`n"
}

if ($testResults.LoadTestResults) {
    $summary += "- [RÃƒÂ©sultats de test de charge]($($testResults.LoadTestResults))`n"
}

if ($testResults.RegressionResults) {
    $summary += "- [RÃƒÂ©sultats de rÃƒÂ©gression]($($testResults.RegressionResults))`n"
}

if ($testResults.ComparisonReport) {
    $summary += "- [Rapport de comparaison]($($testResults.ComparisonReport))`n"
}

$summary | Set-Content -Path $summaryPath -Encoding UTF8
Write-Host "RÃƒÂ©sumÃƒÂ© des tests de performance enregistrÃƒÂ©: $summaryPath"

# CrÃƒÂ©er un script pour exÃƒÂ©cuter les tests dans le pipeline CI
$ciScriptPath = Join-Path -Path $OutputDir -ChildPath "Run-PRPerformanceTests.ps1"
$ciScript = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃƒÂ©cute les tests de performance pour les modules de rapports PR dans le pipeline CI.
.DESCRIPTION
    Ce script est gÃƒÂ©nÃƒÂ©rÃƒÂ© automatiquement par Register-PRPerformanceTests.ps1 et est destinÃƒÂ©
    ÃƒÂ  ÃƒÂªtre exÃƒÂ©cutÃƒÂ© dans le pipeline CI pour tester les performances des modules de rapports PR.
.EXAMPLE
    .\Run-PRPerformanceTests.ps1
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: $(Get-Date -Format "yyyy-MM-dd")
#>

# ExÃƒÂ©cuter les tests de performance
& "$scriptsPath\Register-PRPerformanceTests.ps1" -ConfigPath "$ConfigPath" -OutputDir "$OutputDir"
"@

$ciScript | Set-Content -Path $ciScriptPath -Encoding UTF8
Write-Host "Script CI gÃƒÂ©nÃƒÂ©rÃƒÂ©: $ciScriptPath"

# CrÃƒÂ©er un exemple de configuration pour Azure DevOps
$azureDevOpsConfigPath = Join-Path -Path $OutputDir -ChildPath "azure-pipelines-performance.yml"
$azureDevOpsConfig = @"
# Azure DevOps Pipeline pour les tests de performance

trigger:
  branches:
    include:
    - main
    - develop
  paths:
    include:
    - development/scripts/pr-reporting/**

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  displayName: 'ExÃƒÂ©cuter les tests de performance'
  inputs:
    filePath: '$OutputDir/Run-PRPerformanceTests.ps1'
    failOnStderr: true

- task: PublishPipelineArtifact@1
  displayName: 'Publier les rÃƒÂ©sultats de performance'
  inputs:
    targetPath: '$OutputDir'
    artifact: 'PerformanceResults'
"@

$azureDevOpsConfig | Set-Content -Path $azureDevOpsConfigPath -Encoding UTF8
Write-Host "Configuration Azure DevOps gÃƒÂ©nÃƒÂ©rÃƒÂ©e: $azureDevOpsConfigPath"

# CrÃƒÂ©er un exemple de configuration pour GitHub Actions
$githubActionsConfigPath = Join-Path -Path $OutputDir -ChildPath "github-actions-performance.yml"
$githubActionsConfig = @"
# GitHub Actions Workflow pour les tests de performance

name: Performance Tests

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'development/scripts/pr-reporting/**'
  pull_request:
    branches: [ main ]
    paths:
      - 'development/scripts/pr-reporting/**'

jobs:
  performance-tests:
    runs-on: windows-latest

    steps:
    - uses: actions/checkout@v2

    - name: ExÃƒÂ©cuter les tests de performance
      shell: pwsh
      run: |
        .\$OutputDir\Run-PRPerformanceTests.ps1

    - name: Publier les rÃƒÂ©sultats de performance
      uses: actions/upload-artifact@v2
      with:
        name: performance-results
        path: $OutputDir
"@

$githubActionsConfig | Set-Content -Path $githubActionsConfigPath -Encoding UTF8
Write-Host "Configuration GitHub Actions gÃƒÂ©nÃƒÂ©rÃƒÂ©e: $githubActionsConfigPath"

Write-Host "`nConfiguration des tests de performance terminÃƒÂ©e!"
Write-Host "Pour exÃƒÂ©cuter les tests de performance dans le pipeline CI, utilisez le script: $ciScriptPath"
Write-Host "Pour configurer Azure DevOps, utilisez le fichier: $azureDevOpsConfigPath"
Write-Host "Pour configurer GitHub Actions, utilisez le fichier: $githubActionsConfigPath"
