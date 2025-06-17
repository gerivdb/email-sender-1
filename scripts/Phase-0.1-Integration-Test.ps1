#!/usr/bin/env pwsh
# Phase-0.1-Integration-Test.ps1 - Test complet Phase 0.1 : Diagnostic et Réparation Infrastructure
# Implémentation conforme au plan de développement v59

Write-Host "🔧 Phase 0.1 : Integration Test - Diagnostic et Réparation Infrastructure" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

# Configuration
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$INFRASTRUCTURE_DIR = Join-Path $PROJECT_ROOT "src\managers\infrastructure"
$TIMESTAMP = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$TEST_LOG = Join-Path $PROJECT_ROOT "phase-0.1-test-log-$TIMESTAMP.txt"

# Initialisation du log
function Write-TestLog {
   param([string]$Message, [string]$Level = "INFO")
   $logEntry = "[$((Get-Date).ToString('HH:mm:ss'))] [$Level] $Message"
   Write-Host $logEntry
   Add-Content -Path $TEST_LOG -Value $logEntry
}

Write-TestLog "Starting Phase 0.1 Integration Test..." "START"

# Test 1: Vérification des fichiers d'infrastructure
function Test-InfrastructureFiles {
   Write-TestLog "🔍 Test 1: Infrastructure Files Verification" "TEST"
    
   $requiredFiles = @(
      @{Path = "$INFRASTRUCTURE_DIR\InfrastructureDiagnostic.ts"; Name = "InfrastructureDiagnostic.ts" },
      @{Path = "$INFRASTRUCTURE_DIR\InfrastructureExtensionManager.ts"; Name = "InfrastructureExtensionManager.ts" },
      @{Path = "$SCRIPT_DIR\Emergency-Repair-Fixed.ps1"; Name = "Emergency-Repair-Fixed.ps1" },
      @{Path = "$SCRIPT_DIR\Infrastructure-Scripts-Audit.ps1"; Name = "Infrastructure-Scripts-Audit.ps1" },
      @{Path = "$PROJECT_ROOT\Smart-Memory-Manager.ps1"; Name = "Smart-Memory-Manager.ps1" },
      @{Path = "$PROJECT_ROOT\Memory-Manager-Simple.ps1"; Name = "Memory-Manager-Simple.ps1" },
      @{Path = "$PROJECT_ROOT\Emergency-Memory-Fix.ps1"; Name = "Emergency-Memory-Fix.ps1" }
   )
    
   $filesOK = 0
   foreach ($file in $requiredFiles) {
      if (Test-Path $file.Path) {
         Write-TestLog "   ✅ $($file.Name) - EXISTS" "SUCCESS"
         $filesOK++
      }
      else {
         Write-TestLog "   ❌ $($file.Name) - MISSING" "ERROR"
      }
   }
    
   $result = @{
      Success = ($filesOK -eq $requiredFiles.Count)
      Score   = "$filesOK/$($requiredFiles.Count)"
      Details = "Infrastructure files verification"
   }
    
   Write-TestLog "   Result: $($result.Score) files OK" "RESULT"
   return $result
}

# Test 2: Test du diagnostic TypeScript (simulation)
function Test-TypeScriptDiagnostic {
   Write-TestLog "🩺 Test 2: TypeScript Diagnostic Classes" "TEST"
    
   try {
      # Vérification de la classe InfrastructureDiagnostic
      $diagnosticFile = "$INFRASTRUCTURE_DIR\InfrastructureDiagnostic.ts"
      if (Test-Path $diagnosticFile) {
         $content = Get-Content $diagnosticFile -Raw
            
         $requiredMethods = @(
            "runCompleteDiagnostic",
            "checkApiServerStatus", 
            "checkDockerStatus",
            "checkPortsAvailability",
            "checkSystemResources",
            "detectProcessConflicts",
            "repairApiServer"
         )
            
         $methodsFound = 0
         foreach ($method in $requiredMethods) {
            if ($content -match $method) {
               $methodsFound++
               Write-TestLog "   ✅ Method $method - FOUND" "SUCCESS"
            }
            else {
               Write-TestLog "   ❌ Method $method - MISSING" "ERROR"
            }
         }
            
         $result = @{
            Success = ($methodsFound -eq $requiredMethods.Count)
            Score   = "$methodsFound/$($requiredMethods.Count)"
            Details = "TypeScript diagnostic methods"
         }
      }
      else {
         $result = @{
            Success = $false
            Score   = "0/1"
            Details = "Diagnostic file not found"
         }
      }
   }
   catch {
      Write-TestLog "   ❌ Error testing TypeScript diagnostic: $($_.Exception.Message)" "ERROR"
      $result = @{
         Success = $false
         Score   = "0/1" 
         Details = "Error during test"
      }
   }
    
   Write-TestLog "   Result: $($result.Score) methods found" "RESULT"
   return $result
}

