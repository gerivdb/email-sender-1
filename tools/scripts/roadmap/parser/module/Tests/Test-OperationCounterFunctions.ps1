#
# Test-OperationCounterFunctions.ps1
#
# Script pour tester les fonctions de comptage d'opÃ©rations
#

# Importer le script des fonctions de mesure de performance
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$performanceFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Performance\PerformanceMeasurementFunctions.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $performanceFunctionsPath)) {
    Write-Error "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable Ã  l'emplacement : $performanceFunctionsPath"
    exit 1
}

# Importer le script
. $performanceFunctionsPath

Write-Host "DÃ©but des tests des fonctions de comptage d'opÃ©rations..." -ForegroundColor Cyan

# Test 1: VÃ©rifier que les fonctions sont dÃ©finies
Write-Host "`nTest 1: VÃ©rifier que les fonctions sont dÃ©finies" -ForegroundColor Cyan

$functions = @(
    "Initialize-OperationCounter",
    "Increment-OperationCounter",
    "Reset-OperationCounter",
    "Get-OperationCounter",
    "Get-OperationStatistics",
    "Set-OperationThreshold",
    "Measure-Operations"
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

# Test 2: Tester la fonction Initialize-OperationCounter
Write-Host "`nTest 2: Tester la fonction Initialize-OperationCounter" -ForegroundColor Cyan

# Initialiser un compteur
$counterName = "TestOperationCounter"
Initialize-OperationCounter -Name $counterName

# VÃ©rifier que le compteur a Ã©tÃ© crÃ©Ã©
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

# Test 3: Tester la fonction Increment-OperationCounter
Write-Host "`nTest 3: Tester la fonction Increment-OperationCounter" -ForegroundColor Cyan

# IncrÃ©menter le compteur
$newValue = Increment-OperationCounter -Name $counterName

# VÃ©rifier que le compteur a Ã©tÃ© incrÃ©mentÃ©
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

# Test 4: Tester la fonction Increment-OperationCounter avec IncrementBy
Write-Host "`nTest 4: Tester la fonction Increment-OperationCounter avec IncrementBy" -ForegroundColor Cyan

# IncrÃ©menter le compteur de 5
$newValue = Increment-OperationCounter -Name $counterName -IncrementBy 5

# VÃ©rifier que le compteur a Ã©tÃ© incrÃ©mentÃ©
$success = $script:OperationCounters.ContainsKey($counterName) -and
           $script:OperationCounters[$counterName] -eq 6 -and
           $newValue -eq 6

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  IncrÃ©mentation d'un compteur avec IncrementBy: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Compteur attendu: Nom=$counterName, Valeur=6, Retour=6" -ForegroundColor Red
    if ($script:OperationCounters.ContainsKey($counterName)) {
        Write-Host "    Compteur obtenu: Nom=$counterName, Valeur=$($script:OperationCounters[$counterName]), Retour=$newValue" -ForegroundColor Red
    } else {
        Write-Host "    Compteur obtenu: Non crÃ©Ã©" -ForegroundColor Red
    }
}

# Test 5: Tester la fonction Get-OperationCounter
Write-Host "`nTest 5: Tester la fonction Get-OperationCounter" -ForegroundColor Cyan

# Obtenir la valeur du compteur
$value = Get-OperationCounter -Name $counterName

# VÃ©rifier que la valeur est correcte
$success = $value -eq 6

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Obtention de la valeur d'un compteur: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Valeur attendue: 6" -ForegroundColor Red
    Write-Host "    Valeur obtenue: $value" -ForegroundColor Red
}

# Test 6: Tester la fonction Reset-OperationCounter
Write-Host "`nTest 6: Tester la fonction Reset-OperationCounter" -ForegroundColor Cyan

# RÃ©initialiser le compteur
$previousValue = Reset-OperationCounter -Name $counterName

# VÃ©rifier que le compteur a Ã©tÃ© rÃ©initialisÃ©
$success = $script:OperationCounters.ContainsKey($counterName) -and
           $script:OperationCounters[$counterName] -eq 0 -and
           $previousValue -eq 6

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  RÃ©initialisation d'un compteur: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Compteur attendu: Nom=$counterName, Valeur=0, Retour=6" -ForegroundColor Red
    if ($script:OperationCounters.ContainsKey($counterName)) {
        Write-Host "    Compteur obtenu: Nom=$counterName, Valeur=$($script:OperationCounters[$counterName]), Retour=$previousValue" -ForegroundColor Red
    } else {
        Write-Host "    Compteur obtenu: Non crÃ©Ã©" -ForegroundColor Red
    }
}

# Test 7: Tester la fonction Get-OperationStatistics
Write-Host "`nTest 7: Tester la fonction Get-OperationStatistics" -ForegroundColor Cyan

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

# Test 8: Tester la fonction Set-OperationThreshold
Write-Host "`nTest 8: Tester la fonction Set-OperationThreshold" -ForegroundColor Cyan

# DÃ©finir un seuil
Set-OperationThreshold -Name $counterName -Threshold 50

# VÃ©rifier que le seuil a Ã©tÃ© dÃ©fini
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

# Test 9: Tester la fonction Measure-Operations
Write-Host "`nTest 9: Tester la fonction Measure-Operations" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code
$result = Measure-Operations -Name "TestMeasureOperations" -ScriptBlock {
    for ($i = 0; $i -lt 100; $i++) {
        Increment-OperationCounter -Name "TestMeasureOperations"
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

# Test 10: Tester la fonction Measure-Operations avec des paramÃ¨tres
Write-Host "`nTest 10: Tester la fonction Measure-Operations avec des paramÃ¨tres" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code avec des paramÃ¨tres
$result = Measure-Operations -Name "TestMeasureOperationsWithParams" -ScriptBlock {
    param($count)
    
    for ($i = 0; $i -lt $count; $i++) {
        Increment-OperationCounter -Name "TestMeasureOperationsWithParams"
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

# Test 11: Tester la fonction Measure-Operations avec pipeline
Write-Host "`nTest 11: Tester la fonction Measure-Operations avec pipeline" -ForegroundColor Cyan

# Mesurer le nombre d'opÃ©rations effectuÃ©es par un bloc de code avec pipeline
$result = Measure-Operations -Name "TestMeasureOperationsWithPipeline" -ScriptBlock {
    process {
        for ($i = 0; $i -lt $_; $i++) {
            Increment-OperationCounter -Name "TestMeasureOperationsWithPipeline"
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

Write-Host "`nTests des fonctions de comptage d'opÃ©rations terminÃ©s." -ForegroundColor Cyan
