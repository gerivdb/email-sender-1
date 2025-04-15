#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les tests de performance pour les modules de rapports PR dans le pipeline CI.
.DESCRIPTION
    Ce script configure les tests de performance pour qu'ils s'exécutent automatiquement
    dans le pipeline CI. Il définit des seuils de performance acceptables et fait échouer
    le pipeline si les performances se dégradent trop.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration des tests de performance. Par défaut: ".\performance_tests_config.json".
.PARAMETER BaselineResultsPath
    Chemin vers le fichier de résultats de référence. Si non spécifié, les résultats actuels seront utilisés comme référence.
.PARAMETER ThresholdPercent
    Pourcentage d'augmentation du temps d'exécution considéré comme une régression. Par défaut: 10%.
.PARAMETER OutputDir
    Répertoire où enregistrer les résultats des tests. Par défaut: ".\performance_results".
.PARAMETER GenerateReport
    Génère un rapport HTML des résultats de la comparaison.
.PARAMETER FailOnRegression
    Fait échouer le script si des régressions de performance sont détectées.
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

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

# Définir les chemins des scripts de test de performance
$scriptsPath = $PSScriptRoot
$benchmarkScript = Join-Path -Path $scriptsPath -ChildPath "Invoke-PRPerformanceBenchmark.ps1"
$regressionScript = Join-Path -Path $scriptsPath -ChildPath "Test-PRPerformanceRegression.ps1"
$loadTestScript = Join-Path -Path $scriptsPath -ChildPath "Start-PRLoadTest.ps1"
$comparisonScript = Join-Path -Path $scriptsPath -ChildPath "Compare-PRPerformanceResults.ps1"

# Vérifier que les scripts existent
if (-not (Test-Path -Path $benchmarkScript)) {
    throw "Script de benchmark non trouvé: $benchmarkScript"
}

if (-not (Test-Path -Path $regressionScript)) {
    throw "Script de test de régression non trouvé: $regressionScript"
}

if (-not (Test-Path -Path $loadTestScript)) {
    throw "Script de test de charge non trouvé: $loadTestScript"
}

if (-not (Test-Path -Path $comparisonScript)) {
    throw "Script de comparaison non trouvé: $comparisonScript"
}

# Fonction pour créer un fichier de configuration par défaut
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

# Charger ou créer la configuration
if (Test-Path -Path $ConfigPath) {
    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
} else {
    $config = New-DefaultConfig -Path $ConfigPath
}

# Mettre à jour la configuration avec les paramètres
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

# Enregistrer la configuration mise à jour
$config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8

# Fonction pour exécuter les tests de performance
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

    # Exécuter les tests de benchmark
    if ($Config.Benchmark.Enabled) {
        Write-Host "Exécution des tests de benchmark..."

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
            Write-Host "Résultats de benchmark enregistrés: $benchmarkResultsPath"
        } else {
            Write-Warning "Les tests de benchmark n'ont pas généré de résultats."
        }
    }

    # Exécuter les tests de charge
    if ($Config.LoadTest.Enabled) {
        Write-Host "Exécution des tests de charge..."

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
            Write-Host "Résultats de test de charge enregistrés: $loadTestResultsPath"
        } else {
            Write-Warning "Les tests de charge n'ont pas généré de résultats."
        }
    }

    # Exécuter les tests de régression
    if ($Config.Regression.Enabled -and $results.BenchmarkResults) {
        Write-Host "Exécution des tests de régression..."

        # Utiliser les résultats de référence spécifiés ou ceux par défaut
        $baselineResults = $Config.CI.BaselineResultsPath

        if (-not $baselineResults -or -not (Test-Path -Path $baselineResults)) {
            Write-Warning "Aucun résultat de référence spécifié ou trouvé. Les résultats actuels seront utilisés comme référence pour les prochains tests."
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
            Write-Host "Résultats de régression enregistrés: $regressionResultsPath"

            # Vérifier s'il y a des régressions
            $regressionContent = Get-Content -Path $regressionResultsPath -Raw | ConvertFrom-Json
            $results.HasRegressions = $regressionContent.Summary.Regressions -gt 0

            if ($results.HasRegressions) {
                Write-Warning "Des régressions de performance ont été détectées!"
            } else {
                Write-Host "Aucune régression de performance détectée." -ForegroundColor Green
            }
        } else {
            Write-Warning "Les tests de régression n'ont pas généré de résultats."
        }
    }

    # Générer un rapport de comparaison
    if ($Config.Comparison.Enabled -and $results.BenchmarkResults -and $Config.CI.BaselineResultsPath) {
        Write-Host "Génération du rapport de comparaison..."

        $comparisonParams = @{
            ResultsPath = @($Config.CI.BaselineResultsPath, $results.BenchmarkResults)
            Labels      = @("Baseline", "Current")
            OutputPath  = $comparisonReportPath
        }

        & $comparisonScript @comparisonParams

        if (Test-Path -Path $comparisonReportPath) {
            $results.ComparisonReport = $comparisonReportPath
            Write-Host "Rapport de comparaison généré: $comparisonReportPath"
        } else {
            Write-Warning "Le rapport de comparaison n'a pas été généré."
        }
    }

    return $results
}

