#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests simplifiÃ©s pour le module Format-Converters.

.DESCRIPTION
    Ce script exÃ©cute tous les tests simplifiÃ©s pour le module Format-Converters.
    Les tests simplifiÃ©s sont des versions indÃ©pendantes des tests qui ne dÃ©pendent pas
    du module rÃ©el, ce qui permet de les exÃ©cuter sans problÃ¨mes de dÃ©pendances.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
}

# DÃ©finir les fichiers de test simplifiÃ©s
$simplifiedTestFiles = @(
    # Tests unitaires
    ".\Handle-AmbiguousFormats.Tests.Simplified.ps1",
    ".\Show-FormatDetectionResults.Tests.Simplified.ps1",
    ".\Test-FileFormat.Tests.Simplified.ps1",
    ".\Convert-FileFormat.Tests.Simplified.ps1",
    ".\Test-DetectedFileFormat.Tests.Simplified.ps1",
    ".\Confirm-FormatDetection.Tests.Simplified.ps1",
    ".\Test-FileFormatWithConfirmation.Tests.Simplified.ps1",

    # Tests d'intÃ©gration
    ".\Integration.Tests.Simplified.ps1"
)

# ExÃ©cuter les tests
$results = Invoke-Pester -Path $simplifiedTestFiles -PassThru -Output Detailed

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host ""
Write-Host "RÃ©sumÃ© des rÃ©sultats de test :"
Write-Host "Tests exÃ©cutÃ©s : $($results.TotalCount)"
Write-Host "Tests rÃ©ussis : $($results.PassedCount)"
Write-Host "Tests Ã©chouÃ©s : $($results.FailedCount)"
Write-Host "Tests ignorÃ©s : $($results.SkippedCount)"
Write-Host "DurÃ©e totale : $($results.Duration.TotalSeconds) secondes"

# Retourner un code de sortie en fonction des rÃ©sultats
if ($results.FailedCount -gt 0) {
    exit 1
}
else {
    exit 0
}
