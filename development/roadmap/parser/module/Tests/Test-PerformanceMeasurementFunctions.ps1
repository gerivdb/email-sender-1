#
# Test-PerformanceMeasurementFunctions.ps1
#
# Script pour tester les fonctions de mesure de performance
#

# Importer le script des fonctions de mesure de performance
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$performanceFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Performance\PerformanceMeasurementFunctions.ps1"

# CrÃ©er le rÃ©pertoire s'il n'existe pas
$performanceFunctionsDir = Split-Path -Parent $performanceFunctionsPath
if (-not (Test-Path -Path $performanceFunctionsDir)) {
    New-Item -Path $performanceFunctionsDir -ItemType Directory -Force | Out-Null
}

# Importer le script
. $performanceFunctionsPath

Write-Host "DÃ©but des tests des fonctions de mesure de performance..." -ForegroundColor Cyan

# Test 1: VÃ©rifier que les fonctions sont dÃ©finies
Write-Host "`nTest 1: VÃ©rifier que les fonctions sont dÃ©finies" -ForegroundColor Cyan

$functions = @(
    "Set-PerformanceMeasurementConfiguration",
    "Get-PerformanceMeasurementConfiguration",
    "Start-PerformanceTimer",
    "Stop-PerformanceTimer",
    "Reset-PerformanceTimer",
    "Get-PerformanceStatistics",
    "Set-PerformanceThreshold",
    "Measure-ExecutionTime"
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

# Test 2: Tester la configuration de la mesure de performance
Write-Host "`nTest 2: Tester la configuration de la mesure de performance" -ForegroundColor Cyan

# Configurer la mesure de performance
Set-PerformanceMeasurementConfiguration -Enabled $true -Category "TestPerformance"

# Obtenir la configuration
$config = Get-PerformanceMeasurementConfiguration

# VÃ©rifier la configuration
$success = $config.Enabled -eq $true -and
$config.Category -eq "TestPerformance"

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Configuration de la mesure de performance: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Configuration attendue: Enabled=True, Category=TestPerformance" -ForegroundColor Red
    Write-Host "    Configuration obtenue: Enabled=$($config.Enabled), Category=$($config.Category)" -ForegroundColor Red
}

# Test 3: Tester les fonctions de chronomÃ¨tre
Write-Host "`nTest 3: Tester les fonctions de chronomÃ¨tre" -ForegroundColor Cyan

# DÃ©marrer un chronomÃ¨tre
$timerName = "TestTimer"
Start-PerformanceTimer -Name $timerName

# Attendre un peu
Start-Sleep -Milliseconds 100

# ArrÃªter le chronomÃ¨tre
$elapsedMilliseconds = Stop-PerformanceTimer -Name $timerName

# VÃ©rifier le rÃ©sultat
$success = $elapsedMilliseconds -ge 100

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  ChronomÃ¨tre simple: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Temps Ã©coulÃ© attendu: >= 100 ms" -ForegroundColor Red
    Write-Host "    Temps Ã©coulÃ© obtenu: $elapsedMilliseconds ms" -ForegroundColor Red
}

# Test 4: Tester la rÃ©initialisation du chronomÃ¨tre
Write-Host "`nTest 4: Tester la rÃ©initialisation du chronomÃ¨tre" -ForegroundColor Cyan

# DÃ©marrer un chronomÃ¨tre
Start-PerformanceTimer -Name $timerName

# Attendre un peu
Start-Sleep -Milliseconds 50

# RÃ©initialiser le chronomÃ¨tre
Reset-PerformanceTimer -Name $timerName

# Attendre un peu plus
Start-Sleep -Milliseconds 50

# ArrÃªter le chronomÃ¨tre
$elapsedMilliseconds = Stop-PerformanceTimer -Name $timerName

# VÃ©rifier le rÃ©sultat
$success = $elapsedMilliseconds -ge 50 -and $elapsedMilliseconds -lt 100

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  RÃ©initialisation du chronomÃ¨tre: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Temps Ã©coulÃ© attendu: >= 50 ms et < 100 ms" -ForegroundColor Red
    Write-Host "    Temps Ã©coulÃ© obtenu: $elapsedMilliseconds ms" -ForegroundColor Red
}

# Test 5: Tester les statistiques de performance
Write-Host "`nTest 5: Tester les statistiques de performance" -ForegroundColor Cyan

# ExÃ©cuter plusieurs mesures
for ($i = 0; $i -lt 5; $i++) {
    Start-PerformanceTimer -Name $timerName
    Start-Sleep -Milliseconds (10 * ($i + 1))
    Stop-PerformanceTimer -Name $timerName
}

# Obtenir les statistiques
$stats = Get-PerformanceStatistics -Name $timerName

# VÃ©rifier les statistiques
$success = $stats.Count -eq 7 -and
$stats.MinMilliseconds -gt 0 -and
$stats.MaxMilliseconds -gt 0 -and
$stats.AverageMilliseconds -gt 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Statistiques de performance: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=7, MinMilliseconds>0, MaxMilliseconds>0, AverageMilliseconds>0" -ForegroundColor Red
    Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinMilliseconds=$($stats.MinMilliseconds), MaxMilliseconds=$($stats.MaxMilliseconds), AverageMilliseconds=$($stats.AverageMilliseconds)" -ForegroundColor Red
}

# Test 6: Tester la fonction Measure-ExecutionTime
Write-Host "`nTest 6: Tester la fonction Measure-ExecutionTime" -ForegroundColor Cyan

# Mesurer le temps d'exÃ©cution d'un bloc de code
$result = Measure-ExecutionTime -Name "TestMeasure" -ScriptBlock {
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

# Test 7: Tester la fonction Measure-ExecutionTime avec des paramÃ¨tres
Write-Host "`nTest 7: Tester la fonction Measure-ExecutionTime avec des paramÃ¨tres" -ForegroundColor Cyan

# Mesurer le temps d'exÃ©cution d'un bloc de code avec des paramÃ¨tres
$result = Measure-ExecutionTime -Name "TestMeasureWithParams" -ScriptBlock {
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

# Test 8: Tester la fonction Measure-ExecutionTime avec pipeline
Write-Host "`nTest 8: Tester la fonction Measure-ExecutionTime avec pipeline" -ForegroundColor Cyan

# Mesurer le temps d'exÃ©cution d'un bloc de code avec pipeline
$result = Measure-ExecutionTime -Name "TestMeasureWithPipeline" -ScriptBlock {
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

# Test 9: Tester la fonction Set-PerformanceThreshold
Write-Host "`nTest 9: Tester la fonction Set-PerformanceThreshold" -ForegroundColor Cyan

# DÃ©finir un seuil
Set-PerformanceThreshold -Name "TestThreshold" -ThresholdMilliseconds 10

# Mesurer le temps d'exÃ©cution d'un bloc de code qui dÃ©passe le seuil
$result = Measure-ExecutionTime -Name "TestThreshold" -ScriptBlock {
    Start-Sleep -Milliseconds 50
    return "Test seuil dÃ©passÃ©"
}

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq "Test seuil dÃ©passÃ©" -and
$result.ElapsedMilliseconds -ge 50

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Seuil de performance: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result='Test seuil dÃ©passÃ©', ElapsedMilliseconds>=50" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result='$($result.Result)', ElapsedMilliseconds=$($result.ElapsedMilliseconds)" -ForegroundColor Red
}

Write-Host "`nTests des fonctions de mesure de performance terminÃ©s." -ForegroundColor Cyan
