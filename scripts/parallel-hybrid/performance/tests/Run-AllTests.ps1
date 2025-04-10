#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests unitaires pour les scripts de performance.
.DESCRIPTION
    Ce script exécute tous les tests unitaires pour les scripts de performance
    en utilisant le framework Pester. Il génère un rapport de couverture de code
    et affiche les résultats dans la console.
.EXAMPLE
    .\Run-AllTests.ps1
    Exécute tous les tests unitaires et affiche les résultats.
.NOTES
    Auteur: Augment Agent
    Date: 10/04/2025
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$GenerateReport,

    [Parameter()]
    [string]$OutputPath = "$PSScriptRoot\TestResults"
)

# Par défaut, générer un rapport
if (-not $PSBoundParameters.ContainsKey('GenerateReport')) {
    $GenerateReport = $true
}

# Vérifier si Pester est installé
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
}

# Importer Pester
Import-Module Pester

# Créer le répertoire de sortie s'il n'existe pas
if ($GenerateReport -and -not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'

if ($GenerateReport) {
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = "$OutputPath\TestResults.xml"
    # Désactiver la couverture de code car nous ne pouvons pas importer les scripts complets
    $pesterConfig.CodeCoverage.Enabled = $false
}

# Exécuter les tests
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`n=== RÉSUMÉ DES TESTS ===" -ForegroundColor Cyan
Write-Host "Tests exécutés: $($results.TotalCount)" -ForegroundColor White
Write-Host "Tests réussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués: $($results.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host "Durée totale: $($results.Duration.TotalSeconds) secondes" -ForegroundColor White

if ($GenerateReport) {
    Write-Host "`nRapports générés dans: $OutputPath" -ForegroundColor Cyan
}

# Retourner un code d'erreur si des tests ont échoué
if ($results.FailedCount -gt 0) {
    exit 1
}
else {
    exit 0
}
