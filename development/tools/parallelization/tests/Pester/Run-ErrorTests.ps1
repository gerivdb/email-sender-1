# Script pour exécuter les tests d'erreur
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

# Configurer Pester
$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = Join-Path -Path $PSScriptRoot -ChildPath "New-UnifiedError.Tests.ps1"
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.Run.PassThru = $true
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"
$pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\coverage\ErrorTests.xml"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputFormat = "NUnitXml"
$pesterConfig.TestResult.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\coverage\ErrorTests.TestResults.xml"

# Créer le répertoire de couverture s'il n'existe pas
$coverageDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\coverage"
if (-not (Test-Path -Path $coverageDir)) {
    New-Item -Path $coverageDir -ItemType Directory -Force | Out-Null
}

# Exécuter les tests
Write-Host "Exécution des tests unitaires pour la fonction New-UnifiedError..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher le résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "Total des tests: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "Durée totale: $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher les informations de couverture de code
$codeCoverage = $testResults.CodeCoverage
if ($null -ne $codeCoverage) {
    $coverage = [math]::Round(($codeCoverage.CommandsExecutedCount / $codeCoverage.CommandsAnalyzedCount) * 100, 2)
    Write-Host "`nCouverture de code:" -ForegroundColor Cyan
    Write-Host "Commandes analysées: $($codeCoverage.CommandsAnalyzedCount)" -ForegroundColor White
    Write-Host "Commandes exécutées: $($codeCoverage.CommandsExecutedCount)" -ForegroundColor White
    Write-Host "Couverture: $coverage%" -ForegroundColor $(if ($coverage -ge 95) { "Green" } elseif ($coverage -ge 80) { "Yellow" } else { "Red" })
}

# Afficher les résultats détaillés des tests
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nTests échoués:" -ForegroundColor Red
    foreach ($test in $testResults.Failed) {
        Write-Host "- $($test.Name)" -ForegroundColor Red
        Write-Host "  Message: $($test.ErrorRecord.Exception.Message)" -ForegroundColor Red
        Write-Host "  Ligne: $($test.ErrorRecord.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
        Write-Host "  Script: $($test.ErrorRecord.InvocationInfo.ScriptName)" -ForegroundColor Red
    }
}

# Retourner le résultat des tests
return $testResults
