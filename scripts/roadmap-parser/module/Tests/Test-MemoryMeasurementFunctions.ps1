#
# Test-MemoryMeasurementFunctions.ps1
#
# Script pour tester les fonctions de mesure de mémoire
#

# Importer le script des fonctions de mesure de performance
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$performanceFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Performance\PerformanceMeasurementFunctions.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $performanceFunctionsPath)) {
    Write-Error "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable à l'emplacement : $performanceFunctionsPath"
    exit 1
}

# Importer le script
. $performanceFunctionsPath

Write-Host "Début des tests des fonctions de mesure de mémoire..." -ForegroundColor Cyan

# Test 1: Vérifier que les fonctions sont définies
Write-Host "`nTest 1: Vérifier que les fonctions sont définies" -ForegroundColor Cyan

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

# Test 2: Tester la fonction Start-MemorySnapshot
Write-Host "`nTest 2: Tester la fonction Start-MemorySnapshot" -ForegroundColor Cyan

# Démarrer un instantané
$snapshotName = "TestMemorySnapshot"
Start-MemorySnapshot -Name $snapshotName

# Vérifier que l'instantané a été créé
$success = $script:MemorySnapshots.ContainsKey($snapshotName) -and
$null -ne $script:MemorySnapshots[$snapshotName].StartMemory -and
$null -eq $script:MemorySnapshots[$snapshotName].EndMemory

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Démarrage d'un instantané: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Instantané attendu: Nom=$snapshotName, StartMemory!=null, EndMemory=null" -ForegroundColor Red
    if ($script:MemorySnapshots.ContainsKey($snapshotName)) {
        Write-Host "    Instantané obtenu: Nom=$snapshotName, StartMemory=$($script:MemorySnapshots[$snapshotName].StartMemory), EndMemory=$($script:MemorySnapshots[$snapshotName].EndMemory)" -ForegroundColor Red
    } else {
        Write-Host "    Instantané obtenu: Non créé" -ForegroundColor Red
    }
}

# Test 3: Tester la fonction Stop-MemorySnapshot
Write-Host "`nTest 3: Tester la fonction Stop-MemorySnapshot" -ForegroundColor Cyan

# Allouer de la mémoire
$memoryHog = @()
for ($i = 0; $i -lt 1000; $i++) {
    $memoryHog += "X" * 1000
}

# Arrêter l'instantané
$memoryUsed = Stop-MemorySnapshot -Name $snapshotName

# Vérifier que l'instantané a été arrêté
$success = $script:MemorySnapshots.ContainsKey($snapshotName) -and
$null -ne $script:MemorySnapshots[$snapshotName].StartMemory -and
$null -ne $script:MemorySnapshots[$snapshotName].EndMemory -and
$null -ne $script:MemorySnapshots[$snapshotName].MemoryUsed -and
$memoryUsed -eq $script:MemorySnapshots[$snapshotName].MemoryUsed

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Arrêt d'un instantané: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Instantané attendu: Nom=$snapshotName, StartMemory!=null, EndMemory!=null, MemoryUsed!=null" -ForegroundColor Red
    if ($script:MemorySnapshots.ContainsKey($snapshotName)) {
        Write-Host "    Instantané obtenu: Nom=$snapshotName, StartMemory=$($script:MemorySnapshots[$snapshotName].StartMemory), EndMemory=$($script:MemorySnapshots[$snapshotName].EndMemory), MemoryUsed=$($script:MemorySnapshots[$snapshotName].MemoryUsed)" -ForegroundColor Red
    } else {
        Write-Host "    Instantané obtenu: Non créé" -ForegroundColor Red
    }
}

# Test 4: Tester la fonction Reset-MemorySnapshot
Write-Host "`nTest 4: Tester la fonction Reset-MemorySnapshot" -ForegroundColor Cyan

# Réinitialiser l'instantané
Reset-MemorySnapshot -Name $snapshotName

# Vérifier que l'instantané a été réinitialisé
$success = $script:MemorySnapshots.ContainsKey($snapshotName) -and
$null -ne $script:MemorySnapshots[$snapshotName].StartMemory -and
$null -eq $script:MemorySnapshots[$snapshotName].EndMemory

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Réinitialisation d'un instantané: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Instantané attendu: Nom=$snapshotName, StartMemory!=null, EndMemory=null" -ForegroundColor Red
    if ($script:MemorySnapshots.ContainsKey($snapshotName)) {
        Write-Host "    Instantané obtenu: Nom=$snapshotName, StartMemory=$($script:MemorySnapshots[$snapshotName].StartMemory), EndMemory=$($script:MemorySnapshots[$snapshotName].EndMemory)" -ForegroundColor Red
    } else {
        Write-Host "    Instantané obtenu: Non créé" -ForegroundColor Red
    }
}

