#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute des tests de charge distribués sur plusieurs machines.
.DESCRIPTION
    Coordonne l'exécution de tests de charge sur plusieurs machines et agrège les résultats.
.PARAMETER ComputerNames
    Liste des noms d'ordinateurs sur lesquels exécuter les tests.
.PARAMETER Credentials
    Informations d'identification pour se connecter aux ordinateurs distants.
.PARAMETER TestScriptPath
    Chemin local vers le script de test de charge à exécuter sur chaque machine.
.PARAMETER Duration
    Durée des tests en secondes. Par défaut: 30.
.PARAMETER Concurrency
    Nombre d'exécutions concurrentes par machine. Par défaut: 3.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats agrégés. Par défaut: "./distributed-results.json".
.PARAMETER GenerateReport
    Si spécifié, génère un rapport HTML des résultats.
.EXAMPLE
    .\Start-DistributedLoadTest.ps1 -ComputerNames @("Server1", "Server2") -TestScriptPath ".\Simple-PRLoadTest.ps1" -Duration 60
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string[]]$ComputerNames,
    
    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credentials,
    
    [Parameter(Mandatory = $true)]
    [string]$TestScriptPath,
    
    [Parameter(Mandatory = $false)]
    [int]$Duration = 30,
    
    [Parameter(Mandatory = $false)]
    [int]$Concurrency = 3,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./distributed-results.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Fonction pour préparer une machine distante
function Initialize-RemoteMachine {
    param (
        [string]$ComputerName,
        [System.Management.Automation.PSCredential]$Credentials,
        [string]$TestScriptPath
    )
    
    Write-Host "Préparation de la machine $ComputerName..." -ForegroundColor Cyan
    
    # Paramètres pour la session distante
    $sessionParams = @{
        ComputerName = $ComputerName
        ErrorAction = "Stop"
    }
    
    if ($Credentials) {
        $sessionParams.Credential = $Credentials
    }
    
    try {
        # Créer une session distante
        $session = New-PSSession @sessionParams
        
        # Créer un répertoire temporaire sur la machine distante
        $remoteTempDir = Invoke-Command -Session $session -ScriptBlock {
            $tempDir = Join-Path -Path $env:TEMP -ChildPath "DistributedLoadTest_$(Get-Random)"
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
            return $tempDir
        }
        
        # Copier le script de test sur la machine distante
        $remoteScriptPath = Join-Path -Path $remoteTempDir -ChildPath (Split-Path -Path $TestScriptPath -Leaf)
        Copy-Item -Path $TestScriptPath -Destination $remoteScriptPath -ToSession $session
        
        # Vérifier que le script a été copié
        $scriptExists = Invoke-Command -Session $session -ScriptBlock {
            param ($ScriptPath)
            Test-Path -Path $ScriptPath
        } -ArgumentList $remoteScriptPath
        
        if (-not $scriptExists) {
            throw "Échec de la copie du script sur la machine distante."
        }
        
        return @{
            Session = $session
            TempDir = $remoteTempDir
            ScriptPath = $remoteScriptPath
        }
    }
    catch {
        Write-Error "Erreur lors de la préparation de la machine $ComputerName : $_"
        if ($session) {
            Remove-PSSession -Session $session
        }
        return $null
    }
}

# Fonction pour exécuter un test sur une machine distante
function Start-RemoteTest {
    param (
        [System.Management.Automation.Runspaces.PSSession]$Session,
        [string]$ScriptPath,
        [string]$OutputPath,
        [int]$Duration,
        [int]$Concurrency
    )
    
    Write-Host "Démarrage du test sur $($Session.ComputerName)..." -ForegroundColor Cyan
    
    try {
        # Exécuter le script de test sur la machine distante
        $job = Invoke-Command -Session $Session -ScriptBlock {
            param ($ScriptPath, $OutputPath, $Duration, $Concurrency)
            
            # Exécuter le script de test
            & $ScriptPath -Duration $Duration -Concurrency $Concurrency -OutputPath $OutputPath
            
            # Vérifier que les résultats ont été générés
            if (Test-Path -Path $OutputPath) {
                $results = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json
                return @{
                    Success = $true
                    Results = $results
                    OutputPath = $OutputPath
                }
            }
            else {
                return @{
                    Success = $false
                    Error = "Les résultats n'ont pas été générés."
                }
            }
        } -ArgumentList $ScriptPath, $OutputPath, $Duration, $Concurrency -AsJob
        
        return $job
    }
    catch {
        Write-Error "Erreur lors du démarrage du test sur $($Session.ComputerName) : $_"
        return $null
    }
}

