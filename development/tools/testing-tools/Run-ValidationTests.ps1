#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute une suite complÃ¨te de tests et validations pour la dÃ©tection de format.

.DESCRIPTION
    Ce script exÃ©cute une suite complÃ¨te de tests et validations pour la dÃ©tection de format,
    y compris la gÃ©nÃ©ration d'Ã©chantillons, la mesure de la prÃ©cision, et l'optimisation
    des algorithmes. Il est conÃ§u pour Ãªtre utilisÃ© dans le cadre de la section 2.1.5
    "Tests et validation" de la roadmap.

.PARAMETER TestDirectory
    Le rÃ©pertoire oÃ¹ les fichiers de test seront gÃ©nÃ©rÃ©s et stockÃ©s.
    Par dÃ©faut, utilise le rÃ©pertoire 'validation_samples' dans le rÃ©pertoire du script.

.PARAMETER ReportDirectory
    Le rÃ©pertoire oÃ¹ les rapports seront enregistrÃ©s.
    Par dÃ©faut, utilise le rÃ©pertoire 'validation_reports' dans le rÃ©pertoire du script.

.PARAMETER GenerateSamples
    Indique si de nouveaux Ã©chantillons doivent Ãªtre gÃ©nÃ©rÃ©s.
    Par dÃ©faut, cette option est activÃ©e.

.PARAMETER IncludeMalformedSamples
    Indique si les Ã©chantillons malformÃ©s doivent Ãªtre inclus dans les tests.
    Par dÃ©faut, cette option est activÃ©e.

.PARAMETER OptimizeAlgorithms
    Indique si les algorithmes doivent Ãªtre optimisÃ©s en fonction des rÃ©sultats.
    Par dÃ©faut, cette option est activÃ©e.

.PARAMETER GenerateHtmlReports
    Indique si des rapports HTML doivent Ãªtre gÃ©nÃ©rÃ©s.
    Par dÃ©faut, cette option est activÃ©e.

.EXAMPLE
    .\Run-ValidationTests.ps1 -GenerateHtmlReports

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TestDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "validation_samples"),
    
    [Parameter()]
    [string]$ReportDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "validation_reports"),
    
    [Parameter()]
    [switch]$GenerateSamples,
    
    [Parameter()]
    [switch]$IncludeMalformedSamples,
    
    [Parameter()]
    [switch]$OptimizeAlgorithms,
    
    [Parameter()]
    [switch]$GenerateHtmlReports
)

# Importer les scripts nÃ©cessaires
$generateSamplesScript = "$PSScriptRoot\Generate-TestSamples.ps1"
$generateMalformedScript = "$PSScriptRoot\Generate-MalformedSamples.ps1"
$measureAccuracyScript = "$PSScriptRoot\Measure-DetectionAccuracy.ps1"
$optimizeAlgorithmsScript = "$PSScriptRoot\Optimize-DetectionAlgorithms.ps1"

# VÃ©rifier si les scripts nÃ©cessaires existent
$missingScripts = @()

if (-not (Test-Path -Path $generateSamplesScript)) {
    $missingScripts += $generateSamplesScript
}

if (-not (Test-Path -Path $generateMalformedScript)) {
    $missingScripts += $generateMalformedScript
}

if (-not (Test-Path -Path $measureAccuracyScript)) {
    $missingScripts += $measureAccuracyScript
}

if (-not (Test-Path -Path $optimizeAlgorithmsScript)) {
    $missingScripts += $optimizeAlgorithmsScript
}

