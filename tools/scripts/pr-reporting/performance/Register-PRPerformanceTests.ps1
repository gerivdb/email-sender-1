#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les tests de performance pour les modules de rapports PR dans le pipeline CI.
.DESCRIPTION
    Ce script configure les tests de performance pour qu'ils s'exÃ©cutent automatiquement
    dans le pipeline CI. Il dÃ©finit des seuils de performance acceptables et fait Ã©chouer
    le pipeline si les performances se dÃ©gradent trop.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration des tests de performance. Par dÃ©faut: ".\performance_tests_config.json".
.PARAMETER BaselineResultsPath
    Chemin vers le fichier de rÃ©sultats de rÃ©fÃ©rence. Si non spÃ©cifiÃ©, les rÃ©sultats actuels seront utilisÃ©s comme rÃ©fÃ©rence.
.PARAMETER ThresholdPercent
    Pourcentage d'augmentation du temps d'exÃ©cution considÃ©rÃ© comme une rÃ©gression. Par dÃ©faut: 10%.
.PARAMETER OutputDir
    RÃ©pertoire oÃ¹ enregistrer les rÃ©sultats des tests. Par dÃ©faut: ".\performance_results".
.PARAMETER GenerateReport
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats de la comparaison.
.PARAMETER FailOnRegression
    Fait Ã©chouer le script si des rÃ©gressions de performance sont dÃ©tectÃ©es.
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

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

# DÃ©finir les chemins des scripts de test de performance
$scriptsPath = $PSScriptRoot
$benchmarkScript = Join-Path -Path $scriptsPath -ChildPath "Invoke-PRPerformanceBenchmark.ps1"
$regressionScript = Join-Path -Path $scriptsPath -ChildPath "Test-PRPerformanceRegression.ps1"
$loadTestScript = Join-Path -Path $scriptsPath -ChildPath "Start-PRLoadTest.ps1"
$comparisonScript = Join-Path -Path $scriptsPath -ChildPath "Compare-PRPerformanceResults.ps1"

# VÃ©rifier que les scripts existent
if (-not (Test-Path -Path $benchmarkScript)) {
    throw "Script de benchmark non trouvÃ©: $benchmarkScript"
}

if (-not (Test-Path -Path $regressionScript)) {
    throw "Script de test de rÃ©gression non trouvÃ©: $regressionScript"
}

if (-not (Test-Path -Path $loadTestScript)) {
    throw "Script de test de charge non trouvÃ©: $loadTestScript"
}

if (-not (Test-Path -Path $comparisonScript)) {
    throw "Script de comparaison non trouvÃ©: $comparisonScript"
}

# Fonction pour crÃ©er un fichier de configuration par dÃ©faut
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

# Charger ou crÃ©er la configuration
if (Test-Path -Path $ConfigPath) {
    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
} else {
    $config = New-DefaultConfig -Path $ConfigPath
}

# Mettre Ã  jour la configuration avec les paramÃ¨tres
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

# Enregistrer la configuration mise Ã  jour
$config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8

