#
# Test-PerformanceSimple.ps1
#
# Script pour tester les fonctions de mesure de performance de manière simple
#

# Importer les fonctions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$publicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"
$measurePath = Join-Path -Path $publicPath -ChildPath "Measure-RoadmapExecutionTime.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $measurePath)) {
    Write-Error "Le fichier Measure-RoadmapExecutionTime.ps1 est introuvable à l'emplacement : $measurePath"
    exit 1
}

# Importer la fonction
. $measurePath

Write-Host "Début des tests simples de mesure de performance..." -ForegroundColor Cyan

# Test 1: Mesurer le temps d'exécution d'un bloc de code
Write-Host "`nTest 1: Mesurer le temps d'exécution d'un bloc de code" -ForegroundColor Cyan

# Mesurer le temps d'exécution d'un bloc de code
$result = Measure-RoadmapExecutionTime -Name "TestSimple" -ScriptBlock {
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

# Test 2: Mesurer le temps d'exécution d'un bloc de code avec des paramètres
Write-Host "`nTest 2: Mesurer le temps d'exécution d'un bloc de code avec des paramètres" -ForegroundColor Cyan

# Mesurer le temps d'exécution d'un bloc de code avec des paramètres
$result = Measure-RoadmapExecutionTime -Name "TestSimpleWithParams" -ScriptBlock {
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

# Test 3: Mesurer le temps d'exécution d'un bloc de code avec pipeline
Write-Host "`nTest 3: Mesurer le temps d'exécution d'un bloc de code avec pipeline" -ForegroundColor Cyan

# Mesurer le temps d'exécution d'un bloc de code avec pipeline
$result = Measure-RoadmapExecutionTime -Name "TestSimpleWithPipeline" -ScriptBlock {
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

Write-Host "`nTests simples de mesure de performance terminés." -ForegroundColor Cyan