if ($missingScripts.Count -gt 0) {
    Write-Error "Les scripts suivants sont manquants :`n$($missingScripts -join "`n")"
    exit 1
}

# Fonction pour crÃ©er un rÃ©pertoire s'il n'existe pas
function New-DirectoryIfNotExists {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path -PathType Container)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Verbose "RÃ©pertoire crÃ©Ã© : $Path"
    }
}

# Fonction principale
function Main {
    # CrÃ©er les rÃ©pertoires nÃ©cessaires
    New-DirectoryIfNotExists -Path $TestDirectory
    New-DirectoryIfNotExists -Path $ReportDirectory
    
    # Ã‰tape 1 : GÃ©nÃ©rer des Ã©chantillons de test
    if ($GenerateSamples) {
        Write-Host "Ã‰tape 1 : GÃ©nÃ©ration d'Ã©chantillons de test..." -ForegroundColor Cyan
        
        $samplesParams = @{
            OutputDirectory = $TestDirectory
            Force = $true
        }
        
        & $generateSamplesScript @samplesParams
        
        # GÃ©nÃ©rer des Ã©chantillons malformÃ©s
        if ($IncludeMalformedSamples) {
            Write-Host "`nGÃ©nÃ©ration d'Ã©chantillons malformÃ©s..." -ForegroundColor Cyan
            
            $malformedParams = @{
                SourceDirectory = $TestDirectory
                OutputDirectory = (Join-Path -Path $TestDirectory -ChildPath "malformed")
                Force = $true
            }
            
            & $generateMalformedScript @malformedParams
        }
    }
    
    # Ã‰tape 2 : Mesurer la prÃ©cision de la dÃ©tection
    Write-Host "`nÃ‰tape 2 : Mesure de la prÃ©cision de la dÃ©tection..." -ForegroundColor Cyan
    
    $accuracyParams = @{
        TestDirectory = $TestDirectory
        OutputDirectory = $ReportDirectory
        IncludeMalformedSamples = $IncludeMalformedSamples
        GenerateHtmlReport = $GenerateHtmlReports
    }
    
    $accuracyResult = & $measureAccuracyScript @accuracyParams
    
    # Afficher un rÃ©sumÃ© des rÃ©sultats
    $metrics = $accuracyResult.Metrics
    
    Write-Host "`nRÃ©sumÃ© des rÃ©sultats de dÃ©tection :" -ForegroundColor Yellow
    Write-Host "Nombre de fichiers testÃ©s : $($metrics.TotalFiles)" -ForegroundColor White
    Write-Host "PrÃ©cision globale : $([Math]::Round($metrics.Accuracy, 2))%" -ForegroundColor White
    Write-Host "Cas ambigus : $($metrics.AmbiguousCases) (dont $($metrics.ResolvedAmbiguousCases) rÃ©solus correctement, soit $([Math]::Round($metrics.AmbiguousResolutionRate, 2))%)" -ForegroundColor White
    
    # Ã‰tape 3 : Optimiser les algorithmes
    if ($OptimizeAlgorithms) {
        Write-Host "`nÃ‰tape 3 : Optimisation des algorithmes de dÃ©tection..." -ForegroundColor Cyan
        
        $accuracyReportPath = Join-Path -Path $ReportDirectory -ChildPath "DetectionAccuracy.json"
        
        $optimizeParams = @{
            AccuracyReportPath = $accuracyReportPath
            GenerateReport = $GenerateHtmlReports
            ReportPath = (Join-Path -Path $ReportDirectory -ChildPath "OptimizationReport.html")
        }
        
        $optimizationResult = & $optimizeAlgorithmsScript @optimizeParams
        
        # Afficher un rÃ©sumÃ© des optimisations
        Write-Host "`nRÃ©sumÃ© des optimisations :" -ForegroundColor Yellow
        Write-Host "Nombre d'optimisations effectuÃ©es : $($optimizationResult.OptimizationLog.Count)" -ForegroundColor White
    }
    
    # Ã‰tape 4 : GÃ©nÃ©rer un rapport final
    if ($GenerateHtmlReports) {
        Write-Host "`nÃ‰tape 4 : GÃ©nÃ©ration du rapport final..." -ForegroundColor Cyan
        
        $finalReportPath = Join-Path -Path $ReportDirectory -ChildPath "ValidationReport.html"
        
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de validation de la dÃ©tection de format</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .summary {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .section {
            margin-bottom: 30px;
        }
        .metrics {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 20px;
        }
        .metric-card {
            background-color: #fff;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            flex: 1;
            min-width: 200px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .metric-card h3 {
            margin-top: 0;
            color: #3498db;
        }
        .metric-value {
            font-size: 24px;
            font-weight: bold;
            color: #2c3e50;
        }
        .report-links {
            background-color: #e8f4f8;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .report-links ul {
            margin: 0;
            padding-left: 20px;
        }
        .report-links li {
            margin-bottom: 5px;
        }
        .report-links a {
            color: #3498db;
            text-decoration: none;
        }
        .report-links a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de validation de la dÃ©tection de format</h1>
        
        <div class="summary">
            <h2>RÃ©sumÃ©</h2>
            <p><strong>Nombre de fichiers testÃ©s:</strong> $($metrics.TotalFiles)</p>
            <p><strong>PrÃ©cision globale:</strong> $([Math]::Round($metrics.Accuracy, 2))%</p>
            <p><strong>Cas ambigus:</strong> $($metrics.AmbiguousCases) (dont $($metrics.ResolvedAmbiguousCases) rÃ©solus correctement, soit $([Math]::Round($metrics.AmbiguousResolutionRate, 2))%)</p>
            <p><strong>Date de la validation:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
        
        <div class="section">
            <h2>MÃ©triques globales</h2>
            <div class="metrics">
                <div class="metric-card">
                    <h3>PrÃ©cision</h3>
                    <div class="metric-value">$([Math]::Round($metrics.GlobalPrecision, 2))%</div>
                    <p>Pourcentage de dÃ©tections correctes parmi toutes les dÃ©tections</p>
                </div>
                <div class="metric-card">
                    <h3>Rappel</h3>
                    <div class="metric-value">$([Math]::Round($metrics.GlobalRecall, 2))%</div>
                    <p>Pourcentage de formats correctement identifiÃ©s</p>
                </div>
                <div class="metric-card">
                    <h3>F1-Score</h3>
                    <div class="metric-value">$([Math]::Round($metrics.GlobalF1Score, 2))%</div>
                    <p>Moyenne harmonique de la prÃ©cision et du rappel</p>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2>Rapports dÃ©taillÃ©s</h2>
            <div class="report-links">
                <ul>
                    <li><a href="DetectionAccuracy.html" target="_blank">Rapport de prÃ©cision de dÃ©tection</a></li>
"@

        if ($OptimizeAlgorithms) {
            $html += @"
                    <li><a href="OptimizationReport.html" target="_blank">Rapport d'optimisation des algorithmes</a></li>
"@
        }

        $html += @"
                </ul>
            </div>
        </div>
        
        <div class="section">
            <h2>Conclusion</h2>
            <p>
                Cette validation a permis de tester la robustesse et la prÃ©cision des algorithmes de dÃ©tection de format
                sur un ensemble variÃ© de fichiers, y compris des cas difficiles comme des fichiers malformÃ©s, tronquÃ©s,
                ou avec des extensions incorrectes.
            </p>
            <p>
                La prÃ©cision globale de $([Math]::Round($metrics.Accuracy, 2))% montre que le systÃ¨me est capable de dÃ©tecter
                correctement le format de la plupart des fichiers. Les cas ambigus sont gÃ©rÃ©s avec un taux de rÃ©ussite
                de $([Math]::Round($metrics.AmbiguousResolutionRate, 2))%, ce qui dÃ©montre l'efficacitÃ© du mÃ©canisme de
                rÃ©solution des ambiguÃ¯tÃ©s.
            </p>
"@

        if ($OptimizeAlgorithms) {
            $html += @"
            <p>
                Les optimisations proposÃ©es devraient permettre d'amÃ©liorer encore davantage la prÃ©cision de la dÃ©tection,
                notamment pour les cas difficiles identifiÃ©s lors de cette validation.
            </p>
"@
        }

        $html += @"
        </div>
    </div>
</body>
</html>
"@

        $html | Set-Content -Path $finalReportPath -Encoding UTF8
        Write-Host "Rapport final gÃ©nÃ©rÃ© : $finalReportPath" -ForegroundColor Green
    }
    
    Write-Host "`nValidation terminÃ©e avec succÃ¨s !" -ForegroundColor Green
}

# ExÃ©cuter la fonction principale
Main
