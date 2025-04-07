# Script pour analyser l'évolution des erreurs

# Importer le module de collecte de données
$collectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "..\Tracking\ErrorDataCollector.ps1"
if (Test-Path -Path $collectorPath) {
    . $collectorPath
}
else {
    Write-Error "Le module de collecte de données est introuvable: $collectorPath"
    return
}

# Configuration de l'analyse des tendances
$TrendConfig = @{
    # Dossier de sortie des rapports
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorTrends"
    
    # Période d'analyse par défaut (en jours)
    DefaultPeriod = 30
    
    # Intervalle d'analyse (en jours)
    AnalysisInterval = 1
    
    # Seuil d'alerte pour les tendances à la hausse (en pourcentage)
    IncreaseThreshold = 20
    
    # Seuil d'alerte pour les tendances à la baisse (en pourcentage)
    DecreaseThreshold = 20
}

# Fonction pour initialiser l'analyse des tendances
function Initialize-ErrorTrendAnalysis {
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = "",
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultPeriod = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$AnalysisInterval = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$IncreaseThreshold = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$DecreaseThreshold = 0
    )
    
    # Mettre à jour la configuration
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $TrendConfig.OutputFolder = $OutputFolder
    }
    
    if ($DefaultPeriod -gt 0) {
        $TrendConfig.DefaultPeriod = $DefaultPeriod
    }
    
    if ($AnalysisInterval -gt 0) {
        $TrendConfig.AnalysisInterval = $AnalysisInterval
    }
    
    if ($IncreaseThreshold -gt 0) {
        $TrendConfig.IncreaseThreshold = $IncreaseThreshold
    }
    
    if ($DecreaseThreshold -gt 0) {
        $TrendConfig.DecreaseThreshold = $DecreaseThreshold
    }
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $TrendConfig.OutputFolder)) {
        New-Item -Path $TrendConfig.OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Initialiser le collecteur de données
    Initialize-ErrorDataCollector
    
    return $TrendConfig
}

