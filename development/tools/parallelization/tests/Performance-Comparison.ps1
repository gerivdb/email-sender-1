# Test de performance comparatif entre l'implémentation originale et optimisée de Wait-ForCompletedRunspace
# Ce script mesure et compare les performances des deux implémentations

# Importer le module UnifiedParallel pour l'implémentation optimisée
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Importer l'implémentation originale
$originalImplementationPath = Join-Path -Path $PSScriptRoot -ChildPath "Original-WaitForCompletedRunspace.ps1"
. $originalImplementationPath

# Initialiser le module
Initialize-UnifiedParallel -Verbose

# Fonction pour créer des runspaces de test
function New-TestRunspaces {
    param(
        [int]$Count = 10,
        [int[]]$DelaysMilliseconds = @(50, 100, 150, 200, 250)
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

# Fonction pour mesurer les performances
function Measure-Performance {
    param(
        [string]$Implementation,
        [int]$RunspaceCount,
        [int]$Iterations = 3
    )

    $results = @{
        Implementation = $Implementation
        RunspaceCount = $RunspaceCount
        TotalTime = 0
        CPUTime = 0
        MemoryUsage = 0
        Iterations = $Iterations
    }

    for ($iter = 1; $iter -le $Iterations; $iter++) {
        Write-Host "[$Implementation] Itération $iter/$Iterations avec $RunspaceCount runspaces..." -ForegroundColor Gray

        # Créer des runspaces de test
        $testData = New-TestRunspaces -Count $RunspaceCount
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Mesurer le temps d'exécution et l'utilisation CPU
        $process = Get-Process -Id $PID
        $startCPU = $process.TotalProcessorTime
        $startMemory = $process.WorkingSet64

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Exécuter l'implémentation appropriée
        if ($Implementation -eq "Original") {
            $completedRunspaces = Wait-ForCompletedRunspaceOriginal -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 60 -SleepMilliseconds 50
        }
        else {
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 60 -SleepMilliseconds 50
        }

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
        $results.CPUTime += $cpuTime
        $results.MemoryUsage += $memoryUsage

        # Afficher les résultats de l'itération
        Write-Host "  Temps d'exécution: $elapsedMs ms" -ForegroundColor $(if ($Implementation -eq "Original") { "Yellow" } else { "Cyan" })
        Write-Host "  Temps CPU: $([Math]::Round($cpuTime, 2)) ms" -ForegroundColor $(if ($Implementation -eq "Original") { "Yellow" } else { "Cyan" })
        Write-Host "  Utilisation mémoire: $([Math]::Round($memoryUsage, 2)) MB" -ForegroundColor $(if ($Implementation -eq "Original") { "Yellow" } else { "Cyan" })

        # Nettoyer
        $pool.Close()
        $pool.Dispose()
    }

    # Calculer les moyennes
    $results.TotalTime = $results.TotalTime / $Iterations
    $results.CPUTime = $results.CPUTime / $Iterations
    $results.MemoryUsage = $results.MemoryUsage / $Iterations

    return [PSCustomObject]$results
}

# Fonction pour comparer les performances
function Compare-Implementations {
    param(
        [int]$RunspaceCount,
        [int]$Iterations = 3
    )

    # Mesurer les performances de l'implémentation originale
    $originalResults = Measure-Performance -Implementation "Original" -RunspaceCount $RunspaceCount -Iterations $Iterations

    # Mesurer les performances de l'implémentation optimisée
    $optimizedResults = Measure-Performance -Implementation "Optimized" -RunspaceCount $RunspaceCount -Iterations $Iterations

    # Calculer les améliorations
    $timeImprovement = (($originalResults.TotalTime - $optimizedResults.TotalTime) / $originalResults.TotalTime) * 100
    $cpuImprovement = (($originalResults.CPUTime - $optimizedResults.CPUTime) / $originalResults.CPUTime) * 100
    $memoryImprovement = (($originalResults.MemoryUsage - $optimizedResults.MemoryUsage) / $originalResults.MemoryUsage) * 100

    # Créer un objet de résultats
    $comparisonResults = [PSCustomObject]@{
        RunspaceCount = $RunspaceCount
        Original = $originalResults
        Optimized = $optimizedResults
        TimeImprovement = $timeImprovement
        CPUImprovement = $cpuImprovement
        MemoryImprovement = $memoryImprovement
    }

    return $comparisonResults
}

# Exécuter les tests de performance
Write-Host "Test de performance comparatif entre l'implémentation originale et optimisée" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Yellow

# Tester avec différentes charges
$runspaceCounts = @(10, 50, 100)
$results = @()

foreach ($count in $runspaceCounts) {
    Write-Host "`nTest avec $count runspaces:" -ForegroundColor Green
    $comparisonResults = Compare-Implementations -RunspaceCount $count -Iterations 3
    $results += $comparisonResults

    # Afficher les résultats de la comparaison
    Write-Host "`nRésultats pour $count runspaces:" -ForegroundColor Green
    Write-Host "  Original  - Temps: $([Math]::Round($comparisonResults.Original.TotalTime, 2)) ms, CPU: $([Math]::Round($comparisonResults.Original.CPUTime, 2)) ms, Mémoire: $([Math]::Round($comparisonResults.Original.MemoryUsage, 2)) MB" -ForegroundColor Yellow
    Write-Host "  Optimisé  - Temps: $([Math]::Round($comparisonResults.Optimized.TotalTime, 2)) ms, CPU: $([Math]::Round($comparisonResults.Optimized.CPUTime, 2)) ms, Mémoire: $([Math]::Round($comparisonResults.Optimized.MemoryUsage, 2)) MB" -ForegroundColor Cyan
    Write-Host "  Amélioration - Temps: $([Math]::Round($comparisonResults.TimeImprovement, 2))%, CPU: $([Math]::Round($comparisonResults.CPUImprovement, 2))%, Mémoire: $([Math]::Round($comparisonResults.MemoryImprovement, 2))%" -ForegroundColor $(if ($comparisonResults.TimeImprovement -gt 0) { "Green" } else { "Red" })
}

# Afficher le résumé des résultats
Write-Host "`nRésumé des tests de performance:" -ForegroundColor Yellow
$summaryTable = $results | ForEach-Object {
    [PSCustomObject]@{
        RunspaceCount = $_.RunspaceCount
        "Original (ms)" = [Math]::Round($_.Original.TotalTime, 2)
        "Optimisé (ms)" = [Math]::Round($_.Optimized.TotalTime, 2)
        "Amélioration (%)" = [Math]::Round($_.TimeImprovement, 2)
        "CPU Original (ms)" = [Math]::Round($_.Original.CPUTime, 2)
        "CPU Optimisé (ms)" = [Math]::Round($_.Optimized.CPUTime, 2)
        "CPU Amélioration (%)" = [Math]::Round($_.CPUImprovement, 2)
    }
}

$summaryTable | Format-Table -AutoSize

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "`nTests terminés." -ForegroundColor Green
