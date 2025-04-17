#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests unitaires du projet.
.DESCRIPTION
    Ce script exécute tous les tests unitaires du projet et génère des rapports
    de résultats et de couverture de code.
.PARAMETER TestsPath
    Chemin du dossier contenant les tests à exécuter.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de résultats.
.PARAMETER CoveragePath
    Chemin du dossier pour les rapports de couverture de code.
.PARAMETER Tags
    Tags des tests à exécuter (par défaut: tous les tests).
.PARAMETER Parallel
    Exécute les tests en parallèle.
.EXAMPLE
    .\Run-AllTests.ps1 -TestsPath ".\tests" -OutputPath ".\reports\tests" -CoveragePath ".\reports\coverage"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-12
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TestsPath = ".\tests",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\tests",
    
    [Parameter(Mandatory = $false)]
    [string]$CoveragePath = ".\reports\coverage",
    
    [Parameter(Mandatory = $false)]
    [string[]]$Tags = @(),
    
    [Parameter(Mandatory = $false)]
    [switch]$Parallel
)

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "TITLE" { "Cyan" }
    }
    
    Write-Host "[$timestamp] " -NoNewline
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

# Vérifier si Pester est installé
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Log "Pester n'est pas installé. Installation en cours..." -Level "WARNING"
    Install-Module -Name Pester -RequiredVersion 5.3.1 -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -MinimumVersion 5.0.0

# Créer les dossiers de sortie s'ils n'existent pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $CoveragePath)) {
    New-Item -Path $CoveragePath -ItemType Directory -Force | Out-Null
}

# Obtenir tous les fichiers de test
$testFiles = Get-ChildItem -Path $TestsPath -Filter "*.Tests.ps1" -Recurse

Write-Log "Nombre de fichiers de test trouvés: $($testFiles.Count)" -Level "INFO"

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

# Configurer les modules à couvrir
$modulesToCover = @(
    ".\modules\CycleDetector.psm1"
    ".\modules\InputSegmentation.psm1"
    ".\modules\PredictiveCache.psm1"
    ".\scripts\performance\Optimize-ParallelExecution.ps1"
)

$pesterConfig.CodeCoverage.Path = $modulesToCover

# Configurer les tags si spécifiés
if ($Tags.Count -gt 0) {
    $pesterConfig.Filter.Tag = $Tags
}

# Configurer l'exécution parallèle si demandée
if ($Parallel) {
    $pesterConfig.Run.EnableExit = $false
    $pesterConfig.Run.Exit = $false
    $pesterConfig.Run.Throw = $false
    
    # Déterminer le nombre de threads à utiliser
    $maxThreads = [Environment]::ProcessorCount
    $pesterConfig.Run.Container.MaxConcurrency = $maxThreads
    
    Write-Log "Exécution des tests en parallèle avec $maxThreads threads..." -Level "INFO"
}
else {
    Write-Log "Exécution des tests en séquentiel..." -Level "INFO"
}

# Exécuter les tests
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher les résultats
Write-Log "Résultats des tests:" -Level "TITLE"
Write-Log "Tests exécutés: $($testResults.TotalCount)" -Level "INFO"
Write-Log "Tests réussis: $($testResults.PassedCount)" -Level "SUCCESS"
Write-Log "Tests échoués: $($testResults.FailedCount)" -Level $(if ($testResults.FailedCount -gt 0) { "ERROR" } else { "INFO" })
Write-Log "Tests ignorés: $($testResults.SkippedCount)" -Level "INFO"
Write-Log "Tests non exécutés: $($testResults.NotRunCount)" -Level "INFO"
Write-Log "Durée totale: $($testResults.Duration.TotalSeconds) secondes" -Level "INFO"

# Générer un rapport HTML
$htmlReportPath = Join-Path -Path $OutputPath -ChildPath "test-report.html"

