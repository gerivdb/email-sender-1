#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests unitaires pour l'optimisation dynamique de la parallélisation.
.DESCRIPTION
    Ce script exécute tous les tests unitaires pour les modules liés à l'optimisation
    dynamique de la parallélisation et génère un rapport de couverture.
.PARAMETER OutputPath
    Chemin où enregistrer les rapports de test. Par défaut, utilise le répertoire "TestResults"
    dans le répertoire courant.
.EXAMPLE
    .\Run-ParallelizationTests.ps1
    Exécute tous les tests et génère un rapport dans le répertoire par défaut.
.EXAMPLE
    .\Run-ParallelizationTests.ps1 -OutputPath "C:\Reports"
    Exécute tous les tests et génère un rapport dans le répertoire spécifié.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "TestResults")
)

# Vérifier si le répertoire de sortie existe, sinon le créer
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Importer le module Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Configurer Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "TestResults.xml"
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "CodeCoverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
$pesterConfig.CodeCoverage.Path = @(
    (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Dynamic-ThreadManager.psm1"),
    (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "TaskPriorityQueue.psm1")
)

# Exécuter les tests
Write-Host "Exécution des tests unitaires pour l'optimisation dynamique de la parallélisation..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Tests non exécutés: $($testResults.NotRunCount)" -ForegroundColor Gray

# Afficher le chemin des rapports
Write-Host "`nRapports générés:" -ForegroundColor Cyan
Write-Host "  Résultats des tests: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor White
Write-Host "  Couverture de code: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor White

# Retourner les résultats
return $testResults
