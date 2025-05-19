# Test de performance pour différentes tailles de lots dans Wait-ForCompletedRunspace
# Ce script mesure les performances de Wait-ForCompletedRunspace avec différentes tailles de lots

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
        [int]$Iterations = 3
    )

    $results = @{
        BatchSize = $BatchSize
        RunspaceCount = $RunspaceCount
        TotalTime = 0
        CPUTime = 0
        MemoryUsage = 0
        ResponseTimes = @()
        Iterations = $Iterations
    }

    for ($iter = 1; $iter -le $Iterations; $iter++) {
        Write-Host "Itération $iter/$Iterations avec taille de lot $BatchSize et $RunspaceCount runspaces..." -ForegroundColor Gray

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

        # Ajouter aux résultats
        $results.TotalTime += $elapsedMs
        $results.CPUTime += $cpuTime
        $results.MemoryUsage += $memoryUsage
        $results.ResponseTimes += $responseTime

        # Afficher les résultats de l'itération
        Write-Host "  Temps d'exécution: $elapsedMs ms" -ForegroundColor Cyan
        Write-Host "  Temps CPU: $([Math]::Round($cpuTime, 2)) ms" -ForegroundColor Cyan
        Write-Host "  Utilisation mémoire: $([Math]::Round($memoryUsage, 2)) MB" -ForegroundColor Cyan
        Write-Host "  Temps de réponse moyen: $([Math]::Round($responseTime, 2)) ms/runspace" -ForegroundColor Cyan

        # Nettoyer
        $pool.Close()
        $pool.Dispose()
    }

    # Calculer les moyennes
    $results.TotalTime = $results.TotalTime / $Iterations
    $results.CPUTime = $results.CPUTime / $Iterations
    $results.MemoryUsage = $results.MemoryUsage / $Iterations
    $results.AvgResponseTime = ($results.ResponseTimes | Measure-Object -Average).Average

    return [PSCustomObject]$results
}

# Fonction pour exécuter les tests de performance
function Test-BatchSizePerformance {
    param(
        [int[]]$BatchSizes = @(5, 10, 20, 50),
        [int[]]$RunspaceCounts = @(50, 100),
        [int]$Iterations = 3
    )

    $results = @()

    foreach ($runspaceCount in $RunspaceCounts) {
        Write-Host "`nTests avec $runspaceCount runspaces:" -ForegroundColor Green

        foreach ($batchSize in $BatchSizes) {
            Write-Host "`nTest avec taille de lot $batchSize:" -ForegroundColor Yellow
            $batchResults = Measure-BatchSizePerformance -BatchSize $batchSize -RunspaceCount $runspaceCount -Iterations $Iterations
            $results += $batchResults

            # Afficher les résultats
            Write-Host "Résultats pour taille de lot $batchSize avec $runspaceCount runspaces:" -ForegroundColor Green
            Write-Host "  Temps d'exécution moyen: $([Math]::Round($batchResults.TotalTime, 2)) ms" -ForegroundColor Cyan
            Write-Host "  Temps CPU moyen: $([Math]::Round($batchResults.CPUTime, 2)) ms" -ForegroundColor Cyan
            Write-Host "  Utilisation mémoire moyenne: $([Math]::Round($batchResults.MemoryUsage, 2)) MB" -ForegroundColor Cyan
            Write-Host "  Temps de réponse moyen: $([Math]::Round($batchResults.AvgResponseTime, 2)) ms/runspace" -ForegroundColor Cyan
        }
    }

    return $results
}

# Exécuter les tests de performance
Write-Host "Test de performance pour différentes tailles de lots dans Wait-ForCompletedRunspace" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Yellow

# Exécuter les tests
$results = Test-BatchSizePerformance -BatchSizes @(5, 10, 20, 50) -RunspaceCounts @(50, 100) -Iterations 3

# Afficher le résumé des résultats
Write-Host "`nRésumé des tests de performance:" -ForegroundColor Yellow

# Créer un tableau pour les résultats avec 50 runspaces
$results50 = $results | Where-Object { $_.RunspaceCount -eq 50 }
Write-Host "`nRésultats pour 50 runspaces:" -ForegroundColor Green
$summary50 = $results50 | ForEach-Object {
    [PSCustomObject]@{
        BatchSize = $_.BatchSize
        "Temps (ms)" = [Math]::Round($_.TotalTime, 2)
        "CPU (ms)" = [Math]::Round($_.CPUTime, 2)
        "Mémoire (MB)" = [Math]::Round($_.MemoryUsage, 2)
        "Temps de réponse (ms/runspace)" = [Math]::Round($_.AvgResponseTime, 2)
    }
}
$summary50 | Format-Table -AutoSize

# Créer un tableau pour les résultats avec 100 runspaces
$results100 = $results | Where-Object { $_.RunspaceCount -eq 100 }
Write-Host "`nRésultats pour 100 runspaces:" -ForegroundColor Green
$summary100 = $results100 | ForEach-Object {
    [PSCustomObject]@{
        BatchSize = $_.BatchSize
        "Temps (ms)" = [Math]::Round($_.TotalTime, 2)
        "CPU (ms)" = [Math]::Round($_.CPUTime, 2)
        "Mémoire (MB)" = [Math]::Round($_.MemoryUsage, 2)
        "Temps de réponse (ms/runspace)" = [Math]::Round($_.AvgResponseTime, 2)
    }
}
$summary100 | Format-Table -AutoSize

# Identifier la taille de lot optimale pour chaque nombre de runspaces
$optimal50 = $results50 | Sort-Object TotalTime | Select-Object -First 1
$optimal100 = $results100 | Sort-Object TotalTime | Select-Object -First 1

Write-Host "`nTaille de lot optimale:" -ForegroundColor Yellow
Write-Host "  Pour 50 runspaces: $($optimal50.BatchSize) (Temps: $([Math]::Round($optimal50.TotalTime, 2)) ms)" -ForegroundColor Green
Write-Host "  Pour 100 runspaces: $($optimal100.BatchSize) (Temps: $([Math]::Round($optimal100.TotalTime, 2)) ms)" -ForegroundColor Green

# Sauvegarder les résultats dans un fichier CSV
$csvPath = Join-Path -Path $PSScriptRoot -ChildPath "BatchSize-Performance-Results.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "`nRésultats sauvegardés dans $csvPath" -ForegroundColor Green

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "`nTests terminés." -ForegroundColor Green
