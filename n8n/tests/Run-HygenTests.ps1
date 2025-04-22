<#
.SYNOPSIS
    Script pour exécuter tous les tests unitaires de Hygen.

.DESCRIPTION
    Ce script exécute tous les tests unitaires de Hygen et génère un rapport de couverture.

.PARAMETER OutputPath
    Chemin où les rapports de tests seront générés.

.EXAMPLE
    .\Run-HygenTests.ps1
    Exécute tous les tests unitaires et génère un rapport dans le dossier par défaut.

.EXAMPLE
    .\Run-HygenTests.ps1 -OutputPath "C:\Reports"
    Exécute tous les tests unitaires et génère un rapport dans le dossier spécifié.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-01
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "TestResults"
)

# Construire le chemin complet si nécessaire
if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path -Path $PSScriptRoot -ChildPath $OutputPath
}

# Importer le module Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "Créer le dossier de sortie")) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
}

# Définir la configuration Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "HygenTests.xml"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "HygenCoverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"

# Définir les fichiers à tester
$scriptsToTest = @(
    (Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\setup\ensure-hygen-structure.ps1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\setup\install-hygen.ps1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\utils\Generate-N8nComponent.ps1")
)

$pesterConfig.CodeCoverage.Path = $scriptsToTest

# Exécuter les tests
Write-Host "Exécution des tests unitaires Hygen..." -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess("Tests unitaires Hygen", "Exécuter")) {
    $testResults = Invoke-Pester -Configuration $pesterConfig
} else {
    # Simuler des résultats pour WhatIf
    $testResults = [PSCustomObject]@{
        TotalCount   = 0
        PassedCount  = 0
        FailedCount  = 0
        SkippedCount = 0
        Duration     = [TimeSpan]::Zero
    }
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Durée totale: $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher le chemin des rapports
Write-Host "`nRapports générés:" -ForegroundColor Cyan
Write-Host "  Rapport de tests: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor White
Write-Host "  Rapport de couverture: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor White

# Retourner le code de sortie
if ($testResults.FailedCount -gt 0) {
    exit 1
} else {
    exit 0
}
