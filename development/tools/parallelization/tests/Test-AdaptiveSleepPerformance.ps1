# Test de performance pour la fonction Wait-ForCompletedRunspace avec délai adaptatif
# Ce script compare les performances de l'implémentation avec délai adaptatif

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force -Verbose

# Initialiser le module
Initialize-UnifiedParallel -Verbose

# Fonction utilitaire pour créer des runspaces de test avec délais variés
function New-TestRunspacesWithVariableDelays {
    param(
        [int]$Count = 5,
        [int[]]$DelaysMilliseconds = @(100, 200, 300, 400, 500)
    )

    # Créer un pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
    $runspacePool.Open()

    # Créer une liste pour stocker les runspaces
    $runspaces = [System.Collections.Generic.List[object]]::new()

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

# Fonction pour mesurer les performances
function Measure-WaitForCompletedRunspacePerformance {
    param(
        [int]$RunspaceCount = 20,
        [int[]]$DelaysMilliseconds = @(10, 20, 30, 40, 50, 100, 150, 200),
        [int]$Iterations = 5,
        [int]$SleepMilliseconds = 50
    )

    $results = @{
        TotalTime = 0
        CPUUsage = 0
        MemoryUsage = 0
        Iterations = $Iterations
    }

    for ($iter = 1; $iter -le $Iterations; $iter++) {
        Write-Host "Itération $iter/$Iterations..." -ForegroundColor Gray

        # Créer des runspaces de test
        $testData = New-TestRunspacesWithVariableDelays -Count $RunspaceCount -DelaysMilliseconds $DelaysMilliseconds
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Mesurer le temps d'exécution et l'utilisation CPU
        $process = Get-Process -Id $PID
        $startCPU = $process.TotalProcessorTime
        $startMemory = $process.WorkingSet64

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Attendre que tous les runspaces soient complétés
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 30 -SleepMilliseconds $SleepMilliseconds -Verbose

        $stopwatch.Stop()
        $elapsedMs = $stopwatch.ElapsedMilliseconds

        # Mesurer l'utilisation CPU et mémoire
        $process = Get-Process -Id $PID
        $endCPU = $process.TotalProcessorTime
        $endMemory = $process.WorkingSet64

        $cpuTime = ($endCPU - $startCPU).TotalMilliseconds
        $memoryUsage = ($endMemory - $startMemory) / 1MB

        # Ajouter aux résultats
        $results.TotalTime += $elapsedMs
        $results.CPUUsage += $cpuTime
        $results.MemoryUsage += $memoryUsage

        # Afficher les résultats de l'itération
        Write-Host "  Temps d'exécution: $elapsedMs ms" -ForegroundColor Cyan
        Write-Host "  Temps CPU: $([Math]::Round($cpuTime, 2)) ms" -ForegroundColor Cyan
        Write-Host "  Utilisation mémoire: $([Math]::Round($memoryUsage, 2)) MB" -ForegroundColor Cyan

        # Nettoyer
        $pool.Close()
        $pool.Dispose()
    }

    # Calculer les moyennes
    $results.TotalTime = $results.TotalTime / $Iterations
    $results.CPUUsage = $results.CPUUsage / $Iterations
    $results.MemoryUsage = $results.MemoryUsage / $Iterations

    return [PSCustomObject]$results
}

# Exécuter les tests de performance
Write-Host "Test de performance pour Wait-ForCompletedRunspace avec délai adaptatif" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Yellow

# Test avec différentes tailles de données
$runspaceCounts = @(10, 20, 50)
$results = @()

foreach ($count in $runspaceCounts) {
    Write-Host "`nTest avec $count runspaces:" -ForegroundColor Green
    
    # Test avec délai fixe (50ms)
    Write-Host "Délai fixe (50ms):" -ForegroundColor White
    $fixedResult = Measure-WaitForCompletedRunspacePerformance -RunspaceCount $count -SleepMilliseconds 50
    
    $results += [PSCustomObject]@{
        RunspaceCount = $count
        SleepType = "Fixe (50ms)"
        AvgTime = $fixedResult.TotalTime
        AvgCPU = $fixedResult.CPUUsage
        AvgMemory = $fixedResult.MemoryUsage
    }
}

# Afficher les résultats
Write-Host "`nRésultats des tests de performance:" -ForegroundColor Green
$results | Format-Table -Property RunspaceCount, SleepType, AvgTime, AvgCPU, AvgMemory -AutoSize

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "`nTests terminés." -ForegroundColor Green
