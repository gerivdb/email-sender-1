#
# Test-PerformanceMeasurementComplete.ps1
#
# Script pour tester toutes les fonctions de mesure de performance
#

# Importer les fonctions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$privatePath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Performance"
$performanceFunctionsPath = Join-Path -Path $privatePath -ChildPath "PerformanceMeasurementFunctions.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $performanceFunctionsPath)) {
    Write-Error "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable à l'emplacement : $performanceFunctionsPath"
    exit 1
}

# Importer le script
. $performanceFunctionsPath

Write-Host "Début des tests complets des fonctions de mesure de performance..." -ForegroundColor Cyan

# Test 1: Mesure du temps d'exécution
Write-Host "`nTest 1: Mesure du temps d'exécution" -ForegroundColor Cyan

# Mesurer le temps d'exécution d'un bloc de code
$result = Measure-ExecutionTime -Name "TestExecutionTime" -ScriptBlock {
    Start-Sleep -Milliseconds 100
    return "Test réussi"
}

# Vérifier le résultat
$success = $result.Result -eq "Test réussi" -and
           $result.DurationMs -ge 100

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du temps d'exécution: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result='Test réussi', DurationMs>=100" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result='$($result.Result)', DurationMs=$($result.DurationMs)" -ForegroundColor Red
}

# Test 2: Obtenir les statistiques de temps d'exécution
Write-Host "`nTest 2: Obtenir les statistiques de temps d'exécution" -ForegroundColor Cyan

# Exécuter plusieurs mesures
for ($i = 0; $i -lt 3; $i++) {
    $result = Measure-ExecutionTime -Name "TestExecutionTimeStats" -ScriptBlock {
        Start-Sleep -Milliseconds (($i + 1) * 50)
        return "Test réussi"
    }
}

# Obtenir les statistiques
$stats = Get-PerformanceStatistics -Name "TestExecutionTimeStats"

# Vérifier les statistiques
$success = $stats.Count -eq 3 -and
           $stats.MinDurationMs -ge 50 -and
           $stats.MaxDurationMs -ge 150 -and
           $stats.AverageDurationMs -ge 100

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Statistiques de temps d'exécution: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=3, MinDurationMs>=50, MaxDurationMs>=150, AverageDurationMs>=100" -ForegroundColor Red
    Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinDurationMs=$($stats.MinDurationMs), MaxDurationMs=$($stats.MaxDurationMs), AverageDurationMs=$($stats.AverageDurationMs)" -ForegroundColor Red
}

# Test 3: Mesure de l'utilisation de la mémoire
Write-Host "`nTest 3: Mesure de l'utilisation de la mémoire" -ForegroundColor Cyan

# Mesurer l'utilisation de la mémoire d'un bloc de code
$result = Measure-MemoryUsage -Name "TestMemoryUsage" -ScriptBlock {
    $memoryHog = @()
    for ($i = 0; $i -lt 1000; $i++) {
        $memoryHog += "X" * 1000
    }
    
    return "Test réussi"
}

# Vérifier le résultat
$success = $result.Result -eq "Test réussi" -and
           $result.MemoryUsedBytes -gt 0

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure de l'utilisation de la mémoire: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result='Test réussi', MemoryUsedBytes>0" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result='$($result.Result)', MemoryUsedBytes=$($result.MemoryUsedBytes)" -ForegroundColor Red
}

# Test 4: Obtenir les statistiques de mémoire
Write-Host "`nTest 4: Obtenir les statistiques de mémoire" -ForegroundColor Cyan

# Exécuter plusieurs mesures
for ($i = 0; $i -lt 3; $i++) {
    $result = Measure-MemoryUsage -Name "TestMemoryUsageStats" -ScriptBlock {
        $memoryHog = @()
        for ($j = 0; $j -lt ($i + 1) * 500; $j++) {
            $memoryHog += "X" * 100
        }
        
        return "Test réussi"
    }
}

# Obtenir les statistiques
$stats = Get-MemoryStatistics -Name "TestMemoryUsageStats"

# Vérifier les statistiques
$success = $null -ne $stats -and
           $stats.Count -eq 3 -and
           $stats.MinBytes -gt 0 -and
           $stats.MaxBytes -gt 0 -and
           $stats.AverageBytes -gt 0

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Statistiques de mémoire: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=3, MinBytes>0, MaxBytes>0, AverageBytes>0" -ForegroundColor Red
    if ($null -ne $stats) {
        Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinBytes=$($stats.MinBytes), MaxBytes=$($stats.MaxBytes), AverageBytes=$($stats.AverageBytes)" -ForegroundColor Red
    } else {
        Write-Host "    Statistiques obtenues: null" -ForegroundColor Red
    }
}

# Test 5: Mesure du nombre d'opérations
Write-Host "`nTest 5: Mesure du nombre d'opérations" -ForegroundColor Cyan

# Mesurer le nombre d'opérations effectuées par un bloc de code
$result = Measure-Operations -Name "TestOperations" -ScriptBlock {
    for ($i = 0; $i -lt 100; $i++) {
        Increment-OperationCounter -Name "TestOperations"
    }
    
    return "Test réussi"
}

# Vérifier le résultat
$success = $result.Result -eq "Test réussi" -and
           $result.OperationCount -eq 100

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du nombre d'opérations: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result='Test réussi', OperationCount=100" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result='$($result.Result)', OperationCount=$($result.OperationCount)" -ForegroundColor Red
}

# Test 6: Obtenir les statistiques d'opérations
Write-Host "`nTest 6: Obtenir les statistiques d'opérations" -ForegroundColor Cyan

# Exécuter plusieurs mesures
for ($i = 0; $i -lt 3; $i++) {
    $result = Measure-Operations -Name "TestOperationsStats" -ScriptBlock {
        for ($j = 0; $j -lt ($i + 1) * 50; $j++) {
            Increment-OperationCounter -Name "TestOperationsStats"
        }
        
        return "Test réussi"
    }
}

# Obtenir les statistiques
$stats = Get-OperationStatistics -Name "TestOperationsStats"

# Vérifier les statistiques
$success = $null -ne $stats -and
           $stats.Count -eq 3 -and
           $stats.MinOperations -gt 0 -and
           $stats.MaxOperations -gt 0 -and
           $stats.AverageOperations -gt 0

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Statistiques d'opérations: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=3, MinOperations>0, MaxOperations>0, AverageOperations>0" -ForegroundColor Red
    if ($null -ne $stats) {
        Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinOperations=$($stats.MinOperations), MaxOperations=$($stats.MaxOperations), AverageOperations=$($stats.AverageOperations)" -ForegroundColor Red
    } else {
        Write-Host "    Statistiques obtenues: null" -ForegroundColor Red
    }
}

Write-Host "`nTests complets des fonctions de mesure de performance terminés." -ForegroundColor Cyan
