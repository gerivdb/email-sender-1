<#
.SYNOPSIS
    Analyse les donnÃ©es d'utilisation collectÃ©es par le module UsageMonitor.
.DESCRIPTION
    Ce script analyse les donnÃ©es d'utilisation collectÃ©es par le module UsageMonitor
    et gÃ©nÃ¨re des rapports dÃ©taillÃ©s sur les performances des scripts.
.PARAMETER DatabasePath
    Chemin vers le fichier de base de donnÃ©es d'utilisation.
.PARAMETER OutputPath
    Chemin oÃ¹ les rapports seront gÃ©nÃ©rÃ©s.
.PARAMETER ReportFormat
    Format des rapports Ã  gÃ©nÃ©rer (HTML, CSV, JSON).
.EXAMPLE
    .\Analyze-UsageData.ps1 -OutputPath "C:\Reports"
.NOTES
    Auteur: Augment Agent
    Date: 2025-05-15
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$DatabasePath = (Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\usage_data.xml"),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\Reports"),
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("HTML", "CSV", "JSON", "All")]
    [string]$ReportFormat = "HTML"
)

# Importer le module UsageMonitor
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "UsageMonitor.psm1"
Import-Module $modulePath -Force

# Fonction pour Ã©crire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-HtmlReport {
    param (
        [PSCustomObject]$UsageData,
        [PSCustomObject[]]$Bottlenecks,
        [string]$OutputPath
    )
    
    $reportPath = Join-Path -Path $OutputPath -ChildPath "usage_report.html"
    
    $htmlHeader = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'utilisation des scripts</title>
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
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            border-radius: 5px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            text-align: center;
            padding-bottom: 10px;
            border-bottom: 2px solid #eee;
        }
        h2 {
            margin-top: 30px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f1f1f1;
        }
        .warning {
            color: #e67e22;
        }
        .error {
            color: #e74c3c;
        }
        .success {
            color: #2ecc71;
        }
        .chart-container {
            width: 100%;
            height: 400px;
            margin-bottom: 30px;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #eee;
            color: #7f8c8d;
            font-size: 0.9em;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <h1>Rapport d'utilisation des scripts</h1>
        <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "dd/MM/yyyy Ã  HH:mm:ss")</p>
