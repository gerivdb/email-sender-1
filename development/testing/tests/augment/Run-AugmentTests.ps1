#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests pour la structure de documentation Augment.

.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires et d'intÃ©gration pour la structure
    de documentation Augment et gÃ©nÃ¨re un rapport HTML.

.PARAMETER OutputPath
    Le chemin oÃ¹ le rapport HTML sera gÃ©nÃ©rÃ©.
    Par dÃ©faut: "development/testing/tests/augment/reports"

.EXAMPLE
    .\Run-AugmentTests.ps1
    ExÃ©cute tous les tests et gÃ©nÃ¨re un rapport dans le dossier par dÃ©faut.

.EXAMPLE
    .\Run-AugmentTests.ps1 -OutputPath "D:\Reports"
    ExÃ©cute tous les tests et gÃ©nÃ¨re un rapport dans le dossier spÃ©cifiÃ©.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-14
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = "development/testing/tests/augment/reports"
)

# Importer le module Pester s'il est disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -ErrorAction Stop

# DÃ©finir le chemin racine du projet
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# CrÃ©er le dossier de rapports s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "Dossier de rapports crÃ©Ã©: $OutputPath" -ForegroundColor Green
}

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests Augment..." -ForegroundColor Cyan
$testScripts = Get-ChildItem -Path "$PSScriptRoot\Test-*.ps1"

$totalCount = 0
$passedCount = 0
$failedCount = 0
$skippedCount = 0

foreach ($script in $testScripts) {
    Write-Host "ExÃ©cution de $($script.Name)..." -ForegroundColor Yellow
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

# GÃ©nÃ©rer un rapport simple
$reportPath = "$OutputPath\AugmentTests-Results.txt"
Set-Content -Path $reportPath -Value "Rapport des tests Augment - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
Add-Content -Path $reportPath -Value "Tests exÃ©cutÃ©s: $($results.TotalCount)"
Add-Content -Path $reportPath -Value "Tests rÃ©ussis: $($results.PassedCount)"
Add-Content -Path $reportPath -Value "Tests Ã©chouÃ©s: $($results.FailedCount)"
Add-Content -Path $reportPath -Value "Tests ignorÃ©s: $($results.SkippedCount)"

Write-Host "Rapport gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "Tests exÃ©cutÃ©s: $($results.TotalCount)" -ForegroundColor White
Write-Host "Tests rÃ©ussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s: $($results.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorÃ©s: $($results.SkippedCount)" -ForegroundColor Yellow

# Retourner un code de sortie basÃ© sur les rÃ©sultats
if ($results.FailedCount -gt 0) {
    Write-Host "`nDes tests ont Ã©chouÃ©. Veuillez consulter le rapport pour plus de dÃ©tails." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
}
