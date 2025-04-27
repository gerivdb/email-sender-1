#
# Test-OperationsSimple.ps1
#
# Script pour tester les fonctions de comptage d'opÃ©rations de maniÃ¨re simple
#

# Importer les fonctions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$publicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"
$measurePath = Join-Path -Path $publicPath -ChildPath "Measure-RoadmapOperations.ps1"
$addPath = Join-Path -Path $publicPath -ChildPath "Add-RoadmapOperationCount.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $measurePath)) {
    Write-Error "Le fichier Measure-RoadmapOperations.ps1 est introuvable Ã  l'emplacement : $measurePath"
    exit 1
}

if (-not (Test-Path -Path $addPath)) {
    Write-Error "Le fichier Add-RoadmapOperationCount.ps1 est introuvable Ã  l'emplacement : $addPath"
    exit 1
}

# Importer les fonctions
. $measurePath
. $addPath

Write-Host "DÃ©but des tests simples de comptage d'opÃ©rations..." -ForegroundColor Cyan

# Test 1: Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code
Write-Host "`nTest 1: Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code
$result = Measure-RoadmapOperations -Name "TestSimpleOperations" -ScriptBlock {
    for ($i = 0; $i -lt 100; $i++) {
        Add-RoadmapOperationCount -Name "TestSimpleOperations"
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

# Test 2: Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code avec des paramÃ¨tres
Write-Host "`nTest 2: Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code avec des paramÃ¨tres" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code avec des paramÃ¨tres
$result = Measure-RoadmapOperations -Name "TestSimpleOperationsWithParams" -ScriptBlock {
    param($count)
    
    for ($i = 0; $i -lt $count; $i++) {
        Add-RoadmapOperationCount -Name "TestSimpleOperationsWithParams"
    }
    
    return $count
} -ArgumentList 50

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq 50 -and
           $result.OperationCount -eq 50

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du nombre d'opÃ©rations avec paramÃ¨tres: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result=50, OperationCount=50" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result=$($result.Result), OperationCount=$($result.OperationCount)" -ForegroundColor Red
}

# Test 3: Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code avec pipeline
Write-Host "`nTest 3: Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code avec pipeline" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code avec pipeline
$result = Measure-RoadmapOperations -Name "TestSimpleOperationsWithPipeline" -ScriptBlock {
    process {
        for ($i = 0; $i -lt $_; $i++) {
            Add-RoadmapOperationCount -Name "TestSimpleOperationsWithPipeline"
        }
        
        return $_ * 2
    }
} -InputObject 30

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq 60 -and
           $result.OperationCount -eq 30

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du nombre d'opÃ©rations avec pipeline: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result=60, OperationCount=30" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result=$($result.Result), OperationCount=$($result.OperationCount)" -ForegroundColor Red
}

Write-Host "`nTests simples de comptage d'opÃ©rations terminÃ©s." -ForegroundColor Cyan
