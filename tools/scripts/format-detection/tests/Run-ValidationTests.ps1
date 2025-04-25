#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute une suite complète de tests et validations pour la détection de format.

.DESCRIPTION
    Ce script exécute une suite complète de tests et validations pour la détection de format,
    y compris la génération d'échantillons, la mesure de la précision, et l'optimisation
    des algorithmes. Il est conçu pour être utilisé dans le cadre de la section 2.1.5
    "Tests et validation" de la roadmap.

.PARAMETER TestDirectory
    Le répertoire où les fichiers de test seront générés et stockés.
    Par défaut, utilise le répertoire 'validation_samples' dans le répertoire du script.

.PARAMETER ReportDirectory
    Le répertoire où les rapports seront enregistrés.
    Par défaut, utilise le répertoire 'validation_reports' dans le répertoire du script.

.PARAMETER GenerateSamples
    Indique si de nouveaux échantillons doivent être générés.
    Par défaut, cette option est activée.

.PARAMETER IncludeMalformedSamples
    Indique si les échantillons malformés doivent être inclus dans les tests.
    Par défaut, cette option est activée.

.PARAMETER OptimizeAlgorithms
    Indique si les algorithmes doivent être optimisés en fonction des résultats.
    Par défaut, cette option est activée.

.PARAMETER GenerateHtmlReports
    Indique si des rapports HTML doivent être générés.
    Par défaut, cette option est activée.

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

# Importer les scripts nécessaires
$generateSamplesScript = "$PSScriptRoot\Generate-TestSamples.ps1"
$generateMalformedScript = "$PSScriptRoot\Generate-MalformedSamples.ps1"
$measureAccuracyScript = "$PSScriptRoot\Measure-DetectionAccuracy.ps1"
$optimizeAlgorithmsScript = "$PSScriptRoot\Optimize-DetectionAlgorithms.ps1"

# Vérifier si les scripts nécessaires existent
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

# Fonction pour créer un répertoire s'il n'existe pas
function New-DirectoryIfNotExists {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path -PathType Container)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Verbose "Répertoire créé : $Path"
    }
}

