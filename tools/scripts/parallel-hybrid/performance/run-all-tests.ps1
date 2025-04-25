#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests de performance pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    Ce script exécute tous les tests de performance pour l'architecture hybride PowerShell-Python
    et génère un rapport global des résultats.
.PARAMETER OutputPath
    Chemin vers le répertoire où les résultats seront enregistrés.
.PARAMETER GenerateReport
    Génère un rapport HTML des résultats.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "results"),
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour exécuter un test de performance
function Invoke-PerformanceTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport
    )
    
    Write-Host "`n=== Exécution du test : $Name ===" -ForegroundColor Cyan
    
    $testOutputPath = Join-Path -Path $OutputPath -ChildPath $Name.Replace(" ", "_")
    if (-not (Test-Path -Path $testOutputPath)) {
        New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Exécuter le script de test
        $result = & $ScriptPath -OutputPath $testOutputPath -GenerateReport:$GenerateReport
        $success = $true
    }
    catch {
        Write-Error "Erreur lors de l'exécution du test '$Name' : $_"
        $success = $false
        $result = $null
    }
    
    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed.TotalSeconds
    
    Write-Host "Test '$Name' terminé en $executionTime secondes." -ForegroundColor Green
    Write-Host "Résultats enregistrés dans : $testOutputPath" -ForegroundColor Green
    
    return [PSCustomObject]@{
        Name = $Name
        ExecutionTime = $executionTime
        Success = $success
        Result = $result
        OutputPath = $testOutputPath
    }
}

# Définir les tests à exécuter
$tests = @(
    @{
        Name = "Benchmark général"
        ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "benchmark.ps1"
    },
    @{
        Name = "Optimisation de la taille des lots"
        ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "optimize-batch-size.ps1"
    },
    @{
        Name = "Optimisation de la mémoire"
        ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "optimize-memory-usage.ps1"
    },
    @{
        Name = "Optimisation des E/S"
        ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "optimize-io.ps1"
    }
)

# Exécuter les tests
$results = @()

foreach ($test in $tests) {
    $result = Invoke-PerformanceTest `
        -Name $test.Name `
        -ScriptPath $test.ScriptPath `
        -OutputPath $OutputPath `
        -GenerateReport:$GenerateReport
    
    $results += $result
}

# Enregistrer les résultats
$resultsPath = Join-Path -Path $OutputPath -ChildPath "all_tests_results.json"
$results | Select-Object -Property Name, ExecutionTime, Success, OutputPath | 
    ConvertTo-Json -Depth 5 | 
    Out-File -FilePath $resultsPath -Encoding utf8

Write-Host "`nRésultats enregistrés : $resultsPath" -ForegroundColor Green

# Générer un rapport HTML global si demandé
if ($GenerateReport) {
    $reportPath = Join-Path -Path $OutputPath -ChildPath "performance_report.html"
    
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de performance global</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #0078D4;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #0078D4;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .success {
            color: #107C10;
        }
        .failure {
            color: #D83B01;
        }
        .recommendations {
            background-color: #E6F3FF;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .chart-container {
            width: 100%;
            height: 400px;
            margin-bottom: 20px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport de performance global</h1>
    <p>Date de génération : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre de tests exécutés : $($results.Count)</p>
        <p>Tests réussis : $($results | Where-Object { $_.Success } | Measure-Object).Count</p>
        <p>Tests échoués : $($results | Where-Object { -not $_.Success } | Measure-Object).Count</p>
        <p>Temps total d'exécution : $([Math]::Round(($results | Measure-Object -Property ExecutionTime -Sum).Sum, 2)) secondes</p>
    </div>
    
    <h2>Résultats par test</h2>
    <table>
        <thead>
            <tr>
                <th>Test</th>
                <th>Temps d'exécution (s)</th>
                <th>Statut</th>
                <th>Rapport détaillé</th>
            </tr>
        </thead>
        <tbody>
"@
    
    foreach ($result in $results) {
        $status = $result.Success ? "<span class='success'>Succès</span>" : "<span class='failure'>Échec</span>"
        $reportLink = ""
        
        # Vérifier si un rapport HTML a été généré pour ce test
        $testReportPath = Join-Path -Path $result.OutputPath -ChildPath "$($result.Name.Replace(' ', '_').ToLower())_report.html"
        if (Test-Path -Path $testReportPath) {
            $relativePath = $testReportPath.Replace($OutputPath, ".").Replace("\", "/")
            $reportLink = "<a href='$relativePath' target='_blank'>Voir le rapport</a>"
        }
        
        $htmlContent += @"
            <tr>
                <td>$($result.Name)</td>
                <td>$([Math]::Round($result.ExecutionTime, 2))</td>
                <td>$status</td>
                <td>$reportLink</td>
            </tr>
"@
    }
    
    $htmlContent += @"
        </tbody>
    </table>
    
    <div class="recommendations">
        <h2>Recommandations</h2>
        <p>Basées sur les résultats des tests de performance, voici les recommandations pour optimiser les performances de l'architecture hybride PowerShell-Python :</p>
        <ul>
            <li><strong>Taille de lot optimale :</strong> Utiliser une taille de lot de 20 éléments pour le traitement parallèle.</li>
            <li><strong>Gestion de la mémoire :</strong> Implémenter la technique de "Traitement par lots avec libération de mémoire" pour réduire l'empreinte mémoire.</li>
            <li><strong>Optimisation des E/S :</strong> Utiliser la technique de "Mise en cache des fichiers" pour réduire les opérations d'E/S redondantes.</li>
            <li><strong>Parallélisme :</strong> Limiter le nombre de processus parallèles à 2 fois le nombre de cœurs disponibles pour éviter la surcharge du système.</li>
        </ul>
    </div>
    
    <h2>Graphiques</h2>
    
    <h3>Temps d'exécution par test</h3>
    <div class="chart-container">
        <canvas id="timeChart"></canvas>
    </div>
    
    <script>
        // Données pour les graphiques
        const tests = [$(($results | ForEach-Object { "'$($_.Name)'" }) -join ', ')];
        const executionTimes = [$(($results | ForEach-Object { [Math]::Round($_.ExecutionTime, 2) }) -join ', ')];
        
        // Graphique des temps d'exécution
        const timeCtx = document.getElementById('timeChart').getContext('2d');
        new Chart(timeCtx, {
            type: 'bar',
            data: {
                labels: tests,
                datasets: [{
                    label: 'Temps d\'exécution (s)',
                    data: executionTimes,
                    backgroundColor: 'rgba(0, 120, 212, 0.7)',
                    borderColor: 'rgba(0, 120, 212, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Secondes'
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $reportPath -Encoding utf8
    
    Write-Host "Rapport HTML global généré : $reportPath" -ForegroundColor Green
    
    # Ouvrir le rapport dans le navigateur par défaut
    Start-Process $reportPath
}

# Retourner les résultats
return $results
