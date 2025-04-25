#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests de performance pour les modules de rapports PR.
.DESCRIPTION
    Ce script exécute tous les tests de performance pour les modules de rapports PR,
    y compris les benchmarks, les tests de charge, les tests de régression et les comparaisons.
.PARAMETER OutputDir
    Répertoire où enregistrer les résultats des tests. Par défaut: ".\performance_results".
.PARAMETER DataSize
    Taille des données de test (Small, Medium, Large). Par défaut: Medium.
.PARAMETER Iterations
    Nombre d'itérations pour les benchmarks. Par défaut: 5.
.PARAMETER Duration
    Durée des tests de charge en secondes. Par défaut: 30.
.PARAMETER Concurrency
    Nombre d'exécutions concurrentes pour les tests de charge. Par défaut: 3.
.PARAMETER GenerateReport
    Génère un rapport HTML des résultats.
.EXAMPLE
    .\Invoke-AllPerformanceTests.ps1 -DataSize "Large" -Iterations 10
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputDir = ".\performance_results",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Small", "Medium", "Large")]
    [string]$DataSize = "Medium",
    
    [Parameter(Mandatory = $false)]
    [int]$Iterations = 5,
    
    [Parameter(Mandatory = $false)]
    [int]$Duration = 30,
    
    [Parameter(Mandatory = $false)]
    [int]$Concurrency = 3,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

# Définir les chemins des scripts de test de performance
$scriptsPath = $PSScriptRoot
$benchmarkScript = Join-Path -Path $scriptsPath -ChildPath "Invoke-PRPerformanceBenchmark.ps1"
$loadTestScript = Join-Path -Path $scriptsPath -ChildPath "Start-PRLoadTest.ps1"
$comparisonScript = Join-Path -Path $scriptsPath -ChildPath "Compare-PRPerformanceResults.ps1"

# Vérifier que les scripts existent
if (-not (Test-Path -Path $benchmarkScript)) {
    throw "Script de benchmark non trouvé: $benchmarkScript"
}

if (-not (Test-Path -Path $loadTestScript)) {
    throw "Script de test de charge non trouvé: $loadTestScript"
}

if (-not (Test-Path -Path $comparisonScript)) {
    throw "Script de comparaison non trouvé: $comparisonScript"
}

# Générer un timestamp unique pour les fichiers de résultats
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Exécuter les benchmarks
Write-Host "Exécution des benchmarks..."
$benchmarkResultsPath = Join-Path -Path $OutputDir -ChildPath "benchmark_results_$timestamp.json"
& $benchmarkScript -DataSize $DataSize -Iterations $Iterations -OutputPath $benchmarkResultsPath

# Exécuter les tests de charge
Write-Host "Exécution des tests de charge..."
$loadTestResultsPath = Join-Path -Path $OutputDir -ChildPath "load_test_results_$timestamp.json"
& $loadTestScript -DataSize $DataSize -Duration $Duration -Concurrency $Concurrency -OutputPath $loadTestResultsPath

# Générer un rapport de comparaison si demandé
if ($GenerateReport) {
    # Rechercher un fichier de résultats de benchmark précédent
    $previousBenchmarkFiles = Get-ChildItem -Path $OutputDir -Filter "benchmark_results_*.json" | 
                             Where-Object { $_.Name -ne (Split-Path -Path $benchmarkResultsPath -Leaf) } |
                             Sort-Object -Property LastWriteTime -Descending
    
    if ($previousBenchmarkFiles.Count -gt 0) {
        $previousBenchmarkFile = $previousBenchmarkFiles[0].FullName
        Write-Host "Génération d'un rapport de comparaison avec le benchmark précédent: $previousBenchmarkFile"
        
        $comparisonReportPath = Join-Path -Path $OutputDir -ChildPath "performance_comparison_$timestamp.html"
        & $comparisonScript -ResultsPath @($previousBenchmarkFile, $benchmarkResultsPath) -Labels @("Previous", "Current") -OutputPath $comparisonReportPath
    }
    else {
        Write-Warning "Aucun benchmark précédent trouvé pour la comparaison."
    }
}

# Générer un rapport de résumé
$summaryPath = Join-Path -Path $OutputDir -ChildPath "performance_summary_$timestamp.md"
$summary = @"
# Résumé des tests de performance

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Configuration

- Taille des données: $DataSize
- Itérations de benchmark: $Iterations
- Durée des tests de charge: $Duration secondes
- Concurrence des tests de charge: $Concurrency

## Fichiers générés

- [Résultats de benchmark]($benchmarkResultsPath)
- [Résultats de test de charge]($loadTestResultsPath)
"@

if ($GenerateReport -and $previousBenchmarkFiles.Count -gt 0) {
    $summary += "`n- [Rapport de comparaison]($comparisonReportPath)"
}

$summary | Set-Content -Path $summaryPath -Encoding UTF8
Write-Host "Résumé des tests de performance enregistré: $summaryPath"

Write-Host "`nTous les tests de performance ont été exécutés avec succès!"
Write-Host "Résultats de benchmark: $benchmarkResultsPath"
Write-Host "Résultats de test de charge: $loadTestResultsPath"

if ($GenerateReport -and $previousBenchmarkFiles.Count -gt 0) {
    Write-Host "Rapport de comparaison: $comparisonReportPath"
}

Write-Host "Résumé: $summaryPath"
