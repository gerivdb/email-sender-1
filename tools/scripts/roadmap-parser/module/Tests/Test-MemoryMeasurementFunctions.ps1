#
# Test-MemoryMeasurementFunctions.ps1
#
# Script pour tester les fonctions de mesure de mÃ©moire
#

# Importer le script des fonctions de mesure de performance
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$performanceFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Performance\PerformanceMeasurementFunctions.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $performanceFunctionsPath)) {
    Write-Error "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable Ã  l'emplacement : $performanceFunctionsPath"
    exit 1
}

# Importer le script
. $performanceFunctionsPath

Write-Host "DÃ©but des tests des fonctions de mesure de mÃ©moire..." -ForegroundColor Cyan

# Test 1: VÃ©rifier que les fonctions sont dÃ©finies
Write-Host "`nTest 1: VÃ©rifier que les fonctions sont dÃ©finies" -ForegroundColor Cyan

$functions = @(
    "Start-MemorySnapshot",
    "Stop-MemorySnapshot",
    "Reset-MemorySnapshot",
    "Get-MemoryStatistics",
    "Set-MemoryThreshold",
    "Measure-MemoryUsage"
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

# Test 2: Tester la fonction Start-MemorySnapshot
Write-Host "`nTest 2: Tester la fonction Start-MemorySnapshot" -ForegroundColor Cyan

# DÃ©marrer un instantanÃ©
$snapshotName = "TestMemorySnapshot"
Start-MemorySnapshot -Name $snapshotName

# VÃ©rifier que l'instantanÃ© a Ã©tÃ© crÃ©Ã©
$success = $script:MemorySnapshots.ContainsKey($snapshotName) -and
$null -ne $script:MemorySnapshots[$snapshotName].StartMemory -and
$null -eq $script:MemorySnapshots[$snapshotName].EndMemory

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  DÃ©marrage d'un instantanÃ©: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    InstantanÃ© attendu: Nom=$snapshotName, StartMemory!=null, EndMemory=null" -ForegroundColor Red
    if ($script:MemorySnapshots.ContainsKey($snapshotName)) {
        Write-Host "    InstantanÃ© obtenu: Nom=$snapshotName, StartMemory=$($script:MemorySnapshots[$snapshotName].StartMemory), EndMemory=$($script:MemorySnapshots[$snapshotName].EndMemory)" -ForegroundColor Red
    } else {
        Write-Host "    InstantanÃ© obtenu: Non crÃ©Ã©" -ForegroundColor Red
    }
}

# Test 3: Tester la fonction Stop-MemorySnapshot
Write-Host "`nTest 3: Tester la fonction Stop-MemorySnapshot" -ForegroundColor Cyan

# Allouer de la mÃ©moire
$memoryHog = @()
for ($i = 0; $i -lt 1000; $i++) {
    $memoryHog += "X" * 1000
}

# ArrÃªter l'instantanÃ©
$memoryUsed = Stop-MemorySnapshot -Name $snapshotName

# VÃ©rifier que l'instantanÃ© a Ã©tÃ© arrÃªtÃ©
$success = $script:MemorySnapshots.ContainsKey($snapshotName) -and
$null -ne $script:MemorySnapshots[$snapshotName].StartMemory -and
$null -ne $script:MemorySnapshots[$snapshotName].EndMemory -and
$null -ne $script:MemorySnapshots[$snapshotName].MemoryUsed -and
$memoryUsed -eq $script:MemorySnapshots[$snapshotName].MemoryUsed

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  ArrÃªt d'un instantanÃ©: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    InstantanÃ© attendu: Nom=$snapshotName, StartMemory!=null, EndMemory!=null, MemoryUsed!=null" -ForegroundColor Red
    if ($script:MemorySnapshots.ContainsKey($snapshotName)) {
        Write-Host "    InstantanÃ© obtenu: Nom=$snapshotName, StartMemory=$($script:MemorySnapshots[$snapshotName].StartMemory), EndMemory=$($script:MemorySnapshots[$snapshotName].EndMemory), MemoryUsed=$($script:MemorySnapshots[$snapshotName].MemoryUsed)" -ForegroundColor Red
    } else {
        Write-Host "    InstantanÃ© obtenu: Non crÃ©Ã©" -ForegroundColor Red
    }
}