"@
    
    $htmlFooter = @"
        <div class="footer">
            <p>GÃ©nÃ©rÃ© par le module UsageMonitor</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Fonction pour convertir une table de hachage en HTML
    function ConvertTo-HtmlTable {
        param (
            [hashtable]$Data,
            [string]$Title,
            [string]$KeyHeader = "Script",
            [string]$ValueHeader = "Valeur"
        )
        
        if ($Data.Count -eq 0) {
            return "<p>Aucune donnÃ©e disponible pour $Title</p>"
        }
        
        $html = "<h2>$Title</h2>"
        $html += "<table>"
        $html += "<tr><th>$KeyHeader</th><th>$ValueHeader</th></tr>"
        
        foreach ($key in $Data.Keys) {
            $value = $Data[$key]
            $scriptName = Split-Path -Path $key -Leaf
            $html += "<tr><td>$scriptName</td><td>$value</td></tr>"
        }
        
        $html += "</table>"
        return $html
    }
    
    # GÃ©nÃ©rer le contenu HTML
    $htmlContent = $htmlHeader
    
    # Section des scripts les plus utilisÃ©s
    $htmlContent += ConvertTo-HtmlTable -Data $UsageData.TopUsedScripts -Title "Scripts les plus utilisÃ©s" -ValueHeader "Nombre d'exÃ©cutions"
    
    # Section des scripts les plus lents
    $htmlContent += ConvertTo-HtmlTable -Data $UsageData.SlowestScripts -Title "Scripts les plus lents" -ValueHeader "DurÃ©e moyenne (ms)"
    
    # Section des scripts avec le plus d'Ã©checs
    $htmlContent += ConvertTo-HtmlTable -Data $UsageData.MostFailingScripts -Title "Scripts avec le plus d'Ã©checs" -ValueHeader "Taux d'Ã©chec (%)"
    
    # Section des scripts les plus intensifs en ressources
    $htmlContent += ConvertTo-HtmlTable -Data $UsageData.ResourceIntensiveScripts -Title "Scripts les plus intensifs en ressources" -ValueHeader "Utilisation mÃ©moire moyenne (octets)"
    
    # Section des goulots d'Ã©tranglement
    if ($Bottlenecks.Count -gt 0) {
        $htmlContent += "<h2>Goulots d'Ã©tranglement dÃ©tectÃ©s</h2>"
        $htmlContent += "<table>"
        $htmlContent += "<tr><th>Script</th><th>DurÃ©e moyenne (ms)</th><th>Seuil de lenteur (ms)</th><th>ExÃ©cutions lentes</th><th>Pourcentage</th></tr>"
        
        foreach ($bottleneck in $Bottlenecks) {
            $htmlContent += "<tr>"
            $htmlContent += "<td>$($bottleneck.ScriptName)</td>"
            $htmlContent += "<td>$([math]::Round($bottleneck.AverageDuration, 2))</td>"
            $htmlContent += "<td>$([math]::Round($bottleneck.SlowThreshold, 2))</td>"
            $htmlContent += "<td>$($bottleneck.SlowExecutionsCount)/$($bottleneck.TotalExecutionsCount)</td>"
            $htmlContent += "<td>$([math]::Round($bottleneck.SlowExecutionPercentage, 2))%</td>"
            $htmlContent += "</tr>"
        }
        
        $htmlContent += "</table>"
    }
    else {
        $htmlContent += "<h2>Goulots d'Ã©tranglement</h2>"
        $htmlContent += "<p>Aucun goulot d'Ã©tranglement dÃ©tectÃ©.</p>"
    }
    
    # Ajouter des graphiques
    $htmlContent += @"
        <h2>Graphiques</h2>
        
        <h3>Scripts les plus utilisÃ©s</h3>
        <div class="chart-container">
            <canvas id="usageChart"></canvas>
        </div>
        
        <h3>Scripts les plus lents</h3>
        <div class="chart-container">
            <canvas id="durationChart"></canvas>
        </div>
        
        <script>
            // DonnÃ©es pour les graphiques
            const usageData = {
                labels: [$(($UsageData.TopUsedScripts.Keys | ForEach-Object { "'" + (Split-Path -Path $_ -Leaf) + "'" }) -join ', ')],
                datasets: [{
                    label: 'Nombre d\'exÃ©cutions',
                    data: [$(($UsageData.TopUsedScripts.Values) -join ', ')],
                    backgroundColor: 'rgba(54, 162, 235, 0.5)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                }]
            };
            
            const durationData = {
                labels: [$(($UsageData.SlowestScripts.Keys | ForEach-Object { "'" + (Split-Path -Path $_ -Leaf) + "'" }) -join ', ')],
                datasets: [{
                    label: 'DurÃ©e moyenne (ms)',
                    data: [$(($UsageData.SlowestScripts.Values) -join ', ')],
                    backgroundColor: 'rgba(255, 99, 132, 0.5)',
                    borderColor: 'rgba(255, 99, 132, 1)',
                    borderWidth: 1
                }]
            };
            
            // Configuration des graphiques
            const usageChart = new Chart(
                document.getElementById('usageChart'),
                {
                    type: 'bar',
                    data: usageData,
                    options: {
                        scales: {
                            y: {
                                beginAtZero: true
                            }
                        }
                    }
                }
            );
            
            const durationChart = new Chart(
                document.getElementById('durationChart'),
                {
                    type: 'bar',
                    data: durationData,
                    options: {
                        scales: {
                            y: {
                                beginAtZero: true
                            }
                        }
                    }
                }
            );
        </script>
"@
    
    $htmlContent += $htmlFooter
    
    # Ã‰crire le rapport HTML
    $htmlContent | Out-File -FilePath $reportPath -Encoding utf8 -Force
    
    return $reportPath
}

# Fonction pour gÃ©nÃ©rer un rapport CSV
function New-CsvReport {
    param (
        [PSCustomObject]$UsageData,
        [PSCustomObject[]]$Bottlenecks,
        [string]$OutputPath
    )
    
    $topUsedPath = Join-Path -Path $OutputPath -ChildPath "top_used_scripts.csv"
    $slowestPath = Join-Path -Path $OutputPath -ChildPath "slowest_scripts.csv"
    $failingPath = Join-Path -Path $OutputPath -ChildPath "failing_scripts.csv"
    $resourcePath = Join-Path -Path $OutputPath -ChildPath "resource_intensive_scripts.csv"
    $bottlenecksPath = Join-Path -Path $OutputPath -ChildPath "bottlenecks.csv"
    
    # Convertir les hashtables en objets pour l'export CSV
    $topUsed = $UsageData.TopUsedScripts.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            ScriptPath = $_.Key
            ScriptName = Split-Path -Path $_.Key -Leaf
            ExecutionCount = $_.Value
        }
    }
    
    $slowest = $UsageData.SlowestScripts.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            ScriptPath = $_.Key
            ScriptName = Split-Path -Path $_.Key -Leaf
            AverageDurationMs = $_.Value
        }
    }
    
    $failing = $UsageData.MostFailingScripts.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            ScriptPath = $_.Key
            ScriptName = Split-Path -Path $_.Key -Leaf
            FailureRatePercent = $_.Value
        }
    }
    
    $resource = $UsageData.ResourceIntensiveScripts.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            ScriptPath = $_.Key
            ScriptName = Split-Path -Path $_.Key -Leaf
            AverageMemoryUsageBytes = $_.Value
        }
    }
    
    # Exporter les donnÃ©es en CSV
    $topUsed | Export-Csv -Path $topUsedPath -NoTypeInformation -Encoding UTF8 -Force
    $slowest | Export-Csv -Path $slowestPath -NoTypeInformation -Encoding UTF8 -Force
    $failing | Export-Csv -Path $failingPath -NoTypeInformation -Encoding UTF8 -Force
    $resource | Export-Csv -Path $resourcePath -NoTypeInformation -Encoding UTF8 -Force
    
    if ($Bottlenecks.Count -gt 0) {
        $Bottlenecks | Select-Object ScriptPath, ScriptName, AverageDuration, SlowThreshold, SlowExecutionsCount, TotalExecutionsCount, SlowExecutionPercentage |
            Export-Csv -Path $bottlenecksPath -NoTypeInformation -Encoding UTF8 -Force
    }
    
    return @{
        TopUsed = $topUsedPath
        Slowest = $slowestPath
        Failing = $failingPath
        Resource = $resourcePath
        Bottlenecks = $bottlenecksPath
    }
}

