#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests unitaires pour le systÃ¨me d'analyse prÃ©dictive.
.DESCRIPTION
    Ce script exÃ©cute les tests unitaires pour vÃ©rifier le bon fonctionnement
    du systÃ¨me d'analyse prÃ©dictive.
.EXAMPLE
    .\Run-PredictiveAnalysisTests.ps1
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param()

# Obtenir le rÃ©pertoire du script
$scriptDir = $PSScriptRoot

# Obtenir les scripts de test pour l'analyse prÃ©dictive
$testScripts = @(
    "Test-PredictiveAnalysisUnit.ps1",
    "Test-RiskScoreCalculation.ps1",
    "Test-ErrorHistory.ps1"
)

# Afficher les informations sur les tests
Write-Host "Tests unitaires pour le systÃ¨me d'analyse prÃ©dictive" -ForegroundColor Cyan
Write-Host "Nombre de scripts de test: $($testScripts.Count)" -ForegroundColor Cyan
Write-Host ""

# ExÃ©cuter chaque script de test
$results = @()

foreach ($script in $testScripts) {
    $scriptPath = Join-Path -Path $scriptDir -ChildPath $script

    if (Test-Path -Path $scriptPath) {
        Write-Host "ExÃ©cution de $script..." -ForegroundColor Yellow

        $startTime = Get-Date
        & $scriptPath | Out-Null
        $endTime = Get-Date
        $duration = $endTime - $startTime

        $exitCode = $LASTEXITCODE
        $success = $exitCode -eq 0

        $results += [PSCustomObject]@{
            Script   = $script
            Success  = $success
            Duration = $duration
            ExitCode = $exitCode
        }

        Write-Host "  RÃ©sultat: $(if ($success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
        Write-Host "  DurÃ©e: $($duration.TotalSeconds) secondes" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Warning "Script non trouvÃ©: $scriptPath"
    }
}

# Afficher un rÃ©sumÃ© des tests
$successCount = ($results | Where-Object { $_.Success }).Count
$failureCount = ($results | Where-Object { -not $_.Success }).Count
$totalCount = $results.Count
$totalSeconds = ($results | ForEach-Object { $_.Duration.TotalSeconds } | Measure-Object -Sum).Sum

Write-Host "RÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Scripts rÃ©ussis: $successCount" -ForegroundColor Green
Write-Host "  Scripts Ã©chouÃ©s: $failureCount" -ForegroundColor Red
Write-Host "  Total: $totalCount" -ForegroundColor White
Write-Host "  DurÃ©e totale: $([Math]::Round($totalSeconds, 2)) secondes" -ForegroundColor Gray
Write-Host ""

# Afficher les dÃ©tails des Ã©checs
if ($failureCount -gt 0) {
    Write-Host "DÃ©tails des Ã©checs:" -ForegroundColor Red

    foreach ($result in $results | Where-Object { -not $_.Success }) {
        Write-Host "  $($result.Script) (Code de sortie: $($result.ExitCode))" -ForegroundColor Red
    }

    Write-Host ""
}

# Retourner le rÃ©sultat global
$success = $failureCount -eq 0
Write-Host "RÃ©sultat global: $(if ($success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
exit $(if ($success) { 0 } else { 1 })
