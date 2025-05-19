# Tests Pester pour les performances avec différentes tailles de lots
# Ce script utilise Pester pour vérifier que les performances s'améliorent avec la taille de lot optimale

BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel -Verbose

    # Fonction pour créer des runspaces de test
    function New-TestRunspaces {
        param(
            [int]$Count = 50,
            [int[]]$DelaysMilliseconds = @(10, 20, 30, 40, 50)
        )

        # Créer un pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 8, $sessionState, $Host)
        $runspacePool.Open()

        # Créer une liste pour stocker les runspaces
        $runspaces = [System.Collections.Generic.List[object]]::new($Count)

        # Créer les runspaces avec des délais différents
        for ($i = 0; $i -lt $Count; $i++) {
            $delay = $DelaysMilliseconds[$i % $DelaysMilliseconds.Length]
            
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter un script simple avec délai variable
            [void]$powershell.AddScript({
                    param($Item, $DelayMilliseconds)
                    Start-Sleep -Milliseconds $DelayMilliseconds
                    return [PSCustomObject]@{
                        Item = $Item
                        Delay = $DelayMilliseconds
                        ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                        StartTime = Get-Date
                    }
                })

            # Ajouter les paramètres
            [void]$powershell.AddParameter('Item', $i)
            [void]$powershell.AddParameter('DelayMilliseconds', $delay)

            # Démarrer l'exécution asynchrone
            $handle = $powershell.BeginInvoke()

            # Ajouter à la liste des runspaces
            $runspaces.Add([PSCustomObject]@{
                    PowerShell = $powershell
                    Handle     = $handle
                    Item       = $i
                    Delay      = $delay
                    StartTime  = [datetime]::Now
                })
        }

        return @{
            Runspaces = $runspaces
            Pool = $runspacePool
        }
    }

    # Fonction pour mesurer les performances avec une taille de lot spécifique
    function Measure-BatchSizePerformance {
        param(
            [int]$BatchSize,
            [int]$RunspaceCount,
            [int]$Iterations = 2
        )

        $totalTime = 0
        $totalCPU = 0
        $totalMemory = 0
        $totalResponseTime = 0
        $successCount = 0

        for ($iter = 1; $iter -le $Iterations; $iter++) {
            # Créer des runspaces de test
            $testData = New-TestRunspaces -Count $RunspaceCount
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool

            # Mesurer le temps d'exécution et l'utilisation CPU
            $process = Get-Process -Id $PID
            $startCPU = $process.TotalProcessorTime
            $startMemory = $process.WorkingSet64

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Modifier la variable globale de taille de lot
            $script:BatchSizeOverride = $BatchSize

            # Exécuter Wait-ForCompletedRunspace avec la taille de lot spécifiée
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 60 -Verbose

            # Réinitialiser la variable globale
            $script:BatchSizeOverride = $null

            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds

            # Mesurer l'utilisation CPU et mémoire
            $process = Get-Process -Id $PID
            $endCPU = $process.TotalProcessorTime
            $endMemory = $process.WorkingSet64

            $cpuTime = ($endCPU - $startCPU).TotalMilliseconds
            $memoryUsage = ($endMemory - $startMemory) / 1MB

            # Calculer le temps de réponse moyen (temps d'exécution / nombre de runspaces)
            $responseTime = $elapsedMs / $RunspaceCount

            # Vérifier que tous les runspaces ont été traités
            $success = $completedRunspaces.Count -eq $RunspaceCount

            # Ajouter aux totaux
            $totalTime += $elapsedMs
            $totalCPU += $cpuTime
            $totalMemory += $memoryUsage
            $totalResponseTime += $responseTime
            if ($success) { $successCount++ }

            # Nettoyer
            $pool.Close()
            $pool.Dispose()
        }

        # Calculer les moyennes
        $avgTime = $totalTime / $Iterations
        $avgCPU = $totalCPU / $Iterations
        $avgMemory = $totalMemory / $Iterations
        $avgResponseTime = $totalResponseTime / $Iterations
        $reliability = $successCount / $Iterations

        return [PSCustomObject]@{
            BatchSize = $BatchSize
            RunspaceCount = $RunspaceCount
            AvgTime = $avgTime
            AvgCPU = $avgCPU
            AvgMemory = $avgMemory
            AvgResponseTime = $avgResponseTime
            Reliability = $reliability
        }
    }
}

AfterAll {
    # Nettoyer le module
    Clear-UnifiedParallel -Verbose
}

Describe "Performance avec différentes tailles de lots" {
    Context "Avec 50 runspaces" {
        BeforeAll {
            $batchSize5 = Measure-BatchSizePerformance -BatchSize 5 -RunspaceCount 50 -Iterations 2
            $batchSize10 = Measure-BatchSizePerformance -BatchSize 10 -RunspaceCount 50 -Iterations 2
            $batchSize20 = Measure-BatchSizePerformance -BatchSize 20 -RunspaceCount 50 -Iterations 2
            $batchSize50 = Measure-BatchSizePerformance -BatchSize 50 -RunspaceCount 50 -Iterations 2
            
            $results = @($batchSize5, $batchSize10, $batchSize20, $batchSize50)
            $fastestBatchSize = ($results | Sort-Object AvgTime | Select-Object -First 1).BatchSize
        }

        It "Toutes les tailles de lot devraient traiter tous les runspaces correctement" {
            $batchSize5.Reliability | Should -Be 1.0
            $batchSize10.Reliability | Should -Be 1.0
            $batchSize20.Reliability | Should -Be 1.0
            $batchSize50.Reliability | Should -Be 1.0
        }

        It "La taille de lot optimale devrait être identifiée" {
            $fastestBatchSize | Should -BeIn @(5, 10, 20, 50)
        }

        It "Les temps d'exécution devraient être cohérents" {
            $batchSize5.AvgTime | Should -BeGreaterThan 0
            $batchSize10.AvgTime | Should -BeGreaterThan 0
            $batchSize20.AvgTime | Should -BeGreaterThan 0
            $batchSize50.AvgTime | Should -BeGreaterThan 0
        }
    }

    Context "Avec 100 runspaces" {
        BeforeAll {
            $batchSize5 = Measure-BatchSizePerformance -BatchSize 5 -RunspaceCount 100 -Iterations 2
            $batchSize10 = Measure-BatchSizePerformance -BatchSize 10 -RunspaceCount 100 -Iterations 2
            $batchSize20 = Measure-BatchSizePerformance -BatchSize 20 -RunspaceCount 100 -Iterations 2
            $batchSize50 = Measure-BatchSizePerformance -BatchSize 50 -RunspaceCount 100 -Iterations 2
            
            $results = @($batchSize5, $batchSize10, $batchSize20, $batchSize50)
            $fastestBatchSize = ($results | Sort-Object AvgTime | Select-Object -First 1).BatchSize
        }

        It "Toutes les tailles de lot devraient traiter tous les runspaces correctement" {
            $batchSize5.Reliability | Should -Be 1.0
            $batchSize10.Reliability | Should -Be 1.0
            $batchSize20.Reliability | Should -Be 1.0
            $batchSize50.Reliability | Should -Be 1.0
        }

        It "La taille de lot optimale devrait être identifiée" {
            $fastestBatchSize | Should -BeIn @(5, 10, 20, 50)
        }

        It "Les temps d'exécution devraient être cohérents" {
            $batchSize5.AvgTime | Should -BeGreaterThan 0
            $batchSize10.AvgTime | Should -BeGreaterThan 0
            $batchSize20.AvgTime | Should -BeGreaterThan 0
            $batchSize50.AvgTime | Should -BeGreaterThan 0
        }
    }
}