# Exécuter les tests de performance
$testResults = Invoke-PerformanceTests -Config $config -OutputDir $OutputDir

# Mettre à jour le fichier de référence si nécessaire
if ($testResults.BenchmarkResults -and (-not $config.CI.BaselineResultsPath -or -not (Test-Path -Path $config.CI.BaselineResultsPath))) {
    $config.CI.BaselineResultsPath = $testResults.BenchmarkResults
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
    Write-Host "Fichier de référence mis à jour: $($config.CI.BaselineResultsPath)"
}

# Faire échouer le pipeline si des régressions sont détectées
if ($config.CI.FailOnRegression -and $testResults.HasRegressions) {
    Write-Error "Des régressions de performance ont été détectées. Le pipeline a échoué."
    exit 1
}

# Créer un fichier de résumé pour le pipeline CI
$summaryPath = Join-Path -Path $OutputDir -ChildPath "performance_summary_$($testResults.Timestamp).md"
$summary = @"
# Résumé des tests de performance

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résultats

- Tests de benchmark: $($null -ne $testResults.BenchmarkResults)
- Tests de charge: $($null -ne $testResults.LoadTestResults)
- Tests de régression: $($null -ne $testResults.RegressionResults)
- Rapport de comparaison: $($null -ne $testResults.ComparisonReport)

## Régressions

Des régressions ont été détectées: $($testResults.HasRegressions)

## Fichiers générés

"@

if ($testResults.BenchmarkResults) {
    $summary += "- [Résultats de benchmark]($($testResults.BenchmarkResults))`n"
}

if ($testResults.LoadTestResults) {
    $summary += "- [Résultats de test de charge]($($testResults.LoadTestResults))`n"
}

if ($testResults.RegressionResults) {
    $summary += "- [Résultats de régression]($($testResults.RegressionResults))`n"
}

if ($testResults.ComparisonReport) {
    $summary += "- [Rapport de comparaison]($($testResults.ComparisonReport))`n"
}

$summary | Set-Content -Path $summaryPath -Encoding UTF8
Write-Host "Résumé des tests de performance enregistré: $summaryPath"

# Créer un script pour exécuter les tests dans le pipeline CI
$ciScriptPath = Join-Path -Path $OutputDir -ChildPath "Run-PRPerformanceTests.ps1"
$ciScript = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests de performance pour les modules de rapports PR dans le pipeline CI.
.DESCRIPTION
    Ce script est généré automatiquement par Register-PRPerformanceTests.ps1 et est destiné
    à être exécuté dans le pipeline CI pour tester les performances des modules de rapports PR.
.EXAMPLE
    .\Run-PRPerformanceTests.ps1
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: $(Get-Date -Format "yyyy-MM-dd")
#>

# Exécuter les tests de performance
& "$scriptsPath\Register-PRPerformanceTests.ps1" -ConfigPath "$ConfigPath" -OutputDir "$OutputDir"
"@

$ciScript | Set-Content -Path $ciScriptPath -Encoding UTF8
Write-Host "Script CI généré: $ciScriptPath"

# Créer un exemple de configuration pour Azure DevOps
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
  displayName: 'Exécuter les tests de performance'
  inputs:
    filePath: '$OutputDir/Run-PRPerformanceTests.ps1'
    failOnStderr: true

- task: PublishPipelineArtifact@1
  displayName: 'Publier les résultats de performance'
  inputs:
    targetPath: '$OutputDir'
    artifact: 'PerformanceResults'
"@

$azureDevOpsConfig | Set-Content -Path $azureDevOpsConfigPath -Encoding UTF8
Write-Host "Configuration Azure DevOps générée: $azureDevOpsConfigPath"

# Créer un exemple de configuration pour GitHub Actions
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

    - name: Exécuter les tests de performance
      shell: pwsh
      run: |
        .\$OutputDir\Run-PRPerformanceTests.ps1

    - name: Publier les résultats de performance
      uses: actions/upload-artifact@v2
      with:
        name: performance-results
        path: $OutputDir
"@

$githubActionsConfig | Set-Content -Path $githubActionsConfigPath -Encoding UTF8
Write-Host "Configuration GitHub Actions générée: $githubActionsConfigPath"

Write-Host "`nConfiguration des tests de performance terminée!"
Write-Host "Pour exécuter les tests de performance dans le pipeline CI, utilisez le script: $ciScriptPath"
Write-Host "Pour configurer Azure DevOps, utilisez le fichier: $azureDevOpsConfigPath"
Write-Host "Pour configurer GitHub Actions, utilisez le fichier: $githubActionsConfigPath"
