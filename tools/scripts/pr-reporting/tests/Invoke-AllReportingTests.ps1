#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour les modules de rapports d'analyse.

.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour les modules de rapports d'analyse
    en utilisant le framework Pester.

.PARAMETER TestName
    Le nom des tests Ã  exÃ©cuter. Si non spÃ©cifiÃ©, tous les tests seront exÃ©cutÃ©s.

.PARAMETER OutputFormat
    Le format de sortie des rÃ©sultats des tests.
    Valeurs possibles: "Normal", "Detailed", "Diagnostic", "Minimal", "None"
    Par dÃ©faut: "Detailed"

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer les rÃ©sultats des tests.
    Si non spÃ©cifiÃ©, les rÃ©sultats ne seront pas enregistrÃ©s.

.PARAMETER ShowCodeCoverage
    Indique s'il faut afficher la couverture de code.
    Par dÃ©faut: $false

.EXAMPLE
    .\Invoke-AllReportingTests.ps1
    ExÃ©cute tous les tests unitaires avec les paramÃ¨tres par dÃ©faut.

.EXAMPLE
    .\Invoke-AllReportingTests.ps1 -TestName "PRReportTemplates" -OutputFormat "Diagnostic" -ShowCodeCoverage
    ExÃ©cute uniquement les tests pour le module PRReportTemplates avec un format de sortie dÃ©taillÃ© et affiche la couverture de code.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TestName = "",

    [Parameter()]
    [ValidateSet("Normal", "Detailed", "Diagnostic", "Minimal", "None")]
    [string]$OutputFormat = "Detailed",

    [Parameter()]
    [string]$OutputPath = "",

    [Parameter()]
    [switch]$ShowCodeCoverage
)

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation recommandÃ©e: Install-Module -Name Pester -Force -SkipPublisherCheck"
    exit 1
}

# Importer Pester
Import-Module Pester

# Obtenir tous les fichiers de test
$testsPath = $PSScriptRoot
$testFiles = Get-ChildItem -Path $testsPath -Filter "*.Tests.ps1" -Recurse

# Filtrer les fichiers de test si un nom est spÃ©cifiÃ©
if (-not [string]::IsNullOrWhiteSpace($TestName)) {
    $testFiles = $testFiles | Where-Object { $_.BaseName -like "*$TestName*" }
}

# VÃ©rifier s'il y a des fichiers de test
if ($testFiles.Count -eq 0) {
    Write-Warning "Aucun fichier de test trouvÃ©."
    exit 1
}

# Afficher les fichiers de test
Write-Host "Fichiers de test trouvÃ©s:" -ForegroundColor Cyan
foreach ($file in $testFiles) {
    Write-Host "  $($file.Name)" -ForegroundColor White
}

# DÃ©terminer la version de Pester
$pesterVersion = (Get-Module -Name Pester -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1).Version
Write-Host "Utilisation de Pester version $pesterVersion" -ForegroundColor Cyan

# PrÃ©parer les paramÃ¨tres pour Invoke-Pester
$pesterParams = @{}

# ParamÃ¨tres communs Ã  toutes les versions
if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $pesterParams["OutputFile"] = $OutputPath
    $pesterParams["OutputFormat"] = "NUnitXml"
}

# ExÃ©cuter les tests avec les paramÃ¨tres appropriÃ©s selon la version
$results = @()
foreach ($file in $testFiles) {
    Write-Host "ExÃ©cution des tests: $($file.Name)" -ForegroundColor Yellow

    $fileParams = $pesterParams.Clone()
    $fileParams["Path"] = $file.FullName
    $fileParams["PassThru"] = $true

    if ($pesterVersion -ge [Version]"5.0.0") {
        # Pester 5.x
        $fileParams["Output"] = $OutputFormat
    } else {
        # Pester 3.x ou 4.x
        $fileParams["Show"] = $OutputFormat
    }

    $fileResult = Invoke-Pester @fileParams
    $results += $fileResult
}

# Calculer les totaux
$totalCount = 0
$passedCount = 0
$failedCount = 0
$skippedCount = 0
$totalDuration = [TimeSpan]::Zero

foreach ($result in $results) {
    if ($pesterVersion -ge [Version]"5.0.0") {
        # Pester 5.x
        $totalCount += $result.TotalCount
        $passedCount += $result.PassedCount
        $failedCount += $result.FailedCount
        $skippedCount += $result.SkippedCount
        $totalDuration += $result.Duration
    } else {
        # Pester 3.x ou 4.x
        $totalCount += $result.TotalCount
        $passedCount += $result.PassedCount
        $failedCount += $result.FailedCount
        $skippedCount += $result.SkippedCount
        $totalDuration += $result.Time
    }
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $totalCount" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $passedCount" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $failedCount" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $skippedCount" -ForegroundColor Yellow
Write-Host "  DurÃ©e totale: $($totalDuration.TotalSeconds) secondes" -ForegroundColor White

if ($ShowCodeCoverage) {
    Write-Host "`nCouverture de code non disponible dans cette version simplifiÃ©e." -ForegroundColor Yellow
}

# Retourner les rÃ©sultats
return $results
