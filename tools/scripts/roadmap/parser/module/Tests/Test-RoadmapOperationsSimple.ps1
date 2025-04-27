#
# Test-RoadmapOperationsSimple.ps1
#
# Script pour tester la fonction Measure-RoadmapOperations de maniÃ¨re simple
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

Write-Host "DÃ©but du test simple de la fonction Measure-RoadmapOperations..." -ForegroundColor Cyan

# Test : Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code
Write-Host "`nTest : Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code
$result = Measure-RoadmapOperations -Name "TestRoadmapMeasureOperationsSimple" -ScriptBlock {
    for ($i = 0; $i -lt 10; $i++) {
        Add-RoadmapOperationCount -Name "TestRoadmapMeasureOperationsSimple"
    }
    
    return "Test rÃ©ussi"
}

# Afficher le rÃ©sultat
Write-Host "  RÃ©sultat: $($result.Result)" -ForegroundColor Cyan
Write-Host "  Nombre d'opÃ©rations: $($result.OperationCount)" -ForegroundColor Cyan

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq "Test rÃ©ussi" -and
           $result.OperationCount -eq 10

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Test: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result='Test rÃ©ussi', OperationCount=10" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result='$($result.Result)', OperationCount=$($result.OperationCount)" -ForegroundColor Red
}

Write-Host "`nTest simple de la fonction Measure-RoadmapOperations terminÃ©." -ForegroundColor Cyan
