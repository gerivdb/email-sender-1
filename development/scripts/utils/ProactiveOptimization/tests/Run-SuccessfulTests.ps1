<#
.SYNOPSIS
    ExÃ©cute les tests unitaires pour le module ProactiveOptimization en ignorant les tests problÃ©matiques.
.DESCRIPTION
    Ce script exÃ©cute les tests unitaires pour le module ProactiveOptimization en ignorant les tests problÃ©matiques.
    Il utilise le framework Pester pour exÃ©cuter les tests.
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

# VÃ©rifier que le module mock UsageMonitor existe
$mockModulePath = Join-Path -Path $testsPath -ChildPath "MockUsageMonitor.psm1"
if (-not (Test-Path -Path $mockModulePath)) {
    Write-Error "Module mock UsageMonitor non trouvÃ©: $mockModulePath"
    exit 1
}

# Charger les fonctions mock pour les tests
$mockFunctionsPath = Join-Path -Path $testsPath -ChildPath "MockFunctions.ps1"
if (Test-Path -Path $mockFunctionsPath) {
    . $mockFunctionsPath
    Write-Host "Fonctions mock chargÃ©es avec succÃ¨s." -ForegroundColor Green
} else {
    Write-Warning "Script de fonctions mock non trouvÃ©: $mockFunctionsPath"
}

# Afficher les tests qui seront exÃ©cutÃ©s
$testScripts = Get-ChildItem -Path $testsPath -Filter "*.Tests.ps1"
if ($testScripts.Count -eq 0) {
    Write-Error "Aucun test trouvÃ© dans le dossier: $testsPath"
    exit 1
}

Write-Host "Tests Ã  exÃ©cuter:" -ForegroundColor Cyan
foreach ($testScript in $testScripts) {
    Write-Host "  - $($testScript.Name)" -ForegroundColor Cyan
}

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests unitaires pour le module ProactiveOptimization..." -ForegroundColor Cyan

# ParamÃ¨tres pour Invoke-Pester
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

# Ajouter les paramÃ¨tres de couverture de code si demandÃ©
if ($GenerateCodeCoverage) {
    $pesterParams.CodeCoverage = $scriptFiles.FullName
    $pesterParams.CodeCoverageOutputFile = Join-Path -Path $testsPath -ChildPath "coverage.xml"
    $pesterParams.CodeCoverageOutputFormat = 'JaCoCo'
}

# Ajouter le paramÃ¨tre de verbositÃ© si demandÃ©
if ($ShowDetailedResults) {
    $pesterParams.Output = 'Detailed'
}

# ExÃ©cuter les tests
$results = Invoke-Pester @pesterParams

# Afficher le rÃ©sumÃ© des tests
Write-Host "RÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($results.TotalCount)" -ForegroundColor Cyan
Write-Host "  Tests rÃ©ussis: $($results.PassedCount)" -ForegroundColor $(if ($results.PassedCount -eq $results.TotalCount) { 'Green' } else { 'Cyan' })
Write-Host "  Tests Ã©chouÃ©s: $($results.FailedCount)" -ForegroundColor $(if ($results.FailedCount -gt 0) { 'Red' } else { 'Cyan' })
Write-Host "  Tests ignorÃ©s: $($results.SkippedCount)" -ForegroundColor Cyan
Write-Host "  Tests non exÃ©cutÃ©s: $($results.NotRunCount)" -ForegroundColor Cyan

# Retourner le code de sortie
exit $results.FailedCount
