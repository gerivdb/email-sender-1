#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour le projet.
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour le projet et gÃ©nÃ¨re un rapport de couverture de code.
.PARAMETER Tags
    Liste des tags de tests Ã  exÃ©cuter. Si non spÃ©cifiÃ©, tous les tests sont exÃ©cutÃ©s.
.PARAMETER OutputPath
    Chemin du rÃ©pertoire de sortie pour les rapports. Par dÃ©faut: "./reports/tests".
.PARAMETER CoveragePath
    Chemin du rÃ©pertoire de sortie pour les rapports de couverture. Par dÃ©faut: "./reports/coverage".
.PARAMETER Parallel
    ExÃ©cute les tests en parallÃ¨le.
.EXAMPLE
    .\Run-AllUnitTests.ps1 -Tags @("CacheManager", "EncryptionUtils") -Parallel
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string[]]$Tags = @(),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./reports/tests",
    
    [Parameter(Mandatory = $false)]
    [string]$CoveragePath = "./reports/coverage",
    
    [Parameter(Mandatory = $false)]
    [switch]$Parallel
)

# Fonction pour Ã©crire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# VÃ©rifier que Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Log "Le module Pester n'est pas installÃ©. Installation en cours..." -Level "WARNING"
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# CrÃ©er les rÃ©pertoires de sortie
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "RÃ©pertoire de sortie crÃ©Ã©: $OutputPath" -Level "INFO"
}

if (-not (Test-Path -Path $CoveragePath)) {
    New-Item -Path $CoveragePath -ItemType Directory -Force | Out-Null
    Write-Log "RÃ©pertoire de couverture crÃ©Ã©: $CoveragePath" -Level "INFO"
}

# DÃ©finir le chemin des tests
$TestsPath = Join-Path -Path $PSScriptRoot -ChildPath "unit"

# Obtenir tous les fichiers de test
$testFiles = Get-ChildItem -Path $TestsPath -Filter "*.Tests.ps1" -Recurse

Write-Log "Nombre de fichiers de test trouvÃ©s: $($testFiles.Count)" -Level "INFO"

# Configurer les options de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $TestsPath
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $CoveragePath -ChildPath "coverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "test-results.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"

# Configurer les modules Ã  couvrir
$modulesToCover = @(
    ".\modules\CacheManager.ps1"
    ".\modules\EncryptionUtils.ps1"
    ".\modules\UnifiedFileProcessor.ps1"
    ".\modules\UnifiedSegmenter.ps1"
)

$pesterConfig.CodeCoverage.Path = $modulesToCover

# Configurer les tags si spÃ©cifiÃ©s
if ($Tags.Count -gt 0) {
    $pesterConfig.Filter.Tag = $Tags
}

# Configurer l'exÃ©cution parallÃ¨le si demandÃ©e
if ($Parallel) {
    $pesterConfig.Run.EnableExit = $false
    $pesterConfig.Run.Exit = $false
    $pesterConfig.Run.Throw = $false
    
    # DÃ©terminer le nombre de threads Ã  utiliser
    $maxThreads = [Environment]::ProcessorCount
    $pesterConfig.Run.Container.MaxConcurrency = $maxThreads
    
    Write-Log "ExÃ©cution des tests en parallÃ¨le avec $maxThreads threads..." -Level "INFO"
}

# ExÃ©cuter les tests
Write-Log "ExÃ©cution des tests unitaires..." -Level "INFO"
$testResults = Invoke-Pester -Configuration $pesterConfig

# Analyser les rÃ©sultats
Write-Log "Analyse des rÃ©sultats..." -Level "INFO"

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Log "RÃ©sumÃ© des tests unitaires:" -Level "INFO"
Write-Log "Tests exÃ©cutÃ©s: $($testResults.TotalCount)" -Level "INFO"
Write-Log "Tests rÃ©ussis: $($testResults.PassedCount)" -Level "SUCCESS"
Write-Log "Tests Ã©chouÃ©s: $($testResults.FailedCount)" -Level ($testResults.FailedCount -gt 0 ? "ERROR" : "INFO")
Write-Log "Tests ignorÃ©s: $($testResults.SkippedCount)" -Level "INFO"
Write-Log "DurÃ©e totale: $($testResults.Duration.TotalSeconds) secondes" -Level "INFO"

