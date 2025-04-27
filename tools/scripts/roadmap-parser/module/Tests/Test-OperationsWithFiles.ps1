#
# Test-OperationsWithFiles.ps1
#
# Script pour tester les fonctions de comptage d'opÃ©rations avec les fichiers temporaires
#

# Importer les fonctions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$privatePath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Performance"
$performanceFunctionsPath = Join-Path -Path $privatePath -ChildPath "PerformanceMeasurementFunctions.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $performanceFunctionsPath)) {
    Write-Error "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable Ã  l'emplacement : $performanceFunctionsPath"
    exit 1
}

# Importer le script
. $performanceFunctionsPath

Write-Host "DÃ©but des tests des fonctions de comptage d'opÃ©rations avec les fichiers temporaires..." -ForegroundColor Cyan

# Test 1: Initialiser un compteur
Write-Host "`nTest 1: Initialiser un compteur" -ForegroundColor Cyan

# Initialiser un compteur
$counterName = "TestOperationCounterWithFiles"
Initialize-OperationCounter -Name $counterName

# VÃ©rifier que le compteur a Ã©tÃ© crÃ©Ã©
Load-OperationCounters
$success = $script:OperationCounters.ContainsKey($counterName) -and
           $script:OperationCounters[$counterName] -eq 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Initialisation d'un compteur: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Compteur attendu: Nom=$counterName, Valeur=0" -ForegroundColor Red
    if ($script:OperationCounters.ContainsKey($counterName)) {
        Write-Host "    Compteur obtenu: Nom=$counterName, Valeur=$($script:OperationCounters[$counterName])" -ForegroundColor Red
    } else {
        Write-Host "    Compteur obtenu: Non crÃ©Ã©" -ForegroundColor Red
    }
}

# Test 2: IncrÃ©menter un compteur
Write-Host "`nTest 2: IncrÃ©menter un compteur" -ForegroundColor Cyan

# IncrÃ©menter le compteur
$newValue = Increment-OperationCounter -Name $counterName

# VÃ©rifier que le compteur a Ã©tÃ© incrÃ©mentÃ©
Load-OperationCounters
$success = $script:OperationCounters.ContainsKey($counterName) -and
           $script:OperationCounters[$counterName] -eq 1 -and
           $newValue -eq 1

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  IncrÃ©mentation d'un compteur: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Compteur attendu: Nom=$counterName, Valeur=1, Retour=1" -ForegroundColor Red
    if ($script:OperationCounters.ContainsKey($counterName)) {
        Write-Host "    Compteur obtenu: Nom=$counterName, Valeur=$($script:OperationCounters[$counterName]), Retour=$newValue" -ForegroundColor Red
    } else {
        Write-Host "    Compteur obtenu: Non crÃ©Ã©" -ForegroundColor Red
    }
}

# Test 3: Obtenir la valeur d'un compteur
Write-Host "`nTest 3: Obtenir la valeur d'un compteur" -ForegroundColor Cyan

# Obtenir la valeur du compteur
$value = Get-OperationCounter -Name $counterName

# VÃ©rifier que la valeur est correcte
$success = $value -eq 1

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Obtention de la valeur d'un compteur: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Valeur attendue: 1" -ForegroundColor Red
    Write-Host "    Valeur obtenue: $value" -ForegroundColor Red
}

# Test 4: RÃ©initialiser un compteur
Write-Host "`nTest 4: RÃ©initialiser un compteur" -ForegroundColor Cyan

# RÃ©initialiser le compteur
$previousValue = Reset-OperationCounter -Name $counterName

# VÃ©rifier que le compteur a Ã©tÃ© rÃ©initialisÃ©
Load-OperationCounters
$success = $script:OperationCounters.ContainsKey($counterName) -and
           $script:OperationCounters[$counterName] -eq 0 -and
           $previousValue -eq 1

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  RÃ©initialisation d'un compteur: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Compteur attendu: Nom=$counterName, Valeur=0, Retour=1" -ForegroundColor Red
    if ($script:OperationCounters.ContainsKey($counterName)) {
        Write-Host "    Compteur obtenu: Nom=$counterName, Valeur=$($script:OperationCounters[$counterName]), Retour=$previousValue" -ForegroundColor Red
    } else {
        Write-Host "    Compteur obtenu: Non crÃ©Ã©" -ForegroundColor Red
    }
}

# Test 5: Obtenir les statistiques d'un compteur
Write-Host "`nTest 5: Obtenir les statistiques d'un compteur" -ForegroundColor Cyan

# ExÃ©cuter plusieurs opÃ©rations
for ($i = 0; $i -lt 5; $i++) {
    Initialize-OperationCounter -Name $counterName -Reset
    
    # IncrÃ©menter le compteur
    for ($j = 0; $j -lt ($i + 1) * 10; $j++) {
        Increment-OperationCounter -Name $counterName
    }
    
    Reset-OperationCounter -Name $counterName
}

# Obtenir les statistiques
$stats = Get-OperationStatistics -Name $counterName

# VÃ©rifier les statistiques
$success = $stats.Count -eq 6 -and
           $stats.MinOperations -gt 0 -and
           $stats.MaxOperations -gt 0 -and
           $stats.AverageOperations -gt 0

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Statistiques d'opÃ©rations: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Statistiques attendues: Count=6, MinOperations>0, MaxOperations>0, AverageOperations>0" -ForegroundColor Red
    Write-Host "    Statistiques obtenues: Count=$($stats.Count), MinOperations=$($stats.MinOperations), MaxOperations=$($stats.MaxOperations), AverageOperations=$($stats.AverageOperations)" -ForegroundColor Red
}

# Test 6: DÃ©finir un seuil
Write-Host "`nTest 6: DÃ©finir un seuil" -ForegroundColor Cyan

# DÃ©finir un seuil
Set-OperationThreshold -Name $counterName -Threshold 50

# VÃ©rifier que le seuil a Ã©tÃ© dÃ©fini
Load-OperationThresholds
$success = $script:OperationThresholds.ContainsKey($counterName) -and
           $script:OperationThresholds[$counterName] -eq 50

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  DÃ©finition d'un seuil: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Seuil attendu: Nom=$counterName, Seuil=50" -ForegroundColor Red
    if ($script:OperationThresholds.ContainsKey($counterName)) {
        Write-Host "    Seuil obtenu: Nom=$counterName, Seuil=$($script:OperationThresholds[$counterName])" -ForegroundColor Red
    } else {
        Write-Host "    Seuil obtenu: Non dÃ©fini" -ForegroundColor Red
    }
}

# Test 7: Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code
Write-Host "`nTest 7: Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code
$result = Measure-Operations -Name "TestMeasureOperationsWithFiles" -ScriptBlock {
    for ($i = 0; $i -lt 100; $i++) {
        Increment-OperationCounter -Name "TestMeasureOperationsWithFiles"
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

Write-Host "`nTests des fonctions de comptage d'opÃ©rations avec les fichiers temporaires terminÃ©s." -ForegroundColor Cyan
