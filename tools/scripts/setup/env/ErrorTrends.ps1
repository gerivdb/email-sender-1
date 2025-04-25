# Script simplifiÃ© pour analyser les tendances d'erreurs

# Importer le module de collecte de donnÃ©es
$collectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "..\..\D"
if (Test-Path -Path $collectorPath) {
    . $collectorPath
}
else {
    Write-Error "Le module de collecte de donnÃ©es est introuvable: $collectorPath"
    return
}

# Configuration
$TrendConfig = @{
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorTrends"
    DefaultPeriod = 30
    AnalysisInterval = 1
    IncreaseThreshold = 20
}

# Fonction pour initialiser l'analyse

# Script simplifiÃ© pour analyser les tendances d'erreurs

# Importer le module de collecte de donnÃ©es
$collectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "..\..\D"
if (Test-Path -Path $collectorPath) {
    . $collectorPath
}
else {
    Write-Error "Le module de collecte de donnÃ©es est introuvable: $collectorPath"
    return
}

# Configuration
$TrendConfig = @{
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorTrends"
    DefaultPeriod = 30
    AnalysisInterval = 1
    IncreaseThreshold = 20
}

# Fonction pour initialiser l'analyse
function Initialize-ErrorTrends {
    param (
        [string]$OutputFolder = "",
        [int]$DefaultPeriod = 0,
        [int]$AnalysisInterval = 0
    )

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal

    
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $TrendConfig.OutputFolder = $OutputFolder
    }
    
    if ($DefaultPeriod -gt 0) {
        $TrendConfig.DefaultPeriod = $DefaultPeriod
    }
    
    if ($AnalysisInterval -gt 0) {
        $TrendConfig.AnalysisInterval = $AnalysisInterval
    }
    
    if (-not (Test-Path -Path $TrendConfig.OutputFolder)) {
        New-Item -Path $TrendConfig.OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    Initialize-ErrorDataCollector
    
    return $TrendConfig
}

