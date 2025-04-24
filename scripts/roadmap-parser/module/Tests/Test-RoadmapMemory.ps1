#
# Test-RoadmapMemory.ps1
#
# Script pour tester les fonctions publiques de mesure de mémoire
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
        Write-Warning "La fonction $function est introuvable à l'emplacement : $functionPath"
    }
}

Write-Host "Début des tests des fonctions publiques de mesure de mémoire..." -ForegroundColor Cyan

# Test 1: Vérifier que les fonctions sont définies
Write-Host "`nTest 1: Vérifier que les fonctions sont définies" -ForegroundColor Cyan

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

# Test 2: Tester la fonction Measure-RoadmapMemoryUsage
Write-Host "`nTest 2: Tester la fonction Measure-RoadmapMemoryUsage" -ForegroundColor Cyan

# Mesurer l'utilisation de la mémoire d'un bloc de code
$result = Measure-RoadmapMemoryUsage -Name "TestRoadmapMemory" -ScriptBlock {
    # Allouer de la mémoire
    $memoryHog = @()
    for ($i = 0; $i -lt 1000; $i++) {
        $memoryHog += "X" * 1000
    }

    return "Test réussi"
}

# Vérifier le résultat
$success = $result.Result -eq "Test réussi" -and
$result.MemoryUsedBytes -gt 0 -and
$result.MemoryUsedMB -gt 0

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure de l'utilisation de la mémoire: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result='Test réussi', MemoryUsedBytes>0, MemoryUsedMB>0" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result='$($result.Result)', MemoryUsedBytes=$($result.MemoryUsedBytes), MemoryUsedMB=$($result.MemoryUsedMB)" -ForegroundColor Red
}

# Test 3: Tester la fonction Measure-RoadmapMemoryUsage avec des paramètres
Write-Host "`nTest 3: Tester la fonction Measure-RoadmapMemoryUsage avec des paramètres" -ForegroundColor Cyan

# Mesurer l'utilisation de la mémoire d'un bloc de code avec des paramètres
$result = Measure-RoadmapMemoryUsage -Name "TestRoadmapMemoryWithParams" -ScriptBlock {
    param($size)

    # Allouer de la mémoire
    $memoryHog = @()
    for ($i = 0; $i -lt $size; $i++) {
        $memoryHog += "X" * 100
    }

    return $size
} -ArgumentList 500

# Vérifier le résultat
$success = $result.Result -eq 500 -and
$result.MemoryUsedBytes -gt 0 -and
$result.MemoryUsedMB -gt 0

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure de l'utilisation de la mémoire avec paramètres: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result=500, MemoryUsedBytes>0, MemoryUsedMB>0" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result=$($result.Result), MemoryUsedBytes=$($result.MemoryUsedBytes), MemoryUsedMB=$($result.MemoryUsedMB)" -ForegroundColor Red
}

# Test 4: Tester la fonction Measure-RoadmapMemoryUsage avec pipeline
Write-Host "`nTest 4: Tester la fonction Measure-RoadmapMemoryUsage avec pipeline" -ForegroundColor Cyan

# Mesurer l'utilisation de la mémoire d'un bloc de code avec pipeline
$result = Measure-RoadmapMemoryUsage -Name "TestRoadmapMemoryWithPipeline" -ScriptBlock {
    process {
        # Allouer de la mémoire
        $memoryHog = @()
        for ($i = 0; $i -lt $_; $i++) {
            $memoryHog += "X" * 100
        }

        return $_ * 2
    }
} -InputObject 300

# Vérifier le résultat
$success = $result.Result -eq 600 -and
$result.MemoryUsedBytes -gt 0 -and
$result.MemoryUsedMB -gt 0

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure de l'utilisation de la mémoire avec pipeline: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result=600, MemoryUsedBytes>0, MemoryUsedMB>0" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result=$($result.Result), MemoryUsedBytes=$($result.MemoryUsedBytes), MemoryUsedMB=$($result.MemoryUsedMB)" -ForegroundColor Red
}

# Test 5: Tester la fonction Set-RoadmapMemoryThreshold et Get-RoadmapMemoryStatistics
Write-Host "`nTest 5: Tester la fonction Set-RoadmapMemoryThreshold et Get-RoadmapMemoryStatistics" -ForegroundColor Cyan

# Utiliser le même nom d'instantané que pour le test 2
$thresholdName = "TestRoadmapMemory"

# Définir un seuil
Set-RoadmapMemoryThreshold -Name $thresholdName -ThresholdMB 1

# Exécuter plusieurs mesures
for ($i = 0; $i -lt 3; $i++) {
    $result = Measure-RoadmapMemoryUsage -Name $thresholdName -ScriptBlock {
        param($size)

        # Allouer de la mémoire
        $memoryHog = @()
        for ($j = 0; $j -lt $size; $j++) {
            $memoryHog += "X" * 100
        }

        return $size
    } -ArgumentList (($i + 1) * 100)
}

# Obtenir les statistiques
$stats = Get-RoadmapMemoryStatistics -Name $thresholdName

# Vérifier les statistiques
$success = $null -ne $stats -and
$stats.Count -eq 3 -and
$stats.MinBytes -gt 0 -and
$stats.MaxBytes -gt 0 -and
$stats.AverageBytes -gt 0

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Seuil et statistiques de mémoire: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=3, MinBytes>0, MaxBytes>0, AverageBytes>0" -ForegroundColor Red
    if ($null -ne $stats) {
        Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinBytes=$($stats.MinBytes), MaxBytes=$($stats.MaxBytes), AverageBytes=$($stats.AverageBytes)" -ForegroundColor Red
    } else {
        Write-Host "    Statistiques obtenues: null" -ForegroundColor Red
    }
}

Write-Host "`nTests des fonctions publiques de mesure de mémoire terminés." -ForegroundColor Cyan
