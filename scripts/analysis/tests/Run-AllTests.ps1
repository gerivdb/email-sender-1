#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests unitaires pour les scripts d'analyse de code.
.DESCRIPTION
    Ce script exécute tous les tests unitaires pour les scripts d'analyse de code
    et génère un rapport de couverture de code.
.PARAMETER OutputPath
    Chemin du répertoire où les rapports de tests seront générés.
.PARAMETER ShowCoverage
    Indique si le rapport de couverture de code doit être affiché.
.EXAMPLE
    .\Run-AllTests.ps1 -OutputPath ".\results" -ShowCoverage
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$ShowCoverage
)

# Vérifier si Pester est disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas disponible. Installez-le avec 'Install-Module -Name Pester -Force'."
    return
}

# Importer Pester
Import-Module -Name Pester -Force

# Définir le répertoire des tests
$testsDir = $PSScriptRoot
$scriptsDir = Split-Path -Path $testsDir -Parent

# Définir le répertoire de sortie par défaut si non spécifié
if (-not $OutputPath) {
    $OutputPath = Join-Path -Path $testsDir -ChildPath "results"
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath -PathType Container)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Définir les fichiers de test à exécuter
$testFiles = Get-ChildItem -Path $testsDir -Filter "*.Tests.ps1" -File

# Copier le module TestHelpers.psm1 dans le répertoire temporaire de Pester
$testHelpersPath = Join-Path -Path $testsDir -ChildPath "TestHelpers.psm1"
if (Test-Path -Path $testHelpersPath) {
    $pesterTempDir = Join-Path -Path $env:TEMP -ChildPath "Pester"
    if (-not (Test-Path -Path $pesterTempDir -PathType Container)) {
        New-Item -Path $pesterTempDir -ItemType Directory -Force | Out-Null
    }
    Copy-Item -Path $testHelpersPath -Destination $pesterTempDir -Force
}

# Configurer les options de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testFiles.FullName
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "TestResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"

# Configurer la couverture de code si demandé
if ($ShowCoverage) {
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = @(
        Join-Path -Path $scriptsDir -ChildPath "Start-CodeAnalysis.ps1"
        Join-Path -Path $scriptsDir -ChildPath "Fix-HtmlReportEncoding.ps1"
        Join-Path -Path $scriptsDir -ChildPath "Integrate-ThirdPartyTools.ps1"
        Join-Path -Path $scriptsDir -ChildPath "modules\UnifiedResultsFormat.psm1"
    )
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "CodeCoverage.xml"
    $pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"
}

# Exécuter les tests
Write-Host "Exécution des tests unitaires..." -ForegroundColor Cyan
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Cyan
Write-Host "  - Tests exécutés: $($results.TotalCount)" -ForegroundColor White
Write-Host "  - Tests réussis: $($results.PassedCount)" -ForegroundColor $(if ($results.PassedCount -eq $results.TotalCount) { "Green" } else { "White" })
Write-Host "  - Tests échoués: $($results.FailedCount)" -ForegroundColor $(if ($results.FailedCount -gt 0) { "Red" } else { "Green" })
Write-Host "  - Tests ignorés: $($results.SkippedCount)" -ForegroundColor $(if ($results.SkippedCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "  - Tests non exécutés: $($results.NotRunCount)" -ForegroundColor $(if ($results.NotRunCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "  - Durée: $($results.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher le chemin des rapports générés
Write-Host "`nRapports générés:" -ForegroundColor Cyan
Write-Host "  - Rapport de tests: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor White
if ($ShowCoverage) {
    Write-Host "  - Rapport de couverture: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor White
}

# Retourner les résultats
return $results
