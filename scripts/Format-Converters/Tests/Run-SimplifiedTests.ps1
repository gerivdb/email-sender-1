#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests simplifiés pour le module Format-Converters.

.DESCRIPTION
    Ce script exécute tous les tests simplifiés pour le module Format-Converters.
    Les tests simplifiés sont des versions indépendantes des tests qui ne dépendent pas
    du module réel, ce qui permet de les exécuter sans problèmes de dépendances.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
}

# Définir les fichiers de test simplifiés
$simplifiedTestFiles = @(
    # Tests unitaires
    ".\Handle-AmbiguousFormats.Tests.Simplified.ps1",
    ".\Show-FormatDetectionResults.Tests.Simplified.ps1",
    ".\Test-FileFormat.Tests.Simplified.ps1",
    ".\Convert-FileFormat.Tests.Simplified.ps1",
    ".\Test-DetectedFileFormat.Tests.Simplified.ps1",
    ".\Confirm-FormatDetection.Tests.Simplified.ps1",
    ".\Test-FileFormatWithConfirmation.Tests.Simplified.ps1",

    # Tests d'intégration
    ".\Integration.Tests.Simplified.ps1"
)

# Exécuter les tests
$results = Invoke-Pester -Path $simplifiedTestFiles -PassThru -Output Detailed

# Afficher un résumé des résultats
Write-Host ""
Write-Host "Résumé des résultats de test :"
Write-Host "Tests exécutés : $($results.TotalCount)"
Write-Host "Tests réussis : $($results.PassedCount)"
Write-Host "Tests échoués : $($results.FailedCount)"
Write-Host "Tests ignorés : $($results.SkippedCount)"
Write-Host "Durée totale : $($results.Duration.TotalSeconds) secondes"

# Retourner un code de sortie en fonction des résultats
if ($results.FailedCount -gt 0) {
    exit 1
}
else {
    exit 0
}