# Fonction pour récupérer les résultats d'un test distant
function Get-RemoteTestResults {
    param (
        [System.Management.Automation.Job]$Job,
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    
    try {
        # Attendre que le job se termine
        $result = $Job | Wait-Job | Receive-Job
        
        if ($result.Success) {
            # Récupérer les résultats
            return $result.Results
        }
        else {
            Write-Error "Erreur lors de l'exécution du test sur $($Session.ComputerName) : $($result.Error)"
            return $null
        }
    }
    catch {
        Write-Error "Erreur lors de la récupération des résultats sur $($Session.ComputerName) : $_"
        return $null
    }
}

# Fonction pour nettoyer une machine distante
function Clear-RemoteMachine {
    param (
        [System.Management.Automation.Runspaces.PSSession]$Session,
        [string]$TempDir
    )
    
    try {
        # Supprimer le répertoire temporaire
        Invoke-Command -Session $Session -ScriptBlock {
            param ($TempDir)
            if (Test-Path -Path $TempDir) {
                Remove-Item -Path $TempDir -Recurse -Force
            }
        } -ArgumentList $TempDir
        
        # Fermer la session
        Remove-PSSession -Session $Session
    }
    catch {
        Write-Warning "Erreur lors du nettoyage de la machine $($Session.ComputerName) : $_"
    }
}

# Fonction pour agréger les résultats
function Merge-TestResults {
    param (
        [array]$Results
    )
    
    # Vérifier qu'il y a des résultats à agréger
    if ($Results.Count -eq 0) {
        throw "Aucun résultat à agréger."
    }
    
    # Initialiser les résultats agrégés
    $aggregatedResults = [PSCustomObject]@{
        StartTime = $Results[0].StartTime
        Duration = $Results[0].Duration
        Concurrency = $Results.Count * $Results[0].Concurrency
        TotalRequests = 0
        SuccessCount = 0
        ErrorCount = 0
        AvgResponseMs = 0
        MinResponseMs = [double]::MaxValue
        MaxResponseMs = 0
        P90ResponseMs = 0
        P95ResponseMs = 0
        P99ResponseMs = 0
        RequestsPerSecond = 0
        TotalExecTime = 0
        Machines = @()
    }
    
    # Agréger les métriques
    $totalResponseTime = 0
    $allResponseTimes = @()
    
    foreach ($result in $Results) {
        $aggregatedResults.TotalRequests += $result.TotalRequests
        $aggregatedResults.SuccessCount += $result.SuccessCount
        $aggregatedResults.ErrorCount += $result.ErrorCount
        
        $totalResponseTime += $result.AvgResponseMs * $result.TotalRequests
        
        if ($result.MinResponseMs -lt $aggregatedResults.MinResponseMs) {
            $aggregatedResults.MinResponseMs = $result.MinResponseMs
        }
        
        if ($result.MaxResponseMs -gt $aggregatedResults.MaxResponseMs) {
            $aggregatedResults.MaxResponseMs = $result.MaxResponseMs
        }
        
        # Ajouter les informations de la machine
        $aggregatedResults.Machines += [PSCustomObject]@{
            ComputerName = $result.ComputerName
            TotalRequests = $result.TotalRequests
            AvgResponseMs = $result.AvgResponseMs
            RequestsPerSecond = $result.RequestsPerSecond
        }
    }
    
    # Calculer les moyennes
    if ($aggregatedResults.TotalRequests -gt 0) {
        $aggregatedResults.AvgResponseMs = $totalResponseTime / $aggregatedResults.TotalRequests
    }
    
    # Calculer le débit global
    $totalExecTime = ($Results | Measure-Object -Property TotalExecTime -Maximum).Maximum
    $aggregatedResults.TotalExecTime = $totalExecTime
    $aggregatedResults.RequestsPerSecond = $aggregatedResults.TotalRequests / $totalExecTime
    
    return $aggregatedResults
}

# Fonction pour générer un rapport HTML
function New-DistributedTestReport {
    param (
        [object]$Results,
        [string]$OutputPath
    )
    
    # Préparer les données pour les graphiques
    $machineLabels = $Results.Machines | ForEach-Object { $_.ComputerName }
    $machineRequests = $Results.Machines | ForEach-Object { $_.TotalRequests }
    $machineResponseTimes = $Results.Machines | ForEach-Object { $_.AvgResponseMs }
    $machineRps = $Results.Machines | ForEach-Object { $_.RequestsPerSecond }
    
    $machineRows = ""
    foreach ($machine in $Results.Machines) {
        $machineRows += @"
        <tr>
            <td>$($machine.ComputerName)</td>
            <td>$($machine.TotalRequests)</td>
            <td>$([Math]::Round($machine.AvgResponseMs, 2)) ms</td>
            <td>$([Math]::Round($machine.RequestsPerSecond, 2))</td>
        </tr>
"@
    }
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de test de charge distribué</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid #eee;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .metric-card {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .metric-title {
            font-size: 0.9em;
            color: #6c757d;
            margin-bottom: 5px;
        }
        .metric-value {
            font-size: 1.8em;
            font-weight: bold;
            color: #2c3e50;
        }
        .metric-unit {
            font-size: 0.8em;
            color: #6c757d;
        }
        .chart-container {
            margin-bottom: 30px;
            height: 400px;
        }
        .section {
            margin-bottom: 40px;
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
            background-color: #f5f5f5;
        }
        .footer {
            text-align: center;
            margin-top: 50px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #6c757d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Rapport de test de charge distribué</h1>
        <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <div class="section">
        <h2>Résumé global</h2>
        <div class="summary">
            <div class="metric-card">
                <div class="metric-title">Machines</div>
                <div class="metric-value">$($Results.Machines.Count)</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Concurrence totale</div>
                <div class="metric-value">$($Results.Concurrency)</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Requêtes totales</div>
                <div class="metric-value">$($Results.TotalRequests)</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Requêtes par seconde</div>
                <div class="metric-value">$([Math]::Round($Results.RequestsPerSecond, 2))</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Temps de réponse moyen</div>
                <div class="metric-value">$([Math]::Round($Results.AvgResponseMs, 2))<span class="metric-unit">ms</span></div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Durée du test</div>
                <div class="metric-value">$([Math]::Round($Results.TotalExecTime, 2))<span class="metric-unit">s</span></div>
            </div>
        </div>
    </div>
    
    <div class="section">
        <h2>Performance par machine</h2>
        <div class="chart-container">
            <canvas id="requestsChart"></canvas>
        </div>
        <div class="chart-container">
            <canvas id="responseTimeChart"></canvas>
        </div>
        <div class="chart-container">
            <canvas id="rpsChart"></canvas>
        </div>
    </div>
    
    <div class="section">
        <h2>Détails par machine</h2>
        <table>
            <tr>
                <th>Machine</th>
                <th>Requêtes</th>
                <th>Temps de réponse moyen</th>
                <th>Requêtes par seconde</th>
            </tr>
            $machineRows
        </table>
    </div>
    
    <div class="footer">
        <p>Rapport généré par Start-DistributedLoadTest.ps1</p>
    </div>
    
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Graphique des requêtes par machine
            const requestsCtx = document.getElementById('requestsChart').getContext('2d');
            new Chart(requestsCtx, {
                type: 'bar',
                data: {
                    labels: $($machineLabels | ConvertTo-Json),
                    datasets: [{
                        label: 'Requêtes par machine',
                        data: $($machineRequests | ConvertTo-Json),
                        backgroundColor: 'rgba(54, 162, 235, 0.5)',
                        borderColor: 'rgba(54, 162, 235, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Requêtes par machine'
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Nombre de requêtes'
                            }
                        }
                    }
                }
            });
            
            // Graphique des temps de réponse par machine
            const responseTimeCtx = document.getElementById('responseTimeChart').getContext('2d');
            new Chart(responseTimeCtx, {
                type: 'bar',
                data: {
                    labels: $($machineLabels | ConvertTo-Json),
                    datasets: [{
                        label: 'Temps de réponse moyen par machine',
                        data: $($machineResponseTimes | ConvertTo-Json),
                        backgroundColor: 'rgba(255, 99, 132, 0.5)',
                        borderColor: 'rgba(255, 99, 132, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Temps de réponse moyen par machine'
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Temps (ms)'
                            }
                        }
                    }
                }
            });
            
            // Graphique des RPS par machine
            const rpsCtx = document.getElementById('rpsChart').getContext('2d');
            new Chart(rpsCtx, {
                type: 'bar',
                data: {
                    labels: $($machineLabels | ConvertTo-Json),
                    datasets: [{
                        label: 'Requêtes par seconde par machine',
                        data: $($machineRps | ConvertTo-Json),
                        backgroundColor: 'rgba(75, 192, 192, 0.5)',
                        borderColor: 'rgba(75, 192, 192, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Requêtes par seconde par machine'
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'RPS'
                            }
                        }
                    }
                }
            });
        });
    </script>
