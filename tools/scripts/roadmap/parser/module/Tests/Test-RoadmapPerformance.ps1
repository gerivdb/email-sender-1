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
        Write-Warning "La fonction $function est introuvable à l'emplacement : $functionPath"
    }
}

Write-Host "Début des tests des fonctions publiques de mesure de performance..." -ForegroundColor Cyan

# Test 1: Vérifier que les fonctions sont définies
Write-Host "`nTest 1: Vérifier que les fonctions sont définies" -ForegroundColor Cyan

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

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  Vérification de la fonction $function : $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    La fonction $function n'est pas définie" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Tester la fonction Measure-RoadmapExecutionTime
Write-Host "`nTest 2: Tester la fonction Measure-RoadmapExecutionTime" -ForegroundColor Cyan

# Mesurer le temps d'exécution d'un bloc de code
$result = Measure-RoadmapExecutionTime -Name "TestRoadmapMeasure" -ScriptBlock {
    Start-Sleep -Milliseconds 100
    return "Test réussi"
}

# Vérifier le résultat
$success = $result.Result -eq "Test réussi" -and
$result.ElapsedMilliseconds -ge 100

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du temps d'exécution: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result='Test réussi', ElapsedMilliseconds>=100" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result='$($result.Result)', ElapsedMilliseconds=$($result.ElapsedMilliseconds)" -ForegroundColor Red
}

# Test 3: Tester les fonctions Start-RoadmapPerformanceTimer et Stop-RoadmapPerformanceTimer via Measure-RoadmapExecutionTime
Write-Host "`nTest 3: Tester les fonctions Start-RoadmapPerformanceTimer et Stop-RoadmapPerformanceTimer via Measure-RoadmapExecutionTime" -ForegroundColor Cyan

# Mesurer le temps d'exécution d'un bloc de code
$timerName = "TestRoadmapTimer2"
$result = Measure-RoadmapExecutionTime -Name $timerName -ScriptBlock {
    Start-Sleep -Milliseconds 100
    return "Test réussi"
}

# Vérifier le résultat
$success = $result.Result -eq "Test réussi" -and
$result.ElapsedMilliseconds -ge 100

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Chronomètre simple: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result='Test réussi', ElapsedMilliseconds>=100" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result='$($result.Result)', ElapsedMilliseconds=$($result.ElapsedMilliseconds)" -ForegroundColor Red
}

# Test 4: Tester la fonction Get-RoadmapPerformanceStatistics via Measure-RoadmapExecutionTime
Write-Host "`nTest 4: Tester la fonction Get-RoadmapPerformanceStatistics via Measure-RoadmapExecutionTime" -ForegroundColor Cyan

# Exécuter plusieurs mesures
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

# Vérifier les statistiques
$success = $null -ne $stats -and
$stats.Count -gt 0 -and
$stats.MinMilliseconds -gt 0 -and
$stats.MaxMilliseconds -gt 0 -and
$stats.AverageMilliseconds -gt 0

$status = if ($success) { "Réussi" } else { "Échoué" }
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

# Test 5: Tester la fonction Measure-RoadmapExecutionTime avec des paramètres
Write-Host "`nTest 5: Tester la fonction Measure-RoadmapExecutionTime avec des paramètres" -ForegroundColor Cyan

# Mesurer le temps d'exécution d'un bloc de code avec des paramètres
$result = Measure-RoadmapExecutionTime -Name "TestRoadmapMeasureWithParams" -ScriptBlock {
    param($a, $b)
    Start-Sleep -Milliseconds 50
    return $a + $b
} -ArgumentList 10, 20

# Vérifier le résultat
$success = $result.Result -eq 30 -and
$result.ElapsedMilliseconds -ge 50

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du temps d'exécution avec paramètres: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result=30, ElapsedMilliseconds>=50" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result=$($result.Result), ElapsedMilliseconds=$($result.ElapsedMilliseconds)" -ForegroundColor Red
}

# Test 6: Tester la fonction Measure-RoadmapExecutionTime avec pipeline
Write-Host "`nTest 6: Tester la fonction Measure-RoadmapExecutionTime avec pipeline" -ForegroundColor Cyan

# Mesurer le temps d'exécution d'un bloc de code avec pipeline
$result = Measure-RoadmapExecutionTime -Name "TestRoadmapMeasureWithPipeline" -ScriptBlock {
    process {
        Start-Sleep -Milliseconds 50
        return $_ * 2
    }
} -InputObject 15

# Vérifier le résultat
$success = $result.Result -eq 30 -and
$result.ElapsedMilliseconds -ge 50

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du temps d'exécution avec pipeline: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result=30, ElapsedMilliseconds>=50" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result=$($result.Result), ElapsedMilliseconds=$($result.ElapsedMilliseconds)" -ForegroundColor Red
}

Write-Host "`nTests des fonctions publiques de mesure de performance terminés." -ForegroundColor Cyan