$htmlReport = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tests unitaires</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #0066cc;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .test-container {
            margin-bottom: 30px;
        }
        .test-file {
            background-color: #fff;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .test-file-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        .test-file-title {
            margin: 0;
        }
        .test-file-status {
            font-weight: bold;
            padding: 5px 10px;
            border-radius: 3px;
        }
        .status-passed {
            background-color: #2ecc71;
            color: white;
        }
        .status-failed {
            background-color: #e74c3c;
            color: white;
        }
        .status-mixed {
            background-color: #f39c12;
            color: white;
        }
        .test-block {
            margin-top: 10px;
        }
        .test-describe {
            background-color: #f9f9f9;
            border-left: 4px solid #0066cc;
            padding: 10px;
            margin-bottom: 10px;
        }
        .test-context {
            background-color: #f9f9f9;
            border-left: 4px solid #3498db;
            padding: 10px;
            margin-left: 20px;
            margin-bottom: 10px;
        }
        .test-it {
            background-color: #f9f9f9;
            border-left: 4px solid #2ecc71;
            padding: 10px;
            margin-left: 40px;
            margin-bottom: 10px;
        }
        .test-it.failed {
            border-left-color: #e74c3c;
        }
        .test-it.skipped {
            border-left-color: #f39c12;
        }
        .timestamp {
            color: #666;
            font-style: italic;
            margin-top: 20px;
        }
        .coverage-summary {
            background-color: #e8f4fc;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .progress-bar {
            height: 20px;
            background-color: #ecf0f1;
            border-radius: 10px;
            margin-bottom: 10px;
            overflow: hidden;
        }
        .progress {
            height: 100%;
            background-color: #2ecc71;
            text-align: center;
            line-height: 20px;
            color: white;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <h1>Rapport de tests unitaires</h1>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Tests exécutés: <strong>$($testResults.TotalCount)</strong></p>
        <p>Tests réussis: <strong>$($testResults.PassedCount)</strong></p>
        <p>Tests échoués: <strong>$($testResults.FailedCount)</strong></p>
        <p>Tests ignorés: <strong>$($testResults.SkippedCount)</strong></p>
        <p>Tests non exécutés: <strong>$($testResults.NotRunCount)</strong></p>
        <p>Durée totale: <strong>$($testResults.Duration.TotalSeconds) secondes</strong></p>
        
        <div class="progress-bar">
            <div class="progress" style="width: $([Math]::Round(($testResults.PassedCount / [Math]::Max(1, $testResults.TotalCount)) * 100))%">
                $([Math]::Round(($testResults.PassedCount / [Math]::Max(1, $testResults.TotalCount)) * 100))%
            </div>
        </div>
    </div>
    
    <div class="coverage-summary">
        <h2>Couverture de code</h2>
        <p>Rapport de couverture disponible: <a href="$($pesterConfig.CodeCoverage.OutputPath)">$($pesterConfig.CodeCoverage.OutputPath)</a></p>
    </div>
    
    <h2>Détails des tests</h2>
    <div class="test-container">
"@

# Ajouter les détails des tests
foreach ($container in $testResults.Containers) {
    $fileName = [System.IO.Path]::GetFileName($container.Item.FullName)
    $passedCount = ($container.Tests | Where-Object { $_.Result -eq "Passed" }).Count
    $failedCount = ($container.Tests | Where-Object { $_.Result -eq "Failed" }).Count
    $skippedCount = ($container.Tests | Where-Object { $_.Result -eq "Skipped" }).Count
    
    $status = if ($failedCount -gt 0) {
        "failed"
    } elseif ($passedCount -eq $container.Tests.Count) {
        "passed"
    } else {
        "mixed"
    }
    
    $statusText = switch ($status) {
        "passed" { "Réussi" }
        "failed" { "Échoué" }
        "mixed" { "Mixte" }
    }
    
    $htmlReport += @"
        <div class="test-file">
            <div class="test-file-header">
                <h3 class="test-file-title">$fileName</h3>
                <span class="test-file-status status-$status">$statusText</span>
            </div>
            <p>Chemin: $($container.Item.FullName)</p>
            <p>Tests réussis: $passedCount / $($container.Tests.Count)</p>
"@
    
    # Ajouter les blocs de test
    foreach ($block in $container.Blocks) {
        $htmlReport += @"
            <div class="test-block">
                <div class="test-describe">
                    <h4>$($block.Name)</h4>
"@
        
        foreach ($childBlock in $block.Blocks) {
            $htmlReport += @"
                    <div class="test-context">
                        <h5>$($childBlock.Name)</h5>
"@
            
            foreach ($test in $childBlock.Tests) {
                $testClass = switch ($test.Result) {
                    "Passed" { "" }
                    "Failed" { "failed" }
                    "Skipped" { "skipped" }
                    default { "" }
                }
                
                $htmlReport += @"
                        <div class="test-it $testClass">
                            <p>$($test.Name) - <strong>$($test.Result)</strong></p>
"@
                
                if ($test.Result -eq "Failed") {
                    $htmlReport += @"
                            <p>Erreur: $($test.ErrorRecord.Exception.Message)</p>
"@
                }
                
                $htmlReport += @"
                        </div>
"@
            }
            
            $htmlReport += @"
                    </div>
"@
        }
        
        $htmlReport += @"
                </div>
            </div>
"@
    }
    
    $htmlReport += @"
        </div>
"@
}

$htmlReport += @"
    </div>
    
    <p class="timestamp">Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
</body>
</html>
"@

$htmlReport | Out-File -FilePath $htmlReportPath -Encoding utf8

Write-Log "Rapport HTML généré: $htmlReportPath" -Level "SUCCESS"

# Retourner le code de sortie
if ($testResults.FailedCount -gt 0) {
    Write-Log "Des tests ont échoué. Veuillez consulter le rapport pour plus de détails." -Level "ERROR"
    exit 1
} else {
    Write-Log "Tous les tests ont réussi!" -Level "SUCCESS"
    exit 0
}
