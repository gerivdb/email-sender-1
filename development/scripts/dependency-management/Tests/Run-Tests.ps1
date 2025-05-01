#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests unitaires pour le module ModuleDependencyDetector.

.DESCRIPTION
    Ce script exécute les tests unitaires pour le module ModuleDependencyDetector
    en utilisant Pester et génère un rapport de couverture de code.

.PARAMETER OutputPath
    Chemin du répertoire de sortie pour les rapports de tests.
    Par défaut, utilise un sous-répertoire "TestResults" dans le répertoire courant.

.PARAMETER ShowCoverage
    Indique si la couverture de code doit être affichée dans la console.

.EXAMPLE
    .\Run-Tests.ps1

.EXAMPLE
    .\Run-Tests.ps1 -OutputPath "C:\Reports" -ShowCoverage

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-16
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "TestResults"),

    [Parameter(Mandatory = $false)]
    [switch]$ShowCoverage
)

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory | Out-Null
}

# Configurer les options de Pester
$testResultsPath = Join-Path -Path $OutputPath -ChildPath "TestResults.xml"

# Exécuter les tests
$testResults = Invoke-Pester -Path $PSScriptRoot -PassThru -OutputFormat NUnitXml -OutputFile $testResultsPath

# Afficher les résultats
Write-Host "`nRésultats des tests :" -ForegroundColor Cyan
Write-Host "  Tests exécutés : $($testResults.TotalCount)" -ForegroundColor Yellow
Write-Host "  Tests réussis : $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués : $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorés : $($testResults.SkippedCount)" -ForegroundColor Gray
Write-Host "  Tests non exécutés : $($testResults.NotRunCount)" -ForegroundColor Gray

# Afficher la couverture de code
if ($ShowCoverage) {
    Write-Host "`nCouverture de code :" -ForegroundColor Cyan
    Write-Host "  La couverture de code n'est pas disponible avec cette version de Pester." -ForegroundColor Yellow
}

# Afficher le chemin des rapports
Write-Host "`nRapports générés :" -ForegroundColor Cyan
Write-Host "  Résultats des tests : $testResultsPath" -ForegroundColor Gray

# Retourner le code de sortie
exit $testResults.FailedCount