# Fonction pour exÃ©cuter les tests de performance
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

    # ExÃ©cuter les tests de benchmark
    if ($Config.Benchmark.Enabled) {
        Write-Host "ExÃ©cution des tests de benchmark..."

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
            Write-Host "RÃ©sultats de benchmark enregistrÃ©s: $benchmarkResultsPath"
        } else {
            Write-Warning "Les tests de benchmark n'ont pas gÃ©nÃ©rÃ© de rÃ©sultats."
        }
    }

    # ExÃ©cuter les tests de charge
    if ($Config.LoadTest.Enabled) {
        Write-Host "ExÃ©cution des tests de charge..."

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
            Write-Host "RÃ©sultats de test de charge enregistrÃ©s: $loadTestResultsPath"
        } else {
            Write-Warning "Les tests de charge n'ont pas gÃ©nÃ©rÃ© de rÃ©sultats."
        }
    }

    # ExÃ©cuter les tests de rÃ©gression
    if ($Config.Regression.Enabled -and $results.BenchmarkResults) {
        Write-Host "ExÃ©cution des tests de rÃ©gression..."

        # Utiliser les rÃ©sultats de rÃ©fÃ©rence spÃ©cifiÃ©s ou ceux par dÃ©faut
        $baselineResults = $Config.CI.BaselineResultsPath

        if (-not $baselineResults -or -not (Test-Path -Path $baselineResults)) {
            Write-Warning "Aucun rÃ©sultat de rÃ©fÃ©rence spÃ©cifiÃ© ou trouvÃ©. Les rÃ©sultats actuels seront utilisÃ©s comme rÃ©fÃ©rence pour les prochains tests."
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
            Write-Host "RÃ©sultats de rÃ©gression enregistrÃ©s: $regressionResultsPath"

            # VÃ©rifier s'il y a des rÃ©gressions
            $regressionContent = Get-Content -Path $regressionResultsPath -Raw | ConvertFrom-Json
            $results.HasRegressions = $regressionContent.Summary.Regressions -gt 0

            if ($results.HasRegressions) {
                Write-Warning "Des rÃ©gressions de performance ont Ã©tÃ© dÃ©tectÃ©es!"
            } else {
                Write-Host "Aucune rÃ©gression de performance dÃ©tectÃ©e." -ForegroundColor Green
            }
        } else {
            Write-Warning "Les tests de rÃ©gression n'ont pas gÃ©nÃ©rÃ© de rÃ©sultats."
        }
    }

    # GÃ©nÃ©rer un rapport de comparaison
    if ($Config.Comparison.Enabled -and $results.BenchmarkResults -and $Config.CI.BaselineResultsPath) {
        Write-Host "GÃ©nÃ©ration du rapport de comparaison..."

        $comparisonParams = @{
            ResultsPath = @($Config.CI.BaselineResultsPath, $results.BenchmarkResults)
            Labels      = @("Baseline", "Current")
            OutputPath  = $comparisonReportPath
        }

        & $comparisonScript @comparisonParams

        if (Test-Path -Path $comparisonReportPath) {
            $results.ComparisonReport = $comparisonReportPath
            Write-Host "Rapport de comparaison gÃ©nÃ©rÃ©: $comparisonReportPath"
        } else {
            Write-Warning "Le rapport de comparaison n'a pas Ã©tÃ© gÃ©nÃ©rÃ©."
        }
    }

    return $results
}

# ExÃ©cuter les tests de performance
$testResults = Invoke-PerformanceTests -Config $config -OutputDir $OutputDir

# Mettre Ã  jour le fichier de rÃ©fÃ©rence si nÃ©cessaire
if ($testResults.BenchmarkResults -and (-not $config.CI.BaselineResultsPath -or -not (Test-Path -Path $config.CI.BaselineResultsPath))) {
    $config.CI.BaselineResultsPath = $testResults.BenchmarkResults
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
    Write-Host "Fichier de rÃ©fÃ©rence mis Ã  jour: $($config.CI.BaselineResultsPath)"
}

# Faire Ã©chouer le pipeline si des rÃ©gressions sont dÃ©tectÃ©es
if ($config.CI.FailOnRegression -and $testResults.HasRegressions) {
    Write-Error "Des rÃ©gressions de performance ont Ã©tÃ© dÃ©tectÃ©es. Le pipeline a Ã©chouÃ©."
    exit 1
}

# CrÃ©er un fichier de rÃ©sumÃ© pour le pipeline CI
$summaryPath = Join-Path -Path $OutputDir -ChildPath "performance_summary_$($testResults.Timestamp).md"
$summary = @"
# RÃ©sumÃ© des tests de performance

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## RÃ©sultats

- Tests de benchmark: $($null -ne $testResults.BenchmarkResults)
- Tests de charge: $($null -ne $testResults.LoadTestResults)
- Tests de rÃ©gression: $($null -ne $testResults.RegressionResults)
- Rapport de comparaison: $($null -ne $testResults.ComparisonReport)

## RÃ©gressions

Des rÃ©gressions ont Ã©tÃ© dÃ©tectÃ©es: $($testResults.HasRegressions)

## Fichiers gÃ©nÃ©rÃ©s

