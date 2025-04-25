<#
.SYNOPSIS
    Exécute les tests unitaires pour le module ProactiveOptimization en ignorant les tests problématiques.
.DESCRIPTION
    Ce script exécute les tests unitaires pour le module ProactiveOptimization en ignorant les tests problématiques.
    Il utilise le framework Pester pour exécuter les tests.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$GenerateCodeCoverage,

    [Parameter(Mandatory = $false)]
    [switch]$ShowDetailedResults
)

# Chemin vers les tests
$testsPath = $PSScriptRoot
$modulePath = Split-Path -Path $testsPath -Parent
$scriptFiles = Get-ChildItem -Path $modulePath -Filter "*.ps1" | Where-Object { $_.Name -notlike "Test-*" }

# Vérifier que le module mock UsageMonitor existe
$mockModulePath = Join-Path -Path $testsPath -ChildPath "MockUsageMonitor.psm1"
if (-not (Test-Path -Path $mockModulePath)) {
    Write-Error "Module mock UsageMonitor non trouvé: $mockModulePath"
    exit 1
}

# Charger les fonctions mock pour les tests
$mockFunctionsPath = Join-Path -Path $testsPath -ChildPath "MockFunctions.ps1"
if (Test-Path -Path $mockFunctionsPath) {
    . $mockFunctionsPath
    Write-Host "Fonctions mock chargées avec succès." -ForegroundColor Green
} else {
    Write-Warning "Script de fonctions mock non trouvé: $mockFunctionsPath"
}

# Afficher les tests qui seront exécutés
$testScripts = Get-ChildItem -Path $testsPath -Filter "*.Tests.ps1"
if ($testScripts.Count -eq 0) {
    Write-Error "Aucun test trouvé dans le dossier: $testsPath"
    exit 1
}

Write-Host "Tests à exécuter:" -ForegroundColor Cyan
foreach ($testScript in $testScripts) {
    Write-Host "  - $($testScript.Name)" -ForegroundColor Cyan
}

# Exécuter les tests
Write-Host "Exécution des tests unitaires pour le module ProactiveOptimization..." -ForegroundColor Cyan

# Paramètres pour Invoke-Pester
$pesterParams = @{
    Path       = $testsPath
    PassThru   = $true
    ExcludeTag = @(
        'RequiresUsageMonitor',
        'RequiresFileAccess',
        'RequiresParallelization',
        'RequiresReportGeneration'
    )
}

# Ajouter les paramètres de couverture de code si demandé
if ($GenerateCodeCoverage) {
    $pesterParams.CodeCoverage = $scriptFiles.FullName
    $pesterParams.CodeCoverageOutputFile = Join-Path -Path $testsPath -ChildPath "coverage.xml"
    $pesterParams.CodeCoverageOutputFormat = 'JaCoCo'
}

# Ajouter le paramètre de verbosité si demandé
if ($ShowDetailedResults) {
    $pesterParams.Output = 'Detailed'
}

# Exécuter les tests
$results = Invoke-Pester @pesterParams

# Afficher le résumé des tests
Write-Host "Résumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $($results.TotalCount)" -ForegroundColor Cyan
Write-Host "  Tests réussis: $($results.PassedCount)" -ForegroundColor $(if ($results.PassedCount -eq $results.TotalCount) { 'Green' } else { 'Cyan' })
Write-Host "  Tests échoués: $($results.FailedCount)" -ForegroundColor $(if ($results.FailedCount -gt 0) { 'Red' } else { 'Cyan' })
Write-Host "  Tests ignorés: $($results.SkippedCount)" -ForegroundColor Cyan
Write-Host "  Tests non exécutés: $($results.NotRunCount)" -ForegroundColor Cyan

# Retourner le code de sortie
exit $results.FailedCount
