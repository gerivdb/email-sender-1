<#
.SYNOPSIS
    Optimise l'exécution des tests TestOmnibus avec des algorithmes avancés.
.DESCRIPTION
    Ce script utilise des algorithmes avancés pour optimiser l'exécution des tests,
    en tenant compte de l'historique des exécutions, des dépendances entre tests,
    et des ressources système disponibles.
.PARAMETER TestPath
    Chemin vers les tests à exécuter.
.PARAMETER HistoryPath
    Chemin vers l'historique des exécutions précédentes.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats de l'optimisation.
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

# Vérifier les chemins
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

# Créer les répertoires s'ils n'existent pas
if (-not (Test-Path -Path $HistoryPath)) {
    New-Item -Path $HistoryPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour analyser les dépendances entre tests
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
        
        # Analyser le contenu pour trouver les dépendances
        $matches = [regex]::Matches($content, '(?:Describe|Context|It)\s*\(\s*["'']([^"'']+)["'']')
        foreach ($match in $matches) {
            $testName = $match.Groups[1].Value
            $dependencies[$file.FullName].Dependencies += $testName
        }
    }
    
    return $dependencies
}

# Fonction pour analyser l'historique des exécutions
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

# Fonction pour optimiser l'ordre d'exécution des tests
function Get-OptimizedTestOrder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Dependencies,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$History
    )
    
    # Créer une liste de tests avec leurs scores
    $testScores = @()
    
    foreach ($testPath in $Dependencies.Keys) {
        $testName = $Dependencies[$testPath].Name
        $score = 0
        
        # Facteur 1: Taux d'échec (les tests qui échouent souvent sont exécutés en premier)
        if ($History.ContainsKey($testName)) {
            $score += $History[$testName].FailureRate * 100
        }
        
        # Facteur 2: Durée (les tests courts sont exécutés en premier)
        if ($History.ContainsKey($testName)) {
            $duration = $History[$testName].AverageDuration
            $score -= [Math]::Log10($duration + 1) * 10
        }
        
        # Facteur 3: Nombre de dépendances (les tests avec moins de dépendances sont exécutés en premier)
        $score -= $Dependencies[$testPath].Dependencies.Count * 5
        
        $testScores += [PSCustomObject]@{
            Path = $testPath
            Name = $testName
            Score = $score
        }
    }
    
    # Trier les tests par score (décroissant)
    $sortedTests = $testScores | Sort-Object -Property Score -Descending
    
    return $sortedTests.Path
}

# Fonction pour déterminer le nombre optimal de threads
function Get-OptimalThreadCount {
    [CmdletBinding()]
    param ()
    
    # Nombre de cœurs logiques
    $logicalCores = [Environment]::ProcessorCount
    
    # Charge CPU actuelle
    $cpuLoad = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue
    
    # Mémoire disponible
    $memoryInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $memoryAvailable = $memoryInfo.FreePhysicalMemory / $memoryInfo.TotalVisibleMemorySize
    
    # Calculer le nombre optimal de threads
    $threadFactor = 0.75  # Facteur de base (75% des cœurs)
    
    # Ajuster en fonction de la charge CPU
    if ($cpuLoad -gt 80) {
        $threadFactor *= 0.6  # Réduire si la CPU est très chargée
    }
    elseif ($cpuLoad -gt 60) {
        $threadFactor *= 0.8  # Réduire légèrement si la CPU est chargée
    }
    
    # Ajuster en fonction de la mémoire disponible
    if ($memoryAvailable -lt 0.2) {
        $threadFactor *= 0.7  # Réduire si peu de mémoire disponible
    }
    elseif ($memoryAvailable -lt 0.4) {
        $threadFactor *= 0.9  # Réduire légèrement si mémoire limitée
    }
    
    # Calculer le nombre de threads
    $optimalThreads = [Math]::Max(1, [Math]::Floor($logicalCores * $threadFactor))
    
    return $optimalThreads
}

# Fonction pour générer une configuration optimisée
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

# Point d'entrée principal
try {
    # Analyser les dépendances entre tests
    Write-Host "Analyse des dépendances entre tests..." -ForegroundColor Cyan
    $dependencies = Get-TestDependencies -TestPath $TestPath
    Write-Host "Dépendances analysées pour $($dependencies.Count) tests" -ForegroundColor Green
    
    # Analyser l'historique des exécutions
    Write-Host "Analyse de l'historique des exécutions..." -ForegroundColor Cyan
    $history = Get-ExecutionHistory -HistoryPath $HistoryPath
    Write-Host "Historique analysé pour $($history.Count) tests" -ForegroundColor Green
    
    # Optimiser l'ordre d'exécution des tests
    Write-Host "Optimisation de l'ordre d'exécution des tests..." -ForegroundColor Cyan
    $optimizedOrder = Get-OptimizedTestOrder -Dependencies $dependencies -History $history
    Write-Host "Ordre d'exécution optimisé pour $($optimizedOrder.Count) tests" -ForegroundColor Green
    
    # Déterminer le nombre optimal de threads
    Write-Host "Détermination du nombre optimal de threads..." -ForegroundColor Cyan
    $threadCount = Get-OptimalThreadCount
    Write-Host "Nombre optimal de threads: $threadCount" -ForegroundColor Green
    
    # Générer une configuration optimisée
    Write-Host "Génération de la configuration optimisée..." -ForegroundColor Cyan
    $configPath = New-OptimizedConfig -OptimizedOrder $optimizedOrder -ThreadCount $threadCount -OutputPath $OutputPath
    Write-Host "Configuration optimisée générée: $configPath" -ForegroundColor Green
    
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
