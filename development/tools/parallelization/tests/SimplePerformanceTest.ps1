# Test de performance simple pour le module UnifiedParallel
#Requires -Version 5.1

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel

# Fonction pour mesurer le temps d'exécution
function Measure-SimpleTime {
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )
    
    $startTime = [datetime]::Now
    Invoke-Command -ScriptBlock $ScriptBlock
    $endTime = [datetime]::Now
    
    return ($endTime - $startTime).TotalMilliseconds
}

# Test de performance pour différentes tailles de données
Write-Host "Test de performance pour différentes tailles de données" -ForegroundColor Cyan
$sizes = @(10, 100, 1000)
$scriptBlock = { param($item) Start-Sleep -Milliseconds 10; return $item }

foreach ($size in $sizes) {
    $testData = 1..$size
    
    Write-Host "`nTaille des données: $size éléments" -ForegroundColor Yellow
    
    # Test séquentiel
    $sequentialTime = Measure-SimpleTime -ScriptBlock {
        foreach ($item in $testData) {
            & $scriptBlock $item
        }
    }
    Write-Host "Temps d'exécution séquentiel: $sequentialTime ms" -ForegroundColor White
    
    # Test parallèle avec 2 threads
    $parallel2Time = Measure-SimpleTime -ScriptBlock {
        Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $testData -MaxThreads 2 -UseRunspacePool -NoProgress
    }
    $speedup2 = if ($parallel2Time -gt 0) { $sequentialTime / $parallel2Time } else { 0 }
    Write-Host "Temps d'exécution parallèle (2 threads): $parallel2Time ms" -ForegroundColor White
    Write-Host "Accélération avec 2 threads: $([math]::Round($speedup2, 2))x" -ForegroundColor Green
    
    # Test parallèle avec 4 threads
    $parallel4Time = Measure-SimpleTime -ScriptBlock {
        Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $testData -MaxThreads 4 -UseRunspacePool -NoProgress
    }
    $speedup4 = if ($parallel4Time -gt 0) { $sequentialTime / $parallel4Time } else { 0 }
    Write-Host "Temps d'exécution parallèle (4 threads): $parallel4Time ms" -ForegroundColor White
    Write-Host "Accélération avec 4 threads: $([math]::Round($speedup4, 2))x" -ForegroundColor Green
}

# Test de performance pour différents types de tâches
Write-Host "`nTest de performance pour différents types de tâches" -ForegroundColor Cyan
$testData = 1..50

# Tâche CPU-bound (calcul intensif)
$cpuScriptBlock = {
    param($item)
    $result = 0
    for ($i = 0; $i -lt 100000; $i++) {
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

# Test pour tâche CPU-bound
Write-Host "`nType de tâche: CPU-bound" -ForegroundColor Yellow
$cpuSequentialTime = Measure-SimpleTime -ScriptBlock {
    foreach ($item in $testData) {
        & $cpuScriptBlock $item
    }
}
Write-Host "Temps d'exécution séquentiel: $cpuSequentialTime ms" -ForegroundColor White

$cpuTime = Measure-SimpleTime -ScriptBlock {
    Invoke-UnifiedParallel -ScriptBlock $cpuScriptBlock -InputObject $testData -TaskType 'CPU' -UseRunspacePool -NoProgress
}
$cpuSpeedup = if ($cpuTime -gt 0) { $cpuSequentialTime / $cpuTime } else { 0 }
Write-Host "Temps d'exécution parallèle: $cpuTime ms" -ForegroundColor White
Write-Host "Accélération: $([math]::Round($cpuSpeedup, 2))x" -ForegroundColor Green

# Test pour tâche IO-bound
Write-Host "`nType de tâche: IO-bound" -ForegroundColor Yellow
$ioSequentialTime = Measure-SimpleTime -ScriptBlock {
    foreach ($item in $testData) {
        & $ioScriptBlock $item
    }
}
Write-Host "Temps d'exécution séquentiel: $ioSequentialTime ms" -ForegroundColor White

$ioTime = Measure-SimpleTime -ScriptBlock {
    Invoke-UnifiedParallel -ScriptBlock $ioScriptBlock -InputObject $testData -TaskType 'IO' -UseRunspacePool -NoProgress
}
$ioSpeedup = if ($ioTime -gt 0) { $ioSequentialTime / $ioTime } else { 0 }
Write-Host "Temps d'exécution parallèle: $ioTime ms" -ForegroundColor White
Write-Host "Accélération: $([math]::Round($ioSpeedup, 2))x" -ForegroundColor Green

# Nettoyer
Clear-UnifiedParallel

Write-Host "`nTests de performance terminés." -ForegroundColor Cyan