# Fonction principale
function Main {
    # Créer les répertoires nécessaires
    New-DirectoryIfNotExists -Path $TestDirectory
    New-DirectoryIfNotExists -Path $ReportDirectory
    
    # Étape 1 : Générer des échantillons de test
    if ($GenerateSamples) {
        Write-Host "Étape 1 : Génération d'échantillons de test..." -ForegroundColor Cyan
        
        $samplesParams = @{
            OutputDirectory = $TestDirectory
            Force = $true
        }
        
        & $generateSamplesScript @samplesParams
        
        # Générer des échantillons malformés
        if ($IncludeMalformedSamples) {
            Write-Host "`nGénération d'échantillons malformés..." -ForegroundColor Cyan
            
            $malformedParams = @{
                SourceDirectory = $TestDirectory
                OutputDirectory = (Join-Path -Path $TestDirectory -ChildPath "malformed")
                Force = $true
            }
            
            & $generateMalformedScript @malformedParams
        }
    }
    
    # Étape 2 : Mesurer la précision de la détection
    Write-Host "`nÉtape 2 : Mesure de la précision de la détection..." -ForegroundColor Cyan
    
    $accuracyParams = @{
        TestDirectory = $TestDirectory
        OutputDirectory = $ReportDirectory
        IncludeMalformedSamples = $IncludeMalformedSamples
        GenerateHtmlReport = $GenerateHtmlReports
    }
    
    $accuracyResult = & $measureAccuracyScript @accuracyParams
    
    # Afficher un résumé des résultats
    $metrics = $accuracyResult.Metrics
    
    Write-Host "`nRésumé des résultats de détection :" -ForegroundColor Yellow
    Write-Host "Nombre de fichiers testés : $($metrics.TotalFiles)" -ForegroundColor White
    Write-Host "Précision globale : $([Math]::Round($metrics.Accuracy, 2))%" -ForegroundColor White
    Write-Host "Cas ambigus : $($metrics.AmbiguousCases) (dont $($metrics.ResolvedAmbiguousCases) résolus correctement, soit $([Math]::Round($metrics.AmbiguousResolutionRate, 2))%)" -ForegroundColor White
    
    # Étape 3 : Optimiser les algorithmes
    if ($OptimizeAlgorithms) {
        Write-Host "`nÉtape 3 : Optimisation des algorithmes de détection..." -ForegroundColor Cyan
        
        $accuracyReportPath = Join-Path -Path $ReportDirectory -ChildPath "DetectionAccuracy.json"
        
        $optimizeParams = @{
            AccuracyReportPath = $accuracyReportPath
            GenerateReport = $GenerateHtmlReports
            ReportPath = (Join-Path -Path $ReportDirectory -ChildPath "OptimizationReport.html")
        }
        
        $optimizationResult = & $optimizeAlgorithmsScript @optimizeParams
        
        # Afficher un résumé des optimisations
        Write-Host "`nRésumé des optimisations :" -ForegroundColor Yellow
        Write-Host "Nombre d'optimisations effectuées : $($optimizationResult.OptimizationLog.Count)" -ForegroundColor White
    }
    
    # Étape 4 : Générer un rapport final
    if ($GenerateHtmlReports) {
        Write-Host "`nÉtape 4 : Génération du rapport final..." -ForegroundColor Cyan
        
        $finalReportPath = Join-Path -Path $ReportDirectory -ChildPath "ValidationReport.html"
        
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de validation de la détection de format</title>
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
        <h1>Rapport de validation de la détection de format</h1>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p><strong>Nombre de fichiers testés:</strong> $($metrics.TotalFiles)</p>
            <p><strong>Précision globale:</strong> $([Math]::Round($metrics.Accuracy, 2))%</p>
            <p><strong>Cas ambigus:</strong> $($metrics.AmbiguousCases) (dont $($metrics.ResolvedAmbiguousCases) résolus correctement, soit $([Math]::Round($metrics.AmbiguousResolutionRate, 2))%)</p>
            <p><strong>Date de la validation:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
        
        <div class="section">
            <h2>Métriques globales</h2>
            <div class="metrics">
                <div class="metric-card">
                    <h3>Précision</h3>
                    <div class="metric-value">$([Math]::Round($metrics.GlobalPrecision, 2))%</div>
                    <p>Pourcentage de détections correctes parmi toutes les détections</p>
                </div>
                <div class="metric-card">
                    <h3>Rappel</h3>
                    <div class="metric-value">$([Math]::Round($metrics.GlobalRecall, 2))%</div>
                    <p>Pourcentage de formats correctement identifiés</p>
                </div>
                <div class="metric-card">
                    <h3>F1-Score</h3>
                    <div class="metric-value">$([Math]::Round($metrics.GlobalF1Score, 2))%</div>
                    <p>Moyenne harmonique de la précision et du rappel</p>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2>Rapports détaillés</h2>
            <div class="report-links">
                <ul>
                    <li><a href="DetectionAccuracy.html" target="_blank">Rapport de précision de détection</a></li>
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
                Cette validation a permis de tester la robustesse et la précision des algorithmes de détection de format
                sur un ensemble varié de fichiers, y compris des cas difficiles comme des fichiers malformés, tronqués,
                ou avec des extensions incorrectes.
            </p>
            <p>
                La précision globale de $([Math]::Round($metrics.Accuracy, 2))% montre que le système est capable de détecter
                correctement le format de la plupart des fichiers. Les cas ambigus sont gérés avec un taux de réussite
                de $([Math]::Round($metrics.AmbiguousResolutionRate, 2))%, ce qui démontre l'efficacité du mécanisme de
                résolution des ambiguïtés.
            </p>
"@

        if ($OptimizeAlgorithms) {
            $html += @"
            <p>
                Les optimisations proposées devraient permettre d'améliorer encore davantage la précision de la détection,
                notamment pour les cas difficiles identifiés lors de cette validation.
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
        Write-Host "Rapport final généré : $finalReportPath" -ForegroundColor Green
    }
    
    Write-Host "`nValidation terminée avec succès !" -ForegroundColor Green
}

# Exécuter la fonction principale
Main
