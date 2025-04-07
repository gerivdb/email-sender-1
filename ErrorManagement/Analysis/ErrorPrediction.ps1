# Script simplifié pour l'analyse prédictive des erreurs

# Importer le module de collecte de données
$collectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "..\Tracking\ErrorDataCollector.ps1"
if (Test-Path -Path $collectorPath) {
    . $collectorPath
}
else {
    Write-Error "Le module de collecte de données est introuvable: $collectorPath"
    return
}

# Configuration
$PredictionConfig = @{
    # Dossier de sortie des rapports
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorPrediction"
    
    # Période d'historique par défaut (en jours)
    DefaultHistoryDays = 30
    
    # Période de prédiction par défaut (en jours)
    DefaultPredictionDays = 7
    
    # Méthode de prédiction par défaut
    DefaultMethod = "LinearRegression"
    
    # Seuil d'alerte pour les prédictions (en pourcentage)
    AlertThreshold = 20
}

# Fonction pour initialiser l'analyse prédictive
function Initialize-ErrorPrediction {
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = "",
        
        [Parameter(Mandatory = $false)]
        [int]$HistoryDays = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$PredictionDays = 0,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("LinearRegression", "MovingAverage", "ExponentialSmoothing")]
        [string]$Method = ""
    )
    
    # Mettre à jour la configuration
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $PredictionConfig.OutputFolder = $OutputFolder
    }
    
    if ($HistoryDays -gt 0) {
        $PredictionConfig.DefaultHistoryDays = $HistoryDays
    }
    
    if ($PredictionDays -gt 0) {
        $PredictionConfig.DefaultPredictionDays = $PredictionDays
    }
    
    if (-not [string]::IsNullOrEmpty($Method)) {
        $PredictionConfig.DefaultMethod = $Method
    }
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $PredictionConfig.OutputFolder)) {
        New-Item -Path $PredictionConfig.OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Initialiser le collecteur de données
    Initialize-ErrorDataCollector
    
    return $PredictionConfig
}

