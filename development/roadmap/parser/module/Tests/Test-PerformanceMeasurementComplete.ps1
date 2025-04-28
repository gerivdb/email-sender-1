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

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $performanceFunctionsPath)) {
    Write-Error "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable Ã  l'emplacement : $performanceFunctionsPath"
    exit 1
}

# Importer le script
. $performanceFunctionsPath

Write-Host "DÃ©but des tests complets des fonctions de mesure de performance..." -ForegroundColor Cyan

# Test 1: Mesure du temps d'exÃ©cution
Write-Host "`nTest 1: Mesure du temps d'exÃ©cution" -ForegroundColor Cyan

# Mesurer le temps d'exÃ©cution d'un bloc de code
$result = Measure-ExecutionTime -Name "TestExecutionTime" -ScriptBlock {
    Start-Sleep -Milliseconds 100
    return "Test rÃ©ussi"
}

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq "Test rÃ©ussi" -and
           $result.DurationMs -ge 100

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du temps d'exÃ©cution: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result='Test rÃ©ussi', DurationMs>=100" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result='$($result.Result)', DurationMs=$($result.DurationMs)" -ForegroundColor Red
}

# Test 2: Obtenir les statistiques de temps d'exÃ©cution
Write-Host "`nTest 2: Obtenir les statistiques de temps d'exÃ©cution" -ForegroundColor Cyan

# ExÃ©cuter plusieurs mesures
for ($i = 0; $i -lt 3; $i++) {
    $result = Measure-ExecutionTime -Name "TestExecutionTimeStats" -ScriptBlock {
        Start-Sleep -Milliseconds (($i + 1) * 50)
        return "Test rÃ©ussi"
    }
}

# Obtenir les statistiques
$stats = Get-PerformanceStatistics -Name "TestExecutionTimeStats"

# VÃ©rifier les statistiques
$success = $stats.Count -eq 3 -and
           $stats.MinDurationMs -ge 50 -and
           $stats.MaxDurationMs -ge 150 -and
           $stats.AverageDurationMs -ge 100

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Statistiques de temps d'exÃ©cution: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=3, MinDurationMs>=50, MaxDurationMs>=150, AverageDurationMs>=100" -ForegroundColor Red
    Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinDurationMs=$($stats.MinDurationMs), MaxDurationMs=$($stats.MaxDurationMs), AverageDurationMs=$($stats.AverageDurationMs)" -ForegroundColor Red
}

# Test 3: Mesure de l'utilisation de la mÃ©moire
Write-Host "`nTest 3: Mesure de l'utilisation de la mÃ©moire" -ForegroundColor Cyan

# Mesurer l'utilisation de la mÃ©moire d'un bloc de code
$result = Measure-MemoryUsage -Name "TestMemoryUsage" -ScriptBlock {
    $memoryHog = @()
    for ($i = 0; $i -lt 1000; $i++) {
        $memoryHog += "X" * 1000
    }
    
    return "Test rÃ©ussi"
}

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq "Test rÃ©ussi" -and
           $result.MemoryUsedBytes -gt 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure de l'utilisation de la mÃ©moire: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result='Test rÃ©ussi', MemoryUsedBytes>0" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result='$($result.Result)', MemoryUsedBytes=$($result.MemoryUsedBytes)" -ForegroundColor Red
}

# Test 4: Obtenir les statistiques de mÃ©moire
Write-Host "`nTest 4: Obtenir les statistiques de mÃ©moire" -ForegroundColor Cyan

# ExÃ©cuter plusieurs mesures
for ($i = 0; $i -lt 3; $i++) {
    $result = Measure-MemoryUsage -Name "TestMemoryUsageStats" -ScriptBlock {
        $memoryHog = @()
        for ($j = 0; $j -lt ($i + 1) * 500; $j++) {
            $memoryHog += "X" * 100
        }
        
        return "Test rÃ©ussi"
    }
}

# Obtenir les statistiques
$stats = Get-MemoryStatistics -Name "TestMemoryUsageStats"

# VÃ©rifier les statistiques
$success = $null -ne $stats -and
           $stats.Count -eq 3 -and
           $stats.MinBytes -gt 0 -and
           $stats.MaxBytes -gt 0 -and
           $stats.AverageBytes -gt 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Statistiques de mÃ©moire: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=3, MinBytes>0, MaxBytes>0, AverageBytes>0" -ForegroundColor Red
    if ($null -ne $stats) {
        Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinBytes=$($stats.MinBytes), MaxBytes=$($stats.MaxBytes), AverageBytes=$($stats.AverageBytes)" -ForegroundColor Red
    } else {
        Write-Host "    Statistiques obtenues: null" -ForegroundColor Red
    }
}

# Test 5: Mesure du nombre d'opÃ©rations
Write-Host "`nTest 5: Mesure du nombre d'opÃ©rations" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code
$result = Measure-Operations -Name "TestOperations" -ScriptBlock {
    for ($i = 0; $i -lt 100; $i++) {
        Increment-OperationCounter -Name "TestOperations"
    }
    
    return "Test rÃ©ussi"
}

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq "Test rÃ©ussi" -and
           $result.OperationCount -eq 100

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du nombre d'opÃ©rations: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result='Test rÃ©ussi', OperationCount=100" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result='$($result.Result)', OperationCount=$($result.OperationCount)" -ForegroundColor Red
}

# Test 6: Obtenir les statistiques d'opÃ©rations
Write-Host "`nTest 6: Obtenir les statistiques d'opÃ©rations" -ForegroundColor Cyan

# ExÃ©cuter plusieurs mesures
for ($i = 0; $i -lt 3; $i++) {
    $result = Measure-Operations -Name "TestOperationsStats" -ScriptBlock {
        for ($j = 0; $j -lt ($i + 1) * 50; $j++) {
            Increment-OperationCounter -Name "TestOperationsStats"
        }
        
        return "Test rÃ©ussi"
    }
}

# Obtenir les statistiques
$stats = Get-OperationStatistics -Name "TestOperationsStats"

# VÃ©rifier les statistiques
$success = $null -ne $stats -and
           $stats.Count -eq 3 -and
           $stats.MinOperations -gt 0 -and
           $stats.MaxOperations -gt 0 -and
           $stats.AverageOperations -gt 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Statistiques d'opÃ©rations: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=3, MinOperations>0, MaxOperations>0, AverageOperations>0" -ForegroundColor Red
    if ($null -ne $stats) {
        Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinOperations=$($stats.MinOperations), MaxOperations=$($stats.MaxOperations), AverageOperations=$($stats.AverageOperations)" -ForegroundColor Red
    } else {
        Write-Host "    Statistiques obtenues: null" -ForegroundColor Red
    }
}

Write-Host "`nTests complets des fonctions de mesure de performance terminÃ©s." -ForegroundColor Cyan
