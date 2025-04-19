#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests de performance pour le projet.
.DESCRIPTION
    Ce script exécute tous les tests de performance pour le projet et génère des rapports de performance.
.PARAMETER OutputPath
    Chemin du répertoire de sortie pour les rapports. Par défaut: "./reports/performance".
.PARAMETER GenerateCharts
    Génère des graphiques pour les rapports de performance.
.EXAMPLE
    .\Run-AllPerformanceTests.ps1 -GenerateCharts
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./reports/performance",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateCharts
)

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Créer le répertoire de sortie
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Répertoire de sortie créé: $OutputPath" -Level "INFO"
}

# Définir le chemin des tests de performance
$PerformanceTestsPath = Join-Path -Path $PSScriptRoot -ChildPath "performance"

# Obtenir tous les fichiers de test de performance
$performanceTestFiles = Get-ChildItem -Path $PerformanceTestsPath -Filter "*.ps1" -Recurse

Write-Log "Nombre de fichiers de test de performance trouvés: $($performanceTestFiles.Count)" -Level "INFO"

# Exécuter les tests de performance
$results = @()

foreach ($testFile in $performanceTestFiles) {
    Write-Log "Exécution du test de performance: $($testFile.Name)" -Level "INFO"
    
    try {
        # Exécuter le test de performance
        & $testFile.FullName
        
        # Vérifier si le test a généré un fichier CSV
        $csvFileName = $testFile.BaseName + ".csv"
        $csvFilePath = Join-Path -Path $OutputPath -ChildPath $csvFileName
        
        if (Test-Path -Path $csvFilePath) {
            Write-Log "Fichier CSV généré: $csvFilePath" -Level "SUCCESS"
            
            # Lire les résultats du fichier CSV
            $testResults = Import-Csv -Path $csvFilePath
            $results += $testResults
        } else {
            Write-Log "Aucun fichier CSV généré pour le test: $($testFile.Name)" -Level "WARNING"
        }
    } catch {
        Write-Log "Erreur lors de l'exécution du test de performance: $($testFile.Name)" -Level "ERROR"
        Write-Log "Message d'erreur: $_" -Level "ERROR"
    }
}

# Générer un rapport de performance global
$reportPath = Join-Path -Path $OutputPath -ChildPath "performance-report.html"

# Créer le rapport HTML
$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de performance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { margin: 20px 0; padding: 10px; background-color: #f5f5f5; border-radius: 5px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .chart { margin: 20px 0; }
    </style>
"@

if ($GenerateCharts) {
    $htmlReport += @"
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
"@
}

$htmlReport += @"
</head>
<body>
    <h1>Rapport de performance</h1>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre de tests exécutés: $($results.Count)</p>
        <p>Date d'exécution: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <h2>Résultats des tests</h2>
    <table>
        <tr>
            <th>Test</th>
            <th>Durée moyenne (ms)</th>
            <th>Durée minimale (ms)</th>
            <th>Durée maximale (ms)</th>
            <th>Écart type</th>
            <th>Itérations</th>
        </tr>
"@

foreach ($result in $results) {
    $htmlReport += @"
        <tr>
            <td>$($result.TestName)</td>
            <td>$($result.AverageDuration)</td>
            <td>$($result.MinDuration)</td>
            <td>$($result.MaxDuration)</td>
            <td>$($result.StdDeviation)</td>
            <td>$($result.Iterations)</td>
        </tr>
"@
}

$htmlReport += @"
    </table>
"@

if ($GenerateCharts) {
    $htmlReport += @"
    <h2>Graphiques</h2>
    
    <div class="chart">
        <h3>Durée moyenne par test</h3>
        <canvas id="averageDurationChart"></canvas>
    </div>
    
    <script>
        // Données pour le graphique de durée moyenne
        const testNames = [$(($results | ForEach-Object { "'$($_.TestName)'" }) -join ", ")];
        const averageDurations = [$(($results | ForEach-Object { $_.AverageDuration }) -join ", ")];
        
        // Créer le graphique de durée moyenne
        const averageDurationCtx = document.getElementById('averageDurationChart').getContext('2d');
        const averageDurationChart = new Chart(averageDurationCtx, {
            type: 'bar',
            data: {
                labels: testNames,
                datasets: [{
                    label: 'Durée moyenne (ms)',
                    data: averageDurations,
                    backgroundColor: 'rgba(54, 162, 235, 0.5)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    </script>
"@
}

$htmlReport += @"
</body>
</html>
"@

$htmlReport | Set-Content -Path $reportPath -Encoding UTF8

Write-Log "Rapport HTML généré: $reportPath" -Level "SUCCESS"

# Ouvrir le rapport HTML
if (Test-Path -Path $reportPath) {
    Write-Log "Ouverture du rapport HTML..." -Level "INFO"
    Start-Process $reportPath
}

Write-Log "Tous les tests de performance ont été exécutés avec succès!" -Level "SUCCESS"
