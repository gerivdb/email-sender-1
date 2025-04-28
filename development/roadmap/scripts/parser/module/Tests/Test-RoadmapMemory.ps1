#
# Test-RoadmapMemory.ps1
#
# Script pour tester les fonctions publiques de mesure de mÃ©moire
#

# Importer le module RoadmapParser
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$publicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"

# Importer les fonctions publiques
$publicFunctions = @(
    "Measure-RoadmapMemoryUsage.ps1",
    "Get-RoadmapMemoryStatistics.ps1",
    "Set-RoadmapMemoryThreshold.ps1"
)

foreach ($function in $publicFunctions) {
    $functionPath = Join-Path -Path $publicPath -ChildPath $function
    if (Test-Path -Path $functionPath) {
        . $functionPath
    } else {
        Write-Warning "La fonction $function est introuvable Ã  l'emplacement : $functionPath"
    }
}

Write-Host "DÃ©but des tests des fonctions publiques de mesure de mÃ©moire..." -ForegroundColor Cyan

# Test 1: VÃ©rifier que les fonctions sont dÃ©finies
Write-Host "`nTest 1: VÃ©rifier que les fonctions sont dÃ©finies" -ForegroundColor Cyan

$functions = @(
    "Measure-RoadmapMemoryUsage",
    "Get-RoadmapMemoryStatistics",
    "Set-RoadmapMemoryThreshold"
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

# Test 2: Tester la fonction Measure-RoadmapMemoryUsage
Write-Host "`nTest 2: Tester la fonction Measure-RoadmapMemoryUsage" -ForegroundColor Cyan

# Mesurer l'utilisation de la mÃ©moire d'un bloc de code
$result = Measure-RoadmapMemoryUsage -Name "TestRoadmapMemory" -ScriptBlock {
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

# Test 3: Tester la fonction Measure-RoadmapMemoryUsage avec des paramÃ¨tres
Write-Host "`nTest 3: Tester la fonction Measure-RoadmapMemoryUsage avec des paramÃ¨tres" -ForegroundColor Cyan

# Mesurer l'utilisation de la mÃ©moire d'un bloc de code avec des paramÃ¨tres
$result = Measure-RoadmapMemoryUsage -Name "TestRoadmapMemoryWithParams" -ScriptBlock {
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

# Test 4: Tester la fonction Measure-RoadmapMemoryUsage avec pipeline
Write-Host "`nTest 4: Tester la fonction Measure-RoadmapMemoryUsage avec pipeline" -ForegroundColor Cyan

# Mesurer l'utilisation de la mÃ©moire d'un bloc de code avec pipeline
$result = Measure-RoadmapMemoryUsage -Name "TestRoadmapMemoryWithPipeline" -ScriptBlock {
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

# Test 5: Tester la fonction Set-RoadmapMemoryThreshold et Get-RoadmapMemoryStatistics
Write-Host "`nTest 5: Tester la fonction Set-RoadmapMemoryThreshold et Get-RoadmapMemoryStatistics" -ForegroundColor Cyan

# Utiliser le mÃªme nom d'instantanÃ© que pour le test 2
$thresholdName = "TestRoadmapMemory"

# DÃ©finir un seuil
Set-RoadmapMemoryThreshold -Name $thresholdName -ThresholdMB 1

# ExÃ©cuter plusieurs mesures
for ($i = 0; $i -lt 3; $i++) {
    $result = Measure-RoadmapMemoryUsage -Name $thresholdName -ScriptBlock {
        param($size)

        # Allouer de la mÃ©moire
        $memoryHog = @()
        for ($j = 0; $j -lt $size; $j++) {
            $memoryHog += "X" * 100
        }

        return $size
    } -ArgumentList (($i + 1) * 100)
}

# Obtenir les statistiques
$stats = Get-RoadmapMemoryStatistics -Name $thresholdName

# VÃ©rifier les statistiques
$success = $null -ne $stats -and
$stats.Count -eq 3 -and
$stats.MinBytes -gt 0 -and
$stats.MaxBytes -gt 0 -and
$stats.AverageBytes -gt 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Seuil et statistiques de mÃ©moire: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=3, MinBytes>0, MaxBytes>0, AverageBytes>0" -ForegroundColor Red
    if ($null -ne $stats) {
        Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinBytes=$($stats.MinBytes), MaxBytes=$($stats.MaxBytes), AverageBytes=$($stats.AverageBytes)" -ForegroundColor Red
    } else {
        Write-Host "    Statistiques obtenues: null" -ForegroundColor Red
    }
}

Write-Host "`nTests des fonctions publiques de mesure de mÃ©moire terminÃ©s." -ForegroundColor Cyan
