#Requires -Version 5.1
<#
.SYNOPSIS
    Teste les rÃ©gressions de performance pour les modules de rapports PR.
.DESCRIPTION
    Ce script compare les rÃ©sultats de benchmarks actuels avec des rÃ©sultats prÃ©cÃ©dents
    pour dÃ©tecter les rÃ©gressions de performance. Il gÃ©nÃ¨re des alertes si les performances
    se sont dÃ©gradÃ©es au-delÃ  d'un seuil spÃ©cifiÃ©.
.PARAMETER CurrentResults
    Chemin vers le fichier de rÃ©sultats de benchmark actuel.
.PARAMETER BaselineResults
    Chemin vers le fichier de rÃ©sultats de benchmark de rÃ©fÃ©rence.
.PARAMETER ThresholdPercent
    Pourcentage d'augmentation du temps d'exÃ©cution considÃ©rÃ© comme une rÃ©gression. Par dÃ©faut: 10%.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats de la comparaison. Par dÃ©faut: ".\regression_results.json".
.PARAMETER GenerateReport
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats de la comparaison.
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

# VÃ©rifier que les fichiers de rÃ©sultats existent
if (-not (Test-Path -Path $CurrentResults)) {
    throw "Le fichier de rÃ©sultats actuel n'existe pas: $CurrentResults"
}

if (-not (Test-Path -Path $BaselineResults)) {
    throw "Le fichier de rÃ©sultats de rÃ©fÃ©rence n'existe pas: $BaselineResults"
}

# Charger les rÃ©sultats
$current = Get-Content -Path $CurrentResults -Raw | ConvertFrom-Json
$baseline = Get-Content -Path $BaselineResults -Raw | ConvertFrom-Json

# VÃ©rifier que les rÃ©sultats ont le bon format
if (-not $current.Results -or -not $baseline.Results) {
    throw "Format de fichier de rÃ©sultats invalide. Assurez-vous que les fichiers ont Ã©tÃ© gÃ©nÃ©rÃ©s par Invoke-PRPerformanceBenchmark.ps1."
}

# Fonction pour comparer les rÃ©sultats
function Compare-BenchmarkResults {
    param (
        [object]$Current,
        [object]$Baseline,
        [double]$Threshold
    )
    
    $comparisons = @()
    
    # CrÃ©er un dictionnaire des rÃ©sultats de rÃ©fÃ©rence pour un accÃ¨s rapide
    $baselineDict = @{}
    foreach ($result in $Baseline.Results) {
        $key = "$($result.ModuleName).$($result.FunctionName)"
        $baselineDict[$key] = $result
    }
    
    # Comparer chaque rÃ©sultat actuel avec la rÃ©fÃ©rence
    foreach ($result in $Current.Results) {
        $key = "$($result.ModuleName).$($result.FunctionName)"
        $baselineResult = $baselineDict[$key]
        
        if ($baselineResult) {
            # Calculer la diffÃ©rence de performance
            $baselineAvg = $baselineResult.AverageMs
            $currentAvg = $result.AverageMs
            $diffPercent = ($currentAvg - $baselineAvg) / $baselineAvg * 100
            
            # DÃ©terminer s'il s'agit d'une rÃ©gression
            $isRegression = $diffPercent -gt $Threshold
            
            # CrÃ©er un objet de comparaison
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
            Write-Warning "Aucun rÃ©sultat de rÃ©fÃ©rence trouvÃ© pour $key"
        }
    }
    
    return $comparisons
}

# Comparer les rÃ©sultats
$comparisons = Compare-BenchmarkResults -Current $current -Baseline $baseline -Threshold $ThresholdPercent

# CrÃ©er un objet de rÃ©sultats
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

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des rÃ©gressions de performance:"
Write-Host "===================================="
Write-Host "Date de la comparaison: $($regressionResults.Timestamp)"
Write-Host "RÃ©sultats actuels: $($regressionResults.CurrentTimestamp)"
Write-Host "RÃ©sultats de rÃ©fÃ©rence: $($regressionResults.BaselineTimestamp)"
Write-Host "Seuil de rÃ©gression: $ThresholdPercent%"
Write-Host ""
Write-Host "Fonctions testÃ©es: $($regressionResults.Summary.TotalFunctions)"
Write-Host "RÃ©gressions dÃ©tectÃ©es: $($regressionResults.Summary.Regressions)"
Write-Host "AmÃ©liorations dÃ©tectÃ©es: $($regressionResults.Summary.Improvements)"
Write-Host "Pas de changement significatif: $($regressionResults.Summary.NoChange)"
Write-Host ""