# Fonction pour gÃ©nÃ©rer un rapport JSON
function New-JsonReport {
    param (
        [PSCustomObject]$UsageData,
        [PSCustomObject[]]$Bottlenecks,
        [string]$OutputPath
    )
    
    $reportPath = Join-Path -Path $OutputPath -ChildPath "usage_report.json"
    
    $report = [PSCustomObject]@{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TopUsedScripts = $UsageData.TopUsedScripts
        SlowestScripts = $UsageData.SlowestScripts
        MostFailingScripts = $UsageData.MostFailingScripts
        ResourceIntensiveScripts = $UsageData.ResourceIntensiveScripts
        Bottlenecks = $Bottlenecks
    }
    
    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding utf8 -Force
    
    return $reportPath
}

# Point d'entrÃ©e principal
Write-Log "DÃ©marrage de l'analyse des donnÃ©es d'utilisation..." -Level "TITLE"

# VÃ©rifier si le fichier de base de donnÃ©es existe
if (-not (Test-Path -Path $DatabasePath)) {
    Write-Log "Le fichier de base de donnÃ©es spÃ©cifiÃ© n'existe pas: $DatabasePath" -Level "ERROR"
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "RÃ©pertoire de sortie crÃ©Ã©: $OutputPath" -Level "INFO"
}

# Initialiser le moniteur d'utilisation avec la base de donnÃ©es spÃ©cifiÃ©e
Initialize-UsageMonitor -DatabasePath $DatabasePath
Write-Log "Base de donnÃ©es d'utilisation chargÃ©e: $DatabasePath" -Level "INFO"

# RÃ©cupÃ©rer les statistiques d'utilisation
$usageStats = Get-ScriptUsageStatistics
Write-Log "Statistiques d'utilisation rÃ©cupÃ©rÃ©es" -Level "INFO"

# Analyser les goulots d'Ã©tranglement
$bottlenecks = Find-ScriptBottlenecks
Write-Log "Analyse des goulots d'Ã©tranglement terminÃ©e. $($bottlenecks.Count) goulots dÃ©tectÃ©s." -Level "INFO"

# GÃ©nÃ©rer les rapports selon le format spÃ©cifiÃ©
$generatedReports = @()

if ($ReportFormat -eq "HTML" -or $ReportFormat -eq "All") {
    $htmlReport = New-HtmlReport -UsageData $usageStats -Bottlenecks $bottlenecks -OutputPath $OutputPath
    $generatedReports += $htmlReport
    Write-Log "Rapport HTML gÃ©nÃ©rÃ©: $htmlReport" -Level "SUCCESS"
}

if ($ReportFormat -eq "CSV" -or $ReportFormat -eq "All") {
    $csvReports = New-CsvReport -UsageData $usageStats -Bottlenecks $bottlenecks -OutputPath $OutputPath
    $generatedReports += $csvReports.Values
    Write-Log "Rapports CSV gÃ©nÃ©rÃ©s dans: $OutputPath" -Level "SUCCESS"
}

if ($ReportFormat -eq "JSON" -or $ReportFormat -eq "All") {
    $jsonReport = New-JsonReport -UsageData $usageStats -Bottlenecks $bottlenecks -OutputPath $OutputPath
    $generatedReports += $jsonReport
    Write-Log "Rapport JSON gÃ©nÃ©rÃ©: $jsonReport" -Level "SUCCESS"
}

Write-Log "GÃ©nÃ©ration des rapports terminÃ©e." -Level "TITLE"

# Ouvrir le premier rapport gÃ©nÃ©rÃ© si disponible
if ($generatedReports.Count -gt 0 -and $ReportFormat -eq "HTML") {
    $reportToOpen = $generatedReports[0]
    Write-Log "Ouverture du rapport: $reportToOpen" -Level "INFO"
    Start-Process $reportToOpen
}

