<#
.SYNOPSIS
    Script pour exÃ©cuter les tests basiques du systÃ¨me d'apprentissage des erreurs.
.DESCRIPTION
    Ce script exÃ©cute uniquement les tests basiques du systÃ¨me d'apprentissage des erreurs.
.EXAMPLE
    .\Run-BasicTests.ps1
    ExÃ©cute les tests basiques.
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

# DÃ©finir le chemin des tests
$testRoot = Join-Path -Path $PSScriptRoot -ChildPath "Tests"
$basicTests = @(
    (Join-Path -Path $testRoot -ChildPath "Basic.Tests.ps1"),
    (Join-Path -Path $testRoot -ChildPath "Simple.Tests.ps1")
)

# Afficher les tests trouvÃ©s
Write-Host "Tests basiques trouvÃ©s :" -ForegroundColor Cyan
foreach ($testFile in $basicTests) {
    Write-Host "  $([System.IO.Path]::GetFileName($testFile))" -ForegroundColor Yellow
}

# ExÃ©cuter les tests
Write-Host "`nExÃ©cution des tests basiques..." -ForegroundColor Cyan
$results = Invoke-Pester -Path $basicTests -Output Detailed -PassThru

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($results.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($results.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basÃ© sur les rÃ©sultats des tests
exit $results.FailedCount
