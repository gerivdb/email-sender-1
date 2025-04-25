#
# Run-ValidationTests.ps1
#
# Script pour exécuter tous les tests unitaires des fonctions de validation
#

# Vérifier si Pester est installé
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# Obtenir le chemin du script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Obtenir le chemin des tests de validation
$validationTestsPath = Join-Path -Path $scriptPath -ChildPath "Validation"

# Exécuter les tests
Write-Host "Exécution des tests unitaires des fonctions de validation..." -ForegroundColor Cyan

$testResults = Invoke-Pester -Path $validationTestsPath -PassThru

# Afficher les résultats
Write-Host "`nRésultats des tests :" -ForegroundColor Cyan
Write-Host "  Tests exécutés : $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis : $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués : $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -eq 0) { "Green" } else { "Red" })
Write-Host "  Tests ignorés : $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Tests non exécutés : $($testResults.NotRunCount)" -ForegroundColor Yellow

# Afficher les tests échoués
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nTests échoués :" -ForegroundColor Red
    foreach ($testResult in $testResults.TestResult | Where-Object { $_.Result -eq "Failed" }) {
        Write-Host "  $($testResult.Describe) > $($testResult.Context) > $($testResult.Name)" -ForegroundColor Red
        Write-Host "    $($testResult.FailureMessage)" -ForegroundColor Red
    }
}

# Retourner le nombre de tests échoués
return $testResults.FailedCount
