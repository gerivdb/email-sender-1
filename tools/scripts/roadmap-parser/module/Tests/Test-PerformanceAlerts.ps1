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

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $setAlertPath)) {
    Write-Error "Le fichier Set-RoadmapPerformanceAlert.ps1 est introuvable à l'emplacement : $setAlertPath"
    exit 1
}

if (-not (Test-Path -Path $getAlertPath)) {
    Write-Error "Le fichier Get-RoadmapPerformanceAlert.ps1 est introuvable à l'emplacement : $getAlertPath"
    exit 1
}

if (-not (Test-Path -Path $testAlertPath)) {
    Write-Error "Le fichier Test-RoadmapPerformanceAlert.ps1 est introuvable à l'emplacement : $testAlertPath"
    exit 1
}

# Importer les fonctions
. $setAlertPath
. $getAlertPath
. $testAlertPath

# Créer une fonction de journalisation simplifiée pour le test
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

Write-Host "Début des tests d'alerte de performance..." -ForegroundColor Cyan

# Test 1: Configurer une alerte de temps d'exécution
Write-Host "`nTest 1: Configuration d'une alerte de temps d'exécution" -ForegroundColor Cyan
$executionTimeAlert = Set-RoadmapPerformanceAlert -Type ExecutionTime -Name "TestExecution" -Threshold 1000
Write-Host "Alerte configurée : Type=$($executionTimeAlert.Type), Name=$($executionTimeAlert.Name), Threshold=$($executionTimeAlert.Threshold)" -ForegroundColor Gray

# Test 2: Configurer une alerte d'utilisation de mémoire
Write-Host "`nTest 2: Configuration d'une alerte d'utilisation de mémoire" -ForegroundColor Cyan
$memoryAlert = Set-RoadmapPerformanceAlert -Type MemoryUsage -Name "TestMemory" -Threshold 1048576 # 1 MB
Write-Host "Alerte configurée : Type=$($memoryAlert.Type), Name=$($memoryAlert.Name), Threshold=$($memoryAlert.Threshold)" -ForegroundColor Gray

# Test 3: Configurer une alerte de comptage d'opérations
Write-Host "`nTest 3: Configuration d'une alerte de comptage d'opérations" -ForegroundColor Cyan
$operationsAlert = Set-RoadmapPerformanceAlert -Type Operations -Name "TestOperations" -Threshold 100
Write-Host "Alerte configurée : Type=$($operationsAlert.Type), Name=$($operationsAlert.Name), Threshold=$($operationsAlert.Threshold)" -ForegroundColor Gray

# Test 4: Récupérer toutes les alertes
Write-Host "`nTest 4: Récupération de toutes les alertes" -ForegroundColor Cyan
$allAlerts = Get-RoadmapPerformanceAlert
Write-Host "Nombre d'alertes récupérées : $($allAlerts.Count)" -ForegroundColor Gray
foreach ($alert in $allAlerts) {
    Write-Host "  - Type=$($alert.Type), Name=$($alert.Name), Threshold=$($alert.Threshold), Enabled=$($alert.Enabled)" -ForegroundColor Gray
}

# Test 5: Récupérer les alertes par type
Write-Host "`nTest 5: Récupération des alertes par type" -ForegroundColor Cyan
$executionTimeAlerts = Get-RoadmapPerformanceAlert -Type ExecutionTime
Write-Host "Nombre d'alertes de temps d'exécution : $($executionTimeAlerts.Count)" -ForegroundColor Gray
foreach ($alert in $executionTimeAlerts) {
    Write-Host "  - Type=$($alert.Type), Name=$($alert.Name), Threshold=$($alert.Threshold), Enabled=$($alert.Enabled)" -ForegroundColor Gray
}

# Test 6: Récupérer une alerte spécifique
Write-Host "`nTest 6: Récupération d'une alerte spécifique" -ForegroundColor Cyan
$specificAlert = Get-RoadmapPerformanceAlert -Type MemoryUsage -Name "TestMemory"
Write-Host "Alerte récupérée : Type=$($specificAlert.Type), Name=$($specificAlert.Name), Threshold=$($specificAlert.Threshold), Enabled=$($specificAlert.Enabled)" -ForegroundColor Gray

# Test 7: Tester toutes les alertes
Write-Host "`nTest 7: Test de toutes les alertes" -ForegroundColor Cyan
$testResults = Test-RoadmapPerformanceAlert
Write-Host "Nombre de tests effectués : $($testResults.Count)" -ForegroundColor Gray
foreach ($result in $testResults) {
    Write-Host "  - Type=$($result.Type), Name=$($result.Name), Threshold=$($result.Threshold), TestedValue=$($result.TestedValue), Triggered=$($result.Triggered)" -ForegroundColor Gray
}

# Test 8: Tester une alerte spécifique avec une valeur simulée
Write-Host "`nTest 8: Test d'une alerte spécifique avec une valeur simulée" -ForegroundColor Cyan
$specificTestResult = Test-RoadmapPerformanceAlert -Type Operations -Name "TestOperations" -SimulatedValue 150
Write-Host "Résultat du test : Type=$($specificTestResult.Type), Name=$($specificTestResult.Name), Threshold=$($specificTestResult.Threshold), TestedValue=$($specificTestResult.TestedValue), Triggered=$($specificTestResult.Triggered)" -ForegroundColor Gray

# Test 9: Configurer une alerte avec une action
Write-Host "`nTest 9: Configuration d'une alerte avec une action" -ForegroundColor Cyan
$actionAlert = Set-RoadmapPerformanceAlert -Type ExecutionTime -Name "TestAction" -Threshold 500 -Action {
    param($Alert)
    Write-Host "Action exécutée pour l'alerte : Type=$($Alert.Type), Name=$($Alert.Name), CurrentValue=$($Alert.CurrentValue), Threshold=$($Alert.Threshold)" -ForegroundColor Magenta
}
Write-Host "Alerte avec action configurée : Type=$($actionAlert.Type), Name=$($actionAlert.Name), Threshold=$($actionAlert.Threshold), Action définie=$(if ($actionAlert.Action) { 'Oui' } else { 'Non' })" -ForegroundColor Gray

# Test 10: Tester une alerte avec exécution de l'action
Write-Host "`nTest 10: Test d'une alerte avec exécution de l'action" -ForegroundColor Cyan
$actionTestResult = Test-RoadmapPerformanceAlert -Type ExecutionTime -Name "TestAction" -SimulatedValue 1000 -ExecuteActions $true
Write-Host "Résultat du test : Type=$($actionTestResult.Type), Name=$($actionTestResult.Name), Threshold=$($actionTestResult.Threshold), TestedValue=$($actionTestResult.TestedValue), Triggered=$($actionTestResult.Triggered), ActionExecuted=$($actionTestResult.ActionExecuted)" -ForegroundColor Gray

Write-Host "`nTests d'alerte de performance terminés." -ForegroundColor Cyan
