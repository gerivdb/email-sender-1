<#
.SYNOPSIS
    Script pour exécuter les tests basiques du système d'apprentissage des erreurs.
.DESCRIPTION
    Ce script exécute uniquement les tests basiques du système d'apprentissage des erreurs.
.EXAMPLE
    .\Run-BasicTests.ps1
    Exécute les tests basiques.
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

# Définir le chemin des tests
$testRoot = Join-Path -Path $PSScriptRoot -ChildPath "Tests"
$basicTests = @(
    (Join-Path -Path $testRoot -ChildPath "Basic.Tests.ps1"),
    (Join-Path -Path $testRoot -ChildPath "Simple.Tests.ps1")
)

# Afficher les tests trouvés
Write-Host "Tests basiques trouvés :" -ForegroundColor Cyan
foreach ($testFile in $basicTests) {
    Write-Host "  $([System.IO.Path]::GetFileName($testFile))" -ForegroundColor Yellow
}

# Exécuter les tests
Write-Host "`nExécution des tests basiques..." -ForegroundColor Cyan
$results = Invoke-Pester -Path $basicTests -Output Detailed -PassThru

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $($results.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués: $($results.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorés: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basé sur les résultats des tests
exit $results.FailedCount