# Fonction pour analyser les tendances d'erreurs
function Get-ErrorTrends {
    param (
        [Parameter(Mandatory = $false)]
        [int]$Days = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$Interval = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Severity = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Source = ""
    )
    
    # Utiliser les valeurs par défaut si non spécifiées
    if ($Days -le 0) {
        $Days = $TrendConfig.DefaultPeriod
    }
    
    if ($Interval -le 0) {
        $Interval = $TrendConfig.AnalysisInterval
    }
    
    # Obtenir les données
    $errors = Get-ErrorData -Days $Days -Category $Category -Severity $Severity -Source $Source
    
    # Calculer les tendances
    $trends = @()
    $now = Get-Date
    
    # Déterminer le nombre d'intervalles
    $intervalCount = [Math]::Ceiling($Days / $Interval)
    
    for ($i = 0; $i -lt $intervalCount; $i++) {
        $startDate = $now.AddDays(-($i + 1) * $Interval)
        $endDate = $now.AddDays(-$i * $Interval)
        
        # Filtrer les erreurs pour cet intervalle
        $intervalErrors = $errors | Where-Object {
            $timestamp = [DateTime]::Parse($_.Timestamp)
            $timestamp -ge $startDate -and $timestamp -lt $endDate
        }
        
        # Calculer les statistiques pour cet intervalle
        $stats = @{
            StartDate = $startDate
            EndDate = $endDate
            Interval = $i + 1
            TotalErrors = $intervalErrors.Count
            ErrorsBySeverity = @{}
            ErrorsByCategory = @{}
            ErrorsBySource = @{}
        }
        
        # Calculer les erreurs par sévérité
        $severities = $intervalErrors | Group-Object -Property Severity | Select-Object Name, Count
        foreach ($severity in $severities) {
            $stats.ErrorsBySeverity[$severity.Name] = $severity.Count
        }
        
        # Calculer les erreurs par catégorie
        $categories = $intervalErrors | Group-Object -Property Category | Select-Object Name, Count
        foreach ($category in $categories) {
            $stats.ErrorsByCategory[$category.Name] = $category.Count
        }
        
        # Calculer les erreurs par source
        $sources = $intervalErrors | Group-Object -Property Source | Select-Object Name, Count
        foreach ($source in $sources) {
            $stats.ErrorsBySource[$source.Name] = $source.Count
        }
        
        $trends += $stats
    }
    
    # Calculer les variations
    for ($i = 0; $i -lt $trends.Count - 1; $i++) {
        $current = $trends[$i]
        $previous = $trends[$i + 1]
        
        # Variation du nombre total d'erreurs
        if ($previous.TotalErrors -gt 0) {
            $current.TotalErrorsVariation = [Math]::Round(($current.TotalErrors - $previous.TotalErrors) / $previous.TotalErrors * 100, 2)
        }
        else {
            $current.TotalErrorsVariation = if ($current.TotalErrors -gt 0) { 100 } else { 0 }
        }
        
        # Variation par sévérité
        $current.SeverityVariations = @{}
        
        foreach ($severity in $current.ErrorsBySeverity.Keys) {
            $currentCount = $current.ErrorsBySeverity[$severity]
            $previousCount = if ($previous.ErrorsBySeverity.ContainsKey($severity)) { $previous.ErrorsBySeverity[$severity] } else { 0 }
            
            if ($previousCount -gt 0) {
                $current.SeverityVariations[$severity] = [Math]::Round(($currentCount - $previousCount) / $previousCount * 100, 2)
            }
            else {
                $current.SeverityVariations[$severity] = if ($currentCount -gt 0) { 100 } else { 0 }
            }
        }
        
        # Variation par catégorie
        $current.CategoryVariations = @{}
        
        foreach ($category in $current.ErrorsByCategory.Keys) {
            $currentCount = $current.ErrorsByCategory[$category]
            $previousCount = if ($previous.ErrorsByCategory.ContainsKey($category)) { $previous.ErrorsByCategory[$category] } else { 0 }
            
            if ($previousCount -gt 0) {
                $current.CategoryVariations[$category] = [Math]::Round(($currentCount - $previousCount) / $previousCount * 100, 2)
            }
            else {
                $current.CategoryVariations[$category] = if ($currentCount -gt 0) { 100 } else { 0 }
            }
        }
        
        # Variation par source
        $current.SourceVariations = @{}
        
        foreach ($source in $current.ErrorsBySource.Keys) {
            $currentCount = $current.ErrorsBySource[$source]
            $previousCount = if ($previous.ErrorsBySource.ContainsKey($source)) { $previous.ErrorsBySource[$source] } else { 0 }
            
            if ($previousCount -gt 0) {
                $current.SourceVariations[$source] = [Math]::Round(($currentCount - $previousCount) / $previousCount * 100, 2)
            }
            else {
                $current.SourceVariations[$source] = if ($currentCount -gt 0) { 100 } else { 0 }
            }
        }
    }
    
    return $trends
}

