#
# Test-OperationsVerySimple.ps1
#
# Script pour tester les fonctions de comptage d'opÃ©rations de maniÃ¨re trÃ¨s simple
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

Write-Host "DÃ©but des tests trÃ¨s simples de comptage d'opÃ©rations..." -ForegroundColor Cyan

# Test 1: Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code
Write-Host "`nTest 1: Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code
$result = Measure-RoadmapOperations -Name "TestVerySimpleOperations" -ScriptBlock {
    for ($i = 0; $i -lt 10; $i++) {
        Add-RoadmapOperationCount -Name "TestVerySimpleOperations"
    }
    
    return "Test rÃ©ussi"
}

# Afficher le rÃ©sultat
Write-Host "  RÃ©sultat: $($result.Result)" -ForegroundColor Cyan
Write-Host "  Nombre d'opÃ©rations: $($result.OperationCount)" -ForegroundColor Cyan

Write-Host "`nTests trÃ¨s simples de comptage d'opÃ©rations terminÃ©s." -ForegroundColor Cyan
