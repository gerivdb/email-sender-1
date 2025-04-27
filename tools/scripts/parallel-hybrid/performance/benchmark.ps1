#Requires -Version 5.1
<#
.SYNOPSIS
    Script de benchmark pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    Ce script mesure les performances de l'architecture hybride PowerShell-Python
    en exÃ©cutant diffÃ©rents scÃ©narios de test.
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
    [int]$Iterations = 3,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Importer les modules nÃ©cessaires
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ParallelHybrid.psm1"
Import-Module $modulePath -Force

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour mesurer les performances d'une opÃ©ration
function Measure-Operation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )
    
    Write-Host "`n=== Test de performance : $Name ===" -ForegroundColor Cyan
    
    $results = @()
    
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Host "  ItÃ©ration $i/$Iterations..." -ForegroundColor Yellow
        
        # Nettoyer la mÃ©moire avant chaque test
        [System.GC]::Collect()
        
        # Mesurer l'utilisation de la mÃ©moire avant
        $memoryBefore = [System.GC]::GetTotalMemory($true)
        
        # Mesurer le temps d'exÃ©cution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            # ExÃ©cuter l'opÃ©ration
            $result = & $ScriptBlock @Parameters
            $success = $true
        }
        catch {
            Write-Error "Erreur lors de l'exÃ©cution du test '$Name' : $_"
            $success = $false
            $result = $null
        }
        
        $stopwatch.Stop()
        $executionTime = $stopwatch.Elapsed.TotalSeconds
        
        # Mesurer l'utilisation de la mÃ©moire aprÃ¨s
        $memoryAfter = [System.GC]::GetTotalMemory($true)
        $memoryUsage = ($memoryAfter - $memoryBefore) / 1MB
        
        # Enregistrer les rÃ©sultats
        $results += [PSCustomObject]@{
            Iteration = $i
            ExecutionTime = $executionTime
            MemoryUsageMB = $memoryUsage
            Success = $success
            Result = $result
        }
        
        Write-Host "    Temps d'exÃ©cution : $executionTime secondes" -ForegroundColor Yellow
        Write-Host "    Utilisation mÃ©moire : $memoryUsage MB" -ForegroundColor Yellow
        Write-Host "    SuccÃ¨s : $success" -ForegroundColor ($success ? "Green" : "Red")
    }
    
    # Calculer les statistiques
    $avgTime = ($results | Measure-Object -Property ExecutionTime -Average).Average
    $minTime = ($results | Measure-Object -Property ExecutionTime -Minimum).Minimum
    $maxTime = ($results | Measure-Object -Property ExecutionTime -Maximum).Maximum
    $avgMemory = ($results | Measure-Object -Property MemoryUsageMB -Average).Average
    $successRate = ($results | Where-Object { $_.Success } | Measure-Object).Count / $Iterations * 100
    
    Write-Host "`n  RÃ©sultats pour '$Name' :" -ForegroundColor Cyan
    Write-Host "    Temps moyen : $avgTime secondes" -ForegroundColor Green
    Write-Host "    Temps min/max : $minTime / $maxTime secondes" -ForegroundColor Green
    Write-Host "    MÃ©moire moyenne : $avgMemory MB" -ForegroundColor Green
    Write-Host "    Taux de succÃ¨s : $successRate%" -ForegroundColor Green
    
    return [PSCustomObject]@{
        Name = $Name
        AverageTime = $avgTime
        MinTime = $minTime
        MaxTime = $maxTime
        AverageMemoryMB = $avgMemory
        SuccessRate = $successRate
        DetailedResults = $results
    }
}

# Fonction pour gÃ©nÃ©rer des fichiers de test
function New-TestFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [int]$SmallFiles = 50,
        
        [Parameter(Mandatory = $false)]
        [int]$MediumFiles = 20,
        
        [Parameter(Mandatory = $false)]
        [int]$LargeFiles = 5
    )
    
    $testFilesPath = Join-Path -Path $OutputPath -ChildPath "test_files"
    
    if (-not (Test-Path -Path $testFilesPath)) {
        New-Item -Path $testFilesPath -ItemType Directory -Force | Out-Null
    }
    
    # ModÃ¨les de contenu
    $smallTemplate = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Petit script de test.
.DESCRIPTION
    Ce script est utilisÃ© pour les tests de performance.
#>