# Analyser les rÃ©sultats de couverture
$coverageReport = [xml](Get-Content -Path $pesterConfig.CodeCoverage.OutputPath -ErrorAction SilentlyContinue)

if ($null -ne $coverageReport) {
    # Extraire les statistiques de couverture
    $packages = $coverageReport.report.package
    $totalLines = 0
    $coveredLines = 0
    $uncoveredFunctions = @()
    
    foreach ($package in $packages) {
        $packageName = $package.name
        
        foreach ($class in $package.class) {
            $className = $class.name
            $classLines = 0
            $classCoveredLines = 0
            
            foreach ($method in $class.method) {
                $methodName = $method.name
                $methodLines = 0
                $methodCoveredLines = 0
                
                foreach ($line in $method.line) {
                    $methodLines++
                    if ($line.ci -gt 0) {
                        $methodCoveredLines++
                    }
                }
                
                $methodCoverage = if ($methodLines -gt 0) { $methodCoveredLines / $methodLines * 100 } else { 0 }
                
                if ($methodCoverage -lt 100) {
                    $uncoveredFunctions += [PSCustomObject]@{
                        Package = $packageName
                        Class = $className
                        Method = $methodName
                        Coverage = [Math]::Round($methodCoverage, 2)
                    }
                }
                
                $classLines += $methodLines
                $classCoveredLines += $methodCoveredLines
            }
            
            $totalLines += $classLines
            $coveredLines += $classCoveredLines
        }
    }
    
    $totalCoverage = if ($totalLines -gt 0) { $coveredLines / $totalLines * 100 } else { 0 }
    
    Write-Log "Couverture de code: $([Math]::Round($totalCoverage, 2))%" -Level ($totalCoverage -ge 80 ? "SUCCESS" : "WARNING")
    Write-Log "Lignes totales: $totalLines" -Level "INFO"
    Write-Log "Lignes couvertes: $coveredLines" -Level "INFO"
    
    if ($uncoveredFunctions.Count -gt 0) {
        Write-Log "Fonctions non couvertes Ã  100%:" -Level "WARNING"
        $uncoveredFunctions | Format-Table -AutoSize
    }
    
    # GÃ©nÃ©rer un rapport HTML
    $htmlReportPath = Join-Path -Path $CoveragePath -ChildPath "coverage-report.html"
    
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de couverture de code</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { margin: 20px 0; padding: 10px; background-color: #f5f5f5; border-radius: 5px; }
        .good { color: green; }
        .warning { color: orange; }
        .bad { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Rapport de couverture de code</h1>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Couverture totale: <span class="$($totalCoverage -ge 80 ? 'good' : ($totalCoverage -ge 60 ? 'warning' : 'bad'))">$([Math]::Round($totalCoverage, 2))%</span></p>
        <p>Lignes totales: $totalLines</p>
        <p>Lignes couvertes: $coveredLines</p>
    </div>
    
    <h2>Fonctions non couvertes Ã  100%</h2>
    <table>
        <tr>
            <th>Package</th>
            <th>Classe</th>
            <th>MÃ©thode</th>
            <th>Couverture</th>
        </tr>
"@
    
    foreach ($function in $uncoveredFunctions) {
        $htmlReport += @"
        <tr>
            <td>$($function.Package)</td>
            <td>$($function.Class)</td>
            <td>$($function.Method)</td>
            <td class="$($function.Coverage -ge 80 ? 'good' : ($function.Coverage -ge 60 ? 'warning' : 'bad'))">$($function.Coverage)%</td>
        </tr>
"@
    }
    
    $htmlReport += @"
    </table>
</body>
</html>
"@
    
    $htmlReport | Set-Content -Path $htmlReportPath -Encoding UTF8
    
    Write-Log "Rapport HTML gÃ©nÃ©rÃ©: $htmlReportPath" -Level "SUCCESS"
}

# Retourner un code de sortie en fonction des rÃ©sultats
if ($testResults.FailedCount -gt 0) {
    Write-Log "Des tests ont Ã©chouÃ©!" -Level "ERROR"
    exit 1
} else {
    Write-Log "Tous les tests ont rÃ©ussi!" -Level "SUCCESS"
    exit 0
}
