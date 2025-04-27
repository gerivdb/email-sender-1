#Requires -Version 5.1
<#
.SYNOPSIS
    Compare les rÃ©sultats de performance des modules de rapports PR.
.DESCRIPTION
    Ce script compare les rÃ©sultats de performance entre diffÃ©rentes versions
    des modules de rapports PR et gÃ©nÃ¨re des visualisations pour faciliter l'analyse.
.PARAMETER ResultsPath
    Tableau de chemins vers les fichiers de rÃ©sultats Ã  comparer.
.PARAMETER Labels
    Tableau d'Ã©tiquettes pour identifier chaque ensemble de rÃ©sultats. Doit avoir la mÃªme longueur que ResultsPath.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer le rapport de comparaison. Par dÃ©faut: ".\performance_comparison.html".
.PARAMETER IncludeRawData
    Inclut les donnÃ©es brutes dans le rapport.
.EXAMPLE
    .\Compare-PRPerformanceResults.ps1 -ResultsPath @(".\baseline_results.json", ".\current_results.json") -Labels @("Baseline", "Current")
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string[]]$ResultsPath,
    
    [Parameter(Mandatory = $true)]
    [string[]]$Labels,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\performance_comparison.html",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeRawData
)

# VÃ©rifier que les paramÃ¨tres sont valides
if ($ResultsPath.Count -ne $Labels.Count) {
    throw "Le nombre de chemins de rÃ©sultats ($($ResultsPath.Count)) doit Ãªtre Ã©gal au nombre d'Ã©tiquettes ($($Labels.Count))."
}

# VÃ©rifier que les fichiers de rÃ©sultats existent
foreach ($path in $ResultsPath) {
    if (-not (Test-Path -Path $path)) {
        throw "Le fichier de rÃ©sultats n'existe pas: $path"
    }
}

# Importer les modules nÃ©cessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$modules = @(
    "PRReportTemplates",
    "PRVisualization"
)

# Importer les modules
foreach ($module in $modules) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath "$module.psm1"
    if (Test-Path -Path $modulePath) {
        Import-Module $modulePath -Force
        Write-Verbose "Module importÃ©: $module"
    }
    else {
        Write-Error "Module non trouvÃ©: $modulePath"
    }
}

# Fonction pour charger les rÃ©sultats
function Import-Results {
    param (
        [string[]]$Paths,
        [string[]]$Labels
    )
    
    $results = @()
    
    for ($i = 0; $i -lt $Paths.Count; $i++) {
        $path = $Paths[$i]
        $label = $Labels[$i]
        
        $content = Get-Content -Path $path -Raw | ConvertFrom-Json
        
        $results += [PSCustomObject]@{
            Label     = $label
            Path      = $path
            Timestamp = $content.Timestamp
            DataSize  = $content.DataSize
            System    = $content.System
            Results   = $content.Results
        }
    }
    
    return $results
}

# Fonction pour comparer les rÃ©sultats
function Compare-Results {
    param (
        [object[]]$Results
    )
    
    $comparisons = @()
    
    # CrÃ©er un dictionnaire pour regrouper les rÃ©sultats par fonction
    $functionResults = @{}
    
    foreach ($result in $Results) {
        foreach ($functionResult in $result.Results) {
            $key = "$($functionResult.ModuleName).$($functionResult.FunctionName)"
            
            if (-not $functionResults.ContainsKey($key)) {
                $functionResults[$key] = @()
            }
            
            $functionResults[$key] += [PSCustomObject]@{
                Label      = $result.Label
                ModuleName = $functionResult.ModuleName
                FunctionName = $functionResult.FunctionName
                AverageMs  = $functionResult.AverageMs
                MinMs      = $functionResult.MinMs
                MaxMs      = $functionResult.MaxMs
                Iterations = $functionResult.Iterations
            }
        }
    }
    
    # Comparer les rÃ©sultats pour chaque fonction
    foreach ($key in $functionResults.Keys) {
        $functionData = $functionResults[$key]
        
        # VÃ©rifier que nous avons des rÃ©sultats pour toutes les versions
        if ($functionData.Count -eq $Results.Count) {
            $comparison = [PSCustomObject]@{
                ModuleName   = $functionData[0].ModuleName
                FunctionName = $functionData[0].FunctionName
                Results      = $functionData
                Differences  = @()
            }
            
            # Calculer les diffÃ©rences entre les versions
            for ($i = 1; $i -lt $functionData.Count; $i++) {
                $baseline = $functionData[0]
                $current = $functionData[$i]
                
                $diffPercent = ($current.AverageMs - $baseline.AverageMs) / $baseline.AverageMs * 100
                
                $comparison.Differences += [PSCustomObject]@{
                    BaselineLabel = $baseline.Label
                    CurrentLabel  = $current.Label
                    BaselineAvgMs = $baseline.AverageMs
                    CurrentAvgMs  = $current.AverageMs
                    DiffMs        = $current.AverageMs - $baseline.AverageMs
                    DiffPercent   = $diffPercent
                    Improvement   = $diffPercent -lt 0
                }
            }
            
            $comparisons += $comparison
        }
    }
    
    return $comparisons
}

