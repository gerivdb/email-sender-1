#
# Test-RoadmapPerformanceComplete.ps1
#
# Script pour tester toutes les fonctions publiques de mesure de performance
#

# Importer les fonctions publiques
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$publicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"

# Fonctions de mesure de temps d'exÃ©cution
$measureExecutionTimePath = Join-Path -Path $publicPath -ChildPath "Measure-RoadmapExecutionTime.ps1"
$getPerformanceStatisticsPath = Join-Path -Path $publicPath -ChildPath "Get-RoadmapPerformanceStatistics.ps1"
$setPerformanceThresholdPath = Join-Path -Path $publicPath -ChildPath "Set-RoadmapPerformanceThreshold.ps1"

# Fonctions de mesure de mÃ©moire
$measureMemoryUsagePath = Join-Path -Path $publicPath -ChildPath "Measure-RoadmapMemoryUsage.ps1"
$getMemoryStatisticsPath = Join-Path -Path $publicPath -ChildPath "Get-RoadmapMemoryStatistics.ps1"
$setMemoryThresholdPath = Join-Path -Path $publicPath -ChildPath "Set-RoadmapMemoryThreshold.ps1"

# Fonctions de comptage d'opÃ©rations
$measureOperationsPath = Join-Path -Path $publicPath -ChildPath "Measure-RoadmapOperations.ps1"
$addOperationCountPath = Join-Path -Path $publicPath -ChildPath "Add-RoadmapOperationCount.ps1"
$getOperationStatisticsPath = Join-Path -Path $publicPath -ChildPath "Get-RoadmapOperationStatistics.ps1"
$setOperationThresholdPath = Join-Path -Path $publicPath -ChildPath "Set-RoadmapOperationThreshold.ps1"

# Importer les fonctions
. $measureExecutionTimePath
. $getPerformanceStatisticsPath
. $setPerformanceThresholdPath
. $measureMemoryUsagePath
. $getMemoryStatisticsPath
. $setMemoryThresholdPath
. $measureOperationsPath
. $addOperationCountPath
. $getOperationStatisticsPath
. $setOperationThresholdPath

Write-Host "DÃ©but des tests des fonctions publiques de mesure de performance..." -ForegroundColor Cyan

# Test 1: Mesure du temps d'exÃ©cution
Write-Host "`nTest 1: Mesure du temps d'exÃ©cution" -ForegroundColor Cyan

# Mesurer le temps d'exÃ©cution d'un bloc de code
$result = Measure-RoadmapExecutionTime -Name "TestRoadmapExecutionTime" -ScriptBlock {
    Start-Sleep -Milliseconds 100
    return "Test rÃ©ussi"
}

# VÃ©rifier le rÃ©sultat
Write-Host "  RÃ©sultat: $($result.Result)" -ForegroundColor Cyan
Write-Host "  DurÃ©e: $($result.DurationMs) ms" -ForegroundColor Cyan

# Test 2: Mesure de l'utilisation de la mÃ©moire
Write-Host "`nTest 2: Mesure de l'utilisation de la mÃ©moire" -ForegroundColor Cyan

# Mesurer l'utilisation de la mÃ©moire d'un bloc de code
$result = Measure-RoadmapMemoryUsage -Name "TestRoadmapMemoryUsage" -ScriptBlock {
    $memoryHog = @()
    for ($i = 0; $i -lt 1000; $i++) {
        $memoryHog += "X" * 1000
    }
    
    return "Test rÃ©ussi"
}

# VÃ©rifier le rÃ©sultat
Write-Host "  RÃ©sultat: $($result.Result)" -ForegroundColor Cyan
Write-Host "  MÃ©moire utilisÃ©e: $($result.MemoryUsedBytes) octets" -ForegroundColor Cyan

# Test 3: Mesure du nombre d'opÃ©rations
Write-Host "`nTest 3: Mesure du nombre d'opÃ©rations" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code
$result = Measure-RoadmapOperations -Name "TestRoadmapOperations" -ScriptBlock {
    for ($i = 0; $i -lt 100; $i++) {
        Add-RoadmapOperationCount -Name "TestRoadmapOperations"
    }
    
    return "Test rÃ©ussi"
}

# VÃ©rifier le rÃ©sultat
Write-Host "  RÃ©sultat: $($result.Result)" -ForegroundColor Cyan
Write-Host "  Nombre d'opÃ©rations: $($result.OperationCount)" -ForegroundColor Cyan

Write-Host "`nTests des fonctions publiques de mesure de performance terminÃ©s." -ForegroundColor Cyan