# Fonction simple
function Test-Function {
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$InputString
    )
    
    Write-Output `$InputString
}

# Appel de la fonction
Test-Function -InputString "Hello, World!"
"@
    
    $mediumTemplate = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test de taille moyenne.
.DESCRIPTION
    Ce script est utilisÃ© pour les tests de performance.
    Il contient plusieurs fonctions et structures de contrÃ´le.
.NOTES
    Version: 1.0
    Auteur: Test
    Date: 2025-04-10
#>

# Variables
`$maxItems = 10
`$processingEnabled = `$true

# Fonction avec gestion d'erreurs
function Process-Items {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [int]`$Count,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$Force
    )
    
    try {
        # Boucle for
        for (`$i = 1; `$i -le `$Count; `$i++) {
            # Structure conditionnelle
            if (`$i % 2 -eq 0) {
                Write-Output "Item `$i est pair"
            }
            else {
                Write-Output "Item `$i est impair"
            }
            
            # Structure switch
            switch (`$i % 3) {
                0 { Write-Verbose "Divisible par 3" }
                1 { Write-Verbose "Reste 1" }
                2 { Write-Verbose "Reste 2" }
            }
        }
    }
    catch {
        Write-Error "Une erreur s'est produite : `$_"
    }
}

# Fonction avec boucle foreach
function Get-ItemsReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [string[]]`$Items
    )
    
    `$results = @()
    
    # Boucle foreach
    foreach (`$item in `$Items) {
        `$results += @{
            Name = `$item
            Length = `$item.Length
            UpperCase = `$item.ToUpper()
        }
    }
    
    return `$results
}

# Appel des fonctions
if (`$processingEnabled) {
    Process-Items -Count `$maxItems
    Get-ItemsReport -Items @("Apple", "Banana", "Cherry")
}
"@
    
    $largeTemplate = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Grand script de test.
.DESCRIPTION
    Ce script est utilisÃ© pour les tests de performance.
    Il contient de nombreuses fonctions, classes et structures de contrÃ´le.
.NOTES
    Version: 1.0
    Auteur: Test
    Date: 2025-04-10
#>

# DÃ©finition de classe
class TestItem {
    [string]`$Name
    [int]`$Value
    [datetime]`$CreatedDate
    
    TestItem([string]`$name, [int]`$value) {
        `$this.Name = `$name
        `$this.Value = `$value
        `$this.CreatedDate = Get-Date
    }
    
    [string] ToString() {
        return "`$(`$this.Name) (`$(`$this.Value)) - `$(`$this.CreatedDate.ToString('yyyy-MM-dd'))"
    }
    
    [bool] IsValid() {
        return -not [string]::IsNullOrEmpty(`$this.Name) -and `$this.Value -gt 0
    }
}

# Fonctions d'aide
function New-TestItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$Name,
        
        [Parameter(Mandatory = `$false)]
        [int]`$Value = 1
    )
    
    return [TestItem]::new(`$Name, `$Value)
}

function Test-ItemValidity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [TestItem]`$Item
    )
    
    return `$Item.IsValid()
}

function Get-ItemsStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [TestItem[]]`$Items
    )
    
    `$validItems = `$Items | Where-Object { `$_.IsValid() }
    `$totalValue = (`$validItems | Measure-Object -Property Value -Sum).Sum
    `$averageValue = (`$validItems | Measure-Object -Property Value -Average).Average
    
    return @{
        TotalItems = `$Items.Count
        ValidItems = `$validItems.Count
        TotalValue = `$totalValue
        AverageValue = `$averageValue
    }
}

# Fonction principale
function Start-ItemsProcessing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [int]`$Count,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$IncludeInvalid
    )
    
    try {
        Write-Verbose "DÃ©marrage du traitement de `$Count Ã©lÃ©ments..."
        
        `$items = @()
        
        # CrÃ©ation des Ã©lÃ©ments
        for (`$i = 1; `$i -le `$Count; `$i++) {
            `$name = "Item_`$i"
            `$value = Get-Random -Minimum (`$IncludeInvalid ? -10 : 1) -Maximum 100
            
            `$item = New-TestItem -Name `$name -Value `$value
            `$items += `$item
            
            Write-Verbose "Ã‰lÃ©ment crÃ©Ã© : `$item"
        }
        
        # Validation des Ã©lÃ©ments
        `$validItems = @()
        `$invalidItems = @()
        
        foreach (`$item in `$items) {
            if (Test-ItemValidity -Item `$item) {
                `$validItems += `$item
            }
            else {
                `$invalidItems += `$item
            }
        }
        
        # Statistiques
        `$statistics = Get-ItemsStatistics -Items `$items
        
        # RÃ©sultats
        return @{
            Items = `$items
            ValidItems = `$validItems
            InvalidItems = `$invalidItems
            Statistics = `$statistics
        }
    }
    catch {
        Write-Error "Erreur lors du traitement des Ã©lÃ©ments : `$_"
        return `$null
    }
}

# ExÃ©cution du traitement
`$result = Start-ItemsProcessing -Count 50 -IncludeInvalid
Write-Output "Traitement terminÃ© avec `$(`$result.ValidItems.Count) Ã©lÃ©ments valides sur `$(`$result.Items.Count) au total."
Write-Output "Valeur totale : `$(`$result.Statistics.TotalValue)"
Write-Output "Valeur moyenne : `$(`$result.Statistics.AverageValue)"

# Traitement supplÃ©mentaire
`$categories = @("A", "B", "C")
`$itemsByCategory = @{}

foreach (`$category in `$categories) {
    `$itemsInCategory = `$result.ValidItems | Where-Object { `$_.Value % `$categories.Count -eq `$categories.IndexOf(`$category) }
    `$itemsByCategory[`$category] = `$itemsInCategory
    
    Write-Output "CatÃ©gorie `$category : `$(`$itemsInCategory.Count) Ã©lÃ©ments"
}

