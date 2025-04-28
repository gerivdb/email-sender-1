<#
.SYNOPSIS
    Optimise l'exÃ©cution des tests TestOmnibus avec des algorithmes avancÃ©s.
.DESCRIPTION
    Ce script utilise des algorithmes avancÃ©s pour optimiser l'exÃ©cution des tests,
    en tenant compte de l'historique des exÃ©cutions, des dÃ©pendances entre tests,
    et des ressources systÃ¨me disponibles.
.PARAMETER TestPath
    Chemin vers les tests Ã  exÃ©cuter.
.PARAMETER HistoryPath
    Chemin vers l'historique des exÃ©cutions prÃ©cÃ©dentes.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats de l'optimisation.
.EXAMPLE
    .\Advanced-Optimizer.ps1 -TestPath "D:\Tests" -HistoryPath "D:\TestHistory"
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
    [string]$HistoryPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\History"),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results")
)

# VÃ©rifier les chemins
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

# CrÃ©er les rÃ©pertoires s'ils n'existent pas
if (-not (Test-Path -Path $HistoryPath)) {
    New-Item -Path $HistoryPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour analyser les dÃ©pendances entre tests
function Get-TestDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )
    
    $testFiles = Get-ChildItem -Path $TestPath -Filter "*.Tests.ps1" -Recurse
    $dependencies = @{}
    
    foreach ($file in $testFiles) {
        $content = Get-Content -Path $file.FullName -Raw
        $dependencies[$file.FullName] = @{
            Name = $file.BaseName
            Path = $file.FullName
            Dependencies = @()
        }
        
        # Analyser le contenu pour trouver les dÃ©pendances
        $matches = [regex]::Matches($content, '(?:Describe|Context|It)\s*\(\s*["'']([^"'']+)["'']')
        foreach ($match in $matches) {
            $testName = $match.Groups[1].Value
            $dependencies[$file.FullName].Dependencies += $testName
        }
    }
    
    return $dependencies
}

# Fonction pour analyser l'historique des exÃ©cutions
function Get-ExecutionHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$HistoryPath
    )
    
    $historyFiles = Get-ChildItem -Path $HistoryPath -Filter "results_*.xml" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 10
    $history = @{}
    
    foreach ($file in $historyFiles) {
        try {
            $results = Import-Clixml -Path $file.FullName
            
            foreach ($result in $results) {
                $testName = $result.Name
                
                if (-not $history.ContainsKey($testName)) {
                    $history[$testName] = @{
                        Name = $testName
                        Executions = @()
                        FailureRate = 0
                        AverageDuration = 0
                    }
                }
                
                $history[$testName].Executions += @{
                    Date = $file.LastWriteTime
                    Success = $result.Success
                    Duration = $result.Duration
                }
            }
        }
        catch {
            Write-Warning "Erreur lors du chargement du fichier $($file.FullName): $_"
        }
    }
    
    # Calculer les statistiques
    foreach ($testName in $history.Keys) {
        $executions = $history[$testName].Executions
        $failureCount = ($executions | Where-Object { -not $_.Success } | Measure-Object).Count
        $history[$testName].FailureRate = if ($executions.Count -gt 0) { $failureCount / $executions.Count } else { 0 }
        $history[$testName].AverageDuration = if ($executions.Count -gt 0) { ($executions | Measure-Object -Property Duration -Average).Average } else { 0 }
    }
    
    return $history
}

# Fonction pour optimiser l'ordre d'exÃ©cution des tests
function Get-OptimizedTestOrder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Dependencies,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$History
    )
    
    # CrÃ©er une liste de tests avec leurs scores
    $testScores = @()
    
    foreach ($testPath in $Dependencies.Keys) {
        $testName = $Dependencies[$testPath].Name
        $score = 0
        
        # Facteur 1: Taux d'Ã©chec (les tests qui Ã©chouent souvent sont exÃ©cutÃ©s en premier)
        if ($History.ContainsKey($testName)) {
            $score += $History[$testName].FailureRate * 100
        }
        
        # Facteur 2: DurÃ©e (les tests courts sont exÃ©cutÃ©s en premier)
        if ($History.ContainsKey($testName)) {
            $duration = $History[$testName].AverageDuration
            $score -= [Math]::Log10($duration + 1) * 10
        }
        
        # Facteur 3: Nombre de dÃ©pendances (les tests avec moins de dÃ©pendances sont exÃ©cutÃ©s en premier)
        $score -= $Dependencies[$testPath].Dependencies.Count * 5
        
        $testScores += [PSCustomObject]@{
            Path = $testPath
            Name = $testName
            Score = $score
        }
    }
    
    # Trier les tests par score (dÃ©croissant)
    $sortedTests = $testScores | Sort-Object -Property Score -Descending
    
    return $sortedTests.Path
}

