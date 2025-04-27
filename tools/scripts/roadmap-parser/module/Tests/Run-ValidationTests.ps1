#
# Run-ValidationTests.ps1
#
# Script pour exÃ©cuter tous les tests unitaires des fonctions de validation
#

# VÃ©rifier si Pester est installÃ©
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

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests unitaires des fonctions de validation..." -ForegroundColor Cyan

$testResults = Invoke-Pester -Path $validationTestsPath -PassThru

# Afficher les rÃ©sultats
Write-Host "`nRÃ©sultats des tests :" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s : $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis : $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s : $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -eq 0) { "Green" } else { "Red" })
Write-Host "  Tests ignorÃ©s : $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Tests non exÃ©cutÃ©s : $($testResults.NotRunCount)" -ForegroundColor Yellow

# Afficher les tests Ã©chouÃ©s
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nTests Ã©chouÃ©s :" -ForegroundColor Red
    foreach ($testResult in $testResults.TestResult | Where-Object { $_.Result -eq "Failed" }) {
        Write-Host "  $($testResult.Describe) > $($testResult.Context) > $($testResult.Name)" -ForegroundColor Red
        Write-Host "    $($testResult.FailureMessage)" -ForegroundColor Red
    }
}

# Retourner le nombre de tests Ã©chouÃ©s
return $testResults.FailedCount