# Exportation des rÃ©sultats (simulation)
Write-Output "Exportation des rÃ©sultats..."
Start-Sleep -Seconds 1
Write-Output "Exportation terminÃ©e."
"@
    
    # CrÃ©er les fichiers de test
    Write-Host "CrÃ©ation des fichiers de test..." -ForegroundColor Yellow
    
    # Petits fichiers
    for ($i = 1; $i -le $SmallFiles; $i++) {
        $filePath = Join-Path -Path $testFilesPath -ChildPath "small_$i.ps1"
        $smallTemplate | Out-File -FilePath $filePath -Encoding utf8
    }
    
    # Fichiers moyens
    for ($i = 1; $i -le $MediumFiles; $i++) {
        $filePath = Join-Path -Path $testFilesPath -ChildPath "medium_$i.ps1"
        $mediumTemplate | Out-File -FilePath $filePath -Encoding utf8
    }
    
    # Grands fichiers
    for ($i = 1; $i -le $LargeFiles; $i++) {
        $filePath = Join-Path -Path $testFilesPath -ChildPath "large_$i.ps1"
        $largeTemplate | Out-File -FilePath $filePath -Encoding utf8
    }
    
    Write-Host "CrÃ©ation des fichiers de test terminÃ©e." -ForegroundColor Green
    Write-Host "  Petits fichiers : $SmallFiles" -ForegroundColor Green
    Write-Host "  Fichiers moyens : $MediumFiles" -ForegroundColor Green
    Write-Host "  Grands fichiers : $LargeFiles" -ForegroundColor Green
    
    return $testFilesPath
}

# CrÃ©er les fichiers de test
$testFilesPath = New-TestFiles -OutputPath $OutputPath

# DÃ©finir les scÃ©narios de test
$testScenarios = @(
    @{
        Name = "Analyse de scripts (sÃ©quentiel)"
        ScriptBlock = {
            param($TestFilesPath, $OutputPath)
            
            $analyzerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "examples\script-analyzer-simple.ps1"
            $result = & $analyzerPath -ScriptsPath $TestFilesPath -OutputPath $OutputPath -Sequential
            
            return $result
        }
        Parameters = @{
            TestFilesPath = $testFilesPath
            OutputPath = (Join-Path -Path $OutputPath -ChildPath "sequential")
        }
    },
    @{
        Name = "Analyse de scripts (parallÃ¨le)"
        ScriptBlock = {
            param($TestFilesPath, $OutputPath)
            
            $analyzerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "examples\script-analyzer-simple.ps1"
            $result = & $analyzerPath -ScriptsPath $TestFilesPath -OutputPath $OutputPath
            
            return $result
        }
        Parameters = @{
            TestFilesPath = $testFilesPath
            OutputPath = (Join-Path -Path $OutputPath -ChildPath "parallel")
        }
    },
    @{
        Name = "Analyse de scripts (parallÃ¨le avec cache)"
        ScriptBlock = {
            param($TestFilesPath, $OutputPath)
            
            $analyzerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "examples\script-analyzer-simple.ps1"
            $result = & $analyzerPath -ScriptsPath $TestFilesPath -OutputPath $OutputPath -UseCache
            
            return $result
        }
        Parameters = @{
            TestFilesPath = $testFilesPath
            OutputPath = (Join-Path -Path $OutputPath -ChildPath "parallel_cache")
        }
    }
)

