# Script pour exécuter tous les tests Pester pour le module UnifiedParallel
param (
    [Parameter(Mandatory = $false)]
    [switch]$CodeCoverage,

    [Parameter(Mandatory = $false)]
    [switch]$OutputFile,

    [Parameter(Mandatory = $false)]
    [string]$TestName = "*",

    [Parameter(Mandatory = $false)]
    [string]$Tag = "*"
)

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Pester n'est pas installé. Installation en cours..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -MinimumVersion 5.0

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\tools\parallelization\UnifiedParallel.psm1"

# Configuration Pester
$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Run.PassThru = $true
$pesterConfig.Filter.Tag = $Tag
$pesterConfig.Filter.FullName = $TestName
$pesterConfig.Output.Verbosity = 'Detailed'

# Configurer la couverture de code si demandée
if ($CodeCoverage) {
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = $modulePath
    $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "coverage.xml"
}

# Configurer le fichier de sortie si demandé
if ($OutputFile) {
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
    $pesterConfig.TestResult.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "testResults.xml"
}

# Exécuter les tests
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "Tests exécutés: $($results.TotalCount)" -ForegroundColor Cyan
Write-Host "Tests réussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués: $($results.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host "Tests non exécutés: $($results.NotRunCount)" -ForegroundColor Gray

# Afficher les détails des tests échoués
if ($results.FailedCount -gt 0) {
    Write-Host "`nDétails des tests échoués:" -ForegroundColor Red
    foreach ($failure in $results.Failed) {
        Write-Host "  - $($failure.Name)" -ForegroundColor Red
        Write-Host "    $($failure.ErrorRecord.Exception.Message)" -ForegroundColor Red
    }
}

# Afficher les informations de couverture de code si demandées
if ($CodeCoverage) {
    Write-Host "`nCouverture de code:" -ForegroundColor Cyan
    Write-Host "  - Lignes analysées: $($results.CodeCoverage.NumberOfCommandsAnalyzed)" -ForegroundColor Cyan
    Write-Host "  - Lignes couvertes: $($results.CodeCoverage.NumberOfCommandsExecuted)" -ForegroundColor Cyan
    
    $coveragePercent = 0
    if ($results.CodeCoverage.NumberOfCommandsAnalyzed -gt 0) {
        $coveragePercent = [Math]::Round(($results.CodeCoverage.NumberOfCommandsExecuted / $results.CodeCoverage.NumberOfCommandsAnalyzed) * 100, 2)
    }
    
    Write-Host "  - Pourcentage de couverture: $coveragePercent%" -ForegroundColor Cyan
    
    Write-Host "`nFichier de couverture généré: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor Cyan
}

# Retourner les résultats pour une utilisation dans d'autres scripts
return $results
