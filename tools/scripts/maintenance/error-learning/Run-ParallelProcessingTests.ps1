<#
.SYNOPSIS
    Script pour exécuter les tests des scripts de traitement parallèle.
.DESCRIPTION
    Ce script exécute les tests des scripts de traitement parallèle.
.EXAMPLE
    .\Run-ParallelProcessingTests.ps1
    Exécute les tests des scripts de traitement parallèle.
#>

[CmdletBinding()]
param ()

# Vérifier la version de PowerShell
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "Les tests de parallélisation nécessitent PowerShell 7.0 ou supérieur. Certains tests seront ignorés."
}

# Vérifier que Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir le chemin du test des scripts de traitement parallèle
$testFile = Join-Path -Path $PSScriptRoot -ChildPath "Tests\ParallelProcessing.Tests.ps1"

# Afficher les tests trouvés
Write-Host "Test des scripts de traitement parallèle trouvé :" -ForegroundColor Cyan
Write-Host "  ParallelProcessing.Tests.ps1" -ForegroundColor Yellow

# Exécuter les tests
Write-Host "`nExécution des tests des scripts de traitement parallèle..." -ForegroundColor Cyan
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
