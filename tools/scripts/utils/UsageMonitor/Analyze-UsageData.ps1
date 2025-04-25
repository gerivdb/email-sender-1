<#
.SYNOPSIS
    Analyse les données d'utilisation collectées par le module UsageMonitor.
.DESCRIPTION
    Ce script analyse les données d'utilisation collectées par le module UsageMonitor
    et génère des rapports détaillés sur les performances des scripts.
.PARAMETER DatabasePath
    Chemin vers le fichier de base de données d'utilisation.
.PARAMETER OutputPath
    Chemin où les rapports seront générés.
.PARAMETER ReportFormat
    Format des rapports à générer (HTML, CSV, JSON).
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

# Fonction pour écrire des messages de log
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

# Fonction pour générer un rapport HTML
function Generate-HtmlReport {
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
        <p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss")</p>
"@
    
    $htmlFooter = @"
        <div class="footer">
            <p>Généré par le module UsageMonitor</p>
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
            return "<p>Aucune donnée disponible pour $Title</p>"
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
    
    # Générer le contenu HTML
    $htmlContent = $htmlHeader
    
    # Section des scripts les plus utilisés
    $htmlContent += ConvertTo-HtmlTable -Data $UsageData.TopUsedScripts -Title "Scripts les plus utilisés" -ValueHeader "Nombre d'exécutions"
    
    # Section des scripts les plus lents
    $htmlContent += ConvertTo-HtmlTable -Data $UsageData.SlowestScripts -Title "Scripts les plus lents" -ValueHeader "Durée moyenne (ms)"
    
    # Section des scripts avec le plus d'échecs
    $htmlContent += ConvertTo-HtmlTable -Data $UsageData.MostFailingScripts -Title "Scripts avec le plus d'échecs" -ValueHeader "Taux d'échec (%)"
    
    # Section des scripts les plus intensifs en ressources
    $htmlContent += ConvertTo-HtmlTable -Data $UsageData.ResourceIntensiveScripts -Title "Scripts les plus intensifs en ressources" -ValueHeader "Utilisation mémoire moyenne (octets)"
    
    # Section des goulots d'étranglement
    if ($Bottlenecks.Count -gt 0) {
        $htmlContent += "<h2>Goulots d'étranglement détectés</h2>"
        $htmlContent += "<table>"
        $htmlContent += "<tr><th>Script</th><th>Durée moyenne (ms)</th><th>Seuil de lenteur (ms)</th><th>Exécutions lentes</th><th>Pourcentage</th></tr>"
        
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
        $htmlContent += "<h2>Goulots d'étranglement</h2>"
        $htmlContent += "<p>Aucun goulot d'étranglement détecté.</p>"
    }
    
    # Ajouter des graphiques
    $htmlContent += @"
        <h2>Graphiques</h2>
        
        <h3>Scripts les plus utilisés</h3>
        <div class="chart-container">
            <canvas id="usageChart"></canvas>
        </div>
        
        <h3>Scripts les plus lents</h3>
        <div class="chart-container">
            <canvas id="durationChart"></canvas>
        </div>
        
        <script>
            // Données pour les graphiques
            const usageData = {
                labels: [$(($UsageData.TopUsedScripts.Keys | ForEach-Object { "'" + (Split-Path -Path $_ -Leaf) + "'" }) -join ', ')],
                datasets: [{
                    label: 'Nombre d\'exécutions',
                    data: [$(($UsageData.TopUsedScripts.Values) -join ', ')],
                    backgroundColor: 'rgba(54, 162, 235, 0.5)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                }]
            };
            
            const durationData = {
                labels: [$(($UsageData.SlowestScripts.Keys | ForEach-Object { "'" + (Split-Path -Path $_ -Leaf) + "'" }) -join ', ')],
                datasets: [{
                    label: 'Durée moyenne (ms)',
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
    
    # Écrire le rapport HTML
    $htmlContent | Out-File -FilePath $reportPath -Encoding utf8 -Force
    
    return $reportPath
}

# Fonction pour générer un rapport CSV
function Generate-CsvReport {
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
    
    # Exporter les données en CSV
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

# Fonction pour générer un rapport JSON
function Generate-JsonReport {
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

# Point d'entrée principal
Write-Log "Démarrage de l'analyse des données d'utilisation..." -Level "TITLE"

# Vérifier si le fichier de base de données existe
if (-not (Test-Path -Path $DatabasePath)) {
    Write-Log "Le fichier de base de données spécifié n'existe pas: $DatabasePath" -Level "ERROR"
    exit 1
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Répertoire de sortie créé: $OutputPath" -Level "INFO"
}

# Initialiser le moniteur d'utilisation avec la base de données spécifiée
Initialize-UsageMonitor -DatabasePath $DatabasePath
Write-Log "Base de données d'utilisation chargée: $DatabasePath" -Level "INFO"

# Récupérer les statistiques d'utilisation
$usageStats = Get-ScriptUsageStatistics
Write-Log "Statistiques d'utilisation récupérées" -Level "INFO"

# Analyser les goulots d'étranglement
$bottlenecks = Find-ScriptBottlenecks
Write-Log "Analyse des goulots d'étranglement terminée. $($bottlenecks.Count) goulots détectés." -Level "INFO"

# Générer les rapports selon le format spécifié
$generatedReports = @()

if ($ReportFormat -eq "HTML" -or $ReportFormat -eq "All") {
    $htmlReport = Generate-HtmlReport -UsageData $usageStats -Bottlenecks $bottlenecks -OutputPath $OutputPath
    $generatedReports += $htmlReport
    Write-Log "Rapport HTML généré: $htmlReport" -Level "SUCCESS"
}

if ($ReportFormat -eq "CSV" -or $ReportFormat -eq "All") {
    $csvReports = Generate-CsvReport -UsageData $usageStats -Bottlenecks $bottlenecks -OutputPath $OutputPath
    $generatedReports += $csvReports.Values
    Write-Log "Rapports CSV générés dans: $OutputPath" -Level "SUCCESS"
}

if ($ReportFormat -eq "JSON" -or $ReportFormat -eq "All") {
    $jsonReport = Generate-JsonReport -UsageData $usageStats -Bottlenecks $bottlenecks -OutputPath $OutputPath
    $generatedReports += $jsonReport
    Write-Log "Rapport JSON généré: $jsonReport" -Level "SUCCESS"
}

Write-Log "Génération des rapports terminée." -Level "TITLE"

# Ouvrir le premier rapport généré si disponible
if ($generatedReports.Count -gt 0 -and $ReportFormat -eq "HTML") {
    $reportToOpen = $generatedReports[0]
    Write-Log "Ouverture du rapport: $reportToOpen" -Level "INFO"
    Start-Process $reportToOpen
}
