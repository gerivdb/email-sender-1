#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests de sécurité pour le projet.
.DESCRIPTION
    Ce script exécute les tests de sécurité pour le projet et génère un rapport de résultats.
.PARAMETER OutputPath
    Chemin du répertoire de sortie pour les rapports. Par défaut: "./reports/security".
.EXAMPLE
    .\Run-SecurityTests.ps1 -OutputPath "./reports/security"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./reports/security"
)

# Fonction pour écrire des messages de log
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

# Créer le répertoire de sortie
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Répertoire de sortie créé: $OutputPath" -Level "INFO"
}

# Vérifier que Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Log "Le module Pester n'est pas installé. Installation en cours..." -Level "WARNING"
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir le chemin des tests de sécurité
$securityTestsPath = Join-Path -Path $PSScriptRoot -ChildPath "security"

# Vérifier que le répertoire des tests de sécurité existe
if (-not (Test-Path -Path $securityTestsPath)) {
    Write-Log "Le répertoire des tests de sécurité n'existe pas: $securityTestsPath" -Level "ERROR"
    exit 1
}

# Obtenir tous les fichiers de test de sécurité
$securityTestFiles = Get-ChildItem -Path $securityTestsPath -Filter "*.Tests.ps1" -Recurse

if ($securityTestFiles.Count -eq 0) {
    Write-Log "Aucun fichier de test de sécurité trouvé dans: $securityTestsPath" -Level "WARNING"
    exit 0
}

Write-Log "Nombre de fichiers de test de sécurité trouvés: $($securityTestFiles.Count)" -Level "INFO"

# Configurer les options de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $securityTestsPath
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "security-test-results.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"

# Exécuter les tests de sécurité
Write-Log "Exécution des tests de sécurité..." -Level "TITLE"
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher les résultats
Write-Log "Résultats des tests de sécurité:" -Level "TITLE"
Write-Log "Tests exécutés: $($testResults.TotalCount)" -Level "INFO"
Write-Log "Tests réussis: $($testResults.PassedCount)" -Level "SUCCESS"
Write-Log "Tests échoués: $($testResults.FailedCount)" -Level $(if ($testResults.FailedCount -gt 0) { "ERROR" } else { "INFO" })
Write-Log "Tests ignorés: $($testResults.SkippedCount)" -Level "INFO"
Write-Log "Tests non exécutés: $($testResults.NotRunCount)" -Level "INFO"
Write-Log "Durée totale: $($testResults.Duration.TotalSeconds) secondes" -Level "INFO"

# Générer un rapport HTML
$htmlReportPath = Join-Path -Path $OutputPath -ChildPath "security-test-report.html"

$htmlReport = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tests de sécurité</title>
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
    <h1>Rapport de tests de sécurité</h1>
    
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

# Ouvrir le rapport HTML
if (Test-Path -Path $htmlReportPath) {
    Write-Log "Ouverture du rapport HTML..." -Level "INFO"
    Start-Process $htmlReportPath
}

# Retourner le code de sortie
if ($testResults.FailedCount -gt 0) {
    Write-Log "Des tests de sécurité ont échoué. Veuillez consulter le rapport pour plus de détails." -Level "ERROR"
    exit 1
} else {
    Write-Log "Tous les tests de sécurité ont réussi!" -Level "SUCCESS"
    exit 0
}
