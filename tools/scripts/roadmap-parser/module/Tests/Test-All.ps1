#
# Test-All.ps1
#
# Script pour exécuter tous les tests du module
#

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Configurer Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'

# Importer le module TestHelpers qui contient les fonctions de validation
$testHelpersPath = Join-Path -Path $PSScriptRoot -ChildPath "TestHelpers.psm1"
Import-Module -Name $testHelpersPath -Force

# Exécuter les tests
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:"
Write-Host "Tests exécutés: $($results.TotalCount)"
Write-Host "Tests réussis: $($results.PassedCount)"
Write-Host "Tests échoués: $($results.FailedCount)"
Write-Host "Tests ignorés: $($results.SkippedCount)"
Write-Host "Tests non exécutés: $($results.NotRunCount)"

# Retourner un code d'erreur si des tests ont échoué
if ($results.FailedCount -gt 0) {
    Write-Host "`nDes tests ont échoué. Consultez les détails ci-dessus." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
}
