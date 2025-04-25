#Requires -Version 5.1
<#
.SYNOPSIS
    Teste les régressions de performance pour les modules de rapports PR.
.DESCRIPTION
    Ce script compare les résultats de benchmarks actuels avec des résultats précédents
    pour détecter les régressions de performance. Il génère des alertes si les performances
    se sont dégradées au-delà d'un seuil spécifié.
.PARAMETER CurrentResults
    Chemin vers le fichier de résultats de benchmark actuel.
.PARAMETER BaselineResults
    Chemin vers le fichier de résultats de benchmark de référence.
.PARAMETER ThresholdPercent
    Pourcentage d'augmentation du temps d'exécution considéré comme une régression. Par défaut: 10%.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats de la comparaison. Par défaut: ".\regression_results.json".
.PARAMETER GenerateReport
    Génère un rapport HTML des résultats de la comparaison.
.EXAMPLE
    .\Test-PRPerformanceRegression.ps1 -CurrentResults ".\current_results.json" -BaselineResults ".\baseline_results.json"
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$CurrentResults,
    
    [Parameter(Mandatory = $true)]
    [string]$BaselineResults,
    
    [Parameter(Mandatory = $false)]
    [double]$ThresholdPercent = 10.0,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\regression_results.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Vérifier que les fichiers de résultats existent
if (-not (Test-Path -Path $CurrentResults)) {
    throw "Le fichier de résultats actuel n'existe pas: $CurrentResults"
}

if (-not (Test-Path -Path $BaselineResults)) {
    throw "Le fichier de résultats de référence n'existe pas: $BaselineResults"
}

# Charger les résultats
$current = Get-Content -Path $CurrentResults -Raw | ConvertFrom-Json
$baseline = Get-Content -Path $BaselineResults -Raw | ConvertFrom-Json

# Vérifier que les résultats ont le bon format
if (-not $current.Results -or -not $baseline.Results) {
    throw "Format de fichier de résultats invalide. Assurez-vous que les fichiers ont été générés par Invoke-PRPerformanceBenchmark.ps1."
}

# Fonction pour comparer les résultats
function Compare-BenchmarkResults {
    param (
        [object]$Current,
        [object]$Baseline,
        [double]$Threshold
    )
    
    $comparisons = @()
    
    # Créer un dictionnaire des résultats de référence pour un accès rapide
    $baselineDict = @{}
    foreach ($result in $Baseline.Results) {
        $key = "$($result.ModuleName).$($result.FunctionName)"
        $baselineDict[$key] = $result
    }
    
    # Comparer chaque résultat actuel avec la référence
    foreach ($result in $Current.Results) {
        $key = "$($result.ModuleName).$($result.FunctionName)"
        $baselineResult = $baselineDict[$key]
        
        if ($baselineResult) {
            # Calculer la différence de performance
            $baselineAvg = $baselineResult.AverageMs
            $currentAvg = $result.AverageMs
            $diffPercent = ($currentAvg - $baselineAvg) / $baselineAvg * 100
            
            # Déterminer s'il s'agit d'une régression
            $isRegression = $diffPercent -gt $Threshold
            
            # Créer un objet de comparaison
            $comparison = [PSCustomObject]@{
                ModuleName     = $result.ModuleName
                FunctionName   = $result.FunctionName
                BaselineAvgMs  = $baselineAvg
                CurrentAvgMs   = $currentAvg
                DiffMs         = $currentAvg - $baselineAvg
                DiffPercent    = $diffPercent
                IsRegression   = $isRegression
                ThresholdPercent = $Threshold
            }
            
            $comparisons += $comparison
        }
        else {
            Write-Warning "Aucun résultat de référence trouvé pour $key"
        }
    }
    
    return $comparisons
}

# Comparer les résultats
$comparisons = Compare-BenchmarkResults -Current $current -Baseline $baseline -Threshold $ThresholdPercent

