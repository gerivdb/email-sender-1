#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests de performance pour les modules de rapports PR.
.DESCRIPTION
    Ce script exÃ©cute tous les tests de performance pour les modules de rapports PR,
    y compris les benchmarks, les tests de charge, les tests de rÃ©gression et les comparaisons.
.PARAMETER OutputDir
    RÃ©pertoire oÃ¹ enregistrer les rÃ©sultats des tests. Par dÃ©faut: ".\performance_results".
.PARAMETER DataSize
    Taille des donnÃ©es de test (Small, Medium, Large). Par dÃ©faut: Medium.
.PARAMETER Iterations
    Nombre d'itÃ©rations pour les benchmarks. Par dÃ©faut: 5.
.PARAMETER Duration
    DurÃ©e des tests de charge en secondes. Par dÃ©faut: 30.
.PARAMETER Concurrency
    Nombre d'exÃ©cutions concurrentes pour les tests de charge. Par dÃ©faut: 3.
.PARAMETER GenerateReport
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats.
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

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

# DÃ©finir les chemins des scripts de test de performance
$scriptsPath = $PSScriptRoot
$benchmarkScript = Join-Path -Path $scriptsPath -ChildPath "Invoke-PRPerformanceBenchmark.ps1"
$loadTestScript = Join-Path -Path $scriptsPath -ChildPath "Start-PRLoadTest.ps1"
$comparisonScript = Join-Path -Path $scriptsPath -ChildPath "Compare-PRPerformanceResults.ps1"

# VÃ©rifier que les scripts existent
if (-not (Test-Path -Path $benchmarkScript)) {
    throw "Script de benchmark non trouvÃ©: $benchmarkScript"
}

if (-not (Test-Path -Path $loadTestScript)) {
    throw "Script de test de charge non trouvÃ©: $loadTestScript"
}

if (-not (Test-Path -Path $comparisonScript)) {
    throw "Script de comparaison non trouvÃ©: $comparisonScript"
}

# GÃ©nÃ©rer un timestamp unique pour les fichiers de rÃ©sultats
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# ExÃ©cuter les benchmarks
Write-Host "ExÃ©cution des benchmarks..."
$benchmarkResultsPath = Join-Path -Path $OutputDir -ChildPath "benchmark_results_$timestamp.json"
& $benchmarkScript -DataSize $DataSize -Iterations $Iterations -OutputPath $benchmarkResultsPath

# ExÃ©cuter les tests de charge
Write-Host "ExÃ©cution des tests de charge..."
$loadTestResultsPath = Join-Path -Path $OutputDir -ChildPath "load_test_results_$timestamp.json"
& $loadTestScript -DataSize $DataSize -Duration $Duration -Concurrency $Concurrency -OutputPath $loadTestResultsPath

# GÃ©nÃ©rer un rapport de comparaison si demandÃ©
if ($GenerateReport) {
    # Rechercher un fichier de rÃ©sultats de benchmark prÃ©cÃ©dent
    $previousBenchmarkFiles = Get-ChildItem -Path $OutputDir -Filter "benchmark_results_*.json" | 
                             Where-Object { $_.Name -ne (Split-Path -Path $benchmarkResultsPath -Leaf) } |
                             Sort-Object -Property LastWriteTime -Descending
    
    if ($previousBenchmarkFiles.Count -gt 0) {
        $previousBenchmarkFile = $previousBenchmarkFiles[0].FullName
        Write-Host "GÃ©nÃ©ration d'un rapport de comparaison avec le benchmark prÃ©cÃ©dent: $previousBenchmarkFile"
        
        $comparisonReportPath = Join-Path -Path $OutputDir -ChildPath "performance_comparison_$timestamp.html"
        & $comparisonScript -ResultsPath @($previousBenchmarkFile, $benchmarkResultsPath) -Labels @("Previous", "Current") -OutputPath $comparisonReportPath
    }
    else {
        Write-Warning "Aucun benchmark prÃ©cÃ©dent trouvÃ© pour la comparaison."
    }
}

# GÃ©nÃ©rer un rapport de rÃ©sumÃ©
$summaryPath = Join-Path -Path $OutputDir -ChildPath "performance_summary_$timestamp.md"
$summary = @"
# RÃ©sumÃ© des tests de performance

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Configuration

- Taille des donnÃ©es: $DataSize
- ItÃ©rations de benchmark: $Iterations
- DurÃ©e des tests de charge: $Duration secondes
- Concurrence des tests de charge: $Concurrency

## Fichiers gÃ©nÃ©rÃ©s

- [RÃ©sultats de benchmark]($benchmarkResultsPath)
- [RÃ©sultats de test de charge]($loadTestResultsPath)
"@

if ($GenerateReport -and $previousBenchmarkFiles.Count -gt 0) {
    $summary += "`n- [Rapport de comparaison]($comparisonReportPath)"
}

$summary | Set-Content -Path $summaryPath -Encoding UTF8
Write-Host "RÃ©sumÃ© des tests de performance enregistrÃ©: $summaryPath"

Write-Host "`nTous les tests de performance ont Ã©tÃ© exÃ©cutÃ©s avec succÃ¨s!"
Write-Host "RÃ©sultats de benchmark: $benchmarkResultsPath"
Write-Host "RÃ©sultats de test de charge: $loadTestResultsPath"

if ($GenerateReport -and $previousBenchmarkFiles.Count -gt 0) {
    Write-Host "Rapport de comparaison: $comparisonReportPath"
}

Write-Host "RÃ©sumÃ©: $summaryPath"
