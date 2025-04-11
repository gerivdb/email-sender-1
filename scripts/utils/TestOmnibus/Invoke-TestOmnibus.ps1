<#
.SYNOPSIS
    Version simplifiée de TestOmnibus pour tester l'intégration.
.DESCRIPTION
    Ce script est une version simplifiée de TestOmnibus qui permet de tester
    l'intégration avec le Système d'Optimisation Proactive.
.PARAMETER Path
    Chemin vers les tests à exécuter.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration.
.EXAMPLE
    .\Invoke-TestOmnibus.ps1 -Path "C:\Tests"
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-11
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath
)

# Charger la configuration
$config = @{
    MaxThreads = 4
    OutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results"
    GenerateHtmlReport = $true
    CollectPerformanceData = $true
}

if ($ConfigPath -and (Test-Path -Path $ConfigPath)) {
    try {
        $configFromFile = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        
        if ($configFromFile.MaxThreads) {
            $config.MaxThreads = $configFromFile.MaxThreads
        }
        
        if ($configFromFile.OutputPath) {
            $config.OutputPath = $configFromFile.OutputPath
        }
        
        if ($null -ne $configFromFile.GenerateHtmlReport) {
            $config.GenerateHtmlReport = $configFromFile.GenerateHtmlReport
        }
        
        if ($null -ne $configFromFile.CollectPerformanceData) {
            $config.CollectPerformanceData = $configFromFile.CollectPerformanceData
        }
        
        if ($configFromFile.PriorityScripts) {
            $config.PriorityScripts = $configFromFile.PriorityScripts
        }
    }
    catch {
        Write-Warning "Erreur lors du chargement de la configuration: $_"
    }
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $config.OutputPath)) {
    New-Item -Path $config.OutputPath -ItemType Directory -Force | Out-Null
}

# Rechercher les tests
$testFiles = Get-ChildItem -Path $Path -Filter "*.Tests.ps1" -Recurse

if ($testFiles.Count -eq 0) {
    Write-Warning "Aucun fichier de test trouvé dans: $Path"
    return
}

Write-Host "Exécution de $($testFiles.Count) tests avec $($config.MaxThreads) threads..." -ForegroundColor Cyan

# Préparer les résultats
$results = @()

# Exécuter les tests
foreach ($testFile in $testFiles) {
    Write-Host "Exécution du test: $($testFile.Name)" -ForegroundColor Yellow
    
    $startTime = Get-Date
    $success = $true
    $errorMessage = ""
    
    try {
        # Simuler l'exécution du test
        if ($testFile.Name -match "Failing") {
            # Simuler un échec
            $success = $false
            $errorMessage = "Test échoué"
            Write-Host "  - Échec" -ForegroundColor Red
        }
        elseif ($testFile.Name -match "Slow") {
            # Simuler un test lent
            Start-Sleep -Seconds 2
            Write-Host "  - Succès (lent)" -ForegroundColor Green
        }
        else {
            # Simuler un succès
            Start-Sleep -Milliseconds 100
            Write-Host "  - Succès" -ForegroundColor Green
        }
    }
    catch {
        $success = $false
        $errorMessage = $_.Exception.Message
        Write-Host "  - Erreur: $errorMessage" -ForegroundColor Red
    }
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    # Ajouter le résultat
    $result = [PSCustomObject]@{
        Name = $testFile.Name -replace "\.Tests\.ps1", ""
        Path = $testFile.FullName
        Success = $success
        ErrorMessage = $errorMessage
        Duration = $duration
        StartTime = $startTime
        EndTime = $endTime
    }
    
    $results += $result
}

# Générer un rapport XML
$resultsPath = Join-Path -Path $config.OutputPath -ChildPath "results.xml"
$results | Export-Clixml -Path $resultsPath -Force

Write-Host "Résultats des tests sauvegardés: $resultsPath" -ForegroundColor Green

# Générer un rapport HTML si demandé
if ($config.GenerateHtmlReport) {
    $reportPath = Join-Path -Path $config.OutputPath -ChildPath "report.html"
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Tests</title>
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
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de Tests</h1>
        <p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss")</p>
        
        <h2>Résumé</h2>
        <p>
            <strong>Tests exécutés:</strong> $($results.Count)<br>
            <strong>Tests réussis:</strong> $($results | Where-Object { $_.Success } | Measure-Object).Count<br>
            <strong>Tests échoués:</strong> $($results | Where-Object { -not $_.Success } | Measure-Object).Count<br>
            <strong>Durée totale:</strong> $([math]::Round(($results | Measure-Object -Property Duration -Sum).Sum, 2)) ms<br>
            <strong>Threads utilisés:</strong> $($config.MaxThreads)
        </p>
        
        <h2>Résultats détaillés</h2>
        <table>
            <tr>
                <th>Test</th>
                <th>Résultat</th>
                <th>Durée (ms)</th>
                <th>Détails</th>
            </tr>
"@
    
    foreach ($result in $results) {
        $statusClass = if ($result.Success) { "success" } else { "failure" }
        $statusText = if ($result.Success) { "Succès" } else { "Échec" }
        
        if ($result.Success -and $result.Duration -gt 1000) {
            $statusClass = "slow"
            $statusText = "Succès (lent)"
        }
        
        $html += @"
            <tr>
                <td>$($result.Name)</td>
                <td class="$statusClass">$statusText</td>
                <td>$([math]::Round($result.Duration, 2))</td>
                <td>$($result.ErrorMessage)</td>
            </tr>
"@
    }
    
    $html += @"
        </table>
        
        <div class="footer">
            <p>Généré par TestOmnibus</p>
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $reportPath -Encoding utf8 -Force
    
    Write-Host "Rapport HTML généré: $reportPath" -ForegroundColor Green
}

# Afficher un résumé
$successCount = ($results | Where-Object { $_.Success } | Measure-Object).Count
$failureCount = ($results | Where-Object { -not $_.Success } | Measure-Object).Count
$totalDuration = ($results | Measure-Object -Property Duration -Sum).Sum

Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  - Tests exécutés: $($results.Count)" -ForegroundColor White
Write-Host "  - Tests réussis: $successCount" -ForegroundColor Green
Write-Host "  - Tests échoués: $failureCount" -ForegroundColor Red
Write-Host "  - Durée totale: $([math]::Round($totalDuration, 2)) ms" -ForegroundColor White
Write-Host "  - Threads utilisés: $($config.MaxThreads)" -ForegroundColor White

# Retourner les résultats
return $results