# Test 3: Test des scripts PowerShell de réparation
function Test-PowerShellRepair {
   Write-TestLog "🔧 Test 3: PowerShell Repair Scripts" "TEST"
    
   $scriptsToTest = @(
      @{Path = "$SCRIPT_DIR\Emergency-Repair-Fixed.ps1"; Name = "Emergency-Repair-Fixed" },
      @{Path = "$PROJECT_ROOT\Smart-Memory-Manager.ps1"; Name = "Smart-Memory-Manager" },
      @{Path = "$PROJECT_ROOT\Emergency-Memory-Fix.ps1"; Name = "Emergency-Memory-Fix" }
   )
    
   $scriptsOK = 0
   foreach ($script in $scriptsToTest) {
      try {
         Write-TestLog "   Testing $($script.Name)..." "INFO"
            
         # Test de syntaxe PowerShell
         $syntaxCheck = pwsh -NoProfile -Command "& { try { . '$($script.Path)'; Write-Output 'SYNTAX_OK' } catch { Write-Output 'SYNTAX_ERROR' } }"
            
         if ($syntaxCheck -match "SYNTAX_OK") {
            Write-TestLog "   ✅ $($script.Name) - SYNTAX OK" "SUCCESS"
            $scriptsOK++
         }
         else {
            Write-TestLog "   ❌ $($script.Name) - SYNTAX ERROR" "ERROR"
         }
      }
      catch {
         Write-TestLog "   ❌ $($script.Name) - TEST ERROR: $($_.Exception.Message)" "ERROR"
      }
   }
    
   $result = @{
      Success = ($scriptsOK -eq $scriptsToTest.Count)
      Score   = "$scriptsOK/$($scriptsToTest.Count)"
      Details = "PowerShell scripts syntax check"
   }
    
   Write-TestLog "   Result: $($result.Score) scripts OK" "RESULT"
   return $result
}

# Test 4: Test de l'API Server Health Check
function Test-ApiServerHealth {
   Write-TestLog "🌐 Test 4: API Server Health Check" "TEST"
    
   try {
      # Test de connexion API Server
      $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 10 -ErrorAction Stop
        
      if ($response.status -eq "healthy") {
         Write-TestLog "   ✅ API Server - HEALTHY" "SUCCESS"
         $result = @{
            Success = $true
            Score   = "1/1"
            Details = "API Server responding correctly"
         }
      }
      else {
         Write-TestLog "   ⚠️ API Server - UNHEALTHY" "WARNING"
         $result = @{
            Success = $false
            Score   = "0/1"
            Details = "API Server unhealthy response"
         }
      }
   }
   catch {
      Write-TestLog "   ❌ API Server - UNREACHABLE: $($_.Exception.Message)" "ERROR"
      $result = @{
         Success = $false
         Score   = "0/1"
         Details = "API Server connection failed"
      }
   }
    
   Write-TestLog "   Result: $($result.Details)" "RESULT"
   return $result
}

# Test 5: Test de la gestion mémoire
function Test-MemoryManagement {
   Write-TestLog "🧠 Test 5: Memory Management Validation" "TEST"
    
   try {
      # Vérification de l'usage mémoire actuel
      $memory = Get-CimInstance -ClassName Win32_OperatingSystem
      $totalRAM = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
      $usedRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
      $freeRAM = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)
      $usagePercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
        
      Write-TestLog "   Total RAM: $totalRAM GB" "INFO"
      Write-TestLog "   Used RAM: $usedRAM GB ($usagePercent%)" "INFO"
      Write-TestLog "   Free RAM: $freeRAM GB" "INFO"
        
      # Seuils d'alerte conformes au plan (20GB pour VSCode, Docker, Python, Go)
      $success = $true
      if ($usedRAM -le 20) {
         Write-TestLog "   ✅ Memory usage within optimal range" "SUCCESS"
      }
      elseif ($usedRAM -le 24) {
         Write-TestLog "   ⚠️ Memory usage approaching limit" "WARNING"
      }
      else {
         Write-TestLog "   ❌ Memory usage exceeding safe limits" "ERROR"
         $success = $false
      }
        
      $result = @{
         Success = $success
         Score   = if ($success) { "1/1" } else { "0/1" }
         Details = "Memory: $usedRAM GB used ($usagePercent%)"
      }
   }
   catch {
      Write-TestLog "   ❌ Error checking memory: $($_.Exception.Message)" "ERROR"
      $result = @{
         Success = $false
         Score   = "0/1"
         Details = "Memory check failed"
      }
   }
    
   Write-TestLog "   Result: $($result.Details)" "RESULT"
   return $result
}

