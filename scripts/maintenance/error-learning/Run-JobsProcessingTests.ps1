<#
.SYNOPSIS
    Script pour exécuter les tests des scripts de traitement avec Jobs PowerShell.
.DESCRIPTION
    Ce script exécute les tests des scripts de traitement avec Jobs PowerShell.
.EXAMPLE
    .\Run-JobsProcessingTests.ps1
    Exécute les tests des scripts de traitement avec Jobs PowerShell.
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

# Définir le chemin du test des scripts de traitement avec Jobs PowerShell
$testFile = Join-Path -Path $PSScriptRoot -ChildPath "Tests\JobsProcessing.Tests.ps1"

# Afficher les tests trouvés
Write-Host "Test des scripts de traitement avec Jobs PowerShell trouvé :" -ForegroundColor Cyan
Write-Host "  JobsProcessing.Tests.ps1" -ForegroundColor Yellow

# Exécuter les tests
Write-Host "`nExécution des tests des scripts de traitement avec Jobs PowerShell..." -ForegroundColor Cyan
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
