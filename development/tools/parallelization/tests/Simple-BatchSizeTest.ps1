# Test simplifié pour les performances avec différentes tailles de lots
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

# Fonction pour tester une taille de lot spécifique
function Test-BatchSize {
    param(
        [int]$BatchSize,
        [int]$RunspaceCount
    )

    Write-Host "Test avec taille de lot $BatchSize et $RunspaceCount runspaces..." -ForegroundColor Cyan

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

    # Afficher les résultats
    Write-Host "  Temps d'exécution: $elapsedMs ms" -ForegroundColor Green
    Write-Host "  Temps CPU: $([Math]::Round($cpuTime, 2)) ms" -ForegroundColor Green
    Write-Host "  Utilisation mémoire: $([Math]::Round($memoryUsage, 2)) MB" -ForegroundColor Green
    Write-Host "  Temps de réponse moyen: $([Math]::Round($responseTime, 2)) ms/runspace" -ForegroundColor Green
    Write-Host "  Runspaces complétés: $($completedRunspaces.Count) sur $RunspaceCount" -ForegroundColor Green

    # Nettoyer
    $pool.Close()
    $pool.Dispose()

    return [PSCustomObject]@{
        BatchSize = $BatchSize
        RunspaceCount = $RunspaceCount
        Time = $elapsedMs
        CPU = $cpuTime
        Memory = $memoryUsage
        ResponseTime = $responseTime
        CompletedCount = $completedRunspaces.Count
    }
}

# Exécuter les tests
Write-Host "Test simplifié pour les performances avec différentes tailles de lots" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Yellow

# Tester avec 50 runspaces
Write-Host "`nTests avec 50 runspaces:" -ForegroundColor Green
$results50 = @()
$results50 += Test-BatchSize -BatchSize 5 -RunspaceCount 50
$results50 += Test-BatchSize -BatchSize 10 -RunspaceCount 50
$results50 += Test-BatchSize -BatchSize 20 -RunspaceCount 50
$results50 += Test-BatchSize -BatchSize 50 -RunspaceCount 50

# Tester avec 100 runspaces
Write-Host "`nTests avec 100 runspaces:" -ForegroundColor Green
$results100 = @()
$results100 += Test-BatchSize -BatchSize 5 -RunspaceCount 100
$results100 += Test-BatchSize -BatchSize 10 -RunspaceCount 100
$results100 += Test-BatchSize -BatchSize 20 -RunspaceCount 100
$results100 += Test-BatchSize -BatchSize 50 -RunspaceCount 100

# Afficher le résumé des résultats
Write-Host "`nRésumé des tests de performance:" -ForegroundColor Yellow

# Créer un tableau pour les résultats avec 50 runspaces
Write-Host "`nRésultats pour 50 runspaces:" -ForegroundColor Green
$summary50 = $results50 | ForEach-Object {
    [PSCustomObject]@{
        BatchSize = $_.BatchSize
        "Temps (ms)" = $_.Time
        "CPU (ms)" = [Math]::Round($_.CPU, 2)
        "Mémoire (MB)" = [Math]::Round($_.Memory, 2)
        "Temps de réponse (ms/runspace)" = [Math]::Round($_.ResponseTime, 2)
    }
}
$summary50 | Format-Table -AutoSize

# Créer un tableau pour les résultats avec 100 runspaces
Write-Host "`nRésultats pour 100 runspaces:" -ForegroundColor Green
$summary100 = $results100 | ForEach-Object {
    [PSCustomObject]@{
        BatchSize = $_.BatchSize
        "Temps (ms)" = $_.Time
        "CPU (ms)" = [Math]::Round($_.CPU, 2)
        "Mémoire (MB)" = [Math]::Round($_.Memory, 2)
        "Temps de réponse (ms/runspace)" = [Math]::Round($_.ResponseTime, 2)
    }
}
$summary100 | Format-Table -AutoSize

# Identifier la taille de lot optimale pour chaque nombre de runspaces
$optimal50 = $results50 | Sort-Object Time | Select-Object -First 1
$optimal100 = $results100 | Sort-Object Time | Select-Object -First 1

Write-Host "`nTaille de lot optimale:" -ForegroundColor Yellow
Write-Host "  Pour 50 runspaces: $($optimal50.BatchSize) (Temps: $($optimal50.Time) ms)" -ForegroundColor Green
Write-Host "  Pour 100 runspaces: $($optimal100.BatchSize) (Temps: $($optimal100.Time) ms)" -ForegroundColor Green

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "`nTests terminés." -ForegroundColor Green