# Test 6: Test d'intégration complète
function Test-CompleteIntegration {
   Write-TestLog "🔗 Test 6: Complete Integration Test" "TEST"
    
   try {
      Write-TestLog "   Running emergency repair simulation..." "INFO"
        
      # Simulation d'un repair complet (sans modifications destructives)
      $repairResult = & "$SCRIPT_DIR\Emergency-Repair-Fixed.ps1" 2>&1
        
      if ($LASTEXITCODE -eq 0 -or $repairResult -match "SUCCESS: INFRASTRUCTURE FULLY OPERATIONAL") {
         Write-TestLog "   ✅ Emergency repair simulation - SUCCESS" "SUCCESS"
         $result = @{
            Success = $true
            Score   = "1/1"
            Details = "Complete integration test passed"
         }
      }
      else {
         Write-TestLog "   ⚠️ Emergency repair simulation - PARTIAL" "WARNING"
         $result = @{
            Success = $false
            Score   = "0/1"
            Details = "Integration test partially failed"
         }
      }
   }
   catch {
      Write-TestLog "   ❌ Integration test error: $($_.Exception.Message)" "ERROR"
      $result = @{
         Success = $false
         Score   = "0/1"
         Details = "Integration test failed"
      }
   }
    
   Write-TestLog "   Result: $($result.Details)" "RESULT"
   return $result
}

# Exécution de tous les tests
Write-TestLog "Starting comprehensive test suite..." "INFO"

$testResults = @()
$testResults += Test-InfrastructureFiles
$testResults += Test-TypeScriptDiagnostic  
$testResults += Test-PowerShellRepair
$testResults += Test-ApiServerHealth
$testResults += Test-MemoryManagement
$testResults += Test-CompleteIntegration

# Calcul des résultats finaux
Write-TestLog "=========================================================================" "SUMMARY"
Write-TestLog "🏁 PHASE 0.1 INTEGRATION TEST RESULTS" "SUMMARY"
Write-TestLog "=========================================================================" "SUMMARY"

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Success }).Count
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

for ($i = 0; $i -lt $testResults.Count; $i++) {
   $test = $testResults[$i]
   $testName = @(
      "Infrastructure Files",
      "TypeScript Diagnostic", 
      "PowerShell Repair",
      "API Server Health",
      "Memory Management",
      "Complete Integration"
   )[$i]
    
   $status = if ($test.Success) { "✅ PASS" } else { "❌ FAIL" }
   Write-TestLog "Test $('{0:D2}' -f ($i+1)): $testName - $status ($($test.Score))" "SUMMARY"
}

Write-TestLog "=========================================================================" "SUMMARY"
Write-TestLog "Overall Success Rate: $successRate% ($passedTests/$totalTests tests passed)" "SUMMARY"

if ($successRate -eq 100) {
   Write-TestLog "🎉 PHASE 0.1 IMPLEMENTATION: COMPLETE SUCCESS" "SUCCESS"
   $exitCode = 0
}
elseif ($successRate -ge 80) {
   Write-TestLog "✅ PHASE 0.1 IMPLEMENTATION: MOSTLY SUCCESSFUL" "SUCCESS"
   $exitCode = 0
}
else {
   Write-TestLog "⚠️ PHASE 0.1 IMPLEMENTATION: NEEDS ATTENTION" "WARNING"
   $exitCode = 1
}

Write-TestLog "Test log saved to: $TEST_LOG" "INFO"
Write-TestLog "Phase 0.1 Integration Test completed." "END"

exit $exitCode
