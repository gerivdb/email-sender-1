#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module OptimizedParallel.
.DESCRIPTION
    Ce script teste les fonctionnalités du module OptimizedParallel
    en exécutant des tâches simples en parallèle.
.EXAMPLE
    .\Test-OptimizedParallel.ps1
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param()

# Importer le module de parallélisation optimisée
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\OptimizedParallel.psm1"
if (-not (Test-Path -Path $modulePath)) {
    throw "Module de parallélisation optimisée non trouvé: $modulePath"
}

Import-Module $modulePath -Force

# Fonction de test qui simule une charge de travail
function Test-WorkloadSimulation {
    param (
        [int]$Duration = 2,
        [int]$Complexity = 1
    )
    
    $startTime = Get-Date
    $result = @{
        StartTime = $startTime
        Duration = $Duration
        Complexity = $Complexity
        ProcessId = $PID
        ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    }
    
    # Simuler une charge CPU
    $data = @()
    for ($i = 0; $i -lt ($Complexity * 10000); $i++) {
        $data += [Math]::Pow($i, 2) / ($i + 1)
    }
    
    # Simuler un délai
    Start-Sleep -Seconds $Duration
    
    $endTime = Get-Date
    $result.EndTime = $endTime
    $result.ActualDuration = ($endTime - $startTime).TotalSeconds
    $result.DataPoints = $data.Count
    
    return [PSCustomObject]$result
}

# Test 1: Exécution séquentielle
Write-Host "Test 1: Exécution séquentielle de 5 tâches..." -ForegroundColor Cyan
$sequentialStart = Get-Date
$sequentialResults = @()

for ($i = 1; $i -le 5; $i++) {
    Write-Host "  Exécution de la tâche $i..." -ForegroundColor Gray
    $result = Test-WorkloadSimulation -Duration 2 -Complexity $i
    $sequentialResults += $result
}

$sequentialDuration = (Get-Date) - $sequentialStart
Write-Host "Exécution séquentielle terminée en $($sequentialDuration.TotalSeconds) secondes" -ForegroundColor Green

# Test 2: Exécution parallèle simple
Write-Host "`nTest 2: Exécution parallèle de 5 tâches..." -ForegroundColor Cyan
$parallelStart = Get-Date

# Initialiser le pool de parallélisation
Initialize-ParallelPool -MaxThreads 4

$parallelResults = @()
$jobIds = @()

for ($i = 1; $i -le 5; $i++) {
    Write-Host "  Démarrage de la tâche $i en parallèle..." -ForegroundColor Gray
    $jobId = Invoke-ParallelTask -ScriptBlock {
        param($Duration, $Complexity)
        Test-WorkloadSimulation -Duration $Duration -Complexity $Complexity
    } -ArgumentList @(2, $i)
    
    $jobIds += $jobId
}

# Attendre que toutes les tâches soient terminées
foreach ($jobId in $jobIds) {
    $result = Wait-ParallelTask -JobId $jobId
    $parallelResults += $result
}

$parallelDuration = (Get-Date) - $parallelStart
Write-Host "Exécution parallèle terminée en $($parallelDuration.TotalSeconds) secondes" -ForegroundColor Green

# Test 3: Exécution parallèle avec Invoke-ParallelTasks
Write-Host "`nTest 3: Exécution parallèle avec Invoke-ParallelTasks..." -ForegroundColor Cyan
$parallelTasksStart = Get-Date

$inputs = @()
for ($i = 1; $i -le 5; $i++) {
    $inputs += [PSCustomObject]@{
        Duration = 2
        Complexity = $i
    }
}

$parallelTasksResults = Invoke-ParallelTasks -ScriptBlock {
    param($Input)
    Test-WorkloadSimulation -Duration $Input.Duration -Complexity $Input.Complexity
} -InputObjects $inputs -ThrottleLimit 4 -ShowProgress

$parallelTasksDuration = (Get-Date) - $parallelTasksStart
Write-Host "Exécution avec Invoke-ParallelTasks terminée en $($parallelTasksDuration.TotalSeconds) secondes" -ForegroundColor Green

# Afficher les résultats
Write-Host "`nRésumé des performances:" -ForegroundColor Yellow
Write-Host "  Temps séquentiel: $($sequentialDuration.TotalSeconds) secondes"
Write-Host "  Temps parallèle (méthode 1): $($parallelDuration.TotalSeconds) secondes"
Write-Host "  Temps parallèle (méthode 2): $($parallelTasksDuration.TotalSeconds) secondes"
Write-Host "  Accélération (méthode 1): $([Math]::Round($sequentialDuration.TotalSeconds / $parallelDuration.TotalSeconds, 2))x"
Write-Host "  Accélération (méthode 2): $([Math]::Round($sequentialDuration.TotalSeconds / $parallelTasksDuration.TotalSeconds, 2))x"

# Nettoyer les ressources
Clear-ParallelPool -Force

# Afficher l'état des ressources système
$cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
$memoryCounter = Get-Counter '\Memory\% Committed Bytes In Use' -ErrorAction SilentlyContinue

Write-Host "`nÉtat des ressources système:" -ForegroundColor Yellow
Write-Host "  CPU: $([Math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2))%"
Write-Host "  Mémoire: $([Math]::Round($memoryCounter.CounterSamples[0].CookedValue, 2))%"