# ExÃ©cuter les tests de performance
$benchmarkResults = @()

foreach ($scenario in $testScenarios) {
    $result = Measure-Operation `
        -Name $scenario.Name `
        -ScriptBlock $scenario.ScriptBlock `
        -Iterations $Iterations `
        -Parameters $scenario.Parameters
    
    $benchmarkResults += $result
}

# Enregistrer les rÃ©sultats
$resultsPath = Join-Path -Path $OutputPath -ChildPath "benchmark_results.json"
$benchmarkResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsPath -Encoding utf8

Write-Host "`nRÃ©sultats du benchmark enregistrÃ©s : $resultsPath" -ForegroundColor Green

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateReport) {
    $reportPath = Join-Path -Path $OutputPath -ChildPath "benchmark_report.html"
    
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de benchmark</title>
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
        .chart-container {
            width: 100%;
            height: 400px;
            margin-bottom: 20px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport de benchmark</h1>
    <p>Date de gÃ©nÃ©ration : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Nombre de scÃ©narios testÃ©s : $($benchmarkResults.Count)</p>
        <p>Nombre d'itÃ©rations par scÃ©nario : $Iterations</p>
    </div>
    
    <h2>RÃ©sultats par scÃ©nario</h2>
    <table>
        <thead>
            <tr>
                <th>ScÃ©nario</th>
                <th>Temps moyen (s)</th>
                <th>Temps min (s)</th>
                <th>Temps max (s)</th>
                <th>MÃ©moire moyenne (MB)</th>
                <th>Taux de succÃ¨s (%)</th>
            </tr>
        </thead>
        <tbody>
"@
    
    foreach ($result in $benchmarkResults) {
        $htmlContent += @"
            <tr>
                <td>$($result.Name)</td>
                <td>$([Math]::Round($result.AverageTime, 2))</td>
                <td>$([Math]::Round($result.MinTime, 2))</td>
                <td>$([Math]::Round($result.MaxTime, 2))</td>
                <td>$([Math]::Round($result.AverageMemoryMB, 2))</td>
                <td>$([Math]::Round($result.SuccessRate, 2))</td>
            </tr>
"@
    }
    
    $htmlContent += @"
        </tbody>
    </table>
    
    <h2>Graphiques</h2>
    
    <h3>Temps d'exÃ©cution moyen</h3>
    <div class="chart-container">
        <canvas id="timeChart"></canvas>
    </div>
    
    <h3>Utilisation mÃ©moire moyenne</h3>
    <div class="chart-container">
        <canvas id="memoryChart"></canvas>
    </div>
    
    <script>
        // DonnÃ©es pour les graphiques
        const scenarios = [$(($benchmarkResults | ForEach-Object { "'$($_.Name)'" }) -join ', ')];
        const avgTimes = [$(($benchmarkResults | ForEach-Object { [Math]::Round($_.AverageTime, 2) }) -join ', ')];
        const avgMemory = [$(($benchmarkResults | ForEach-Object { [Math]::Round($_.AverageMemoryMB, 2) }) -join ', ')];
        
        // Graphique des temps d'exÃ©cution
        const timeCtx = document.getElementById('timeChart').getContext('2d');
        new Chart(timeCtx, {
            type: 'bar',
            data: {
                labels: scenarios,
                datasets: [{
                    label: 'Temps d\'exÃ©cution moyen (s)',
                    data: avgTimes,
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
        
        // Graphique de l'utilisation mÃ©moire
        const memoryCtx = document.getElementById('memoryChart').getContext('2d');
        new Chart(memoryCtx, {
            type: 'bar',
            data: {
                labels: scenarios,
                datasets: [{
                    label: 'Utilisation mÃ©moire moyenne (MB)',
                    data: avgMemory,
                    backgroundColor: 'rgba(0, 183, 74, 0.7)',
                    borderColor: 'rgba(0, 183, 74, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'MB'
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
    
    Write-Host "Rapport HTML gÃ©nÃ©rÃ© : $reportPath" -ForegroundColor Green
    
    # Ouvrir le rapport dans le navigateur par dÃ©faut
    Start-Process $reportPath
}

# Retourner les rÃ©sultats
return $benchmarkResults
