<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour le module ProactiveOptimization.
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour le module ProactiveOptimization
    et gÃ©nÃ¨re un rapport de couverture de code.
.EXAMPLE
    .\Run-AllTests.ps1
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$GenerateCodeCoverage,

    [Parameter(Mandatory = $false)]
    [switch]$ShowDetailedResults
)

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# DÃ©finir les chemins
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
    # Renommer les fichiers de test pour suivre la convention de nommage Pester
    $oldTestScripts = Get-ChildItem -Path $testsPath -Filter "Test-*.ps1"
    Write-Host "Renommage des fichiers de test:" -ForegroundColor Cyan
    foreach ($test in $oldTestScripts) {
        $newName = $test.BaseName.Replace("Test-", "") + ".Tests.ps1"
        $newPath = Join-Path -Path $testsPath -ChildPath $newName

        # Renommer le fichier s'il n'existe pas dÃ©jÃ 
        if (-not (Test-Path -Path $newPath)) {
            Write-Host "  - Renommage de $($test.Name) en $newName" -ForegroundColor Yellow
            Rename-Item -Path $test.FullName -NewName $newName -Force
        } else {
            Write-Host "  - $newName existe dÃ©jÃ " -ForegroundColor White
        }
    }

    # RÃ©cupÃ©rer la liste mise Ã  jour des fichiers de test
    $testScripts = Get-ChildItem -Path $testsPath -Filter "*.Tests.ps1"
}

Write-Host "Tests Ã  exÃ©cuter:" -ForegroundColor Cyan
foreach ($test in $testScripts) {
    Write-Host "  - $($test.Name)" -ForegroundColor White
}

# Configurer les options de Pester
$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = $testsPath
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'

# Configurer la couverture de code si demandÃ©e
if ($GenerateCodeCoverage) {
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = $scriptFiles.FullName
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $testsPath -ChildPath "coverage.xml"
    $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
}

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests unitaires pour le module ProactiveOptimization..." -ForegroundColor Cyan
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($results.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($results.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Tests non exÃ©cutÃ©s: $($results.NotRunCount)" -ForegroundColor Gray

# Afficher les rÃ©sultats dÃ©taillÃ©s si demandÃ©
if ($ShowDetailedResults -and $results.FailedCount -gt 0) {
    Write-Host "`nTests Ã©chouÃ©s:" -ForegroundColor Red
    foreach ($failure in $results.Failed) {
        Write-Host "  - $($failure.Name)" -ForegroundColor Red
        Write-Host "    $($failure.ErrorRecord.Exception.Message)" -ForegroundColor Red
    }
}

# Afficher les informations de couverture de code si gÃ©nÃ©rÃ©es
if ($GenerateCodeCoverage) {
    Write-Host "`nCouverture de code:" -ForegroundColor Cyan
    Write-Host "  Rapport de couverture gÃ©nÃ©rÃ©: $(Join-Path -Path $testsPath -ChildPath 'coverage.xml')" -ForegroundColor White

    # Calculer le pourcentage de couverture
    $coverage = $results.CodeCoverage
    if ($coverage) {
        $totalCommands = $coverage.NumberOfCommandsAnalyzed
        $coveredCommands = $coverage.NumberOfCommandsExecuted
        $coveragePercent = if ($totalCommands -gt 0) { [math]::Round(($coveredCommands / $totalCommands) * 100, 2) } else { 0 }

        Write-Host "  Lignes analysÃ©es: $totalCommands" -ForegroundColor White
        Write-Host "  Lignes couvertes: $coveredCommands" -ForegroundColor White

        $coverageColor = switch ($coveragePercent) {
            { $_ -ge 90 } { "Green" }
            { $_ -ge 75 } { "Yellow" }
            default { "Red" }
        }

        Write-Host "  Pourcentage de couverture: $coveragePercent%" -ForegroundColor $coverageColor
    }
}

# Retourner le statut de succÃ¨s/Ã©chec
exit $results.FailedCount