# Fonction pour dÃ©terminer le nombre optimal de threads
function Get-OptimalThreadCount {
    [CmdletBinding()]
    param ()
    
    # Nombre de cÅ“urs logiques
    $logicalCores = [Environment]::ProcessorCount
    
    # Charge CPU actuelle
    $cpuLoad = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue
    
    # MÃ©moire disponible
    $memoryInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $memoryAvailable = $memoryInfo.FreePhysicalMemory / $memoryInfo.TotalVisibleMemorySize
    
    # Calculer le nombre optimal de threads
    $threadFactor = 0.75  # Facteur de base (75% des cÅ“urs)
    
    # Ajuster en fonction de la charge CPU
    if ($cpuLoad -gt 80) {
        $threadFactor *= 0.6  # RÃ©duire si la CPU est trÃ¨s chargÃ©e
    }
    elseif ($cpuLoad -gt 60) {
        $threadFactor *= 0.8  # RÃ©duire lÃ©gÃ¨rement si la CPU est chargÃ©e
    }
    
    # Ajuster en fonction de la mÃ©moire disponible
    if ($memoryAvailable -lt 0.2) {
        $threadFactor *= 0.7  # RÃ©duire si peu de mÃ©moire disponible
    }
    elseif ($memoryAvailable -lt 0.4) {
        $threadFactor *= 0.9  # RÃ©duire lÃ©gÃ¨rement si mÃ©moire limitÃ©e
    }
    
    # Calculer le nombre de threads
    $optimalThreads = [Math]::Max(1, [Math]::Floor($logicalCores * $threadFactor))
    
    return $optimalThreads
}

# Fonction pour gÃ©nÃ©rer une configuration optimisÃ©e
function New-OptimizedConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$OptimizedOrder,
        
        [Parameter(Mandatory = $true)]
        [int]$ThreadCount,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    $config = @{
        MaxThreads = $ThreadCount
        OutputPath = $OutputPath
        GenerateHtmlReport = $true
        CollectPerformanceData = $true
        OptimizedTestOrder = $OptimizedOrder
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    # Enregistrer la configuration
    $configPath = Join-Path -Path $OutputPath -ChildPath "optimized_config.json"
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding utf8 -Force
    
    return $configPath
}

# Point d'entrÃ©e principal
try {
    # Analyser les dÃ©pendances entre tests
    Write-Host "Analyse des dÃ©pendances entre tests..." -ForegroundColor Cyan
    $dependencies = Get-TestDependencies -TestPath $TestPath
    Write-Host "DÃ©pendances analysÃ©es pour $($dependencies.Count) tests" -ForegroundColor Green
    
    # Analyser l'historique des exÃ©cutions
    Write-Host "Analyse de l'historique des exÃ©cutions..." -ForegroundColor Cyan
    $history = Get-ExecutionHistory -HistoryPath $HistoryPath
    Write-Host "Historique analysÃ© pour $($history.Count) tests" -ForegroundColor Green
    
    # Optimiser l'ordre d'exÃ©cution des tests
    Write-Host "Optimisation de l'ordre d'exÃ©cution des tests..." -ForegroundColor Cyan
    $optimizedOrder = Get-OptimizedTestOrder -Dependencies $dependencies -History $history
    Write-Host "Ordre d'exÃ©cution optimisÃ© pour $($optimizedOrder.Count) tests" -ForegroundColor Green
    
    # DÃ©terminer le nombre optimal de threads
    Write-Host "DÃ©termination du nombre optimal de threads..." -ForegroundColor Cyan
    $threadCount = Get-OptimalThreadCount
    Write-Host "Nombre optimal de threads: $threadCount" -ForegroundColor Green
    
    # GÃ©nÃ©rer une configuration optimisÃ©e
    Write-Host "GÃ©nÃ©ration de la configuration optimisÃ©e..." -ForegroundColor Cyan
    $configPath = New-OptimizedConfig -OptimizedOrder $optimizedOrder -ThreadCount $threadCount -OutputPath $OutputPath
    Write-Host "Configuration optimisÃ©e gÃ©nÃ©rÃ©e: $configPath" -ForegroundColor Green
    
    # Retourner la configuration
    return @{
        ConfigPath = $configPath
        ThreadCount = $threadCount
        TestCount = $optimizedOrder.Count
    }
}
catch {
    Write-Error "Erreur lors de l'optimisation: $_"
    return 1
}