# Fonction pour analyser les tendances
function Get-ErrorTrends {
    param (
        [int]$Days = 0,
        [int]$Interval = 0,
        [string]$Category = "",
        [string]$Severity = ""
    )
    
    if ($Days -le 0) {
        $Days = $TrendConfig.DefaultPeriod
    }
    
    if ($Interval -le 0) {
        $Interval = $TrendConfig.AnalysisInterval
    }
    
    $errors = Get-ErrorData -Days $Days -Category $Category -Severity $Severity
    $trends = @()
    $now = Get-Date
    $intervalCount = [Math]::Ceiling($Days / $Interval)
    
    for ($i = 0; $i -lt $intervalCount; $i++) {
        $startDate = $now.AddDays(-($i + 1) * $Interval)
        $endDate = $now.AddDays(-$i * $Interval)
        
        $intervalErrors = $errors | Where-Object {
            $timestamp = [DateTime]::Parse($_.Timestamp)
            $timestamp -ge $startDate -and $timestamp -lt $endDate
        }
        
        $stats = @{
            StartDate = $startDate
            EndDate = $endDate
            Interval = $i + 1
            TotalErrors = $intervalErrors.Count
            ErrorsBySeverity = @{}
            ErrorsByCategory = @{}
        }
        
        $severities = $intervalErrors | Group-Object -Property Severity | Select-Object Name, Count
        foreach ($severity in $severities) {
            $stats.ErrorsBySeverity[$severity.Name] = $severity.Count
        }
        
        $categories = $intervalErrors | Group-Object -Property Category | Select-Object Name, Count
        foreach ($category in $categories) {
            $stats.ErrorsByCategory[$category.Name] = $category.Count
        }
        
        $trends += $stats
    }
    
    # Calculer les variations
    for ($i = 0; $i -lt $trends.Count - 1; $i++) {
        $current = $trends[$i]
        $previous = $trends[$i + 1]
        
        if ($previous.TotalErrors -gt 0) {
            $current.TotalErrorsVariation = [Math]::Round(($current.TotalErrors - $previous.TotalErrors) / $previous.TotalErrors * 100, 2)
        }
        else {
            $current.TotalErrorsVariation = if ($current.TotalErrors -gt 0) { 100 } else { 0 }
        }
        
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
    }
    
    return $trends
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-ErrorTrendReport {
    param (
        [string]$Title = "Rapport d'Ã©volution des erreurs",
        [int]$Days = 0,
        [int]$Interval = 0,
        [string]$Category = "",
        [string]$Severity = "",
        [string]$OutputPath = "",
        [switch]$OpenOutput
    )
    
    if ($Days -le 0) {
        $Days = $TrendConfig.DefaultPeriod
    }
    
    if ($Interval -le 0) {
        $Interval = $TrendConfig.AnalysisInterval
    }
    
    $trends = Get-ErrorTrends -Days $Days -Interval $Interval -Category $Category -Severity $Severity
    
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "ErrorTrends-$timestamp.html"
        $OutputPath = Join-Path -Path $TrendConfig.OutputFolder -ChildPath $fileName
    }
    
    $trendData = @()
    foreach ($trend in ($trends | Sort-Object -Property Interval)) {
        $trendData += @{
            interval = $trend.Interval
            startDate = $trend.StartDate.ToString("yyyy-MM-dd")
            endDate = $trend.EndDate.ToString("yyyy-MM-dd")
            totalErrors = $trend.TotalErrors
            variation = $trend.TotalErrorsVariation
        }
    }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .chart-container { height: 400px; margin-bottom: 30px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #4CAF50; color: white; }
        .positive { color: green; }
        .negative { color: red; }
    </style>
</head>
<body>
    <div class="container">
        <h1>$Title</h1>
        <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | PÃ©riode: $Days jours | Intervalle: $Interval jours</p>
        
        <div class="chart-container">
            <canvas id="errorsChart"></canvas>
        </div>
        
        <h2>DÃ©tails des tendances</h2>
        <table>
            <tr>
                <th>PÃ©riode</th>
                <th>Erreurs</th>
                <th>Variation</th>
                <th>DÃ©tails</th>
            </tr>
            $(foreach ($trend in ($trends | Sort-Object -Property Interval)) {
                $startDate = $trend.StartDate.ToString("yyyy-MM-dd")
                $endDate = $trend.EndDate.ToString("yyyy-MM-dd")
                $variationClass = if ($trend.TotalErrorsVariation -gt 0) { "negative" } elseif ($trend.TotalErrorsVariation -lt 0) { "positive" } else { "" }
                $variationSign = if ($trend.TotalErrorsVariation -gt 0) { "+" } else { "" }
                
                $details = ""
                if ($trend.SeverityVariations) {
                    $details += "<strong>Par sÃ©vÃ©ritÃ©:</strong><br>"
                    foreach ($severity in $trend.SeverityVariations.Keys) {
                        $count = $trend.ErrorsBySeverity[$severity]
                        $variation = $trend.SeverityVariations[$severity]
                        $varClass = if ($variation -gt 0) { "negative" } elseif ($variation -lt 0) { "positive" } else { "" }
                        $varSign = if ($variation -gt 0) { "+" } else { "" }
                        $details += "$severity: $count (<span class='$varClass'>$varSign$variation%</span>)<br>"
                    }
                }
                
                "<tr>
                    <td>$startDate Ã  $endDate</td>
                    <td>$($trend.TotalErrors)</td>
                    <td class='$variationClass'>$variationSign$($trend.TotalErrorsVariation)%</td>
                    <td>$details</td>
                </tr>"
            })
        </table>
    </div>
    
    <script>
        const trendData = $(ConvertTo-Json -InputObject $trendData);
        
        const ctx = document.getElementById('errorsChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: trendData.map(d => d.startDate + ' Ã  ' + d.endDate),
                datasets: [{
                    label: 'Nombre d\'erreurs',
                    data: trendData.map(d => d.totalErrors),
                    borderColor: 'rgb(75, 192, 192)',
                    tension: 0.1,
                    fill: false
                }, {
                    label: 'Variation (%)',
                    data: trendData.map(d => d.variation),
                    borderColor: 'rgb(255, 99, 132)',
                    tension: 0.1,
                    fill: false,
                    yAxisID: 'y1'
                }]
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
                    y1: {
                        position: 'right',
                        title: {
                            display: true,
                            text: 'Variation (%)'
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
    
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Fonction pour dÃ©tecter les anomalies
function Get-ErrorTrendAnomalies {
    param (
        [int]$Days = 0,
        [int]$Interval = 0,
        [int]$Threshold = 0
    )
    
    if ($Days -le 0) {
        $Days = $TrendConfig.DefaultPeriod
    }
    
    if ($Interval -le 0) {
        $Interval = $TrendConfig.AnalysisInterval
    }
    
    if ($Threshold -le 0) {
        $Threshold = $TrendConfig.IncreaseThreshold
    }
    
    $trends = Get-ErrorTrends -Days $Days -Interval $Interval
    $anomalies = @()
    
    foreach ($trend in $trends) {
        if (-not $trend.TotalErrorsVariation) {
            continue
        }
        
        if ([Math]::Abs($trend.TotalErrorsVariation) -ge $Threshold) {
            $type = if ($trend.TotalErrorsVariation -gt 0) { "Augmentation" } else { "Diminution" }
            
            $anomalies += [PSCustomObject]@{
                StartDate = $trend.StartDate
                EndDate = $trend.EndDate
                Type = $type
                Value = $trend.TotalErrors
                Variation = $trend.TotalErrorsVariation
                Details = "$type significative du nombre total d'erreurs"
            }
        }
        
        if ($trend.SeverityVariations) {
            foreach ($severity in $trend.SeverityVariations.Keys) {
                $variation = $trend.SeverityVariations[$severity]
                
                if ([Math]::Abs($variation) -ge $Threshold) {
                    $type = if ($variation -gt 0) { "Augmentation" } else { "Diminution" }
                    
                    $anomalies += [PSCustomObject]@{
                        StartDate = $trend.StartDate
                        EndDate = $trend.EndDate
                        Type = $type
                        Category = "Severity"
                        Name = $severity
                        Value = $trend.ErrorsBySeverity[$severity]
                        Variation = $variation
                        Details = "$type significative des erreurs de sÃ©vÃ©ritÃ© '$severity'"
                    }
                }
            }
        }
    }
    
    return $anomalies
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorTrends, Get-ErrorTrends, New-ErrorTrendReport, Get-ErrorTrendAnomalies


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
