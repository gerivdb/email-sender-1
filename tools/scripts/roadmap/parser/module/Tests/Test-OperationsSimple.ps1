#
# Test-OperationsSimple.ps1
#
# Script pour tester les fonctions de comptage d'opérations de manière simple
#

# Importer les fonctions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$publicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"
$measurePath = Join-Path -Path $publicPath -ChildPath "Measure-RoadmapOperations.ps1"
$addPath = Join-Path -Path $publicPath -ChildPath "Add-RoadmapOperationCount.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $measurePath)) {
    Write-Error "Le fichier Measure-RoadmapOperations.ps1 est introuvable à l'emplacement : $measurePath"
    exit 1
}

if (-not (Test-Path -Path $addPath)) {
    Write-Error "Le fichier Add-RoadmapOperationCount.ps1 est introuvable à l'emplacement : $addPath"
    exit 1
}

# Importer les fonctions
. $measurePath
. $addPath

Write-Host "Début des tests simples de comptage d'opérations..." -ForegroundColor Cyan

# Test 1: Mesurer le nombre d'opérations effectuées par un bloc de code
Write-Host "`nTest 1: Mesurer le nombre d'opérations effectuées par un bloc de code" -ForegroundColor Cyan

# Mesurer le nombre d'opérations effectuées par un bloc de code
$result = Measure-RoadmapOperations -Name "TestSimpleOperations" -ScriptBlock {
    for ($i = 0; $i -lt 100; $i++) {
        Add-RoadmapOperationCount -Name "TestSimpleOperations"
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

# Test 2: Mesurer le nombre d'opérations effectuées par un bloc de code avec des paramètres
Write-Host "`nTest 2: Mesurer le nombre d'opérations effectuées par un bloc de code avec des paramètres" -ForegroundColor Cyan

# Mesurer le nombre d'opérations effectuées par un bloc de code avec des paramètres
$result = Measure-RoadmapOperations -Name "TestSimpleOperationsWithParams" -ScriptBlock {
    param($count)
    
    for ($i = 0; $i -lt $count; $i++) {
        Add-RoadmapOperationCount -Name "TestSimpleOperationsWithParams"
    }
    
    return $count
} -ArgumentList 50

# Vérifier le résultat
$success = $result.Result -eq 50 -and
           $result.OperationCount -eq 50

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du nombre d'opérations avec paramètres: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result=50, OperationCount=50" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result=$($result.Result), OperationCount=$($result.OperationCount)" -ForegroundColor Red
}

# Test 3: Mesurer le nombre d'opérations effectuées par un bloc de code avec pipeline
Write-Host "`nTest 3: Mesurer le nombre d'opérations effectuées par un bloc de code avec pipeline" -ForegroundColor Cyan

# Mesurer le nombre d'opérations effectuées par un bloc de code avec pipeline
$result = Measure-RoadmapOperations -Name "TestSimpleOperationsWithPipeline" -ScriptBlock {
    process {
        for ($i = 0; $i -lt $_; $i++) {
            Add-RoadmapOperationCount -Name "TestSimpleOperationsWithPipeline"
        }
        
        return $_ * 2
    }
} -InputObject 30

# Vérifier le résultat
$success = $result.Result -eq 60 -and
           $result.OperationCount -eq 30

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du nombre d'opérations avec pipeline: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Result=60, OperationCount=30" -ForegroundColor Red
    Write-Host "    Résultat obtenu: Result=$($result.Result), OperationCount=$($result.OperationCount)" -ForegroundColor Red
}

Write-Host "`nTests simples de comptage d'opérations terminés." -ForegroundColor Cyan
