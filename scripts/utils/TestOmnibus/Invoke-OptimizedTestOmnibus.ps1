<#
.SYNOPSIS
    Exécute TestOmnibus avec des paramètres optimisés en fonction des données d'utilisation.
.DESCRIPTION
    Ce script utilise les données d'utilisation collectées par le système d'optimisation proactive
    pour exécuter TestOmnibus avec des paramètres optimisés, comme le nombre de threads,
    l'ordre d'exécution des tests, etc.
.PARAMETER TestPath
    Chemin vers les tests à exécuter.
.PARAMETER UsageDataPath
    Chemin vers le fichier de données d'utilisation.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats des tests.
.PARAMETER ConfigPath
    Chemin vers un fichier de configuration personnalisé.
.PARAMETER GenerateDetailedReport
    Génère un rapport détaillé des résultats des tests.
.EXAMPLE
    .\Invoke-OptimizedTestOmnibus.ps1 -TestPath "D:\Tests" -UsageDataPath "D:\UsageData\usage_data.xml" -OutputPath "D:\TestResults"
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TestPath,
    
    [Parameter(Mandatory = $false)]
    [string]$UsageDataPath = (Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\usage_data.xml"),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results"),
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateDetailedReport
)

# Vérifier que le chemin des tests existe
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Chemin vers l'optimiseur
$optimizerPath = Join-Path -Path $PSScriptRoot -ChildPath "Optimizers\UsageBasedOptimizer.ps1"

# Chemin vers TestOmnibus
$testOmnibusPath = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"

# Vérifier que les scripts existent
if (-not (Test-Path -Path $optimizerPath)) {
    Write-Error "L'optimiseur n'existe pas: $optimizerPath"
    return 1
}

if (-not (Test-Path -Path $testOmnibusPath)) {
    Write-Error "TestOmnibus n'existe pas: $testOmnibusPath"
    return 1
}

# Exécuter l'optimiseur pour obtenir une configuration optimisée
Write-Host "Optimisation de l'exécution des tests..." -ForegroundColor Cyan
$optimizedConfig = & $optimizerPath -UsageDataPath $UsageDataPath -OutputPath $OutputPath

# Créer un fichier de configuration temporaire
$tempConfigPath = Join-Path -Path $OutputPath -ChildPath "optimized_config.json"
$optimizedConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $tempConfigPath -Encoding utf8 -Force

# Utiliser la configuration personnalisée si spécifiée
$configToUse = if ($ConfigPath -and (Test-Path -Path $ConfigPath)) { $ConfigPath } else { $tempConfigPath }

# Exécuter TestOmnibus avec la configuration optimisée
Write-Host "Exécution de TestOmnibus avec la configuration optimisée..." -ForegroundColor Cyan
Write-Host "Nombre de threads: $($optimizedConfig.MaxThreads)" -ForegroundColor Cyan
Write-Host "Répertoire de sortie: $($optimizedConfig.OutputPath)" -ForegroundColor Cyan

# Construire les paramètres pour TestOmnibus
$testOmnibusParams = @{
    Path = $TestPath
    ConfigPath = $configToUse
}

# Exécuter TestOmnibus
$result = & $testOmnibusPath @testOmnibusParams

# Générer un rapport détaillé si demandé
if ($GenerateDetailedReport) {
    Write-Host "Génération d'un rapport détaillé..." -ForegroundColor Cyan
    
    # Chemin vers le rapport détaillé
    $detailedReportPath = Join-Path -Path $OutputPath -ChildPath "detailed_report.html"
    
    # Récupérer les résultats des tests
    $testResults = Import-Clixml -Path (Join-Path -Path $optimizedConfig.OutputPath -ChildPath "results.xml")
    
    # Générer le rapport détaillé
    $htmlReport = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport détaillé des tests</title>
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
        .success {
            color: #2ecc71;
        }
        .failure {
            color: #e74c3c;
        }
        .slow {
            color: #f39c12;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #eee;
            color: #7f8c8d;
            font-size: 0.9em;
        }
        .optimization-info {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .chart-container {
            width: 100%;
            height: 300px;
            margin-bottom: 20px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <h1>Rapport détaillé des tests</h1>
        <p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss")</p>
        
        <div class="optimization-info">
            <h2>Informations d'optimisation</h2>
            <p>
                <strong>Nombre de threads:</strong> $($optimizedConfig.MaxThreads)<br>
                <strong>Répertoire de sortie:</strong> $($optimizedConfig.OutputPath)<br>
                <strong>Génération de rapport HTML:</strong> $($optimizedConfig.GenerateHtmlReport)<br>
                <strong>Collecte de données de performance:</strong> $($optimizedConfig.CollectPerformanceData)
            </p>
        </div>
        
        <h2>Résumé des tests</h2>
        <p>
            <strong>Tests exécutés:</strong> $($testResults.Count)<br>
            <strong>Tests réussis:</strong> $(($testResults | Where-Object { $_.Success }).Count)<br>
            <strong>Tests échoués:</strong> $(($testResults | Where-Object { -not $_.Success }).Count)<br>
            <strong>Durée totale:</strong> $([math]::Round(($testResults | Measure-Object -Property Duration -Sum).Sum, 2)) ms
        </p>
        
        <div class="chart-container">
            <canvas id="testResultsChart"></canvas>
        </div>
        
        <h2>Résultats détaillés</h2>
        <table>
            <tr>
                <th>Test</th>
                <th>Résultat</th>
                <th>Durée (ms)</th>
                <th>Détails</th>
            </tr>
"@

    foreach ($result in $testResults) {
        $statusClass = if ($result.Success) { "success" } else { "failure" }
        $statusText = if ($result.Success) { "Succès" } else { "Échec" }
        
        if ($result.Success -and $result.Duration -gt 1000) {
            $statusClass = "slow"
            $statusText = "Succès (lent)"
        }
        
        $htmlReport += @"
            <tr>
                <td>$($result.Name)</td>
                <td class="$statusClass">$statusText</td>
                <td>$([math]::Round($result.Duration, 2))</td>
                <td>$($result.ErrorMessage)</td>
            </tr>
"@
    }

    $htmlReport += @"
        </table>
        
        <script>
            // Créer un graphique des résultats des tests
            const ctx = document.getElementById('testResultsChart').getContext('2d');
            const testResultsChart = new Chart(ctx, {
                type: 'pie',
                data: {
                    labels: ['Réussis', 'Échoués'],
                    datasets: [{
                        label: 'Résultats des tests',
                        data: [$(($testResults | Where-Object { $_.Success }).Count), $(($testResults | Where-Object { -not $_.Success }).Count)],
                        backgroundColor: [
                            '#2ecc71',
                            '#e74c3c'
                        ],
                        borderColor: [
                            '#27ae60',
                            '#c0392b'
                        ],
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
                            display: true,
                            text: 'Résultats des tests'
                        }
                    }
                }
            });
        </script>
        
        <div class="footer">
            <p>Généré par TestOmnibus Optimizer</p>
        </div>
    </div>
</body>
</html>
"@

    # Enregistrer le rapport détaillé
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($detailedReportPath, $htmlReport, $utf8WithBom)
    
    Write-Host "Rapport détaillé généré: $detailedReportPath" -ForegroundColor Green
}

# Retourner le résultat
return $result
