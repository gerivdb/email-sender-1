# Tests de performance pour la création de runspaces en batch vs individuelle
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel -Verbose

    # Fonction pour créer des runspaces individuellement (méthode traditionnelle)
    function New-IndividualRunspaces {
        param(
            [Parameter(Mandatory = $true)]
            [System.Management.Automation.Runspaces.RunspacePool]$RunspacePool,

            [Parameter(Mandatory = $true)]
            [scriptblock]$ScriptBlock,

            [Parameter(Mandatory = $true)]
            [object[]]$InputObjects
        )

        $runspaces = [System.Collections.Generic.List[PSObject]]::new()

        foreach ($item in $InputObjects) {
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $RunspacePool

            # Ajouter le script
            [void]$powershell.AddScript($ScriptBlock.ToString())

            # Ajouter le paramètre
            [void]$powershell.AddParameter('Item', $item)

            # Démarrer l'exécution asynchrone
            $handle = $powershell.BeginInvoke()

            # Ajouter à la liste des runspaces
            $runspaces.Add([PSCustomObject]@{
                    PowerShell = $powershell
                    Handle     = $handle
                    Item       = $item
                    StartTime  = [datetime]::Now
                })
        }

        return $runspaces
    }

    # Fonction pour mesurer les performances
    function Measure-RunspaceCreationPerformance {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Method,

            [Parameter(Mandatory = $true)]
            [int]$ItemCount,

            [Parameter(Mandatory = $false)]
            [int]$BatchSize = 10,

            [Parameter(Mandatory = $false)]
            [int]$Iterations = 3
        )

        $totalTime = 0
        $totalCPU = 0
        $totalMemory = 0

        for ($iter = 1; $iter -le $Iterations; $iter++) {
            # Créer un pool de runspaces
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
            $runspacePool.Open()

            # Préparer les données
            $scriptBlock = { param($Item) Start-Sleep -Milliseconds 10; return "Test $Item" }
            $inputObjects = 1..$ItemCount

            # Mesurer les performances
            $process = Get-Process -Id $PID
            $startCPU = $process.TotalProcessorTime
            $startMemory = $process.WorkingSet64

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Créer les runspaces selon la méthode spécifiée
            $runspaces = if ($Method -eq 'Batch') {
                New-RunspaceBatch -RunspacePool $runspacePool -Scriptblock $scriptBlock -InputObjects $inputObjects -BatchSize $BatchSize
            } else {
                New-IndividualRunspaces -RunspacePool $runspacePool -Scriptblock $scriptBlock -InputObjects $inputObjects
            }

            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds

            # Mesurer l'utilisation CPU et mémoire
            $process = Get-Process -Id $PID
            $endCPU = $process.TotalProcessorTime
            $endMemory = $process.WorkingSet64

            $cpuTime = ($endCPU - $startCPU).TotalMilliseconds
            $memoryUsage = ($endMemory - $startMemory) / 1MB

            # Ajouter aux totaux
            $totalTime += $elapsedMs
            $totalCPU += $cpuTime
            $totalMemory += $memoryUsage

            # Attendre que tous les runspaces soient terminés
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress

            # Nettoyer
            $runspacePool.Close()
            $runspacePool.Dispose()
        }

        # Calculer les moyennes
        $avgTime = $totalTime / $Iterations
        $avgCPU = $totalCPU / $Iterations
        $avgMemory = $totalMemory / $Iterations

        return [PSCustomObject]@{
            Method      = $Method
            ItemCount   = $ItemCount
            BatchSize   = if ($Method -eq 'Batch') { $BatchSize } else { 'N/A' }
            AvgTime     = $avgTime
            AvgCPU      = $avgCPU
            AvgMemory   = $avgMemory
            TimePerItem = $avgTime / $ItemCount
        }
    }
}

AfterAll {
    # Nettoyer le module
    Clear-UnifiedParallel -Verbose
}