# Test 5: Tester la fonction Get-MemoryStatistics
Write-Host "`nTest 5: Tester la fonction Get-MemoryStatistics" -ForegroundColor Cyan

# Exécuter plusieurs mesures
for ($i = 0; $i -lt 5; $i++) {
    Start-MemorySnapshot -Name $snapshotName

    # Allouer de la mémoire
    $memoryHog = @()
    for ($j = 0; $j -lt ($i + 1) * 100; $j++) {
        $memoryHog += "X" * 100
    }

    Stop-MemorySnapshot -Name $snapshotName
}

# Obtenir les statistiques
$stats = Get-MemoryStatistics -Name $snapshotName

# Vérifier les statistiques
$success = $stats.Count -eq 6 -and
$stats.MinBytes -gt 0 -and
$stats.MaxBytes -gt 0 -and
$stats.AverageBytes -gt 0

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Statistiques de mémoire: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=6, MinBytes>0, MaxBytes>0, AverageBytes>0" -ForegroundColor Red
    Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinBytes=$($stats.MinBytes), MaxBytes=$($stats.MaxBytes), AverageBytes=$($stats.AverageBytes)" -ForegroundColor Red
}

# Test 6: Tester la fonction Set-MemoryThreshold
Write-Host "`nTest 6: Tester la fonction Set-MemoryThreshold" -ForegroundColor Cyan

# Définir un seuil
Set-MemoryThreshold -Name $snapshotName -ThresholdMB 1

# Vérifier que le seuil a été défini
$success = $script:MemoryThresholds.ContainsKey($snapshotName) -and
$script:MemoryThresholds[$snapshotName] -eq 1MB

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Définition d'un seuil: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Seuil attendu: Nom=$snapshotName, Seuil=1MB" -ForegroundColor Red
    if ($script:MemoryThresholds.ContainsKey($snapshotName)) {
        Write-Host "    Seuil obtenu: Nom=$snapshotName, Seuil=$($script:MemoryThresholds[$snapshotName] / 1MB)MB" -ForegroundColor Red
    } else {
        Write-Host "    Seuil obtenu: Non défini" -ForegroundColor Red
    }
}

# Test 7: Tester la fonction Measure-MemoryUsage
Write-Host "`nTest 7: Tester la fonction Measure-MemoryUsage" -ForegroundColor Cyan

# Mesurer l'utilisation de la mémoire d'un bloc de code
$result = Measure-MemoryUsage -Name "TestMeasureMemory" -ScriptBlock {
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

# Test 8: Tester la fonction Measure-MemoryUsage avec des paramètres
Write-Host "`nTest 8: Tester la fonction Measure-MemoryUsage avec des paramètres" -ForegroundColor Cyan

# Mesurer l'utilisation de la mémoire d'un bloc de code avec des paramètres
$result = Measure-MemoryUsage -Name "TestMeasureMemoryWithParams" -ScriptBlock {
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

# Test 9: Tester la fonction Measure-MemoryUsage avec pipeline
Write-Host "`nTest 9: Tester la fonction Measure-MemoryUsage avec pipeline" -ForegroundColor Cyan

# Mesurer l'utilisation de la mémoire d'un bloc de code avec pipeline
$result = Measure-MemoryUsage -Name "TestMeasureMemoryWithPipeline" -ScriptBlock {
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

# Test 10: Tester la fonction Measure-MemoryUsage avec ForceGC
Write-Host "`nTest 10: Tester la fonction Measure-MemoryUsage avec ForceGC" -ForegroundColor Cyan

# Mesurer l'utilisation de la mémoire d'un bloc de code avec ForceGC
$result = Measure-MemoryUsage -Name "TestMeasureMemoryWithForceGC" -ScriptBlock {
    # Allouer de la mémoire
    $memoryHog = @()
    for ($i = 0; $i -lt 1000; $i++) {
        $memoryHog += "X" * 1000
    }

    return "Test réussi"
} -ForceGC

# Vérifier le résultat
$success = $result.Result -eq "Test réussi" -and
$result.MemoryUsedBytes -ge 0 -and
$result.MemoryUsedMB -ge 0

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure de l'utilisation de la mémoire avec ForceGC: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result='Test réussi', MemoryUsedBytes>=0, MemoryUsedMB>=0" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result='$($result.Result)', MemoryUsedBytes=$($result.MemoryUsedBytes), MemoryUsedMB=$($result.MemoryUsedMB)" -ForegroundColor Red
}

Write-Host "`nTests des fonctions de mesure de mémoire terminés." -ForegroundColor Cyan
