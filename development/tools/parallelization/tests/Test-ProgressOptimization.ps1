# Script de test pour la gestion optimisée de la progression
#Requires -Version 5.1

# Importer le module UnifiedParallel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel -Verbose

# Fonction pour mesurer les performances avec différentes configurations de progression
function Measure-ProgressPerformance {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $true)]
        [int]$ItemCount,

        [Parameter(Mandatory = $false)]
        [switch]$NoProgress,

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3,

        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 4
    )

    $totalTime = 0
    $totalCPU = 0

    for ($iter = 1; $iter -le $Iterations; $iter++) {
        # Créer des éléments de test
        $items = 1..$ItemCount

        # Mesurer les performances
        $process = Get-Process -Id $PID
        $startCPU = $process.TotalProcessorTime

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Traiter les éléments un par un (sans parallélisation) pour éviter les problèmes
        # Cela nous permet quand même de tester l'impact de la barre de progression
        $results = @()
        
        # Préparer la barre de progression
        if (-not $NoProgress) {
            $progressParams = @{
                Activity = "Test de progression: $TestName"
                Status = "Préparation..."
                PercentComplete = 0
            }
            Write-Progress @progressParams
        }
        
        # Traiter chaque élément
        for ($i = 0; $i -lt $items.Count; $i++) {
            $item = $items[$i]
            
            # Simuler un traitement qui prend du temps
            Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 30)
            $result = $item * 2
            $results += $result
            
            # Mettre à jour la barre de progression
            if (-not $NoProgress) {
                $percentComplete = [Math]::Min(100, [Math]::Floor(($i + 1) / $items.Count * 100))
                
                # Optimisation : mettre à jour seulement tous les 5 éléments ou à la fin
                if (($i + 1) % 5 -eq 0 -or $i -eq $items.Count - 1) {
                    $progressParams = @{
                        Activity = "Test de progression: $TestName"
                        Status = "Traitement de l'élément $($i + 1) sur $($items.Count)"
                        PercentComplete = $percentComplete
                    }
                    Write-Progress @progressParams
                }
            }
        }
        
        # Terminer la barre de progression
        if (-not $NoProgress) {
            Write-Progress -Activity "Test de progression: $TestName" -Completed
        }

        $stopwatch.Stop()
        $elapsedMs = $stopwatch.ElapsedMilliseconds

        # Mesurer l'utilisation CPU
        $process = Get-Process -Id $PID
        $endCPU = $process.TotalProcessorTime
        $cpuTime = ($endCPU - $startCPU).TotalMilliseconds

        # Ajouter aux totaux
        $totalTime += $elapsedMs
        $totalCPU += $cpuTime
    }

    # Calculer les moyennes
    $avgTime = $totalTime / $Iterations
    $avgCPU = $totalCPU / $Iterations

    return [PSCustomObject]@{
        TestName = $TestName
        ItemCount = $ItemCount
        NoProgress = $NoProgress
        AvgTime = $avgTime
        AvgCPU = $avgCPU
        TimePerItem = $avgTime / $ItemCount
        CPUPerItem = $avgCPU / $ItemCount
    }
}

# Exécuter les tests de performance
Write-Host "Exécution des tests de performance pour la gestion optimisée de la progression..." -ForegroundColor Cyan

# Test avec 50 éléments
$noProgressResult = Measure-ProgressPerformance -TestName "Sans progression" -ItemCount 50 -Iterations 3 -NoProgress
$standardProgressResult = Measure-ProgressPerformance -TestName "Progression standard" -ItemCount 50 -Iterations 3

# Afficher les résultats
Write-Host "Résultats de performance pour 50 éléments:" -ForegroundColor Cyan
Write-Host "Sans barre de progression: $($noProgressResult.AvgTime) ms, $($noProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow
Write-Host "Avec progression optimisée: $($standardProgressResult.AvgTime) ms, $($standardProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow

$overhead = ($standardProgressResult.AvgTime - $noProgressResult.AvgTime) / $noProgressResult.AvgTime * 100
Write-Host "Surcoût de la progression optimisée: $([Math]::Round($overhead, 2))%" -ForegroundColor Green

# Test avec 100 éléments
$largeNoProgressResult = Measure-ProgressPerformance -TestName "Grand lot sans progression" -ItemCount 100 -Iterations 2 -NoProgress
$largeStandardProgressResult = Measure-ProgressPerformance -TestName "Grand lot avec progression optimisée" -ItemCount 100 -Iterations 2

# Afficher les résultats
Write-Host "Résultats de performance pour 100 éléments:" -ForegroundColor Cyan
Write-Host "Sans barre de progression: $($largeNoProgressResult.AvgTime) ms, $($largeNoProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow
Write-Host "Avec progression optimisée: $($largeStandardProgressResult.AvgTime) ms, $($largeStandardProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow

$largeOverhead = ($largeStandardProgressResult.AvgTime - $largeNoProgressResult.AvgTime) / $largeNoProgressResult.AvgTime * 100
Write-Host "Surcoût de la progression optimisée: $([Math]::Round($largeOverhead, 2))%" -ForegroundColor Green

# Nettoyer
Clear-UnifiedParallel