# Fonction pour prédire les erreurs futures
function Get-ErrorPrediction {
    param (
        [Parameter(Mandatory = $false)]
        [int]$HistoryDays = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$PredictionDays = 0,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("LinearRegression", "MovingAverage", "ExponentialSmoothing")]
        [string]$Method = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Severity = ""
    )
    
    # Utiliser les valeurs par défaut si non spécifiées
    if ($HistoryDays -le 0) {
        $HistoryDays = $PredictionConfig.DefaultHistoryDays
    }
    
    if ($PredictionDays -le 0) {
        $PredictionDays = $PredictionConfig.DefaultPredictionDays
    }
    
    if ([string]::IsNullOrEmpty($Method)) {
        $Method = $PredictionConfig.DefaultMethod
    }
    
    # Obtenir les données historiques
    $errors = Get-ErrorData -Days $HistoryDays -Category $Category -Severity $Severity
    
    # Agréger les erreurs par jour
    $dailyErrors = @{}
    $now = Get-Date
    
    # Initialiser tous les jours à 0
    for ($i = 0; $i -lt $HistoryDays; $i++) {
        $day = $now.AddDays(-$i).ToString("yyyy-MM-dd")
        $dailyErrors[$day] = 0
    }
    
    # Compter les erreurs par jour
    foreach ($error in $errors) {
        $timestamp = [DateTime]::Parse($error.Timestamp)
        $day = $timestamp.ToString("yyyy-MM-dd")
        
        if ($dailyErrors.ContainsKey($day)) {
            $dailyErrors[$day]++
        }
    }
    
    # Convertir en tableau pour l'analyse
    $dataPoints = @()
    for ($i = $HistoryDays - 1; $i -ge 0; $i--) {
        $day = $now.AddDays(-$i).ToString("yyyy-MM-dd")
        $count = $dailyErrors[$day]
        
        $dataPoints += [PSCustomObject]@{
            Day = $day
            DayNumber = $HistoryDays - $i
            Count = $count
        }
    }
    
    # Effectuer la prédiction selon la méthode choisie
    $predictions = switch ($Method) {
        "LinearRegression" {
            Get-LinearRegressionPrediction -DataPoints $dataPoints -PredictionDays $PredictionDays
        }
        "MovingAverage" {
            Get-MovingAveragePrediction -DataPoints $dataPoints -PredictionDays $PredictionDays
        }
        "ExponentialSmoothing" {
            Get-ExponentialSmoothingPrediction -DataPoints $dataPoints -PredictionDays $PredictionDays
        }
    }
    
    # Calculer les statistiques
    $stats = @{
        HistoryDays = $HistoryDays
        PredictionDays = $PredictionDays
        Method = $Method
        Category = $Category
        Severity = $Severity
        TotalHistoricalErrors = ($dataPoints | Measure-Object -Property Count -Sum).Sum
        AverageDailyErrors = [Math]::Round(($dataPoints | Measure-Object -Property Count -Average).Average, 2)
        PredictedTotalErrors = ($predictions | Measure-Object -Property PredictedCount -Sum).Sum
        PredictedAverageDailyErrors = [Math]::Round(($predictions | Measure-Object -Property PredictedCount -Average).Average, 2)
        HistoricalData = $dataPoints
        Predictions = $predictions
    }
    
    # Calculer la tendance
    $firstWeekAvg = ($dataPoints | Where-Object { $_.DayNumber -le 7 } | Measure-Object -Property Count -Average).Average
    $lastWeekAvg = ($dataPoints | Where-Object { $_.DayNumber -gt ($HistoryDays - 7) } | Measure-Object -Property Count -Average).Average
    
    if ($firstWeekAvg -gt 0) {
        $stats.HistoricalTrend = [Math]::Round(($lastWeekAvg - $firstWeekAvg) / $firstWeekAvg * 100, 2)
    }
    else {
        $stats.HistoricalTrend = if ($lastWeekAvg -gt 0) { 100 } else { 0 }
    }
    
    # Calculer la tendance prédite
    $currentAvg = ($dataPoints | Where-Object { $_.DayNumber -gt ($HistoryDays - 7) } | Measure-Object -Property Count -Average).Average
    $predictedAvg = ($predictions | Measure-Object -Property PredictedCount -Average).Average
    
    if ($currentAvg -gt 0) {
        $stats.PredictedTrend = [Math]::Round(($predictedAvg - $currentAvg) / $currentAvg * 100, 2)
    }
    else {
        $stats.PredictedTrend = if ($predictedAvg -gt 0) { 100 } else { 0 }
    }
    
    return $stats
}

# Fonction pour la prédiction par régression linéaire
function Get-LinearRegressionPrediction {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$DataPoints,
        
        [Parameter(Mandatory = $true)]
        [int]$PredictionDays
    )
    
    # Calculer la régression linéaire
    $n = $DataPoints.Count
    $sumX = ($DataPoints | Measure-Object -Property DayNumber -Sum).Sum
    $sumY = ($DataPoints | Measure-Object -Property Count -Sum).Sum
    $sumXY = ($DataPoints | ForEach-Object { $_.DayNumber * $_.Count } | Measure-Object -Sum).Sum
    $sumXX = ($DataPoints | ForEach-Object { $_.DayNumber * $_.DayNumber } | Measure-Object -Sum).Sum
    
    # Calculer les coefficients
    $slope = if (($n * $sumXX - $sumX * $sumX) -ne 0) {
        ($n * $sumXY - $sumX * $sumY) / ($n * $sumXX - $sumX * $sumX)
    }
    else {
        0
    }
    
    $intercept = ($sumY - $slope * $sumX) / $n
    
    # Générer les prédictions
    $predictions = @()
    $lastDay = [DateTime]::Parse($DataPoints[-1].Day)
    
    for ($i = 1; $i -le $PredictionDays; $i++) {
        $dayNumber = $DataPoints[-1].DayNumber + $i
        $predictedCount = [Math]::Max(0, [Math]::Round($intercept + $slope * $dayNumber, 0))
        $day = $lastDay.AddDays($i).ToString("yyyy-MM-dd")
        
        $predictions += [PSCustomObject]@{
            Day = $day
            DayNumber = $dayNumber
            PredictedCount = $predictedCount
        }
    }
    
    return $predictions
}