# Fonction pour générer un rapport de tendances
function New-ErrorTrendReport {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport d'évolution des erreurs",
        
        [Parameter(Mandatory = $false)]
        [int]$Days = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$Interval = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Severity = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("HTML", "CSV", "JSON", "Text")]
        [string]$Format = "HTML",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Utiliser les valeurs par défaut si non spécifiées
    if ($Days -le 0) {
        $Days = $TrendConfig.DefaultPeriod
    }
    
    if ($Interval -le 0) {
        $Interval = $TrendConfig.AnalysisInterval
    }
    
    # Obtenir les tendances
    $trends = Get-ErrorTrends -Days $Days -Interval $Interval -Category $Category -Severity $Severity -Source $Source
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "ErrorTrends-$timestamp.$($Format.ToLower())"
        $OutputPath = Join-Path -Path $TrendConfig.OutputFolder -ChildPath $fileName
    }
    
    # Générer le rapport selon le format
    switch ($Format) {
        "HTML" {
            $html = New-ErrorTrendReportHtml -Title $Title -Trends $trends -Days $Days -Interval $Interval
            $html | Set-Content -Path $OutputPath -Encoding UTF8
        }
        "CSV" {
            $csvData = @()
            
            foreach ($trend in $trends) {
                $row = [PSCustomObject]@{
                    StartDate = $trend.StartDate
                    EndDate = $trend.EndDate
                    Interval = $trend.Interval
                    TotalErrors = $trend.TotalErrors
                    TotalErrorsVariation = $trend.TotalErrorsVariation
                }
                
                $csvData += $row
            }
            
            $csvData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        }
        "JSON" {
            $report = @{
                Title = $Title
                GeneratedAt = Get-Date -Format "o"
                Period = $Days
                Interval = $Interval
                Filters = @{
                    Category = $Category
                    Severity = $Severity
                    Source = $Source
                }
                Trends = $trends
            }
            
            $report | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
        }
        "Text" {
            $text = New-ErrorTrendReportText -Title $Title -Trends $trends -Days $Days -Interval $Interval
            $text | Set-Content -Path $OutputPath -Encoding UTF8
        }
    }
    
    # Ouvrir le rapport si demandé
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Fonction pour générer un rapport HTML
function New-ErrorTrendReportHtml {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [object[]]$Trends,
        
        [Parameter(Mandatory = $true)]
        [int]$Days,
        
        [Parameter(Mandatory = $true)]
        [int]$Interval
    )
    
    # Préparer les données pour les graphiques
    $trendData = @()
    
    foreach ($trend in ($Trends | Sort-Object -Property Interval)) {
        $trendData += @{
            interval = $trend.Interval
            startDate = $trend.StartDate.ToString("yyyy-MM-dd")
            endDate = $trend.EndDate.ToString("yyyy-MM-dd")
            totalErrors = $trend.TotalErrors
            variation = $trend.TotalErrorsVariation
        }
    }
    
    # Générer le HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1, h2, h3 {
            color: #2c3e50;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        .charts-container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .chart-card {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .chart-card h3 {
            margin-top: 0;
            margin-bottom: 15px;
            font-size: 18px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        th {
            background-color: #4caf50;
            color: white;
        }
        
        tr:hover {
            background-color: #f5f5f5;
        }
        
        .positive {
            color: #4caf50;
        }
        
        .negative {
            color: #f44336;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$Title</h1>
            <div>
                <span>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="charts-container">
            <div class="chart-card">
                <h3>Évolution du nombre d'erreurs</h3>
                <canvas id="errors-chart"></canvas>
            </div>
            
            <div class="chart-card">
                <h3>Variation du nombre d'erreurs</h3>
                <canvas id="variation-chart"></canvas>
            </div>
        </div>
        
        <h2>Détails des tendances</h2>
        
        <table>
            <thead>
                <tr>
                    <th>Période</th>
                    <th>Erreurs</th>
                    <th>Variation</th>
                    <th>Détails</th>
                </tr>
            </thead>
            <tbody>
                $(foreach ($trend in ($Trends | Sort-Object -Property Interval)) {
                    $startDate = $trend.StartDate.ToString("yyyy-MM-dd")
                    $endDate = $trend.EndDate.ToString("yyyy-MM-dd")
                    $variationClass = if ($trend.TotalErrorsVariation -gt 0) { "negative" } elseif ($trend.TotalErrorsVariation -lt 0) { "positive" } else { "" }
                    $variationSign = if ($trend.TotalErrorsVariation -gt 0) { "+" } else { "" }
                    
                    $details = ""
                    
                    # Ajouter les détails par sévérité
                    if ($trend.SeverityVariations) {
                        $details += "<strong>Par sévérité:</strong><br>"
                        
                        foreach ($severity in $trend.SeverityVariations.Keys) {
                            $count = $trend.ErrorsBySeverity[$severity]
                            $variation = $trend.SeverityVariations[$severity]
                            $varClass = if ($variation -gt 0) { "negative" } elseif ($variation -lt 0) { "positive" } else { "" }
                            $varSign = if ($variation -gt 0) { "+" } else { "" }
                            
                            $details += "$severity: $count ($varSign$variation%)<br>"
                        }
                    }
                    
                    "<tr>
                        <td>$startDate à $endDate</td>
                        <td>$($trend.TotalErrors)</td>
                        <td class='$variationClass'>$variationSign$($trend.TotalErrorsVariation)%</td>
                        <td>$details</td>
                    </tr>"
                })
            </tbody>
        </table>
        
        <div class="footer">
            <p>Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Période: $Days jours | Intervalle: $Interval jours</p>
        </div>
    </div>
    
    <script>
        // Données pour les graphiques
        const trendData = $(ConvertTo-Json -InputObject $trendData);
        
        // Graphique d'évolution du nombre d'erreurs
        const errorsCtx = document.getElementById('errors-chart').getContext('2d');
        new Chart(errorsCtx, {
            type: 'line',
            data: {
                labels: trendData.map(d => d.startDate + ' à ' + d.endDate),
                datasets: [{
                    label: 'Nombre d\'erreurs',
                    data: trendData.map(d => d.totalErrors),
                    borderColor: '#4caf50',
                    backgroundColor: 'rgba(76, 175, 80, 0.1)',
                    tension: 0.1,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'top',
                    },
                    title: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            precision: 0
                        }
                    }
                }
            }
        });
        
        // Graphique de variation du nombre d'erreurs
        const variationCtx = document.getElementById('variation-chart').getContext('2d');
        new Chart(variationCtx, {
            type: 'bar',
            data: {
                labels: trendData.map(d => d.startDate + ' à ' + d.endDate),
                datasets: [{
                    label: 'Variation (%)',
                    data: trendData.map(d => d.variation),
                    backgroundColor: trendData.map(d => d.variation > 0 ? 'rgba(244, 67, 54, 0.7)' : 'rgba(76, 175, 80, 0.7)'),
                    borderColor: trendData.map(d => d.variation > 0 ? 'rgb(244, 67, 54)' : 'rgb(76, 175, 80)'),
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'top',
                    },
                    title: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        ticks: {
                            callback: function(value) {
                                return value + '%';
                            }
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
    
    return $html
}

# Fonction pour générer un rapport texte
function New-ErrorTrendReportText {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [object[]]$Trends,
        
        [Parameter(Mandatory = $true)]
        [int]$Days,
        
        [Parameter(Mandatory = $true)]
        [int]$Interval
    )
    
    $text = @"
$Title
$("=" * $Title.Length)

Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Période: $Days jours
Intervalle: $Interval jours

RÉSUMÉ DES TENDANCES
-------------------
$(foreach ($trend in ($Trends | Sort-Object -Property Interval)) {
    $startDate = $trend.StartDate.ToString("yyyy-MM-dd")
    $endDate = $trend.EndDate.ToString("yyyy-MM-dd")
    $variationSign = if ($trend.TotalErrorsVariation -gt 0) { "+" } else { "" }
    
    "Période: $startDate à $endDate"
    "Erreurs: $($trend.TotalErrors)"
    "Variation: $variationSign$($trend.TotalErrorsVariation)%"
    
    if ($trend.SeverityVariations) {
        "`nPar sévérité:"
        foreach ($severity in $trend.SeverityVariations.Keys) {
            $count = $trend.ErrorsBySeverity[$severity]
            $variation = $trend.SeverityVariations[$severity]
            $varSign = if ($variation -gt 0) { "+" } else { "" }
            
            "  $severity: $count ($varSign$variation%)"
        }
    }
    
    if ($trend.CategoryVariations) {
        "`nPar catégorie:"
        foreach ($category in $trend.CategoryVariations.Keys) {
            $count = $trend.ErrorsByCategory[$category]
            $variation = $trend.CategoryVariations[$category]
            $varSign = if ($variation -gt 0) { "+" } else { "" }
            
            "  $category: $count ($varSign$variation%)"
        }
    }
    
    "`n"
})

"@
    
    return $text
}

# Fonction pour détecter les anomalies dans les tendances
function Get-ErrorTrendAnomalies {
    param (
        [Parameter(Mandatory = $false)]
        [int]$Days = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$Interval = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$IncreaseThreshold = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$DecreaseThreshold = 0
    )
    
    # Utiliser les valeurs par défaut si non spécifiées
    if ($Days -le 0) {
        $Days = $TrendConfig.DefaultPeriod
    }
    
    if ($Interval -le 0) {
        $Interval = $TrendConfig.AnalysisInterval
    }
    
    if ($IncreaseThreshold -le 0) {
        $IncreaseThreshold = $TrendConfig.IncreaseThreshold
    }
    
    if ($DecreaseThreshold -le 0) {
        $DecreaseThreshold = $TrendConfig.DecreaseThreshold
    }
    
    # Obtenir les tendances
    $trends = Get-ErrorTrends -Days $Days -Interval $Interval
    
    # Détecter les anomalies
    $anomalies = @()
    
    foreach ($trend in $trends) {
        # Ignorer les tendances sans variation
        if (-not $trend.TotalErrorsVariation) {
            continue
        }
        
        # Détecter les augmentations significatives
        if ($trend.TotalErrorsVariation -ge $IncreaseThreshold) {
            $anomalies += [PSCustomObject]@{
                StartDate = $trend.StartDate
                EndDate = $trend.EndDate
                Type = "Increase"
                Metric = "TotalErrors"
                Value = $trend.TotalErrors
                Variation = $trend.TotalErrorsVariation
                Threshold = $IncreaseThreshold
                Details = "Augmentation significative du nombre total d'erreurs"
            }
        }
        
        # Détecter les diminutions significatives
        if ($trend.TotalErrorsVariation -le -$DecreaseThreshold) {
            $anomalies += [PSCustomObject]@{
                StartDate = $trend.StartDate
                EndDate = $trend.EndDate
                Type = "Decrease"
                Metric = "TotalErrors"
                Value = $trend.TotalErrors
                Variation = $trend.TotalErrorsVariation
                Threshold = $DecreaseThreshold
                Details = "Diminution significative du nombre total d'erreurs"
            }
        }
        
        # Détecter les anomalies par sévérité
        if ($trend.SeverityVariations) {
            foreach ($severity in $trend.SeverityVariations.Keys) {
                $variation = $trend.SeverityVariations[$severity]
                
                if ($variation -ge $IncreaseThreshold) {
                    $anomalies += [PSCustomObject]@{
                        StartDate = $trend.StartDate
                        EndDate = $trend.EndDate
                        Type = "Increase"
                        Metric = "Severity"
                        Category = $severity
                        Value = $trend.ErrorsBySeverity[$severity]
                        Variation = $variation
                        Threshold = $IncreaseThreshold
                        Details = "Augmentation significative des erreurs de sévérité '$severity'"
                    }
                }
                
                if ($variation -le -$DecreaseThreshold) {
                    $anomalies += [PSCustomObject]@{
                        StartDate = $trend.StartDate
                        EndDate = $trend.EndDate
                        Type = "Decrease"
                        Metric = "Severity"
                        Category = $severity
                        Value = $trend.ErrorsBySeverity[$severity]
                        Variation = $variation
                        Threshold = $DecreaseThreshold
                        Details = "Diminution significative des erreurs de sévérité '$severity'"
                    }
                }
            }
        }
        
        # Détecter les anomalies par catégorie
        if ($trend.CategoryVariations) {
            foreach ($category in $trend.CategoryVariations.Keys) {
                $variation = $trend.CategoryVariations[$category]
                
                if ($variation -ge $IncreaseThreshold) {
                    $anomalies += [PSCustomObject]@{
                        StartDate = $trend.StartDate
                        EndDate = $trend.EndDate
                        Type = "Increase"
                        Metric = "Category"
                        Category = $category
                        Value = $trend.ErrorsByCategory[$category]
                        Variation = $variation
                        Threshold = $IncreaseThreshold
                        Details = "Augmentation significative des erreurs de catégorie '$category'"
                    }
                }
                
                if ($variation -le -$DecreaseThreshold) {
                    $anomalies += [PSCustomObject]@{
                        StartDate = $trend.StartDate
                        EndDate = $trend.EndDate
                        Type = "Decrease"
                        Metric = "Category"
                        Category = $category
                        Value = $trend.ErrorsByCategory[$category]
                        Variation = $variation
                        Threshold = $DecreaseThreshold
                        Details = "Diminution significative des erreurs de catégorie '$category'"
                    }
                }
            }
        }
    }
    
    return $anomalies
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorTrendAnalysis, Get-ErrorTrends, New-ErrorTrendReport, Get-ErrorTrendAnomalies
