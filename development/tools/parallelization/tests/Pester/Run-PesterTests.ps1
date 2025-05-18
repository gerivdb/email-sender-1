# Script pour exécuter tous les tests Pester
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -MinimumVersion 5.0.0 -Force

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

# Chemin des tests
$testsPath = $PSScriptRoot

# Créer le dossier de rapports s'il n'existe pas
$reportsPath = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path -Path $reportsPath)) {
    New-Item -Path $reportsPath -ItemType Directory -Force | Out-Null
}

# Configuration des tests
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testsPath
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = $modulePath
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $reportsPath -ChildPath "coverage.xml"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'
$pesterConfig.TestResult.OutputPath = Join-Path -Path $reportsPath -ChildPath "testResults.xml"

# Exécuter les tests
Write-Host "Exécution des tests unitaires pour le module UnifiedParallel..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher le résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "Total des tests: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "Durée totale: $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher le résumé de la couverture de code
Write-Host "`nRésumé de la couverture de code:" -ForegroundColor Cyan
$coverageSummary = $testResults.CodeCoverage.CommandsAnalyzedCount
$coveredCommands = $testResults.CodeCoverage.CommandsExecutedCount
$coveragePercent = if ($coverageSummary -gt 0) { [math]::Round(($coveredCommands / $coverageSummary) * 100, 2) } else { 0 }

Write-Host "Commandes analysées: $coverageSummary" -ForegroundColor White
Write-Host "Commandes couvertes: $coveredCommands" -ForegroundColor White
Write-Host "Pourcentage de couverture: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 95) { "Green" } elseif ($coveragePercent -ge 80) { "Yellow" } else { "Red" })

# Afficher le chemin du rapport de couverture
Write-Host "`nRapport de couverture généré: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor Cyan
Write-Host "Rapport de tests généré: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor Cyan

# Retourner les résultats des tests
return $testResults
