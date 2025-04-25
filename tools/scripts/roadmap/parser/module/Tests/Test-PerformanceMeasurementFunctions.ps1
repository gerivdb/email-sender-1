#
# Test-PerformanceMeasurementFunctions.ps1
#
# Script pour tester les fonctions de mesure de performance
#

# Importer le script des fonctions de mesure de performance
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$performanceFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Performance\PerformanceMeasurementFunctions.ps1"

# Créer le répertoire s'il n'existe pas
$performanceFunctionsDir = Split-Path -Parent $performanceFunctionsPath
if (-not (Test-Path -Path $performanceFunctionsDir)) {
    New-Item -Path $performanceFunctionsDir -ItemType Directory -Force | Out-Null
}

# Importer le script
. $performanceFunctionsPath

Write-Host "Début des tests des fonctions de mesure de performance..." -ForegroundColor Cyan

# Test 1: Vérifier que les fonctions sont définies
Write-Host "`nTest 1: Vérifier que les fonctions sont définies" -ForegroundColor Cyan

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

# Test 2: Tester la configuration de la mesure de performance
Write-Host "`nTest 2: Tester la configuration de la mesure de performance" -ForegroundColor Cyan

# Configurer la mesure de performance
Set-PerformanceMeasurementConfiguration -Enabled $true -Category "TestPerformance"

# Obtenir la configuration
$config = Get-PerformanceMeasurementConfiguration

# Vérifier la configuration
$success = $config.Enabled -eq $true -and
$config.Category -eq "TestPerformance"

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Configuration de la mesure de performance: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Configuration attendue: Enabled=True, Category=TestPerformance" -ForegroundColor Red
    Write-Host "    Configuration obtenue: Enabled=$($config.Enabled), Category=$($config.Category)" -ForegroundColor Red
}

# Test 3: Tester les fonctions de chronomètre
Write-Host "`nTest 3: Tester les fonctions de chronomètre" -ForegroundColor Cyan

# Démarrer un chronomètre
$timerName = "TestTimer"
Start-PerformanceTimer -Name $timerName

# Attendre un peu
Start-Sleep -Milliseconds 100

# Arrêter le chronomètre
$elapsedMilliseconds = Stop-PerformanceTimer -Name $timerName

# Vérifier le résultat
$success = $elapsedMilliseconds -ge 100

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Chronomètre simple: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Temps écoulé attendu: >= 100 ms" -ForegroundColor Red
    Write-Host "    Temps écoulé obtenu: $elapsedMilliseconds ms" -ForegroundColor Red
}

# Test 4: Tester la réinitialisation du chronomètre
Write-Host "`nTest 4: Tester la réinitialisation du chronomètre" -ForegroundColor Cyan

# Démarrer un chronomètre
Start-PerformanceTimer -Name $timerName

# Attendre un peu
Start-Sleep -Milliseconds 50

# Réinitialiser le chronomètre
Reset-PerformanceTimer -Name $timerName

# Attendre un peu plus
Start-Sleep -Milliseconds 50

# Arrêter le chronomètre
$elapsedMilliseconds = Stop-PerformanceTimer -Name $timerName

# Vérifier le résultat
$success = $elapsedMilliseconds -ge 50 -and $elapsedMilliseconds -lt 100

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Réinitialisation du chronomètre: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Temps écoulé attendu: >= 50 ms et < 100 ms" -ForegroundColor Red
    Write-Host "    Temps écoulé obtenu: $elapsedMilliseconds ms" -ForegroundColor Red
}

# Test 5: Tester les statistiques de performance
Write-Host "`nTest 5: Tester les statistiques de performance" -ForegroundColor Cyan

# Exécuter plusieurs mesures
for ($i = 0; $i -lt 5; $i++) {
    Start-PerformanceTimer -Name $timerName
    Start-Sleep -Milliseconds (10 * ($i + 1))
    Stop-PerformanceTimer -Name $timerName
}

# Obtenir les statistiques
$stats = Get-PerformanceStatistics -Name $timerName

# Vérifier les statistiques
$success = $stats.Count -eq 7 -and
$stats.MinMilliseconds -gt 0 -and
$stats.MaxMilliseconds -gt 0 -and
$stats.AverageMilliseconds -gt 0

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Statistiques de performance: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=7, MinMilliseconds>0, MaxMilliseconds>0, AverageMilliseconds>0" -ForegroundColor Red
    Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinMilliseconds=$($stats.MinMilliseconds), MaxMilliseconds=$($stats.MaxMilliseconds), AverageMilliseconds=$($stats.AverageMilliseconds)" -ForegroundColor Red
}

# Test 6: Tester la fonction Measure-ExecutionTime
Write-Host "`nTest 6: Tester la fonction Measure-ExecutionTime" -ForegroundColor Cyan

# Mesurer le temps d'exécution d'un bloc de code
$result = Measure-ExecutionTime -Name "TestMeasure" -ScriptBlock {
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

# Test 7: Tester la fonction Measure-ExecutionTime avec des paramètres
Write-Host "`nTest 7: Tester la fonction Measure-ExecutionTime avec des paramètres" -ForegroundColor Cyan

# Mesurer le temps d'exécution d'un bloc de code avec des paramètres
$result = Measure-ExecutionTime -Name "TestMeasureWithParams" -ScriptBlock {
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

# Test 8: Tester la fonction Measure-ExecutionTime avec pipeline
Write-Host "`nTest 8: Tester la fonction Measure-ExecutionTime avec pipeline" -ForegroundColor Cyan

# Mesurer le temps d'exécution d'un bloc de code avec pipeline
$result = Measure-ExecutionTime -Name "TestMeasureWithPipeline" -ScriptBlock {
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

# Test 9: Tester la fonction Set-PerformanceThreshold
Write-Host "`nTest 9: Tester la fonction Set-PerformanceThreshold" -ForegroundColor Cyan

# Définir un seuil
Set-PerformanceThreshold -Name "TestThreshold" -ThresholdMilliseconds 10

# Mesurer le temps d'exécution d'un bloc de code qui dépasse le seuil
$result = Measure-ExecutionTime -Name "TestThreshold" -ScriptBlock {
    Start-Sleep -Milliseconds 50
    return "Test seuil dépassé"
}

# Vérifier le résultat
$success = $result.Result -eq "Test seuil dépassé" -and
$result.ElapsedMilliseconds -ge 50

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Seuil de performance: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result='Test seuil dépassé', ElapsedMilliseconds>=50" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result='$($result.Result)', ElapsedMilliseconds=$($result.ElapsedMilliseconds)" -ForegroundColor Red
}

Write-Host "`nTests des fonctions de mesure de performance terminés." -ForegroundColor Cyan
