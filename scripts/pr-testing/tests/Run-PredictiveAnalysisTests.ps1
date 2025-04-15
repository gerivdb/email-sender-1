#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests unitaires pour le système d'analyse prédictive.
.DESCRIPTION
    Ce script exécute les tests unitaires pour vérifier le bon fonctionnement
    du système d'analyse prédictive.
.EXAMPLE
    .\Run-PredictiveAnalysisTests.ps1
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param()

# Obtenir le répertoire du script
$scriptDir = $PSScriptRoot

# Obtenir les scripts de test pour l'analyse prédictive
$testScripts = @(
    "Test-PredictiveAnalysisUnit.ps1",
    "Test-RiskScoreCalculation.ps1",
    "Test-ErrorHistory.ps1"
)

# Afficher les informations sur les tests
Write-Host "Tests unitaires pour le système d'analyse prédictive" -ForegroundColor Cyan
Write-Host "Nombre de scripts de test: $($testScripts.Count)" -ForegroundColor Cyan
Write-Host ""

# Exécuter chaque script de test
$results = @()

foreach ($script in $testScripts) {
    $scriptPath = Join-Path -Path $scriptDir -ChildPath $script

    if (Test-Path -Path $scriptPath) {
        Write-Host "Exécution de $script..." -ForegroundColor Yellow

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

        Write-Host "  Résultat: $(if ($success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
        Write-Host "  Durée: $($duration.TotalSeconds) secondes" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Warning "Script non trouvé: $scriptPath"
    }
}

# Afficher un résumé des tests
$successCount = ($results | Where-Object { $_.Success }).Count
$failureCount = ($results | Where-Object { -not $_.Success }).Count
$totalCount = $results.Count
$totalSeconds = ($results | ForEach-Object { $_.Duration.TotalSeconds } | Measure-Object -Sum).Sum

Write-Host "Résumé des tests:" -ForegroundColor Cyan
Write-Host "  Scripts réussis: $successCount" -ForegroundColor Green
Write-Host "  Scripts échoués: $failureCount" -ForegroundColor Red
Write-Host "  Total: $totalCount" -ForegroundColor White
Write-Host "  Durée totale: $([Math]::Round($totalSeconds, 2)) secondes" -ForegroundColor Gray
Write-Host ""

# Afficher les détails des échecs
if ($failureCount -gt 0) {
    Write-Host "Détails des échecs:" -ForegroundColor Red

    foreach ($result in $results | Where-Object { -not $_.Success }) {
        Write-Host "  $($result.Script) (Code de sortie: $($result.ExitCode))" -ForegroundColor Red
    }

    Write-Host ""
}

# Retourner le résultat global
$success = $failureCount -eq 0
Write-Host "Résultat global: $(if ($success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
exit $(if ($success) { 0 } else { 1 })
