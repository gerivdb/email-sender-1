<#
.SYNOPSIS
    Script pour exécuter les tests de validation des corrections du système d'apprentissage des erreurs.
.DESCRIPTION
    Ce script exécute les tests de validation des corrections du système d'apprentissage des erreurs.
.EXAMPLE
    .\Run-ValidationCorrectionsTests.ps1
    Exécute les tests de validation des corrections.
#>

[CmdletBinding()]
param ()

# Vérifier que Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir le chemin du test de validation des corrections
$testFile = Join-Path -Path $PSScriptRoot -ChildPath "Tests\ValidationCorrections.Tests.ps1"

# Afficher les tests trouvés
Write-Host "Test de validation des corrections trouvé :" -ForegroundColor Cyan
Write-Host "  ValidationCorrections.Tests.ps1" -ForegroundColor Yellow

# Exécuter les tests
Write-Host "`nExécution des tests de validation des corrections..." -ForegroundColor Cyan
$results = Invoke-Pester -Path $testFile -Output Detailed -PassThru

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $($results.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués: $($results.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorés: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basé sur les résultats des tests
exit $results.FailedCount
