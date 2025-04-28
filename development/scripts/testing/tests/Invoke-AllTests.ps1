#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour les scripts d'analyse des pull requests.

.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour les scripts d'analyse des pull requests
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
    .\Invoke-AllTests.ps1
    ExÃ©cute tous les tests unitaires avec les paramÃ¨tres par dÃ©faut.

.EXAMPLE
    .\Invoke-AllTests.ps1 -TestName "FileContentIndexer" -OutputFormat "Diagnostic" -ShowCodeCoverage
    ExÃ©cute uniquement les tests pour le module FileContentIndexer avec un format de sortie dÃ©taillÃ© et affiche la couverture de code.

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

# Configurer les options de Pester
$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = $testFiles.FullName
$pesterConfig.Output.Verbosity = $OutputFormat
$pesterConfig.TestResult.Enabled = (-not [string]::IsNullOrWhiteSpace($OutputPath))

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $pesterConfig.TestResult.OutputPath = $OutputPath
    $pesterConfig.TestResult.OutputFormat = "NUnitXml"
}

if ($ShowCodeCoverage) {
    $pesterConfig.CodeCoverage.Enabled = $true
    
    # Obtenir les fichiers Ã  couvrir
    $modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
    $scriptsPath = Join-Path -Path $PSScriptRoot -ChildPath ".."
    
    $filesToCover = @(
        Get-ChildItem -Path $modulesPath -Filter "*.psm1" -Recurse | Select-Object -ExpandProperty FullName
        Get-ChildItem -Path $scriptsPath -Filter "*.ps1" -Recurse | 
            Where-Object { $_.Name -notlike "*.Tests.ps1" -and $_.FullName -notlike "*\tests\*" } | 
            Select-Object -ExpandProperty FullName
    )
    
    $pesterConfig.CodeCoverage.Path = $filesToCover
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "coverage.xml"
    $pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"
}

# ExÃ©cuter les tests
$results = Invoke-Pester -Configuration $pesterConfig -PassThru

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($results.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($results.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host "  DurÃ©e totale: $($results.Duration.TotalSeconds) secondes" -ForegroundColor White

if ($ShowCodeCoverage -and $pesterConfig.CodeCoverage.Enabled) {
    Write-Host "`nCouverture de code:" -ForegroundColor Cyan
    Write-Host "  Fichiers analysÃ©s: $($results.CodeCoverage.NumberOfCommandsAnalyzed)" -ForegroundColor White
    Write-Host "  Commandes couvertes: $($results.CodeCoverage.NumberOfCommandsExecuted)" -ForegroundColor White
    Write-Host "  Pourcentage de couverture: $($results.CodeCoverage.CoveragePercent)%" -ForegroundColor White
    Write-Host "  Rapport de couverture: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor White
}

# Retourner les rÃ©sultats
return $results
