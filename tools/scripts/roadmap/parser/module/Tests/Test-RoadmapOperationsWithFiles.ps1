#
# Test-RoadmapOperationsWithFiles.ps1
#
# Script pour tester les fonctions publiques de comptage d'opÃ©rations avec les fichiers temporaires
#

# Importer le module RoadmapParser
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$publicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"

# Importer les fonctions publiques
$publicFunctions = @(
    "Measure-RoadmapOperations.ps1",
    "Add-RoadmapOperationCount.ps1",
    "Reset-RoadmapOperationCounter.ps1",
    "Get-RoadmapOperationCounter.ps1",
    "Get-RoadmapOperationStatistics.ps1",
    "Set-RoadmapOperationThreshold.ps1"
)

foreach ($function in $publicFunctions) {
    $functionPath = Join-Path -Path $publicPath -ChildPath $function
    if (Test-Path -Path $functionPath) {
        . $functionPath
    } else {
        Write-Warning "La fonction $function est introuvable Ã  l'emplacement : $functionPath"
    }
}

Write-Host "DÃ©but des tests des fonctions publiques de comptage d'opÃ©rations avec les fichiers temporaires..." -ForegroundColor Cyan

# Test 1: VÃ©rifier que les fonctions sont dÃ©finies
Write-Host "`nTest 1: VÃ©rifier que les fonctions sont dÃ©finies" -ForegroundColor Cyan

$functions = @(
    "Measure-RoadmapOperations",
    "Add-RoadmapOperationCount",
    "Reset-RoadmapOperationCounter",
    "Get-RoadmapOperationCounter",
    "Get-RoadmapOperationStatistics",
    "Set-RoadmapOperationThreshold"
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

# Test 2: Tester la fonction Add-RoadmapOperationCount
Write-Host "`nTest 2: Tester la fonction Add-RoadmapOperationCount" -ForegroundColor Cyan

# IncrÃ©menter un compteur
$counterName = "TestRoadmapOperationCounterWithFiles"
$newValue = Add-RoadmapOperationCount -Name $counterName

# VÃ©rifier le rÃ©sultat
$success = $newValue -eq 1

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  IncrÃ©mentation d'un compteur: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Valeur attendue: 1" -ForegroundColor Red
    Write-Host "    Valeur obtenue: $newValue" -ForegroundColor Red
}

# Test 3: Tester la fonction Add-RoadmapOperationCount avec IncrementBy
Write-Host "`nTest 3: Tester la fonction Add-RoadmapOperationCount avec IncrementBy" -ForegroundColor Cyan

# IncrÃ©menter un compteur de 5
$newValue = Add-RoadmapOperationCount -Name $counterName -IncrementBy 5

# VÃ©rifier le rÃ©sultat
$success = $newValue -eq 6

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  IncrÃ©mentation d'un compteur avec IncrementBy: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Valeur attendue: 6" -ForegroundColor Red
    Write-Host "    Valeur obtenue: $newValue" -ForegroundColor Red
}

# Test 4: Tester la fonction Get-RoadmapOperationCounter
Write-Host "`nTest 4: Tester la fonction Get-RoadmapOperationCounter" -ForegroundColor Cyan

# Obtenir la valeur du compteur
$value = Get-RoadmapOperationCounter -Name $counterName

# VÃ©rifier le rÃ©sultat
$success = $value -eq 6

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Obtention de la valeur d'un compteur: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Valeur attendue: 6" -ForegroundColor Red
    Write-Host "    Valeur obtenue: $value" -ForegroundColor Red
}

# Test 5: Tester la fonction Reset-RoadmapOperationCounter
Write-Host "`nTest 5: Tester la fonction Reset-RoadmapOperationCounter" -ForegroundColor Cyan

# RÃ©initialiser le compteur
$previousValue = Reset-RoadmapOperationCounter -Name $counterName

# VÃ©rifier le rÃ©sultat
$success = $previousValue -eq 6

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  RÃ©initialisation d'un compteur: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Valeur attendue: 6" -ForegroundColor Red
    Write-Host "    Valeur obtenue: $previousValue" -ForegroundColor Red
}

# Test 6: Tester la fonction Measure-RoadmapOperations
Write-Host "`nTest 6: Tester la fonction Measure-RoadmapOperations" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code
$result = Measure-RoadmapOperations -Name "TestRoadmapMeasureOperationsWithFiles" -ScriptBlock {
    for ($i = 0; $i -lt 100; $i++) {
        Add-RoadmapOperationCount -Name "TestRoadmapMeasureOperationsWithFiles"
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

# Test 7: Tester la fonction Measure-RoadmapOperations avec des paramÃ¨tres
Write-Host "`nTest 7: Tester la fonction Measure-RoadmapOperations avec des paramÃ¨tres" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code avec des paramÃ¨tres
$result = Measure-RoadmapOperations -Name "TestRoadmapMeasureOperationsWithParamsFiles" -ScriptBlock {
    param($count)
    
    for ($i = 0; $i -lt $count; $i++) {
        Add-RoadmapOperationCount -Name "TestRoadmapMeasureOperationsWithParamsFiles"
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

# Test 8: Tester la fonction Measure-RoadmapOperations avec pipeline
Write-Host "`nTest 8: Tester la fonction Measure-RoadmapOperations avec pipeline" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code avec pipeline
$result = Measure-RoadmapOperations -Name "TestRoadmapMeasureOperationsWithPipelineFiles" -ScriptBlock {
    process {
        for ($i = 0; $i -lt $_; $i++) {
            Add-RoadmapOperationCount -Name "TestRoadmapMeasureOperationsWithPipelineFiles"
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

# Test 9: Tester la fonction Set-RoadmapOperationThreshold et Get-RoadmapOperationStatistics
Write-Host "`nTest 9: Tester la fonction Set-RoadmapOperationThreshold et Get-RoadmapOperationStatistics" -ForegroundColor Cyan

# DÃ©finir un seuil
Set-RoadmapOperationThreshold -Name "TestRoadmapOperationThresholdFiles" -Threshold 50

# ExÃ©cuter plusieurs opÃ©rations
for ($i = 0; $i -lt 3; $i++) {
    $result = Measure-RoadmapOperations -Name "TestRoadmapOperationThresholdFiles" -ScriptBlock {
        param($count)
        
        for ($j = 0; $j -lt $count; $j++) {
            Add-RoadmapOperationCount -Name "TestRoadmapOperationThresholdFiles"
        }
        
        return $count
    } -ArgumentList (($i + 1) * 20)
}

# Obtenir les statistiques
$stats = Get-RoadmapOperationStatistics -Name "TestRoadmapOperationThresholdFiles"

# VÃ©rifier les statistiques
$success = $null -ne $stats -and
           $stats.Count -eq 3 -and
           $stats.MinOperations -gt 0 -and
           $stats.MaxOperations -gt 0 -and
           $stats.AverageOperations -gt 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Seuil et statistiques d'opÃ©rations: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=3, MinOperations>0, MaxOperations>0, AverageOperations>0" -ForegroundColor Red
    if ($null -ne $stats) {
        Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinOperations=$($stats.MinOperations), MaxOperations=$($stats.MaxOperations), AverageOperations=$($stats.AverageOperations)" -ForegroundColor Red
    } else {
        Write-Host "    Statistiques obtenues: null" -ForegroundColor Red
    }
}

Write-Host "`nTests des fonctions publiques de comptage d'opÃ©rations avec les fichiers temporaires terminÃ©s." -ForegroundColor Cyan
