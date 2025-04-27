<#
.SYNOPSIS
    Script pour exÃ©cuter les tests des fonctions du systÃ¨me d'apprentissage des erreurs.
.DESCRIPTION
    Ce script exÃ©cute les tests des fonctions principales du systÃ¨me d'apprentissage des erreurs.
.EXAMPLE
    .\Run-FunctionTests.ps1
    ExÃ©cute les tests des fonctions.
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

# DÃ©finir le chemin des tests des fonctions
$testFiles = @(
    (Join-Path -Path $PSScriptRoot -ChildPath "Tests\ErrorFunctions.Tests.ps1")
)

# Afficher les tests trouvÃ©s
Write-Host "Tests des fonctions trouvÃ©s :" -ForegroundColor Cyan
foreach ($testFile in $testFiles) {
    Write-Host "  $([System.IO.Path]::GetFileName($testFile))" -ForegroundColor Yellow
}

# ExÃ©cuter les tests
Write-Host "`nExÃ©cution des tests des fonctions..." -ForegroundColor Cyan
$results = Invoke-Pester -Path $testFiles -Output Detailed -PassThru

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($results.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($results.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basÃ© sur les rÃ©sultats des tests
exit $results.FailedCount