# Test 4: Tester la fonction Reset-MemorySnapshot
Write-Host "`nTest 4: Tester la fonction Reset-MemorySnapshot" -ForegroundColor Cyan

# RÃ©initialiser l'instantanÃ©
Reset-MemorySnapshot -Name $snapshotName

# VÃ©rifier que l'instantanÃ© a Ã©tÃ© rÃ©initialisÃ©
$success = $script:MemorySnapshots.ContainsKey($snapshotName) -and
$null -ne $script:MemorySnapshots[$snapshotName].StartMemory -and
$null -eq $script:MemorySnapshots[$snapshotName].EndMemory

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  RÃ©initialisation d'un instantanÃ©: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    InstantanÃ© attendu: Nom=$snapshotName, StartMemory!=null, EndMemory=null" -ForegroundColor Red
    if ($script:MemorySnapshots.ContainsKey($snapshotName)) {
        Write-Host "    InstantanÃ© obtenu: Nom=$snapshotName, StartMemory=$($script:MemorySnapshots[$snapshotName].StartMemory), EndMemory=$($script:MemorySnapshots[$snapshotName].EndMemory)" -ForegroundColor Red
    } else {
        Write-Host "    InstantanÃ© obtenu: Non crÃ©Ã©" -ForegroundColor Red
    }
}

# Test 5: Tester la fonction Get-MemoryStatistics
Write-Host "`nTest 5: Tester la fonction Get-MemoryStatistics" -ForegroundColor Cyan

# ExÃ©cuter plusieurs mesures
for ($i = 0; $i -lt 5; $i++) {
    Start-MemorySnapshot -Name $snapshotName

    # Allouer de la mÃ©moire
    $memoryHog = @()
    for ($j = 0; $j -lt ($i + 1) * 100; $j++) {
        $memoryHog += "X" * 100
    }

    Stop-MemorySnapshot -Name $snapshotName
}

# Obtenir les statistiques
$stats = Get-MemoryStatistics -Name $snapshotName

# VÃ©rifier les statistiques
$success = $stats.Count -eq 6 -and
$stats.MinBytes -gt 0 -and
$stats.MaxBytes -gt 0 -and
$stats.AverageBytes -gt 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Statistiques de mÃ©moire: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=6, MinBytes>0, MaxBytes>0, AverageBytes>0" -ForegroundColor Red
    Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinBytes=$($stats.MinBytes), MaxBytes=$($stats.MaxBytes), AverageBytes=$($stats.AverageBytes)" -ForegroundColor Red
}

# Test 6: Tester la fonction Set-MemoryThreshold
Write-Host "`nTest 6: Tester la fonction Set-MemoryThreshold" -ForegroundColor Cyan

# DÃ©finir un seuil
Set-MemoryThreshold -Name $snapshotName -ThresholdMB 1

# VÃ©rifier que le seuil a Ã©tÃ© dÃ©fini
$success = $script:MemoryThresholds.ContainsKey($snapshotName) -and
$script:MemoryThresholds[$snapshotName] -eq 1MB

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  DÃ©finition d'un seuil: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Seuil attendu: Nom=$snapshotName, Seuil=1MB" -ForegroundColor Red
    if ($script:MemoryThresholds.ContainsKey($snapshotName)) {
        Write-Host "    Seuil obtenu: Nom=$snapshotName, Seuil=$($script:MemoryThresholds[$snapshotName] / 1MB)MB" -ForegroundColor Red
    } else {
        Write-Host "    Seuil obtenu: Non dÃ©fini" -ForegroundColor Red
    }
}

# Test 7: Tester la fonction Measure-MemoryUsage
Write-Host "`nTest 7: Tester la fonction Measure-MemoryUsage" -ForegroundColor Cyan