Describe "Performance de création de runspaces" {
    Context "Comparaison batch vs individuel avec 100 éléments" {
        BeforeAll {
            # Tester différentes tailles de batch pour trouver l'optimale
            $individualResult = Measure-RunspaceCreationPerformance -Method 'Individual' -ItemCount 100 -Iterations 3
            $batchResult5 = Measure-RunspaceCreationPerformance -Method 'Batch' -ItemCount 100 -BatchSize 5 -Iterations 3
            $batchResult10 = Measure-RunspaceCreationPerformance -Method 'Batch' -ItemCount 100 -BatchSize 10 -Iterations 3
            $batchResult20 = Measure-RunspaceCreationPerformance -Method 'Batch' -ItemCount 100 -BatchSize 20 -Iterations 3

            Write-Host "Résultats de performance pour 100 éléments:" -ForegroundColor Cyan
            Write-Host "Méthode individuelle: $($individualResult.AvgTime) ms, $($individualResult.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Méthode par batch (5): $($batchResult5.AvgTime) ms, $($batchResult5.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Méthode par batch (10): $($batchResult10.AvgTime) ms, $($batchResult10.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Méthode par batch (20): $($batchResult20.AvgTime) ms, $($batchResult20.TimePerItem) ms/item" -ForegroundColor Yellow

            # Trouver la meilleure taille de batch
            $bestBatchResult = @($batchResult5, $batchResult10, $batchResult20) |
                Sort-Object -Property AvgTime |
                Select-Object -First 1

            Write-Host "Meilleure taille de batch: $($bestBatchResult.BatchSize) avec $($bestBatchResult.AvgTime) ms" -ForegroundColor Green
            Write-Host "Amélioration avec la meilleure taille: $([Math]::Round(($individualResult.AvgTime - $bestBatchResult.AvgTime) / $individualResult.AvgTime * 100, 2))%" -ForegroundColor Green

            # Utiliser le meilleur résultat pour les tests
            $script:bestBatchResult = $bestBatchResult
        }

        It "La méthode par batch avec taille optimale devrait être plus rapide que la méthode individuelle" {
            $script:bestBatchResult.AvgTime | Should -BeLessThan $individualResult.AvgTime
        }

        It "Le temps par élément devrait être inférieur avec la méthode par batch optimale" {
            $script:bestBatchResult.TimePerItem | Should -BeLessThan $individualResult.TimePerItem
        }
    }

    Context "Comparaison batch vs individuel avec 500 éléments" {
        BeforeAll {
            # Tester différentes tailles de batch pour trouver l'optimale
            $individualResult = Measure-RunspaceCreationPerformance -Method 'Individual' -ItemCount 500 -Iterations 2
            $batchResult10 = Measure-RunspaceCreationPerformance -Method 'Batch' -ItemCount 500 -BatchSize 10 -Iterations 2
            $batchResult20 = Measure-RunspaceCreationPerformance -Method 'Batch' -ItemCount 500 -BatchSize 20 -Iterations 2
            $batchResult50 = Measure-RunspaceCreationPerformance -Method 'Batch' -ItemCount 500 -BatchSize 50 -Iterations 2
            $batchResult100 = Measure-RunspaceCreationPerformance -Method 'Batch' -ItemCount 500 -BatchSize 100 -Iterations 2

            Write-Host "Résultats de performance pour 500 éléments:" -ForegroundColor Cyan
            Write-Host "Méthode individuelle: $($individualResult.AvgTime) ms, $($individualResult.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Méthode par batch (10): $($batchResult10.AvgTime) ms, $($batchResult10.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Méthode par batch (20): $($batchResult20.AvgTime) ms, $($batchResult20.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Méthode par batch (50): $($batchResult50.AvgTime) ms, $($batchResult50.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Méthode par batch (100): $($batchResult100.AvgTime) ms, $($batchResult100.TimePerItem) ms/item" -ForegroundColor Yellow

            # Trouver la meilleure taille de batch
            $bestBatchResult = @($batchResult10, $batchResult20, $batchResult50, $batchResult100) |
                Sort-Object -Property AvgTime |
                Select-Object -First 1

            Write-Host "Meilleure taille de batch: $($bestBatchResult.BatchSize) avec $($bestBatchResult.AvgTime) ms" -ForegroundColor Green
            Write-Host "Amélioration avec la meilleure taille: $([Math]::Round(($individualResult.AvgTime - $bestBatchResult.AvgTime) / $individualResult.AvgTime * 100, 2))%" -ForegroundColor Green

            # Utiliser le meilleur résultat pour les tests
            $script:bestBatchResult = $bestBatchResult
        }

        It "La méthode par batch avec taille optimale devrait être plus rapide que la méthode individuelle" {
            $script:bestBatchResult.AvgTime | Should -BeLessThan $individualResult.AvgTime
        }

        It "La méthode par batch avec taille optimale devrait utiliser moins de CPU que la méthode individuelle" {
            $script:bestBatchResult.AvgCPU | Should -BeLessThan $individualResult.AvgCPU
        }

        It "Le temps par élément devrait être inférieur avec la méthode par batch optimale" {
            $script:bestBatchResult.TimePerItem | Should -BeLessThan $individualResult.TimePerItem
        }
    }
}
