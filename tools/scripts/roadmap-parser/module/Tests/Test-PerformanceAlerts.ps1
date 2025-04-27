#
# Test-PerformanceAlerts.ps1
#
# Script pour tester les fonctions d'alerte de performance
#

# Importer les fonctions d'alerte de performance
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$publicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"

# Fonctions d'alerte
$setAlertPath = Join-Path -Path $publicPath -ChildPath "Set-RoadmapPerformanceAlert.ps1"
$getAlertPath = Join-Path -Path $publicPath -ChildPath "Get-RoadmapPerformanceAlert.ps1"
$testAlertPath = Join-Path -Path $publicPath -ChildPath "Test-RoadmapPerformanceAlert.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $setAlertPath)) {
    Write-Error "Le fichier Set-RoadmapPerformanceAlert.ps1 est introuvable Ã  l'emplacement : $setAlertPath"
    exit 1
}

if (-not (Test-Path -Path $getAlertPath)) {
    Write-Error "Le fichier Get-RoadmapPerformanceAlert.ps1 est introuvable Ã  l'emplacement : $getAlertPath"
    exit 1
}

if (-not (Test-Path -Path $testAlertPath)) {
    Write-Error "Le fichier Test-RoadmapPerformanceAlert.ps1 est introuvable Ã  l'emplacement : $testAlertPath"
    exit 1
}

# Importer les fonctions
. $setAlertPath
. $getAlertPath
. $testAlertPath

# CrÃ©er une fonction de journalisation simplifiÃ©e pour le test
function Write-Log {
    param (
        [string]$Message,
        [string]$Level,
        [string]$Source
    )
    Write-Host "[$Level] [$Source] $Message" -ForegroundColor $(
        switch ($Level) {
            "Error" { "Red" }
            "Warning" { "Yellow" }
            "Info" { "Cyan" }
            default { "White" }
        }
    )
}

Write-Host "DÃ©but des tests d'alerte de performance..." -ForegroundColor Cyan

# Test 1: Configurer une alerte de temps d'exÃ©cution
Write-Host "`nTest 1: Configuration d'une alerte de temps d'exÃ©cution" -ForegroundColor Cyan
$executionTimeAlert = Set-RoadmapPerformanceAlert -Type ExecutionTime -Name "TestExecution" -Threshold 1000
Write-Host "Alerte configurÃ©e : Type=$($executionTimeAlert.Type), Name=$($executionTimeAlert.Name), Threshold=$($executionTimeAlert.Threshold)" -ForegroundColor Gray

# Test 2: Configurer une alerte d'utilisation de mÃ©moire
Write-Host "`nTest 2: Configuration d'une alerte d'utilisation de mÃ©moire" -ForegroundColor Cyan
$memoryAlert = Set-RoadmapPerformanceAlert -Type MemoryUsage -Name "TestMemory" -Threshold 1048576 # 1 MB
Write-Host "Alerte configurÃ©e : Type=$($memoryAlert.Type), Name=$($memoryAlert.Name), Threshold=$($memoryAlert.Threshold)" -ForegroundColor Gray

# Test 3: Configurer une alerte de comptage d'opÃ©rations
Write-Host "`nTest 3: Configuration d'une alerte de comptage d'opÃ©rations" -ForegroundColor Cyan
$operationsAlert = Set-RoadmapPerformanceAlert -Type Operations -Name "TestOperations" -Threshold 100
Write-Host "Alerte configurÃ©e : Type=$($operationsAlert.Type), Name=$($operationsAlert.Name), Threshold=$($operationsAlert.Threshold)" -ForegroundColor Gray

# Test 4: RÃ©cupÃ©rer toutes les alertes
Write-Host "`nTest 4: RÃ©cupÃ©ration de toutes les alertes" -ForegroundColor Cyan
$allAlerts = Get-RoadmapPerformanceAlert
Write-Host "Nombre d'alertes rÃ©cupÃ©rÃ©es : $($allAlerts.Count)" -ForegroundColor Gray
foreach ($alert in $allAlerts) {
    Write-Host "  - Type=$($alert.Type), Name=$($alert.Name), Threshold=$($alert.Threshold), Enabled=$($alert.Enabled)" -ForegroundColor Gray
}

