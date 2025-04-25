<#
.SYNOPSIS
    Exécute tous les tests unitaires pour le module ProactiveOptimization.
.DESCRIPTION
    Ce script exécute tous les tests unitaires pour le module ProactiveOptimization
    et génère un rapport de couverture de code.
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

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir les chemins
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
    # Renommer les fichiers de test pour suivre la convention de nommage Pester
    $oldTestScripts = Get-ChildItem -Path $testsPath -Filter "Test-*.ps1"
    Write-Host "Renommage des fichiers de test:" -ForegroundColor Cyan
    foreach ($test in $oldTestScripts) {
        $newName = $test.BaseName.Replace("Test-", "") + ".Tests.ps1"
        $newPath = Join-Path -Path $testsPath -ChildPath $newName

        # Renommer le fichier s'il n'existe pas déjà
        if (-not (Test-Path -Path $newPath)) {
            Write-Host "  - Renommage de $($test.Name) en $newName" -ForegroundColor Yellow
            Rename-Item -Path $test.FullName -NewName $newName -Force
        } else {
            Write-Host "  - $newName existe déjà" -ForegroundColor White
        }
    }

    # Récupérer la liste mise à jour des fichiers de test
    $testScripts = Get-ChildItem -Path $testsPath -Filter "*.Tests.ps1"
}

Write-Host "Tests à exécuter:" -ForegroundColor Cyan
foreach ($test in $testScripts) {
    Write-Host "  - $($test.Name)" -ForegroundColor White
}

# Configurer les options de Pester
$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = $testsPath
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'

# Configurer la couverture de code si demandée
if ($GenerateCodeCoverage) {
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = $scriptFiles.FullName
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $testsPath -ChildPath "coverage.xml"
    $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
}

# Exécuter les tests
Write-Host "Exécution des tests unitaires pour le module ProactiveOptimization..." -ForegroundColor Cyan
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $($results.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués: $($results.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorés: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Tests non exécutés: $($results.NotRunCount)" -ForegroundColor Gray

# Afficher les résultats détaillés si demandé
if ($ShowDetailedResults -and $results.FailedCount -gt 0) {
    Write-Host "`nTests échoués:" -ForegroundColor Red
    foreach ($failure in $results.Failed) {
        Write-Host "  - $($failure.Name)" -ForegroundColor Red
        Write-Host "    $($failure.ErrorRecord.Exception.Message)" -ForegroundColor Red
    }
}

# Afficher les informations de couverture de code si générées
if ($GenerateCodeCoverage) {
    Write-Host "`nCouverture de code:" -ForegroundColor Cyan
    Write-Host "  Rapport de couverture généré: $(Join-Path -Path $testsPath -ChildPath 'coverage.xml')" -ForegroundColor White

    # Calculer le pourcentage de couverture
    $coverage = $results.CodeCoverage
    if ($coverage) {
        $totalCommands = $coverage.NumberOfCommandsAnalyzed
        $coveredCommands = $coverage.NumberOfCommandsExecuted
        $coveragePercent = if ($totalCommands -gt 0) { [math]::Round(($coveredCommands / $totalCommands) * 100, 2) } else { 0 }

        Write-Host "  Lignes analysées: $totalCommands" -ForegroundColor White
        Write-Host "  Lignes couvertes: $coveredCommands" -ForegroundColor White

        $coverageColor = switch ($coveragePercent) {
            { $_ -ge 90 } { "Green" }
            { $_ -ge 75 } { "Yellow" }
            default { "Red" }
        }

        Write-Host "  Pourcentage de couverture: $coveragePercent%" -ForegroundColor $coverageColor
    }
}

# Retourner le statut de succès/échec
exit $results.FailedCount
