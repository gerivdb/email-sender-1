<#
.SYNOPSIS
    Script pour exécuter les tests d'apprentissage adaptatif du système d'apprentissage des erreurs.
.DESCRIPTION
    Ce script exécute les tests d'apprentissage adaptatif du système d'apprentissage des erreurs.
.EXAMPLE
    .\Run-AdaptiveLearningTests.ps1
    Exécute les tests d'apprentissage adaptatif.
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

# Définir le chemin du test d'apprentissage adaptatif
$testFile = Join-Path -Path $PSScriptRoot -ChildPath "Tests\AdaptiveLearning.Tests.ps1"

# Afficher les tests trouvés
Write-Host "Test d'apprentissage adaptatif trouvé :" -ForegroundColor Cyan
Write-Host "  AdaptiveLearning.Tests.ps1" -ForegroundColor Yellow

# Exécuter les tests
Write-Host "`nExécution des tests d'apprentissage adaptatif..." -ForegroundColor Cyan
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
