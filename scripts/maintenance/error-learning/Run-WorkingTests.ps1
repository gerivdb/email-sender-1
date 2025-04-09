<#
.SYNOPSIS
    Script pour exécuter tous les tests qui fonctionnent correctement.
.DESCRIPTION
    Ce script exécute tous les tests qui fonctionnent correctement du système d'apprentissage des erreurs.
.EXAMPLE
    .\Run-WorkingTests.ps1
    Exécute tous les tests qui fonctionnent correctement.
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

# Définir le chemin des tests qui fonctionnent correctement
$testFiles = @(
    (Join-Path -Path $PSScriptRoot -ChildPath "Tests\VeryBasic.Tests.ps1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "Tests\Basic.Tests.ps1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "Tests\SimpleIntegration.Tests.ps1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "Tests\ErrorFunctions.Tests.ps1")
)

# Afficher les tests trouvés
Write-Host "Tests qui fonctionnent correctement trouvés :" -ForegroundColor Cyan
foreach ($testFile in $testFiles) {
    Write-Host "  $([System.IO.Path]::GetFileName($testFile))" -ForegroundColor Yellow
}

# Exécuter les tests
Write-Host "`nExécution des tests qui fonctionnent correctement..." -ForegroundColor Cyan
$totalTests = 0
$passedTests = 0
$failedTests = 0
$skippedTests = 0

# Exécuter chaque test individuellement
foreach ($testFile in $testFiles) {
    Write-Host "  Exécution de $([System.IO.Path]::GetFileName($testFile))..." -ForegroundColor Yellow
    
    # Exécuter le test
    $result = Invoke-Pester -Path $testFile -Output Detailed -PassThru
    
    # Mettre à jour les résultats
    $totalTests += $result.TotalCount
    $passedTests += $result.PassedCount
    $failedTests += $result.FailedCount
    $skippedTests += $result.SkippedCount
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $totalTests" -ForegroundColor White
Write-Host "  Tests réussis: $passedTests" -ForegroundColor Green
Write-Host "  Tests échoués: $failedTests" -ForegroundColor Red
Write-Host "  Tests ignorés: $skippedTests" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basé sur les résultats des tests
exit $failedTests