"@

if ($testResults.BenchmarkResults) {
    $summary += "- [RÃ©sultats de benchmark]($($testResults.BenchmarkResults))`n"
}

if ($testResults.LoadTestResults) {
    $summary += "- [RÃ©sultats de test de charge]($($testResults.LoadTestResults))`n"
}

if ($testResults.RegressionResults) {
    $summary += "- [RÃ©sultats de rÃ©gression]($($testResults.RegressionResults))`n"
}

if ($testResults.ComparisonReport) {
    $summary += "- [Rapport de comparaison]($($testResults.ComparisonReport))`n"
}

$summary | Set-Content -Path $summaryPath -Encoding UTF8
Write-Host "RÃ©sumÃ© des tests de performance enregistrÃ©: $summaryPath"

# CrÃ©er un script pour exÃ©cuter les tests dans le pipeline CI
$ciScriptPath = Join-Path -Path $OutputDir -ChildPath "Run-PRPerformanceTests.ps1"
$ciScript = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests de performance pour les modules de rapports PR dans le pipeline CI.
.DESCRIPTION
    Ce script est gÃ©nÃ©rÃ© automatiquement par Register-PRPerformanceTests.ps1 et est destinÃ©
    Ã  Ãªtre exÃ©cutÃ© dans le pipeline CI pour tester les performances des modules de rapports PR.
.EXAMPLE
    .\Run-PRPerformanceTests.ps1
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: $(Get-Date -Format "yyyy-MM-dd")
#>

# ExÃ©cuter les tests de performance
& "$scriptsPath\Register-PRPerformanceTests.ps1" -ConfigPath "$ConfigPath" -OutputDir "$OutputDir"
"@

$ciScript | Set-Content -Path $ciScriptPath -Encoding UTF8
Write-Host "Script CI gÃ©nÃ©rÃ©: $ciScriptPath"

# CrÃ©er un exemple de configuration pour Azure DevOps
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
    - scripts/pr-reporting/**

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  displayName: 'ExÃ©cuter les tests de performance'
  inputs:
    filePath: '$OutputDir/Run-PRPerformanceTests.ps1'
    failOnStderr: true

- task: PublishPipelineArtifact@1
  displayName: 'Publier les rÃ©sultats de performance'
  inputs:
    targetPath: '$OutputDir'
    artifact: 'PerformanceResults'
"@

$azureDevOpsConfig | Set-Content -Path $azureDevOpsConfigPath -Encoding UTF8
Write-Host "Configuration Azure DevOps gÃ©nÃ©rÃ©e: $azureDevOpsConfigPath"

# CrÃ©er un exemple de configuration pour GitHub Actions
$githubActionsConfigPath = Join-Path -Path $OutputDir -ChildPath "github-actions-performance.yml"
$githubActionsConfig = @"
# GitHub Actions Workflow pour les tests de performance

name: Performance Tests

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'scripts/pr-reporting/**'
  pull_request:
    branches: [ main ]
    paths:
      - 'scripts/pr-reporting/**'

jobs:
  performance-tests:
    runs-on: windows-latest

    steps:
    - uses: actions/checkout@v2

    - name: ExÃ©cuter les tests de performance
      shell: pwsh
      run: |
        .\$OutputDir\Run-PRPerformanceTests.ps1

    - name: Publier les rÃ©sultats de performance
      uses: actions/upload-artifact@v2
      with:
        name: performance-results
        path: $OutputDir
"@

$githubActionsConfig | Set-Content -Path $githubActionsConfigPath -Encoding UTF8
Write-Host "Configuration GitHub Actions gÃ©nÃ©rÃ©e: $githubActionsConfigPath"

Write-Host "`nConfiguration des tests de performance terminÃ©e!"
Write-Host "Pour exÃ©cuter les tests de performance dans le pipeline CI, utilisez le script: $ciScriptPath"
Write-Host "Pour configurer Azure DevOps, utilisez le fichier: $azureDevOpsConfigPath"
Write-Host "Pour configurer GitHub Actions, utilisez le fichier: $githubActionsConfigPath"
