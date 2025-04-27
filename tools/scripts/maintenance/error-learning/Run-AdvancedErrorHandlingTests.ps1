<#
.SYNOPSIS
    Script pour exÃ©cuter les tests de gestion des erreurs avancÃ©e du systÃ¨me d'apprentissage des erreurs.
.DESCRIPTION
    Ce script exÃ©cute les tests de gestion des erreurs avancÃ©e du systÃ¨me d'apprentissage des erreurs.
.EXAMPLE
    .\Run-AdvancedErrorHandlingTests.ps1
    ExÃ©cute les tests de gestion des erreurs avancÃ©e.
#>

[CmdletBinding()]
param ()

# VÃ©rifier que Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# DÃ©finir le chemin du test de gestion des erreurs avancÃ©e
$testFile = Join-Path -Path $PSScriptRoot -ChildPath "Tests\AdvancedErrorHandling.Tests.ps1"

# Afficher les tests trouvÃ©s
Write-Host "Test de gestion des erreurs avancÃ©e trouvÃ© :" -ForegroundColor Cyan
Write-Host "  AdvancedErrorHandling.Tests.ps1" -ForegroundColor Yellow

# ExÃ©cuter les tests
Write-Host "`nExÃ©cution des tests de gestion des erreurs avancÃ©e..." -ForegroundColor Cyan
$results = Invoke-Pester -Path $testFile -Output Detailed -PassThru

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($results.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($results.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basÃ© sur les rÃ©sultats des tests
exit $results.FailedCount