# Test 5: RÃ©cupÃ©rer les alertes par type
Write-Host "`nTest 5: RÃ©cupÃ©ration des alertes par type" -ForegroundColor Cyan
$executionTimeAlerts = Get-RoadmapPerformanceAlert -Type ExecutionTime
Write-Host "Nombre d'alertes de temps d'exÃ©cution : $($executionTimeAlerts.Count)" -ForegroundColor Gray
foreach ($alert in $executionTimeAlerts) {
    Write-Host "  - Type=$($alert.Type), Name=$($alert.Name), Threshold=$($alert.Threshold), Enabled=$($alert.Enabled)" -ForegroundColor Gray
}

# Test 6: RÃ©cupÃ©rer une alerte spÃ©cifique
Write-Host "`nTest 6: RÃ©cupÃ©ration d'une alerte spÃ©cifique" -ForegroundColor Cyan
$specificAlert = Get-RoadmapPerformanceAlert -Type MemoryUsage -Name "TestMemory"
Write-Host "Alerte rÃ©cupÃ©rÃ©e : Type=$($specificAlert.Type), Name=$($specificAlert.Name), Threshold=$($specificAlert.Threshold), Enabled=$($specificAlert.Enabled)" -ForegroundColor Gray

# Test 7: Tester toutes les alertes
Write-Host "`nTest 7: Test de toutes les alertes" -ForegroundColor Cyan
$testResults = Test-RoadmapPerformanceAlert
Write-Host "Nombre de tests effectuÃ©s : $($testResults.Count)" -ForegroundColor Gray
foreach ($result in $testResults) {
    Write-Host "  - Type=$($result.Type), Name=$($result.Name), Threshold=$($result.Threshold), TestedValue=$($result.TestedValue), Triggered=$($result.Triggered)" -ForegroundColor Gray
}

# Test 8: Tester une alerte spÃ©cifique avec une valeur simulÃ©e
Write-Host "`nTest 8: Test d'une alerte spÃ©cifique avec une valeur simulÃ©e" -ForegroundColor Cyan
$specificTestResult = Test-RoadmapPerformanceAlert -Type Operations -Name "TestOperations" -SimulatedValue 150
Write-Host "RÃ©sultat du test : Type=$($specificTestResult.Type), Name=$($specificTestResult.Name), Threshold=$($specificTestResult.Threshold), TestedValue=$($specificTestResult.TestedValue), Triggered=$($specificTestResult.Triggered)" -ForegroundColor Gray

# Test 9: Configurer une alerte avec une action
Write-Host "`nTest 9: Configuration d'une alerte avec une action" -ForegroundColor Cyan
$actionAlert = Set-RoadmapPerformanceAlert -Type ExecutionTime -Name "TestAction" -Threshold 500 -Action {
    param($Alert)
    Write-Host "Action exÃ©cutÃ©e pour l'alerte : Type=$($Alert.Type), Name=$($Alert.Name), CurrentValue=$($Alert.CurrentValue), Threshold=$($Alert.Threshold)" -ForegroundColor Magenta
}
Write-Host "Alerte avec action configurÃ©e : Type=$($actionAlert.Type), Name=$($actionAlert.Name), Threshold=$($actionAlert.Threshold), Action dÃ©finie=$(if ($actionAlert.Action) { 'Oui' } else { 'Non' })" -ForegroundColor Gray

# Test 10: Tester une alerte avec exÃ©cution de l'action
Write-Host "`nTest 10: Test d'une alerte avec exÃ©cution de l'action" -ForegroundColor Cyan
$actionTestResult = Test-RoadmapPerformanceAlert -Type ExecutionTime -Name "TestAction" -SimulatedValue 1000 -ExecuteActions $true
Write-Host "RÃ©sultat du test : Type=$($actionTestResult.Type), Name=$($actionTestResult.Name), Threshold=$($actionTestResult.Threshold), TestedValue=$($actionTestResult.TestedValue), Triggered=$($actionTestResult.Triggered), ActionExecuted=$($actionTestResult.ActionExecuted)" -ForegroundColor Gray

Write-Host "`nTests d'alerte de performance terminÃ©s." -ForegroundColor Cyan
