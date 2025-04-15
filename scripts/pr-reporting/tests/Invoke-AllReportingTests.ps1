#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests unitaires pour les modules de rapports d'analyse.

.DESCRIPTION
    Ce script exécute tous les tests unitaires pour les modules de rapports d'analyse
    en utilisant le framework Pester.

.PARAMETER TestName
    Le nom des tests à exécuter. Si non spécifié, tous les tests seront exécutés.

.PARAMETER OutputFormat
    Le format de sortie des résultats des tests.
    Valeurs possibles: "Normal", "Detailed", "Diagnostic", "Minimal", "None"
    Par défaut: "Detailed"

.PARAMETER OutputPath
    Le chemin où enregistrer les résultats des tests.
    Si non spécifié, les résultats ne seront pas enregistrés.

.PARAMETER ShowCodeCoverage
    Indique s'il faut afficher la couverture de code.
    Par défaut: $false

.EXAMPLE
    .\Invoke-AllReportingTests.ps1
    Exécute tous les tests unitaires avec les paramètres par défaut.

.EXAMPLE
    .\Invoke-AllReportingTests.ps1 -TestName "PRReportTemplates" -OutputFormat "Diagnostic" -ShowCodeCoverage
    Exécute uniquement les tests pour le module PRReportTemplates avec un format de sortie détaillé et affiche la couverture de code.

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

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation recommandée: Install-Module -Name Pester -Force -SkipPublisherCheck"
    exit 1
}

# Importer Pester
Import-Module Pester

# Obtenir tous les fichiers de test
$testsPath = $PSScriptRoot
$testFiles = Get-ChildItem -Path $testsPath -Filter "*.Tests.ps1" -Recurse

# Filtrer les fichiers de test si un nom est spécifié
if (-not [string]::IsNullOrWhiteSpace($TestName)) {
    $testFiles = $testFiles | Where-Object { $_.BaseName -like "*$TestName*" }
}

# Vérifier s'il y a des fichiers de test
if ($testFiles.Count -eq 0) {
    Write-Warning "Aucun fichier de test trouvé."
    exit 1
}

# Afficher les fichiers de test
Write-Host "Fichiers de test trouvés:" -ForegroundColor Cyan
foreach ($file in $testFiles) {
    Write-Host "  $($file.Name)" -ForegroundColor White
}

# Déterminer la version de Pester
$pesterVersion = (Get-Module -Name Pester -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1).Version
Write-Host "Utilisation de Pester version $pesterVersion" -ForegroundColor Cyan

# Préparer les paramètres pour Invoke-Pester
$pesterParams = @{}

# Paramètres communs à toutes les versions
if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $pesterParams["OutputFile"] = $OutputPath
    $pesterParams["OutputFormat"] = "NUnitXml"
}

# Exécuter les tests avec les paramètres appropriés selon la version
$results = @()
foreach ($file in $testFiles) {
    Write-Host "Exécution des tests: $($file.Name)" -ForegroundColor Yellow

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

# Afficher un résumé
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $totalCount" -ForegroundColor White
Write-Host "  Tests réussis: $passedCount" -ForegroundColor Green
Write-Host "  Tests échoués: $failedCount" -ForegroundColor Red
Write-Host "  Tests ignorés: $skippedCount" -ForegroundColor Yellow
Write-Host "  Durée totale: $($totalDuration.TotalSeconds) secondes" -ForegroundColor White

if ($ShowCodeCoverage) {
    Write-Host "`nCouverture de code non disponible dans cette version simplifiée." -ForegroundColor Yellow
}

# Retourner les résultats
return $results