# Fonction pour la prédiction par moyenne mobile
function Get-MovingAveragePrediction {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$DataPoints,
        
        [Parameter(Mandatory = $true)]
        [int]$PredictionDays,
        
        [Parameter(Mandatory = $false)]
        [int]$WindowSize = 7
    )
    
    # Ajuster la taille de la fenêtre si nécessaire
    $WindowSize = [Math]::Min($WindowSize, $DataPoints.Count)
    
    # Calculer la moyenne mobile
    $lastValues = $DataPoints | Select-Object -Last $WindowSize
    $average = ($lastValues | Measure-Object -Property Count -Average).Average
    
    # Générer les prédictions
    $predictions = @()
    $lastDay = [DateTime]::Parse($DataPoints[-1].Day)
    
    for ($i = 1; $i -le $PredictionDays; $i++) {
        $dayNumber = $DataPoints[-1].DayNumber + $i
        $predictedCount = [Math]::Max(0, [Math]::Round($average, 0))
        $day = $lastDay.AddDays($i).ToString("yyyy-MM-dd")
        
        $predictions += [PSCustomObject]@{
            Day = $day
            DayNumber = $dayNumber
            PredictedCount = $predictedCount
        }
    }
    
    return $predictions
}

# Fonction pour la prédiction par lissage exponentiel
function Get-ExponentialSmoothingPrediction {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$DataPoints,
        
        [Parameter(Mandatory = $true)]
        [int]$PredictionDays,
        
        [Parameter(Mandatory = $false)]
        [double]$Alpha = 0.3
    )
    
    # Calculer le lissage exponentiel
    $lastValue = $DataPoints[-1].Count
    $previousSmoothed = $lastValue
    
    # Appliquer le lissage exponentiel aux données historiques
    for ($i = $DataPoints.Count - 2; $i -ge 0; $i--) {
        $currentValue = $DataPoints[$i].Count
        $previousSmoothed = $Alpha * $currentValue + (1 - $Alpha) * $previousSmoothed
    }
    
    # Générer les prédictions
    $predictions = @()
    $lastDay = [DateTime]::Parse($DataPoints[-1].Day)
    
    for ($i = 1; $i -le $PredictionDays; $i++) {
        $dayNumber = $DataPoints[-1].DayNumber + $i
        $predictedCount = [Math]::Max(0, [Math]::Round($previousSmoothed, 0))
        $day = $lastDay.AddDays($i).ToString("yyyy-MM-dd")
        
        $predictions += [PSCustomObject]@{
            Day = $day
            DayNumber = $dayNumber
            PredictedCount = $predictedCount
        }
    }
    
    return $predictions
}