# Mesurer l'utilisation de la mÃ©moire d'un bloc de code
$result = Measure-MemoryUsage -Name "TestMeasureMemory" -ScriptBlock {
    # Allouer de la mÃ©moire
    $memoryHog = @()
    for ($i = 0; $i -lt 1000; $i++) {
        $memoryHog += "X" * 1000
    }

    return "Test rÃ©ussi"
}

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq "Test rÃ©ussi" -and
$result.MemoryUsedBytes -gt 0 -and
$result.MemoryUsedMB -gt 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure de l'utilisation de la mÃ©moire: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result='Test rÃ©ussi', MemoryUsedBytes>0, MemoryUsedMB>0" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result='$($result.Result)', MemoryUsedBytes=$($result.MemoryUsedBytes), MemoryUsedMB=$($result.MemoryUsedMB)" -ForegroundColor Red
}

# Test 8: Tester la fonction Measure-MemoryUsage avec des paramÃ¨tres
Write-Host "`nTest 8: Tester la fonction Measure-MemoryUsage avec des paramÃ¨tres" -ForegroundColor Cyan

# Mesurer l'utilisation de la mÃ©moire d'un bloc de code avec des paramÃ¨tres
$result = Measure-MemoryUsage -Name "TestMeasureMemoryWithParams" -ScriptBlock {
    param($size)

    # Allouer de la mÃ©moire
    $memoryHog = @()
    for ($i = 0; $i -lt $size; $i++) {
        $memoryHog += "X" * 100
    }

    return $size
} -ArgumentList 500

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq 500 -and
$result.MemoryUsedBytes -gt 0 -and
$result.MemoryUsedMB -gt 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure de l'utilisation de la mÃ©moire avec paramÃ¨tres: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result=500, MemoryUsedBytes>0, MemoryUsedMB>0" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result=$($result.Result), MemoryUsedBytes=$($result.MemoryUsedBytes), MemoryUsedMB=$($result.MemoryUsedMB)" -ForegroundColor Red
}

# Test 9: Tester la fonction Measure-MemoryUsage avec pipeline
Write-Host "`nTest 9: Tester la fonction Measure-MemoryUsage avec pipeline" -ForegroundColor Cyan

# Mesurer l'utilisation de la mÃ©moire d'un bloc de code avec pipeline
$result = Measure-MemoryUsage -Name "TestMeasureMemoryWithPipeline" -ScriptBlock {
    process {
        # Allouer de la mÃ©moire
        $memoryHog = @()
        for ($i = 0; $i -lt $_; $i++) {
            $memoryHog += "X" * 100
        }

        return $_ * 2
    }
} -InputObject 300

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq 600 -and
$result.MemoryUsedBytes -gt 0 -and
$result.MemoryUsedMB -gt 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure de l'utilisation de la mÃ©moire avec pipeline: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result=600, MemoryUsedBytes>0, MemoryUsedMB>0" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result=$($result.Result), MemoryUsedBytes=$($result.MemoryUsedBytes), MemoryUsedMB=$($result.MemoryUsedMB)" -ForegroundColor Red
}

# Test 10: Tester la fonction Measure-MemoryUsage avec ForceGC
Write-Host "`nTest 10: Tester la fonction Measure-MemoryUsage avec ForceGC" -ForegroundColor Cyan

# Mesurer l'utilisation de la mÃ©moire d'un bloc de code avec ForceGC
$result = Measure-MemoryUsage -Name "TestMeasureMemoryWithForceGC" -ScriptBlock {
    # Allouer de la mÃ©moire
    $memoryHog = @()
    for ($i = 0; $i -lt 1000; $i++) {
        $memoryHog += "X" * 1000
    }

    return "Test rÃ©ussi"
} -ForceGC

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq "Test rÃ©ussi" -and
$result.MemoryUsedBytes -ge 0 -and
$result.MemoryUsedMB -ge 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure de l'utilisation de la mÃ©moire avec ForceGC: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result='Test rÃ©ussi', MemoryUsedBytes>=0, MemoryUsedMB>=0" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result='$($result.Result)', MemoryUsedBytes=$($result.MemoryUsedBytes), MemoryUsedMB=$($result.MemoryUsedMB)" -ForegroundColor Red
}

Write-Host "`nTests des fonctions de mesure de mÃ©moire terminÃ©s." -ForegroundColor Cyan