# Afficher les rÃ©gressions
$regressions = $comparisons | Where-Object { $_.IsRegression } | Sort-Object -Property DiffPercent -Descending
if ($regressions.Count -gt 0) {
    Write-Host "RÃ©gressions dÃ©tectÃ©es:" -ForegroundColor Red
    foreach ($regression in $regressions) {
        Write-Host "  $($regression.ModuleName).$($regression.FunctionName):" -ForegroundColor Red
        Write-Host "    Avant: $([Math]::Round($regression.BaselineAvgMs, 2)) ms"
        Write-Host "    AprÃ¨s: $([Math]::Round($regression.CurrentAvgMs, 2)) ms"
        Write-Host "    Diff: +$([Math]::Round($regression.DiffPercent, 2))%"
        Write-Host ""
    }
}
else {
    Write-Host "Aucune rÃ©gression dÃ©tectÃ©e." -ForegroundColor Green
}

# Afficher les amÃ©liorations
$improvements = $comparisons | Where-Object { $_.DiffPercent -lt 0 } | Sort-Object -Property DiffPercent
if ($improvements.Count -gt 0) {
    Write-Host "AmÃ©liorations dÃ©tectÃ©es:" -ForegroundColor Green
    foreach ($improvement in $improvements) {
        Write-Host "  $($improvement.ModuleName).$($improvement.FunctionName):" -ForegroundColor Green
        Write-Host "    Avant: $([Math]::Round($improvement.BaselineAvgMs, 2)) ms"
        Write-Host "    AprÃ¨s: $([Math]::Round($improvement.CurrentAvgMs, 2)) ms"
        Write-Host "    Diff: $([Math]::Round($improvement.DiffPercent, 2))%"
        Write-Host ""
    }
}

# Enregistrer les rÃ©sultats dans un fichier JSON
$regressionResults | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "RÃ©sultats enregistrÃ©s dans: $OutputPath"

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateReport) {
    # Importer le module PRReportTemplates
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRReportTemplates.psm1"
    if (Test-Path -Path $modulePath) {
        Import-Module $modulePath -Force
        
        # CrÃ©er un template HTML pour le rapport
        $htmlTemplate = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de rÃ©gression de performance</title>
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
    <h1>Rapport de rÃ©gression de performance</h1>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Date de la comparaison: {{Timestamp}}</p>
        <p>RÃ©sultats actuels: {{CurrentTimestamp}}</p>
        <p>RÃ©sultats de rÃ©fÃ©rence: {{BaselineTimestamp}}</p>
        <p>Seuil de rÃ©gression: {{ThresholdPercent}}%</p>
        <p>Fonctions testÃ©es: {{Summary.TotalFunctions}}</p>
        <p>RÃ©gressions dÃ©tectÃ©es: <span class="{{#if Summary.Regressions}}regression{{else}}no-change{{/if}}">{{Summary.Regressions}}</span></p>
        <p>AmÃ©liorations dÃ©tectÃ©es: <span class="improvement">{{Summary.Improvements}}</span></p>
        <p>Pas de changement significatif: <span class="no-change">{{Summary.NoChange}}</span></p>
    </div>
    
    {{#if Regressions.length}}
    <h2>RÃ©gressions</h2>
    <table>
        <tr>
            <th>Module</th>
            <th>Fonction</th>
            <th>Avant (ms)</th>
            <th>AprÃ¨s (ms)</th>
            <th>DiffÃ©rence (%)</th>
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
    <h2>Aucune rÃ©gression dÃ©tectÃ©e</h2>
    {{/if}}
    
    {{#if Improvements.length}}
    <h2>AmÃ©liorations</h2>
    <table>
        <tr>
            <th>Module</th>
            <th>Fonction</th>
            <th>Avant (ms)</th>
            <th>AprÃ¨s (ms)</th>
            <th>DiffÃ©rence (%)</th>
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
            <th>AprÃ¨s (ms)</th>
            <th>DiffÃ©rence (%)</th>
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
                <span class="regression">RÃ©gression</span>
                {{else}}
                {{#if (lt this.DiffPercent 0)}}
                <span class="improvement">AmÃ©lioration</span>
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
        
        # CrÃ©er un rÃ©pertoire temporaire pour le template
        $tempDir = Join-Path -Path $env:TEMP -ChildPath "PRPerformanceReport_$(Get-Random)"
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er le fichier de template
        $templatePath = Join-Path -Path $tempDir -ChildPath "performance_report.html"
        Set-Content -Path $templatePath -Value $htmlTemplate -Encoding UTF8
        
        # Enregistrer le template
        Register-PRReportTemplate -Name "PerformanceReport" -Format "HTML" -TemplatePath $templatePath -Force | Out-Null
        
        # PrÃ©parer les donnÃ©es pour le rapport
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
        
        # GÃ©nÃ©rer le rapport
        $reportPath = $OutputPath -replace "\.json$", ".html"
        New-PRReport -TemplateName "PerformanceReport" -Format "HTML" -Data $reportData -OutputPath $reportPath | Out-Null
        
        # Nettoyer les fichiers temporaires
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "Rapport HTML gÃ©nÃ©rÃ©: $reportPath"
    }
    else {
        Write-Warning "Module PRReportTemplates non trouvÃ©. Le rapport HTML n'a pas Ã©tÃ© gÃ©nÃ©rÃ©."
    }
}
