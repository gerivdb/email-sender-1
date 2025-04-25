<#
.SYNOPSIS
    Script pour exécuter les tests d'intégration simplifiés du système d'apprentissage des erreurs.
.DESCRIPTION
    Ce script exécute les tests d'intégration simplifiés du système d'apprentissage des erreurs.
.EXAMPLE
    .\Run-SimpleIntegrationTests2.ps1
    Exécute les tests d'intégration simplifiés.
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

# Définir le chemin du test d'intégration simplifié
$testFile = Join-Path -Path $PSScriptRoot -ChildPath "Tests\ErrorLearningSystem.Integration.Simple.ps1"

# Afficher les tests trouvés
Write-Host "Test d'intégration simplifié trouvé :" -ForegroundColor Cyan
Write-Host "  ErrorLearningSystem.Integration.Simple.ps1" -ForegroundColor Yellow

# Exécuter les tests
Write-Host "`nExécution des tests d'intégration simplifiés..." -ForegroundColor Cyan
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
