#Requires -Version 5.1
<#
.SYNOPSIS
    Test de performance pour le système d'analyse de code.
.DESCRIPTION
    Ce script teste les performances du système d'analyse de code en comparant
    l'analyse séquentielle et l'analyse parallèle avec différents nombres de threads.
.PARAMETER TestDirectory
    Répertoire contenant les fichiers à analyser pour le test.
.PARAMETER OutputPath
    Répertoire où les résultats des tests seront enregistrés.
.PARAMETER NumberOfFiles
    Nombre de fichiers à analyser pour le test.
.PARAMETER MaxThreads
    Nombre maximum de threads à utiliser pour l'analyse parallèle.
.EXAMPLE
    .\Test-PerformanceOptimization.ps1 -TestDirectory ".\scripts" -OutputPath ".\results" -NumberOfFiles 100 -MaxThreads 8
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TestDirectory,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\results",
    
    [Parameter(Mandatory = $false)]
    [int]$NumberOfFiles = 100,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxThreads = 8
)

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath -PathType Container)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Vérifier si le répertoire de test existe
if (-not (Test-Path -Path $TestDirectory -PathType Container)) {
    throw "Le répertoire de test '$TestDirectory' n'existe pas."
}

# Récupérer les fichiers PowerShell dans le répertoire de test
$files = Get-ChildItem -Path $TestDirectory -Include "*.ps1", "*.psm1", "*.psd1" -File -Recurse | Select-Object -First $NumberOfFiles

if ($files.Count -eq 0) {
    throw "Aucun fichier PowerShell trouvé dans le répertoire de test '$TestDirectory'."
}

Write-Host "Nombre de fichiers à analyser: $($files.Count)" -ForegroundColor Yellow

# Chemin du script d'analyse
$scriptPath = Join-Path -Path $PSScriptRoot -Parent -ChildPath "Start-CodeAnalysis.ps1"
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Start-CodeAnalysis.ps1 n'existe pas à l'emplacement: $scriptPath"
}

# Fonction pour exécuter un test de performance
function Invoke-PerformanceTest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [string]$TestDirectory,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseParallel,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 4
    )
    
    $outputFile = Join-Path -Path $OutputPath -ChildPath "$TestName.json"
    $htmlFile = Join-Path -Path $OutputPath -ChildPath "$TestName.html"
    
    $params = @{
        Path = $TestDirectory
        Tools = @("PSScriptAnalyzer", "TodoAnalyzer")
        OutputPath = $outputFile
        GenerateHtmlReport = $true
        Recurse = $true
    }
    
    if ($UseParallel) {
        $params.Add("UseParallel", $true)
        $params.Add("MaxThreads", $MaxThreads)
    }
    
    Write-Host "Exécution du test '$TestName'..." -ForegroundColor Cyan
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Exécuter le script d'analyse
    & $ScriptPath @params
    
    $stopwatch.Stop()
    $elapsedTime = $stopwatch.Elapsed.TotalSeconds
    
    Write-Host "Test '$TestName' terminé en $elapsedTime secondes." -ForegroundColor Green
    
    # Récupérer les résultats
    $results = Get-Content -Path $outputFile -Raw | ConvertFrom-Json
    $resultCount = $results.Count
    
    # Créer un objet de résultat
    $testResult = [PSCustomObject]@{
        TestName = $TestName
        ElapsedTime = $elapsedTime
        ResultCount = $resultCount
        UseParallel = $UseParallel
        MaxThreads = $MaxThreads
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    }
    
    return $testResult
}

# Exécuter les tests de performance
$testResults = @()

# Test 1: Analyse séquentielle
$testResults += Invoke-PerformanceTest -TestName "Sequential" -ScriptPath $scriptPath -TestDirectory $TestDirectory -OutputPath $OutputPath

# Test 2: Analyse parallèle avec 2 threads
$testResults += Invoke-PerformanceTest -TestName "Parallel_2_Threads" -ScriptPath $scriptPath -TestDirectory $TestDirectory -OutputPath $OutputPath -UseParallel -MaxThreads 2

# Test 3: Analyse parallèle avec 4 threads
$testResults += Invoke-PerformanceTest -TestName "Parallel_4_Threads" -ScriptPath $scriptPath -TestDirectory $TestDirectory -OutputPath $OutputPath -UseParallel -MaxThreads 4

# Test 4: Analyse parallèle avec 8 threads
$testResults += Invoke-PerformanceTest -TestName "Parallel_8_Threads" -ScriptPath $scriptPath -TestDirectory $TestDirectory -OutputPath $OutputPath -UseParallel -MaxThreads 8

# Enregistrer les résultats des tests
$testResultsFile = Join-Path -Path $OutputPath -ChildPath "PerformanceTestResults.json"
$testResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $testResultsFile -Encoding utf8 -Force

# Générer un rapport HTML
$htmlReportFile = Join-Path -Path $OutputPath -ChildPath "PerformanceTestResults.html"

$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de test de performance</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        h1 {
            color: #333;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-top: 20px;
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
        .chart-container {
            width: 100%;
            height: 400px;
            margin-top: 20px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport de test de performance</h1>
    
    <h2>Configuration du test</h2>
    <ul>
        <li>Répertoire de test: $TestDirectory</li>
        <li>Nombre de fichiers: $($files.Count)</li>
        <li>Version PowerShell: $($PSVersionTable.PSVersion)</li>
        <li>Date du test: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</li>
    </ul>
    
    <h2>Résultats</h2>
    <table>
        <tr>
            <th>Test</th>
            <th>Temps d'exécution (s)</th>
            <th>Nombre de résultats</th>
            <th>Parallèle</th>
            <th>Threads</th>
            <th>Version PowerShell</th>
        </tr>
"@

foreach ($result in $testResults) {
    $htmlReport += @"
        <tr>
            <td>$($result.TestName)</td>
            <td>$($result.ElapsedTime.ToString("F2"))</td>
            <td>$($result.ResultCount)</td>
            <td>$($result.UseParallel)</td>
            <td>$($result.MaxThreads)</td>
            <td>$($result.PowerShellVersion)</td>
        </tr>
"@
}

$htmlReport += @"
    </table>
    
    <h2>Graphique</h2>
    <div class="chart-container">
        <canvas id="performanceChart"></canvas>
    </div>
    
    <script>
        // Données pour le graphique
        const testNames = [$(($testResults | ForEach-Object { "'$($_.TestName)'" }) -join ", ")];
        const elapsedTimes = [$(($testResults | ForEach-Object { $_.ElapsedTime.ToString("F2") }) -join ", ")];
        
        // Créer le graphique
        const ctx = document.getElementById('performanceChart').getContext('2d');
        const chart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: testNames,
                datasets: [{
                    label: 'Temps d\'exécution (s)',
                    data: elapsedTimes,
                    backgroundColor: 'rgba(54, 162, 235, 0.5)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Temps d\'exécution (s)'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Test'
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@

$htmlReport | Out-File -FilePath $htmlReportFile -Encoding utf8 -Force

# Afficher un résumé des résultats
Write-Host "`nRésumé des résultats:" -ForegroundColor Cyan
$testResults | Format-Table -Property TestName, ElapsedTime, ResultCount, UseParallel, MaxThreads, PowerShellVersion -AutoSize

Write-Host "`nRapports générés:" -ForegroundColor Cyan
Write-Host "  - Rapport JSON: $testResultsFile" -ForegroundColor White
Write-Host "  - Rapport HTML: $htmlReportFile" -ForegroundColor White

# Ouvrir le rapport HTML
Start-Process $htmlReportFile
