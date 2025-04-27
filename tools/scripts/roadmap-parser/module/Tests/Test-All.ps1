#
# Test-All.ps1
#
# Script pour exÃ©cuter tous les tests du module
#

# VÃ©rifier si Pester est installÃ©
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

# ExÃ©cuter les tests
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:"
Write-Host "Tests exÃ©cutÃ©s: $($results.TotalCount)"
Write-Host "Tests rÃ©ussis: $($results.PassedCount)"
Write-Host "Tests Ã©chouÃ©s: $($results.FailedCount)"
Write-Host "Tests ignorÃ©s: $($results.SkippedCount)"
Write-Host "Tests non exÃ©cutÃ©s: $($results.NotRunCount)"

# Retourner un code d'erreur si des tests ont Ã©chouÃ©
if ($results.FailedCount -gt 0) {
    Write-Host "`nDes tests ont Ã©chouÃ©. Consultez les dÃ©tails ci-dessus." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
}
