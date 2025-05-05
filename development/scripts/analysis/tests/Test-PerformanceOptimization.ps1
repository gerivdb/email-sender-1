#Requires -Version 5.1
<#
.SYNOPSIS
    Test de performance pour le systÃƒÂ¨me d'analyse de code.
.DESCRIPTION
    Ce script teste les performances du systÃƒÂ¨me d'analyse de code en comparant
    l'analyse sÃƒÂ©quentielle et l'analyse parallÃƒÂ¨le avec diffÃƒÂ©rents nombres de threads.
.PARAMETER TestDirectory
    RÃƒÂ©pertoire contenant les fichiers ÃƒÂ  analyser pour le test.
.PARAMETER OutputPath
    RÃƒÂ©pertoire oÃƒÂ¹ les rÃƒÂ©sultats des tests seront enregistrÃƒÂ©s.
.PARAMETER NumberOfFiles
    Nombre de fichiers ÃƒÂ  analyser pour le test.
.PARAMETER MaxThreads
    Nombre maximum de threads ÃƒÂ  utiliser pour l'analyse parallÃƒÂ¨le.
.EXAMPLE
    .\Test-PerformanceOptimization.ps1 -TestDirectory ".\development\scripts" -OutputPath ".\results" -NumberOfFiles 100 -MaxThreads 8
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

# CrÃƒÂ©er le rÃƒÂ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath -PathType Container)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# VÃƒÂ©rifier si le rÃƒÂ©pertoire de test existe
if (-not (Test-Path -Path $TestDirectory -PathType Container)) {
    throw "Le rÃƒÂ©pertoire de test '$TestDirectory' n'existe pas."
}

# RÃƒÂ©cupÃƒÂ©rer les fichiers PowerShell dans le rÃƒÂ©pertoire de test
$files = Get-ChildItem -Path $TestDirectory -Include "*.ps1", "*.psm1", "*.psd1" -File -Recurse | Select-Object -First $NumberOfFiles

if ($files.Count -eq 0) {
    throw "Aucun fichier PowerShell trouvÃƒÂ© dans le rÃƒÂ©pertoire de test '$TestDirectory'."
}

Write-Host "Nombre de fichiers ÃƒÂ  analyser: $($files.Count)" -ForegroundColor Yellow

# Chemin du script d'analyse
$scriptPath = Join-Path -Path $PSScriptRoot -Parent -ChildPath "Start-CodeAnalysis.ps1"
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Start-CodeAnalysis.ps1 n'existe pas ÃƒÂ  l'emplacement: $scriptPath"
}

# Fonction pour exÃƒÂ©cuter un test de performance
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
    
    Write-Host "ExÃƒÂ©cution du test '$TestName'..." -ForegroundColor Cyan
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # ExÃƒÂ©cuter le script d'analyse
    & $ScriptPath @params
    
    $stopwatch.Stop()
    $elapsedTime = $stopwatch.Elapsed.TotalSeconds
    
    Write-Host "Test '$TestName' terminÃƒÂ© en $elapsedTime secondes." -ForegroundColor Green
    
    # RÃƒÂ©cupÃƒÂ©rer les rÃƒÂ©sultats
    $results = Get-Content -Path $outputFile -Raw | ConvertFrom-Json
    $resultCount = $results.Count
    
    # CrÃƒÂ©er un objet de rÃƒÂ©sultat
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

# ExÃƒÂ©cuter les tests de performance
$testResults = @()

# Test 1: Analyse sÃƒÂ©quentielle
$testResults += Invoke-PerformanceTest -TestName "Sequential" -ScriptPath $scriptPath -TestDirectory $TestDirectory -OutputPath $OutputPath

# Test 2: Analyse parallÃƒÂ¨le avec 2 threads
$testResults += Invoke-PerformanceTest -TestName "Parallel_2_Threads" -ScriptPath $scriptPath -TestDirectory $TestDirectory -OutputPath $OutputPath -UseParallel -MaxThreads 2

# Test 3: Analyse parallÃƒÂ¨le avec 4 threads
$testResults += Invoke-PerformanceTest -TestName "Parallel_4_Threads" -ScriptPath $scriptPath -TestDirectory $TestDirectory -OutputPath $OutputPath -UseParallel -MaxThreads 4

# Test 4: Analyse parallÃƒÂ¨le avec 8 threads
$testResults += Invoke-PerformanceTest -TestName "Parallel_8_Threads" -ScriptPath $scriptPath -TestDirectory $TestDirectory -OutputPath $OutputPath -UseParallel -MaxThreads 8

# Enregistrer les rÃƒÂ©sultats des tests
$testResultsFile = Join-Path -Path $OutputPath -ChildPath "PerformanceTestResults.json"
$testResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $testResultsFile -Encoding utf8 -Force

# GÃƒÂ©nÃƒÂ©rer un rapport HTML
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
        <li>RÃƒÂ©pertoire de test: $TestDirectory</li>
        <li>Nombre de fichiers: $($files.Count)</li>
        <li>Version PowerShell: $($PSVersionTable.PSVersion)</li>
        <li>Date du test: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</li>
    </ul>
    
    <h2>RÃƒÂ©sultats</h2>
    <table>
        <tr>
            <th>Test</th>
            <th>Temps d'exÃƒÂ©cution (s)</th>
            <th>Nombre de rÃƒÂ©sultats</th>
            <th>ParallÃƒÂ¨le</th>
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
        // DonnÃƒÂ©es pour le graphique
        const testNames = [$(($testResults | ForEach-Object { "'$($_.TestName)'" }) -join ", ")];
        const elapsedTimes = [$(($testResults | ForEach-Object { $_.ElapsedTime.ToString("F2") }) -join ", ")];
        
        // CrÃƒÂ©er le graphique
        const ctx = document.getElementById('performanceChart').getContext('2d');
        const chart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: testNames,
                datasets: [{
                    label: 'Temps d\'exÃƒÂ©cution (s)',
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
                            text: 'Temps d\'exÃƒÂ©cution (s)'
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

# Afficher un rÃƒÂ©sumÃƒÂ© des rÃƒÂ©sultats
Write-Host "`nRÃƒÂ©sumÃƒÂ© des rÃƒÂ©sultats:" -ForegroundColor Cyan
$testResults | Format-Table -Property TestName, ElapsedTime, ResultCount, UseParallel, MaxThreads, PowerShellVersion -AutoSize

Write-Host "`nRapports gÃƒÂ©nÃƒÂ©rÃƒÂ©s:" -ForegroundColor Cyan
Write-Host "  - Rapport JSON: $testResultsFile" -ForegroundColor White
Write-Host "  - Rapport HTML: $htmlReportFile" -ForegroundColor White

# Ouvrir le rapport HTML
Start-Process $htmlReportFile