# Fonction pour gÃ©nÃ©rer des donnÃ©es de visualisation
function New-VisualizationData {
    param (
        [object[]]$Comparisons
    )
    
    $visualizations = @{}
    
    # DonnÃ©es pour le graphique Ã  barres des temps moyens
    $barChartData = @()
    foreach ($comparison in $Comparisons) {
        foreach ($result in $comparison.Results) {
            $barChartData += [PSCustomObject]@{
                Label = "$($comparison.ModuleName).$($comparison.FunctionName) ($($result.Label))"
                Value = $result.AverageMs
                Color = if ($result.Label -eq $comparison.Results[0].Label) { "#3498db" } else { "#e74c3c" }
            }
        }
    }
    
    # DonnÃ©es pour le graphique Ã  barres des diffÃ©rences
    $diffChartData = @()
    foreach ($comparison in $Comparisons) {
        foreach ($diff in $comparison.Differences) {
            $diffChartData += [PSCustomObject]@{
                Label = "$($comparison.ModuleName).$($comparison.FunctionName) ($($diff.CurrentLabel) vs $($diff.BaselineLabel))"
                Value = $diff.DiffPercent
                Color = if ($diff.Improvement) { "#2ecc71" } else { "#e74c3c" }
            }
        }
    }
    
    # DonnÃ©es pour le graphique en ligne des temps min/max/avg
    $lineChartData = @()
    foreach ($comparison in $Comparisons) {
        $lineData = @()
        foreach ($result in $comparison.Results) {
            $lineData += [PSCustomObject]@{
                Label = $result.Label
                Min   = $result.MinMs
                Avg   = $result.AverageMs
                Max   = $result.MaxMs
            }
        }
        
        $lineChartData += [PSCustomObject]@{
            Function = "$($comparison.ModuleName).$($comparison.FunctionName)"
            Data     = $lineData
        }
    }
    
    $visualizations.BarChartData = $barChartData
    $visualizations.DiffChartData = $diffChartData
    $visualizations.LineChartData = $lineChartData
    
    return $visualizations
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-ComparisonReport {
    param (
        [object[]]$Results,
        [object[]]$Comparisons,
        [object]$VisualizationData,
        [string]$OutputPath,
        [bool]$IncludeRawData
    )
    
    # CrÃ©er un template HTML pour le rapport
    $htmlTemplate = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de comparaison de performance</title>
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
        .improvement {
            color: #2ecc71;
            font-weight: bold;
        }
        .regression {
            color: #e74c3c;
            font-weight: bold;
        }
        .chart-container {
            margin-bottom: 30px;
            border: 1px solid #ddd;
            padding: 15px;
            border-radius: 5px;
        }
        .chart-title {
            font-weight: bold;
            margin-bottom: 10px;
        }
        .pr-bar-chart, .pr-line-chart {
            height: 400px;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <h1>Rapport de comparaison de performance</h1>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Date de la comparaison: {{Timestamp}}</p>
        <p>Versions comparÃ©es:</p>
        <ul>
            {{#each Results}}
            <li><strong>{{this.Label}}</strong>: {{this.Timestamp}} ({{this.DataSize}})</li>
            {{/each}}
        </ul>
        <p>Fonctions comparÃ©es: {{Comparisons.length}}</p>
        <p>AmÃ©liorations: <span class="improvement">{{ImprovementCount}}</span></p>
        <p>RÃ©gressions: <span class="regression">{{RegressionCount}}</span></p>
    </div>
    
    <h2>Visualisations</h2>
    
    <div class="chart-container">
        <div class="chart-title">Temps d'exÃ©cution moyens par fonction</div>
        <div id="avgTimeChart" class="pr-bar-chart">
            {{AvgTimeChart}}
        </div>
    </div>
    
    <div class="chart-container">
        <div class="chart-title">DiffÃ©rences de performance (%)</div>
        <div id="diffChart" class="pr-bar-chart">
            {{DiffChart}}
        </div>
    </div>
    
    <h2>Comparaisons dÃ©taillÃ©es</h2>
    
    <table>
        <tr>
            <th>Module</th>
            <th>Fonction</th>
            {{#each Results}}
            <th>{{this.Label}} (ms)</th>
            {{/each}}
            <th>DiffÃ©rence</th>
        </tr>
        {{#each Comparisons}}
        <tr>
            <td>{{this.ModuleName}}</td>
            <td>{{this.FunctionName}}</td>
            {{#each this.Results}}
            <td>{{this.AverageMs}}</td>
            {{/each}}
            <td class="{{#if this.Differences.[0].Improvement}}improvement{{else}}regression{{/if}}">
                {{#if this.Differences.[0].Improvement}}
                {{this.Differences.[0].DiffPercent}}% (amÃ©lioration)
                {{else}}
                +{{this.Differences.[0].DiffPercent}}% (rÃ©gression)
                {{/if}}
            </td>
        </tr>
        {{/each}}
    </table>
    
    {{#if IncludeRawData}}
    <h2>DonnÃ©es brutes</h2>
    
    {{#each Comparisons}}
    <h3>{{this.ModuleName}}.{{this.FunctionName}}</h3>
    
    <table>
        <tr>
            <th>Version</th>
            <th>Moyenne (ms)</th>
            <th>Min (ms)</th>
            <th>Max (ms)</th>
            <th>ItÃ©rations</th>
        </tr>
        {{#each this.Results}}
        <tr>
            <td>{{this.Label}}</td>
            <td>{{this.AverageMs}}</td>
            <td>{{this.MinMs}}</td>
            <td>{{this.MaxMs}}</td>
            <td>{{this.Iterations}}</td>
        </tr>
        {{/each}}
    </table>
    {{/each}}
    {{/if}}
</body>
</html>
"@
    
    # CrÃ©er un rÃ©pertoire temporaire pour le template
    $tempDir = Join-Path -Path $env:TEMP -ChildPath "PRPerformanceComparison_$(Get-Random)"
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    
    # CrÃ©er le fichier de template
    $templatePath = Join-Path -Path $tempDir -ChildPath "performance_comparison.html"
    Set-Content -Path $templatePath -Value $htmlTemplate -Encoding UTF8
    
    # Enregistrer le template
    Register-PRReportTemplate -Name "PerformanceComparison" -Format "HTML" -TemplatePath $templatePath -Force | Out-Null
    
    # GÃ©nÃ©rer les graphiques
    $avgTimeChart = New-PRBarChart -Data $VisualizationData.BarChartData -Title "Temps d'exÃ©cution moyens" -XAxisLabel "Fonction" -YAxisLabel "Temps (ms)"
    $diffChart = New-PRBarChart -Data $VisualizationData.DiffChartData -Title "DiffÃ©rences de performance" -XAxisLabel "Fonction" -YAxisLabel "DiffÃ©rence (%)"
    
    # Compter les amÃ©liorations et les rÃ©gressions
    $improvementCount = 0
    $regressionCount = 0
    
    foreach ($comparison in $Comparisons) {
        foreach ($diff in $comparison.Differences) {
            if ($diff.Improvement) {
                $improvementCount++
            }
            else {
                $regressionCount++
            }
        }
    }
    
    # PrÃ©parer les donnÃ©es pour le rapport
    $reportData = @{
        Timestamp       = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Results         = $Results
        Comparisons     = $Comparisons
        AvgTimeChart    = $avgTimeChart
        DiffChart       = $diffChart
        ImprovementCount = $improvementCount
        RegressionCount = $regressionCount
        IncludeRawData  = $IncludeRawData
    }
    
    # GÃ©nÃ©rer le rapport
    New-PRReport -TemplateName "PerformanceComparison" -Format "HTML" -Data $reportData -OutputPath $OutputPath | Out-Null
    
    # Nettoyer les fichiers temporaires
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    
    return $OutputPath
}

# Charger les rÃ©sultats
$results = Import-Results -Paths $ResultsPath -Labels $Labels

# Comparer les rÃ©sultats
$comparisons = Compare-Results -Results $results

# GÃ©nÃ©rer des donnÃ©es de visualisation
$visualizationData = New-VisualizationData -Comparisons $comparisons

# GÃ©nÃ©rer un rapport HTML
$reportPath = New-ComparisonReport -Results $results -Comparisons $comparisons -VisualizationData $visualizationData -OutputPath $OutputPath -IncludeRawData $IncludeRawData

# Afficher un rÃ©sumÃ©
Write-Host "Rapport de comparaison gÃ©nÃ©rÃ©: $reportPath"
Write-Host "Versions comparÃ©es:"
foreach ($result in $results) {
    Write-Host "  $($result.Label): $($result.Timestamp) ($($result.DataSize))"
}

# Compter les amÃ©liorations et les rÃ©gressions
$improvementCount = 0
$regressionCount = 0

foreach ($comparison in $comparisons) {
    foreach ($diff in $comparison.Differences) {
        if ($diff.Improvement) {
            $improvementCount++
        }
        else {
            $regressionCount++
        }
    }
}

Write-Host "Fonctions comparÃ©es: $($comparisons.Count)"
Write-Host "AmÃ©liorations: $improvementCount"
Write-Host "RÃ©gressions: $regressionCount"

# Ouvrir le rapport dans le navigateur par dÃ©faut
Start-Process $reportPath
