#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module OptimizedParallel.
.DESCRIPTION
    Ce script teste les fonctionnalitÃ©s du module OptimizedParallel
    en exÃ©cutant des tÃ¢ches simples en parallÃ¨le.
.EXAMPLE
    .\Test-OptimizedParallel.ps1
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param()

# Importer le module de parallÃ©lisation optimisÃ©e
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\OptimizedParallel.psm1"
if (-not (Test-Path -Path $modulePath)) {
    throw "Module de parallÃ©lisation optimisÃ©e non trouvÃ©: $modulePath"
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
    
    # Simuler un dÃ©lai
    Start-Sleep -Seconds $Duration
    
    $endTime = Get-Date
    $result.EndTime = $endTime
    $result.ActualDuration = ($endTime - $startTime).TotalSeconds
    $result.DataPoints = $data.Count
    
    return [PSCustomObject]$result
}

# Test 1: ExÃ©cution sÃ©quentielle
Write-Host "Test 1: ExÃ©cution sÃ©quentielle de 5 tÃ¢ches..." -ForegroundColor Cyan
$sequentialStart = Get-Date
$sequentialResults = @()

for ($i = 1; $i -le 5; $i++) {
    Write-Host "  ExÃ©cution de la tÃ¢che $i..." -ForegroundColor Gray
    $result = Test-WorkloadSimulation -Duration 2 -Complexity $i
    $sequentialResults += $result
}

$sequentialDuration = (Get-Date) - $sequentialStart
Write-Host "ExÃ©cution sÃ©quentielle terminÃ©e en $($sequentialDuration.TotalSeconds) secondes" -ForegroundColor Green

# Test 2: ExÃ©cution parallÃ¨le simple
Write-Host "`nTest 2: ExÃ©cution parallÃ¨le de 5 tÃ¢ches..." -ForegroundColor Cyan
$parallelStart = Get-Date

# Initialiser le pool de parallÃ©lisation
Initialize-ParallelPool -MaxThreads 4

$parallelResults = @()
$jobIds = @()

for ($i = 1; $i -le 5; $i++) {
    Write-Host "  DÃ©marrage de la tÃ¢che $i en parallÃ¨le..." -ForegroundColor Gray
    $jobId = Invoke-ParallelTask -ScriptBlock {
        param($Duration, $Complexity)
        Test-WorkloadSimulation -Duration $Duration -Complexity $Complexity
    } -ArgumentList @(2, $i)
    
    $jobIds += $jobId
}

# Attendre que toutes les tÃ¢ches soient terminÃ©es
foreach ($jobId in $jobIds) {
    $result = Wait-ParallelTask -JobId $jobId
    $parallelResults += $result
}

$parallelDuration = (Get-Date) - $parallelStart
Write-Host "ExÃ©cution parallÃ¨le terminÃ©e en $($parallelDuration.TotalSeconds) secondes" -ForegroundColor Green

# Test 3: ExÃ©cution parallÃ¨le avec Invoke-ParallelTasks
Write-Host "`nTest 3: ExÃ©cution parallÃ¨le avec Invoke-ParallelTasks..." -ForegroundColor Cyan
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
Write-Host "ExÃ©cution avec Invoke-ParallelTasks terminÃ©e en $($parallelTasksDuration.TotalSeconds) secondes" -ForegroundColor Green

# Afficher les rÃ©sultats
Write-Host "`nRÃ©sumÃ© des performances:" -ForegroundColor Yellow
Write-Host "  Temps sÃ©quentiel: $($sequentialDuration.TotalSeconds) secondes"
Write-Host "  Temps parallÃ¨le (mÃ©thode 1): $($parallelDuration.TotalSeconds) secondes"
Write-Host "  Temps parallÃ¨le (mÃ©thode 2): $($parallelTasksDuration.TotalSeconds) secondes"
Write-Host "  AccÃ©lÃ©ration (mÃ©thode 1): $([Math]::Round($sequentialDuration.TotalSeconds / $parallelDuration.TotalSeconds, 2))x"
Write-Host "  AccÃ©lÃ©ration (mÃ©thode 2): $([Math]::Round($sequentialDuration.TotalSeconds / $parallelTasksDuration.TotalSeconds, 2))x"

# Nettoyer les ressources
Clear-ParallelPool -Force

# Afficher l'Ã©tat des ressources systÃ¨me
$cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
$memoryCounter = Get-Counter '\Memory\% Committed Bytes In Use' -ErrorAction SilentlyContinue

Write-Host "`nÃ‰tat des ressources systÃ¨me:" -ForegroundColor Yellow
Write-Host "  CPU: $([Math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2))%"
Write-Host "  MÃ©moire: $([Math]::Round($memoryCounter.CounterSamples[0].CookedValue, 2))%"
