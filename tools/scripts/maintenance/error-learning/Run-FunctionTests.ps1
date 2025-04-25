<#
.SYNOPSIS
    Script pour exécuter les tests des fonctions du système d'apprentissage des erreurs.
.DESCRIPTION
    Ce script exécute les tests des fonctions principales du système d'apprentissage des erreurs.
.EXAMPLE
    .\Run-FunctionTests.ps1
    Exécute les tests des fonctions.
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

# Définir le chemin des tests des fonctions
$testFiles = @(
    (Join-Path -Path $PSScriptRoot -ChildPath "Tests\ErrorFunctions.Tests.ps1")
)

# Afficher les tests trouvés
Write-Host "Tests des fonctions trouvés :" -ForegroundColor Cyan
foreach ($testFile in $testFiles) {
    Write-Host "  $([System.IO.Path]::GetFileName($testFile))" -ForegroundColor Yellow
}

# Exécuter les tests
Write-Host "`nExécution des tests des fonctions..." -ForegroundColor Cyan
$results = Invoke-Pester -Path $testFiles -Output Detailed -PassThru

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $($results.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués: $($results.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorés: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basé sur les résultats des tests
exit $results.FailedCount
