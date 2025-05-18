# Tests de performance pour le module UnifiedParallel

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$modulePath = Join-Path -Path $modulePath -ChildPath "UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel

# Fonction pour mesurer le temps d'exécution
function Measure-SimpleExecutionTime {
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 1
    )

    $totalTime = 0

    for ($i = 0; $i -lt $Iterations; $i++) {
        $startTime = [datetime]::Now
        Invoke-Command -ScriptBlock $ScriptBlock
        $endTime = [datetime]::Now
        $totalTime += ($endTime - $startTime).TotalMilliseconds
    }

    return $totalTime / $Iterations
}

# Test de performance pour différentes tailles de données
Write-Host "Test de performance pour différentes tailles de données" -ForegroundColor Cyan
$sizes = @(10, 100, 1000)
$scriptBlock = { param($item) Start-Sleep -Milliseconds 10; return $item }

foreach ($size in $sizes) {
    $testData = 1..$size

    Write-Host "`nTaille des données: $size éléments" -ForegroundColor Yellow

    # Test séquentiel
    $sequentialTime = Measure-ExecutionTime -ScriptBlock {
        $results = foreach ($item in $testData) {
            & $scriptBlock $item
        }
    }
    Write-Host "Temps d'exécution séquentiel: $sequentialTime ms" -ForegroundColor White

    # Test parallèle avec 2 threads
    $parallel2Time = Measure-ExecutionTime -ScriptBlock {
        $results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $testData -MaxThreads 2 -UseRunspacePool -NoProgress
    }
    Write-Host "Temps d'exécution parallèle (2 threads): $parallel2Time ms" -ForegroundColor White

    # Test parallèle avec 4 threads
    $parallel4Time = Measure-ExecutionTime -ScriptBlock {
        $results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $testData -MaxThreads 4 -UseRunspacePool -NoProgress
    }
    Write-Host "Temps d'exécution parallèle (4 threads): $parallel4Time ms" -ForegroundColor White

    # Test parallèle avec 8 threads
    $parallel8Time = Measure-ExecutionTime -ScriptBlock {
        $results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $testData -MaxThreads 8 -UseRunspacePool -NoProgress
    }
    Write-Host "Temps d'exécution parallèle (8 threads): $parallel8Time ms" -ForegroundColor White

    # Calculer les accélérations
    $speedup2 = if ($parallel2Time -gt 0) { $sequentialTime / $parallel2Time } else { 0 }
    $speedup4 = if ($parallel4Time -gt 0) { $sequentialTime / $parallel4Time } else { 0 }
    $speedup8 = if ($parallel8Time -gt 0) { $sequentialTime / $parallel8Time } else { 0 }

    Write-Host "Accélération avec 2 threads: $([math]::Round($speedup2, 2))x" -ForegroundColor Green
    Write-Host "Accélération avec 4 threads: $([math]::Round($speedup4, 2))x" -ForegroundColor Green
    Write-Host "Accélération avec 8 threads: $([math]::Round($speedup8, 2))x" -ForegroundColor Green
}

# Test de performance pour différents types de tâches
Write-Host "`nTest de performance pour différents types de tâches" -ForegroundColor Cyan
$testData = 1..100

# Tâche CPU-bound (calcul intensif)
$cpuScriptBlock = {
    param($item)
    $result = 0
    for ($i = 0; $i -lt 1000000; $i++) {
        $result += $i * $item
    }
    return $result
}

# Tâche IO-bound (attente)
$ioScriptBlock = {
    param($item)
    Start-Sleep -Milliseconds ($item % 10 * 10)
    return $item
}

# Tâche mixte
$mixedScriptBlock = {
    param($item)
    # Partie CPU
    $result = 0
    for ($i = 0; $i -lt 100000; $i++) {
        $result += $i * $item
    }

    # Partie IO
    Start-Sleep -Milliseconds ($item % 10 * 5)

    return $result
}

# Test pour tâche CPU-bound
Write-Host "`nType de tâche: CPU-bound" -ForegroundColor Yellow
$cpuTime = Measure-ExecutionTime -ScriptBlock {
    $results = Invoke-UnifiedParallel -ScriptBlock $cpuScriptBlock -InputObject $testData -TaskType 'CPU' -UseRunspacePool -NoProgress
}
Write-Host "Temps d'exécution: $cpuTime ms" -ForegroundColor White

# Test pour tâche IO-bound
Write-Host "`nType de tâche: IO-bound" -ForegroundColor Yellow
$ioTime = Measure-ExecutionTime -ScriptBlock {
    $results = Invoke-UnifiedParallel -ScriptBlock $ioScriptBlock -InputObject $testData -TaskType 'IO' -UseRunspacePool -NoProgress
}
Write-Host "Temps d'exécution: $ioTime ms" -ForegroundColor White

# Test pour tâche mixte
Write-Host "`nType de tâche: Mixed" -ForegroundColor Yellow
$mixedTime = Measure-ExecutionTime -ScriptBlock {
    $results = Invoke-UnifiedParallel -ScriptBlock $mixedScriptBlock -InputObject $testData -TaskType 'Mixed' -UseRunspacePool -NoProgress
}
Write-Host "Temps d'exécution: $mixedTime ms" -ForegroundColor White

# Test de charge avec un grand nombre d'éléments
Write-Host "`nTest de charge avec un grand nombre d'éléments" -ForegroundColor Cyan
$largeTestData = 1..1000
$largeDataTime = Measure-ExecutionTime -ScriptBlock {
    $results = Invoke-UnifiedParallel -ScriptBlock { param($item) return $item } -InputObject $largeTestData -MaxThreads 8 -UseRunspacePool -NoProgress
}
Write-Host "Temps d'exécution pour 1000 éléments: $largeDataTime ms" -ForegroundColor White

# Test de charge avec des tâches longues
Write-Host "`nTest de charge avec des tâches longues" -ForegroundColor Cyan
$longTasksData = 1..20
$longTasksTime = Measure-ExecutionTime -ScriptBlock {
    $results = Invoke-UnifiedParallel -ScriptBlock { param($item) Start-Sleep -Milliseconds 500; return $item } -InputObject $longTasksData -MaxThreads 8 -UseRunspacePool -NoProgress
}
Write-Host "Temps d'exécution pour 20 tâches longues: $longTasksTime ms" -ForegroundColor White

# Nettoyer
Clear-UnifiedParallel

Write-Host "`nTests de performance terminés." -ForegroundColor Cyan