# Fonction pour générer un rapport de prédiction
function New-ErrorPredictionReport {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport de prédiction d'erreurs",
        
        [Parameter(Mandatory = $false)]
        [int]$HistoryDays = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$PredictionDays = 0,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("LinearRegression", "MovingAverage", "ExponentialSmoothing")]
        [string]$Method = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Severity = "",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Obtenir les prédictions
    $prediction = Get-ErrorPrediction -HistoryDays $HistoryDays -PredictionDays $PredictionDays -Method $Method -Category $Category -Severity $Severity
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "ErrorPrediction-$timestamp.html"
        $OutputPath = Join-Path -Path $PredictionConfig.OutputFolder -ChildPath $fileName
    }
    
    # Préparer les données pour les graphiques
    $historicalData = @()
    foreach ($point in $prediction.HistoricalData) {
        $historicalData += @{
            day = $point.Day
            count = $point.Count
        }
    }
    
    $predictionData = @()
    foreach ($point in $prediction.Predictions) {
        $predictionData += @{
            day = $point.Day
            count = $point.PredictedCount
        }
    }
    
    # Générer le HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
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
        
        .summary {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .summary-card {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            flex: 1;
            min-width: 200px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .summary-card h3 {
            margin-top: 0;
            margin-bottom: 10px;
            font-size: 16px;
        }
        
        .summary-value {
            font-size: 24px;
            font-weight: bold;
        }
        
        .chart-container {
            height: 400px;
            margin-bottom: 30px;
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
        
        <div class="summary">
            <div class="summary-card">
                <h3>Historique</h3>
                <div class="summary-value">$($prediction.TotalHistoricalErrors)</div>
                <div>Moyenne quotidienne: $($prediction.AverageDailyErrors)</div>
                <div>Tendance: <span class="$($prediction.HistoricalTrend -lt 0 ? 'positive' : ($prediction.HistoricalTrend -gt 0 ? 'negative' : ''))">$($prediction.HistoricalTrend)%</span></div>
            </div>
            
            <div class="summary-card">
                <h3>Prédiction</h3>
                <div class="summary-value">$($prediction.PredictedTotalErrors)</div>
                <div>Moyenne quotidienne: $($prediction.PredictedAverageDailyErrors)</div>
                <div>Tendance: <span class="$($prediction.PredictedTrend -lt 0 ? 'positive' : ($prediction.PredictedTrend -gt 0 ? 'negative' : ''))">$($prediction.PredictedTrend)%</span></div>
            </div>
            
            <div class="summary-card">
                <h3>Méthode</h3>
                <div class="summary-value">$($prediction.Method)</div>
                <div>Historique: $($prediction.HistoryDays) jours</div>
                <div>Prédiction: $($prediction.PredictionDays) jours</div>
            </div>
        </div>
        
        <h2>Graphique de prédiction</h2>
        <div class="chart-container">
            <canvas id="prediction-chart"></canvas>
        </div>
        
        <h2>Détails des prédictions</h2>
        <table>
            <tr>
                <th>Date</th>
                <th>Erreurs prédites</th>
            </tr>
            $(foreach ($point in $prediction.Predictions) {
                "<tr>
                    <td>$($point.Day)</td>
                    <td>$($point.PredictedCount)</td>
                </tr>"
            })
        </table>
        
        <div class="footer">
            <p>Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Méthode: $($prediction.Method) | Historique: $($prediction.HistoryDays) jours | Prédiction: $($prediction.PredictionDays) jours</p>
        </div>
    </div>
    
    <script>
        // Données pour les graphiques
        const historicalData = $(ConvertTo-Json -InputObject $historicalData);
        const predictionData = $(ConvertTo-Json -InputObject $predictionData);
        
        // Combiner les données
        const labels = [...historicalData.map(d => d.day), ...predictionData.map(d => d.day)];
        const historicalValues = [...historicalData.map(d => d.count), ...Array(predictionData.length).fill(null)];
        const predictionValues = [...Array(historicalData.length).fill(null), ...predictionData.map(d => d.count)];
        
        // Graphique de prédiction
        const ctx = document.getElementById('prediction-chart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [
                    {
                        label: 'Historique',
                        data: historicalValues,
                        borderColor: 'rgb(54, 162, 235)',
                        backgroundColor: 'rgba(54, 162, 235, 0.1)',
                        fill: true,
                        tension: 0.1
                    },
                    {
                        label: 'Prédiction',
                        data: predictionValues,
                        borderColor: 'rgb(255, 99, 132)',
                        backgroundColor: 'rgba(255, 99, 132, 0.1)',
                        fill: true,
                        tension: 0.1,
                        borderDash: [5, 5]
                    }
                ]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Nombre d\'erreurs'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Date'
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le rapport si demandé
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorPrediction, Get-ErrorPrediction, New-ErrorPredictionReport