</body>
</html>
"@
    
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Rapport HTML généré: $OutputPath" -ForegroundColor Green
}

# Fonction principale
function Main {
    # Vérifier que le script de test existe
    if (-not (Test-Path -Path $TestScriptPath)) {
        Write-Error "Le script de test n'existe pas: $TestScriptPath"
        return
    }
    
    # Vérifier que le répertoire de sortie existe
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        Write-Host "Répertoire de sortie créé: $outputDir" -ForegroundColor Cyan
    }
    
    # Préparer les machines distantes
    $remoteInfo = @{}
    foreach ($computer in $ComputerNames) {
        $info = Initialize-RemoteMachine -ComputerName $computer -Credentials $Credentials -TestScriptPath $TestScriptPath
        if ($info) {
            $remoteInfo[$computer] = $info
        }
    }
    
    if ($remoteInfo.Count -eq 0) {
        Write-Error "Aucune machine distante n'a pu être préparée."
        return
    }
    
    # Démarrer les tests sur chaque machine
    $jobs = @{}
    foreach ($computer in $remoteInfo.Keys) {
        $info = $remoteInfo[$computer]
        $remoteOutputPath = Join-Path -Path $info.TempDir -ChildPath "results_$computer.json"
        $job = Start-RemoteTest -Session $info.Session -ScriptPath $info.ScriptPath -OutputPath $remoteOutputPath -Duration $Duration -Concurrency $Concurrency
        if ($job) {
            $jobs[$computer] = @{
                Job = $job
                Session = $info.Session
                OutputPath = $remoteOutputPath
            }
        }
    }
    
    if ($jobs.Count -eq 0) {
        Write-Error "Aucun test n'a pu être démarré."
        return
    }
    
    # Attendre que tous les tests se terminent
    Write-Host "Attente de la fin des tests sur toutes les machines..." -ForegroundColor Cyan
    $results = @()
    
    foreach ($computer in $jobs.Keys) {
        $jobInfo = $jobs[$computer]
        $result = Get-RemoteTestResults -Job $jobInfo.Job -Session $jobInfo.Session
        
        if ($result) {
            # Ajouter le nom de la machine aux résultats
            $result | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $computer
            $results += $result
        }
    }
    
    # Nettoyer les machines distantes
    foreach ($computer in $remoteInfo.Keys) {
        $info = $remoteInfo[$computer]
        Clear-RemoteMachine -Session $info.Session -TempDir $info.TempDir
    }
    
    if ($results.Count -eq 0) {
        Write-Error "Aucun résultat n'a été récupéré."
        return
    }
    
    # Agréger les résultats
    try {
        $aggregatedResults = Merge-TestResults -Results $results
        
        # Enregistrer les résultats agrégés
        $aggregatedResults | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Host "Résultats agrégés enregistrés: $OutputPath" -ForegroundColor Green
        
        # Générer un rapport HTML si demandé
        if ($GenerateReport) {
            $reportPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
            New-DistributedTestReport -Results $aggregatedResults -OutputPath $reportPath
        }
        
        # Afficher un résumé
        Write-Host "`nRésumé du test distribué:" -ForegroundColor Cyan
        Write-Host "=======================" -ForegroundColor Cyan
        Write-Host "Machines: $($results.Count)"
        Write-Host "Requêtes totales: $($aggregatedResults.TotalRequests)"
        Write-Host "Requêtes par seconde: $([Math]::Round($aggregatedResults.RequestsPerSecond, 2))"
        Write-Host "Temps de réponse moyen: $([Math]::Round($aggregatedResults.AvgResponseMs, 2)) ms"
        
        return $aggregatedResults
    }
    catch {
        Write-Error "Erreur lors de l'agrégation des résultats: $_"
    }
}

# Exécuter le script
Main