# Créer un objet de résultats
$regressionResults = @{
    Timestamp        = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    CurrentTimestamp = $current.Timestamp
    BaselineTimestamp = $baseline.Timestamp
    ThresholdPercent = $ThresholdPercent
    Comparisons      = $comparisons
    Summary          = @{
        TotalFunctions = $comparisons.Count
        Regressions    = ($comparisons | Where-Object { $_.IsRegression }).Count
        Improvements   = ($comparisons | Where-Object { $_.DiffPercent -lt 0 }).Count
        NoChange       = ($comparisons | Where-Object { $_.DiffPercent -ge 0 -and $_.DiffPercent -le $ThresholdPercent }).Count
    }
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des régressions de performance:"
Write-Host "===================================="
Write-Host "Date de la comparaison: $($regressionResults.Timestamp)"
Write-Host "Résultats actuels: $($regressionResults.CurrentTimestamp)"
Write-Host "Résultats de référence: $($regressionResults.BaselineTimestamp)"
Write-Host "Seuil de régression: $ThresholdPercent%"
Write-Host ""
Write-Host "Fonctions testées: $($regressionResults.Summary.TotalFunctions)"
Write-Host "Régressions détectées: $($regressionResults.Summary.Regressions)"
Write-Host "Améliorations détectées: $($regressionResults.Summary.Improvements)"
Write-Host "Pas de changement significatif: $($regressionResults.Summary.NoChange)"
Write-Host ""

# Afficher les régressions
$regressions = $comparisons | Where-Object { $_.IsRegression } | Sort-Object -Property DiffPercent -Descending
if ($regressions.Count -gt 0) {
    Write-Host "Régressions détectées:" -ForegroundColor Red
    foreach ($regression in $regressions) {
        Write-Host "  $($regression.ModuleName).$($regression.FunctionName):" -ForegroundColor Red
        Write-Host "    Avant: $([Math]::Round($regression.BaselineAvgMs, 2)) ms"
        Write-Host "    Après: $([Math]::Round($regression.CurrentAvgMs, 2)) ms"
        Write-Host "    Diff: +$([Math]::Round($regression.DiffPercent, 2))%"
        Write-Host ""
    }
}
else {
    Write-Host "Aucune régression détectée." -ForegroundColor Green
}

# Afficher les améliorations
$improvements = $comparisons | Where-Object { $_.DiffPercent -lt 0 } | Sort-Object -Property DiffPercent
if ($improvements.Count -gt 0) {
    Write-Host "Améliorations détectées:" -ForegroundColor Green
    foreach ($improvement in $improvements) {
        Write-Host "  $($improvement.ModuleName).$($improvement.FunctionName):" -ForegroundColor Green
        Write-Host "    Avant: $([Math]::Round($improvement.BaselineAvgMs, 2)) ms"
        Write-Host "    Après: $([Math]::Round($improvement.CurrentAvgMs, 2)) ms"
        Write-Host "    Diff: $([Math]::Round($improvement.DiffPercent, 2))%"
        Write-Host ""
    }
}

# Enregistrer les résultats dans un fichier JSON
$regressionResults | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Résultats enregistrés dans: $OutputPath"

# Générer un rapport HTML si demandé
if ($GenerateReport) {
    # Importer le module PRReportTemplates
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRReportTemplates.psm1"
    if (Test-Path -Path $modulePath) {
        Import-Module $modulePath -Force
        
        # Créer un template HTML pour le rapport
        $htmlTemplate = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de régression de performance</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            line-height: 1.6;
        }
        h1, h2, h3 {
            color: #333;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .regression {
            color: #d9534f;
            font-weight: bold;
        }
        .improvement {
            color: #5cb85c;
            font-weight: bold;
        }
        .no-change {
            color: #5bc0de;
        }
    </style>
</head>
<body>
    <h1>Rapport de régression de performance</h1>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Date de la comparaison: {{Timestamp}}</p>
        <p>Résultats actuels: {{CurrentTimestamp}}</p>
        <p>Résultats de référence: {{BaselineTimestamp}}</p>
        <p>Seuil de régression: {{ThresholdPercent}}%</p>
        <p>Fonctions testées: {{Summary.TotalFunctions}}</p>
        <p>Régressions détectées: <span class="{{#if Summary.Regressions}}regression{{else}}no-change{{/if}}">{{Summary.Regressions}}</span></p>
        <p>Améliorations détectées: <span class="improvement">{{Summary.Improvements}}</span></p>
        <p>Pas de changement significatif: <span class="no-change">{{Summary.NoChange}}</span></p>
    </div>
    
    {{#if Regressions.length}}
    <h2>Régressions</h2>
    <table>
        <tr>
            <th>Module</th>
            <th>Fonction</th>
            <th>Avant (ms)</th>
            <th>Après (ms)</th>
            <th>Différence (%)</th>
        </tr>
        {{#each Regressions}}
        <tr>
            <td>{{this.ModuleName}}</td>
            <td>{{this.FunctionName}}</td>
            <td>{{this.BaselineAvgMs}}</td>
            <td>{{this.CurrentAvgMs}}</td>
            <td class="regression">+{{this.DiffPercent}}%</td>
        </tr>
        {{/each}}
    </table>
    {{else}}
    <h2>Aucune régression détectée</h2>
    {{/if}}
    
    {{#if Improvements.length}}
    <h2>Améliorations</h2>
    <table>
        <tr>
            <th>Module</th>
            <th>Fonction</th>
            <th>Avant (ms)</th>
            <th>Après (ms)</th>
            <th>Différence (%)</th>
        </tr>
        {{#each Improvements}}
        <tr>
            <td>{{this.ModuleName}}</td>
            <td>{{this.FunctionName}}</td>
            <td>{{this.BaselineAvgMs}}</td>
            <td>{{this.CurrentAvgMs}}</td>
            <td class="improvement">{{this.DiffPercent}}%</td>
        </tr>
        {{/each}}
    </table>
    {{/if}}
    
    <h2>Toutes les comparaisons</h2>
    <table>
        <tr>
            <th>Module</th>
            <th>Fonction</th>
            <th>Avant (ms)</th>
            <th>Après (ms)</th>
            <th>Différence (%)</th>
            <th>Statut</th>
        </tr>
        {{#each Comparisons}}
        <tr>
            <td>{{this.ModuleName}}</td>
            <td>{{this.FunctionName}}</td>
            <td>{{this.BaselineAvgMs}}</td>
            <td>{{this.CurrentAvgMs}}</td>
            <td class="{{#if this.IsRegression}}regression{{else}}{{#if (lt this.DiffPercent 0)}}improvement{{else}}no-change{{/if}}{{/if}}">
                {{#if (lt this.DiffPercent 0)}}{{this.DiffPercent}}{{else}}+{{this.DiffPercent}}{{/if}}%
            </td>
            <td>
                {{#if this.IsRegression}}
                <span class="regression">Régression</span>
                {{else}}
                {{#if (lt this.DiffPercent 0)}}
                <span class="improvement">Amélioration</span>
                {{else}}
                <span class="no-change">Stable</span>
                {{/if}}
                {{/if}}
            </td>
        </tr>
        {{/each}}
    </table>
</body>
</html>
"@
        
        # Créer un répertoire temporaire pour le template
        $tempDir = Join-Path -Path $env:TEMP -ChildPath "PRPerformanceReport_$(Get-Random)"
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        
        # Créer le fichier de template
        $templatePath = Join-Path -Path $tempDir -ChildPath "performance_report.html"
        Set-Content -Path $templatePath -Value $htmlTemplate -Encoding UTF8
        
        # Enregistrer le template
        Register-PRReportTemplate -Name "PerformanceReport" -Format "HTML" -TemplatePath $templatePath -Force | Out-Null
        
        # Préparer les données pour le rapport
        $reportData = @{
            Timestamp        = $regressionResults.Timestamp
            CurrentTimestamp = $regressionResults.CurrentTimestamp
            BaselineTimestamp = $regressionResults.BaselineTimestamp
            ThresholdPercent = $regressionResults.ThresholdPercent
            Summary          = $regressionResults.Summary
            Comparisons      = $comparisons | ForEach-Object {
                [PSCustomObject]@{
                    ModuleName    = $_.ModuleName
                    FunctionName  = $_.FunctionName
                    BaselineAvgMs = [Math]::Round($_.BaselineAvgMs, 2)
                    CurrentAvgMs  = [Math]::Round($_.CurrentAvgMs, 2)
                    DiffPercent   = [Math]::Round($_.DiffPercent, 2)
                    IsRegression  = $_.IsRegression
                }
            }
            Regressions      = $regressions | ForEach-Object {
                [PSCustomObject]@{
                    ModuleName    = $_.ModuleName
                    FunctionName  = $_.FunctionName
                    BaselineAvgMs = [Math]::Round($_.BaselineAvgMs, 2)
                    CurrentAvgMs  = [Math]::Round($_.CurrentAvgMs, 2)
                    DiffPercent   = [Math]::Round($_.DiffPercent, 2)
                }
            }
            Improvements     = $improvements | ForEach-Object {
                [PSCustomObject]@{
                    ModuleName    = $_.ModuleName
                    FunctionName  = $_.FunctionName
                    BaselineAvgMs = [Math]::Round($_.BaselineAvgMs, 2)
                    CurrentAvgMs  = [Math]::Round($_.CurrentAvgMs, 2)
                    DiffPercent   = [Math]::Round($_.DiffPercent, 2)
                }
            }
        }
        
        # Générer le rapport
        $reportPath = $OutputPath -replace "\.json$", ".html"
        New-PRReport -TemplateName "PerformanceReport" -Format "HTML" -Data $reportData -OutputPath $reportPath | Out-Null
        
        # Nettoyer les fichiers temporaires
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "Rapport HTML généré: $reportPath"
    }
    else {
        Write-Warning "Module PRReportTemplates non trouvé. Le rapport HTML n'a pas été généré."
    }
}
