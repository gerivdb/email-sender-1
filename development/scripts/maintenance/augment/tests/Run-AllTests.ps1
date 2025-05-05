<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour l'intÃ©gration avec Augment Code.

.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour l'intÃ©gration avec Augment Code,
    en utilisant le framework Pester.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour le rapport de tests.
    Par dÃ©faut : "reports\augment\test-results.xml".

.EXAMPLE
    .\Run-AllTests.ps1
    # ExÃ©cute tous les tests unitaires

.EXAMPLE
    .\Run-AllTests.ps1 -OutputPath "C:\temp\test-results.xml"
    # ExÃ©cute tous les tests unitaires et enregistre les rÃ©sultats dans le fichier spÃ©cifiÃ©

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

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©terminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de dÃ©terminer le chemin du projet."
        exit 1
    }
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputPath = Join-Path -Path $projectRoot -ChildPath $OutputPath
$outputDir = Split-Path -Path $outputPath -Parent
if (-not (Test-Path -Path $outputDir -PathType Container)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Obtenir la liste des fichiers de test
$testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "Test-*.ps1" | Select-Object -ExpandProperty FullName

# Afficher les fichiers de test trouvÃ©s
Write-Host "Fichiers de test trouvÃ©s :" -ForegroundColor Cyan
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

# ExÃ©cuter les tests
Write-Host "`nExÃ©cution des tests..." -ForegroundColor Cyan
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
Write-Host "Tests exÃ©cutÃ©s : $($results.TotalCount)" -ForegroundColor Gray
Write-Host "Tests rÃ©ussis : $($results.PassedCount)" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s : $($results.FailedCount)" -ForegroundColor $(if ($results.FailedCount -eq 0) { "Green" } else { "Red" })
Write-Host "Tests ignorÃ©s : $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host "Tests non exÃ©cutÃ©s : $($results.NotRunCount)" -ForegroundColor Yellow
Write-Host "DurÃ©e totale : $($results.Duration.TotalSeconds) secondes" -ForegroundColor Gray

# Afficher les tests Ã©chouÃ©s
if ($results.FailedCount -gt 0) {
    Write-Host "`nTests Ã©chouÃ©s :" -ForegroundColor Red
    foreach ($test in $results.Failed) {
        Write-Host "- $($test.Name)" -ForegroundColor Red
        Write-Host "  $($test.ErrorRecord)" -ForegroundColor Red
    }
}

# Afficher le chemin du rapport
Write-Host "`nRapport de tests enregistrÃ© : $outputPath" -ForegroundColor Green

# Retourner le code de sortie
exit $results.FailedCount
