#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests pour la structure de documentation Augment.

.DESCRIPTION
    Ce script exécute tous les tests unitaires et d'intégration pour la structure
    de documentation Augment et génère un rapport HTML.

.PARAMETER OutputPath
    Le chemin où le rapport HTML sera généré.
    Par défaut: "tests/augment/reports"

.EXAMPLE
    .\Run-AugmentTests.ps1
    Exécute tous les tests et génère un rapport dans le dossier par défaut.

.EXAMPLE
    .\Run-AugmentTests.ps1 -OutputPath "D:\Reports"
    Exécute tous les tests et génère un rapport dans le dossier spécifié.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-14
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = "tests/augment/reports"
)

# Importer le module Pester s'il est disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -ErrorAction Stop

# Définir le chemin racine du projet
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Créer le dossier de rapports s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "Dossier de rapports créé: $OutputPath" -ForegroundColor Green
}

# Exécuter les tests
Write-Host "Exécution des tests Augment..." -ForegroundColor Cyan
$testScripts = Get-ChildItem -Path "$PSScriptRoot\Test-*.ps1"

$totalCount = 0
$passedCount = 0
$failedCount = 0
$skippedCount = 0

foreach ($script in $testScripts) {
    Write-Host "Exécution de $($script.Name)..." -ForegroundColor Yellow
    $scriptResults = Invoke-Pester -Script $script.FullName -PassThru

    $totalCount += $scriptResults.TotalCount
    $passedCount += $scriptResults.PassedCount
    $failedCount += $scriptResults.FailedCount
    $skippedCount += $scriptResults.SkippedCount
}

$results = [PSCustomObject]@{
    TotalCount   = $totalCount
    PassedCount  = $passedCount
    FailedCount  = $failedCount
    SkippedCount = $skippedCount
}

# Générer un rapport simple
$reportPath = "$OutputPath\AugmentTests-Results.txt"
Set-Content -Path $reportPath -Value "Rapport des tests Augment - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
Add-Content -Path $reportPath -Value "Tests exécutés: $($results.TotalCount)"
Add-Content -Path $reportPath -Value "Tests réussis: $($results.PassedCount)"
Add-Content -Path $reportPath -Value "Tests échoués: $($results.FailedCount)"
Add-Content -Path $reportPath -Value "Tests ignorés: $($results.SkippedCount)"

Write-Host "Rapport généré: $reportPath" -ForegroundColor Green

# Afficher un résumé
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "Tests exécutés: $($results.TotalCount)" -ForegroundColor White
Write-Host "Tests réussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués: $($results.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés: $($results.SkippedCount)" -ForegroundColor Yellow

# Retourner un code de sortie basé sur les résultats
if ($results.FailedCount -gt 0) {
    Write-Host "`nDes tests ont échoué. Veuillez consulter le rapport pour plus de détails." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
}
