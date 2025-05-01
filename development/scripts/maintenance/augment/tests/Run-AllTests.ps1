<#
.SYNOPSIS
    Exécute tous les tests unitaires pour l'intégration avec Augment Code.

.DESCRIPTION
    Ce script exécute tous les tests unitaires pour l'intégration avec Augment Code,
    en utilisant le framework Pester.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour le rapport de tests.
    Par défaut : "reports\augment\test-results.xml".

.EXAMPLE
    .\Run-AllTests.ps1
    # Exécute tous les tests unitaires

.EXAMPLE
    .\Run-AllTests.ps1 -OutputPath "C:\temp\test-results.xml"
    # Exécute tous les tests unitaires et enregistre les résultats dans le fichier spécifié

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$OutputPath = "reports\augment\test-results.xml"
)

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Créer le répertoire de sortie s'il n'existe pas
$outputPath = Join-Path -Path $projectRoot -ChildPath $OutputPath
$outputDir = Split-Path -Path $outputPath -Parent
if (-not (Test-Path -Path $outputDir -PathType Container)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Obtenir la liste des fichiers de test
$testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "Test-*.ps1" | Select-Object -ExpandProperty FullName

# Afficher les fichiers de test trouvés
Write-Host "Fichiers de test trouvés :" -ForegroundColor Cyan
foreach ($file in $testFiles) {
    Write-Host "- $file" -ForegroundColor Gray
}

# Configurer Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testFiles
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = $outputPath
$pesterConfig.TestResult.OutputFormat = "NUnitXml"

# Exécuter les tests
Write-Host "`nExécution des tests..." -ForegroundColor Cyan
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "Tests exécutés : $($results.TotalCount)" -ForegroundColor Gray
Write-Host "Tests réussis : $($results.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués : $($results.FailedCount)" -ForegroundColor $(if ($results.FailedCount -eq 0) { "Green" } else { "Red" })
Write-Host "Tests ignorés : $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host "Tests non exécutés : $($results.NotRunCount)" -ForegroundColor Yellow
Write-Host "Durée totale : $($results.Duration.TotalSeconds) secondes" -ForegroundColor Gray

# Afficher les tests échoués
if ($results.FailedCount -gt 0) {
    Write-Host "`nTests échoués :" -ForegroundColor Red
    foreach ($test in $results.Failed) {
        Write-Host "- $($test.Name)" -ForegroundColor Red
        Write-Host "  $($test.ErrorRecord)" -ForegroundColor Red
    }
}

# Afficher le chemin du rapport
Write-Host "`nRapport de tests enregistré : $outputPath" -ForegroundColor Green

# Retourner le code de sortie
exit $results.FailedCount
