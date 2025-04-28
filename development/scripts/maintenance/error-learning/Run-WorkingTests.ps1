<#
.SYNOPSIS
    Script pour exÃ©cuter tous les tests qui fonctionnent correctement.
.DESCRIPTION
    Ce script exÃ©cute tous les tests qui fonctionnent correctement du systÃ¨me d'apprentissage des erreurs.
.EXAMPLE
    .\Run-WorkingTests.ps1
    ExÃ©cute tous les tests qui fonctionnent correctement.
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

# DÃ©finir le chemin des tests qui fonctionnent correctement
$testFiles = @(
    (Join-Path -Path $PSScriptRoot -ChildPath "Tests\VeryBasic.Tests.ps1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "Tests\Basic.Tests.ps1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "Tests\SimpleIntegration.Tests.ps1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "Tests\ErrorFunctions.Tests.ps1")
)

# Afficher les tests trouvÃ©s
Write-Host "Tests qui fonctionnent correctement trouvÃ©s :" -ForegroundColor Cyan
foreach ($testFile in $testFiles) {
    Write-Host "  $([System.IO.Path]::GetFileName($testFile))" -ForegroundColor Yellow
}

# ExÃ©cuter les tests
Write-Host "`nExÃ©cution des tests qui fonctionnent correctement..." -ForegroundColor Cyan
$totalTests = 0
$passedTests = 0
$failedTests = 0
$skippedTests = 0

# ExÃ©cuter chaque test individuellement
foreach ($testFile in $testFiles) {
    Write-Host "  ExÃ©cution de $([System.IO.Path]::GetFileName($testFile))..." -ForegroundColor Yellow
    
    # ExÃ©cuter le test
    $result = Invoke-Pester -Path $testFile -Output Detailed -PassThru
    
    # Mettre Ã  jour les rÃ©sultats
    $totalTests += $result.TotalCount
    $passedTests += $result.PassedCount
    $failedTests += $result.FailedCount
    $skippedTests += $result.SkippedCount
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $totalTests" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $passedTests" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $failedTests" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $skippedTests" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basÃ© sur les rÃ©sultats des tests
exit $failedTests
