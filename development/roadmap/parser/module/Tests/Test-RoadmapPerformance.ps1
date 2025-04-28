#
# Test-RoadmapPerformance.ps1
#
# Script pour tester les fonctions publiques de mesure de performance
#

# Importer le module RoadmapParser
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$publicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"

# Importer les fonctions publiques
$publicFunctions = @(
    "Measure-RoadmapExecutionTime.ps1",
    "Start-RoadmapPerformanceTimer.ps1",
    "Stop-RoadmapPerformanceTimer.ps1",
    "Get-RoadmapPerformanceStatistics.ps1"
)

foreach ($function in $publicFunctions) {
    $functionPath = Join-Path -Path $publicPath -ChildPath $function
    if (Test-Path -Path $functionPath) {
        . $functionPath
    } else {
        Write-Warning "La fonction $function est introuvable Ã  l'emplacement : $functionPath"
    }
}

Write-Host "DÃ©but des tests des fonctions publiques de mesure de performance..." -ForegroundColor Cyan

# Test 1: VÃ©rifier que les fonctions sont dÃ©finies
Write-Host "`nTest 1: VÃ©rifier que les fonctions sont dÃ©finies" -ForegroundColor Cyan

$functions = @(
    "Measure-RoadmapExecutionTime",
    "Start-RoadmapPerformanceTimer",
    "Stop-RoadmapPerformanceTimer",
    "Get-RoadmapPerformanceStatistics"
)

$successCount = 0
$failureCount = 0

foreach ($function in $functions) {
    $command = Get-Command -Name $function -ErrorAction SilentlyContinue
    $success = $null -ne $command

    $status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  VÃ©rification de la fonction $function : $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    La fonction $function n'est pas dÃ©finie" -ForegroundColor Red
    }
}

Write-Host "  RÃ©sultats: $successCount rÃ©ussis, $failureCount Ã©chouÃ©s" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Tester la fonction Measure-RoadmapExecutionTime
Write-Host "`nTest 2: Tester la fonction Measure-RoadmapExecutionTime" -ForegroundColor Cyan

# Mesurer le temps d'exÃ©cution d'un bloc de code
$result = Measure-RoadmapExecutionTime -Name "TestRoadmapMeasure" -ScriptBlock {
    Start-Sleep -Milliseconds 100
    return "Test rÃ©ussi"
}

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq "Test rÃ©ussi" -and
$result.ElapsedMilliseconds -ge 100

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du temps d'exÃ©cution: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result='Test rÃ©ussi', ElapsedMilliseconds>=100" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result='$($result.Result)', ElapsedMilliseconds=$($result.ElapsedMilliseconds)" -ForegroundColor Red
}

# Test 3: Tester les fonctions Start-RoadmapPerformanceTimer et Stop-RoadmapPerformanceTimer via Measure-RoadmapExecutionTime
Write-Host "`nTest 3: Tester les fonctions Start-RoadmapPerformanceTimer et Stop-RoadmapPerformanceTimer via Measure-RoadmapExecutionTime" -ForegroundColor Cyan

# Mesurer le temps d'exÃ©cution d'un bloc de code
$timerName = "TestRoadmapTimer2"
$result = Measure-RoadmapExecutionTime -Name $timerName -ScriptBlock {
    Start-Sleep -Milliseconds 100
    return "Test rÃ©ussi"
}

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq "Test rÃ©ussi" -and
$result.ElapsedMilliseconds -ge 100

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  ChronomÃ¨tre simple: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result='Test rÃ©ussi', ElapsedMilliseconds>=100" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result='$($result.Result)', ElapsedMilliseconds=$($result.ElapsedMilliseconds)" -ForegroundColor Red
}

# Test 4: Tester la fonction Get-RoadmapPerformanceStatistics via Measure-RoadmapExecutionTime
Write-Host "`nTest 4: Tester la fonction Get-RoadmapPerformanceStatistics via Measure-RoadmapExecutionTime" -ForegroundColor Cyan

# ExÃ©cuter plusieurs mesures
for ($i = 0; $i -lt 5; $i++) {
    $result = Measure-RoadmapExecutionTime -Name $timerName -ScriptBlock {
        param($sleepTime)
        Start-Sleep -Milliseconds $sleepTime
        return "Test $sleepTime"
    } -ArgumentList (10 * ($i + 1))
}

# Obtenir les statistiques via une autre mesure
$statsResult = Measure-RoadmapExecutionTime -Name "GetStats" -ScriptBlock {
    return Get-RoadmapPerformanceStatistics -Name $timerName
}

$stats = $statsResult.Result

# VÃ©rifier les statistiques
$success = $null -ne $stats -and
$stats.Count -gt 0 -and
$stats.MinMilliseconds -gt 0 -and
$stats.MaxMilliseconds -gt 0 -and
$stats.AverageMilliseconds -gt 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Statistiques de performance: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count>0, MinMilliseconds>0, MaxMilliseconds>0, AverageMilliseconds>0" -ForegroundColor Red
    if ($null -ne $stats) {
        Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinMilliseconds=$($stats.MinMilliseconds), MaxMilliseconds=$($stats.MaxMilliseconds), AverageMilliseconds=$($stats.AverageMilliseconds)" -ForegroundColor Red
    } else {
        Write-Host "    Statistiques obtenues: null" -ForegroundColor Red
    }
}

# Test 5: Tester la fonction Measure-RoadmapExecutionTime avec des paramÃ¨tres
Write-Host "`nTest 5: Tester la fonction Measure-RoadmapExecutionTime avec des paramÃ¨tres" -ForegroundColor Cyan

# Mesurer le temps d'exÃ©cution d'un bloc de code avec des paramÃ¨tres
$result = Measure-RoadmapExecutionTime -Name "TestRoadmapMeasureWithParams" -ScriptBlock {
    param($a, $b)
    Start-Sleep -Milliseconds 50
    return $a + $b
} -ArgumentList 10, 20

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq 30 -and
$result.ElapsedMilliseconds -ge 50

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du temps d'exÃ©cution avec paramÃ¨tres: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result=30, ElapsedMilliseconds>=50" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result=$($result.Result), ElapsedMilliseconds=$($result.ElapsedMilliseconds)" -ForegroundColor Red
}

# Test 6: Tester la fonction Measure-RoadmapExecutionTime avec pipeline
Write-Host "`nTest 6: Tester la fonction Measure-RoadmapExecutionTime avec pipeline" -ForegroundColor Cyan

# Mesurer le temps d'exÃ©cution d'un bloc de code avec pipeline
$result = Measure-RoadmapExecutionTime -Name "TestRoadmapMeasureWithPipeline" -ScriptBlock {
    process {
        Start-Sleep -Milliseconds 50
        return $_ * 2
    }
} -InputObject 15

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq 30 -and
$result.ElapsedMilliseconds -ge 50

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du temps d'exÃ©cution avec pipeline: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result=30, ElapsedMilliseconds>=50" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result=$($result.Result), ElapsedMilliseconds=$($result.ElapsedMilliseconds)" -ForegroundColor Red
}

Write-Host "`nTests des fonctions publiques de mesure de performance terminÃ©s." -ForegroundColor Cyan
