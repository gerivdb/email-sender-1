# test-phase06-integration.ps1
# Test d'intégration Phase 0.6 : Scripts et Outils Automatisés

param(
   [switch]$RunAll,
   [switch]$TestScript,
   [switch]$TestVSCode,
   [switch]$GenerateReport
)

$Colors = @{
   Success = "Green"
   Error   = "Red"
   Warning = "Yellow"
   Info    = "Cyan"
   Header  = "Blue"
}

function Write-TestLog {
   param([string]$Message, [string]$Level = "Info")
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $Colors[$Level]
}

function Write-TestHeader {
   param([string]$Title)
   Write-Host "`n" + "="*80 -ForegroundColor $Colors.Header
   Write-Host "🧪 $Title" -ForegroundColor $Colors.Header
   Write-Host "="*80 -ForegroundColor $Colors.Header
}

function Test-EmergencyDiagnosticScript {
   Write-TestHeader "Testing Emergency Diagnostic Script"
   $scriptPath = ".\Emergency-Diagnostic-Test.ps1"
   $testResults = @()
    
   # Test 1: Vérifier l'existence du script
   Write-TestLog "Testing script existence..." "Info"    if (Test-Path $scriptPath) {
      Write-TestLog "Emergency-Diagnostic-Test.ps1 found" "Success"
      $testResults += @{ Test = "Script Existence"; Result = "PASS" }
   }
   else {
      Write-TestLog "❌ Emergency-Diagnostic-v2.ps1 not found" "Error"
      $testResults += @{ Test = "Script Existence"; Result = "FAIL" }
      return $testResults
   }
    
   # Test 2: Vérifier les paramètres requis
   Write-TestLog "Testing script parameters..." "Info"
   $scriptContent = Get-Content $scriptPath -Raw
   $requiredParams = @("-AllPhases", "-RunDiagnostic", "-RunRepair", "-EmergencyStop")
   $paramsFound = 0
    
   foreach ($param in $requiredParams) {
      if ($scriptContent -match [regex]::Escape($param)) {
         Write-TestLog "✅ Parameter $param found" "Success"
         $paramsFound++
      }
      else {
         Write-TestLog "❌ Parameter $param missing" "Error"
      }
   }
    
   if ($paramsFound -eq $requiredParams.Count) {
      $testResults += @{ Test = "Required Parameters"; Result = "PASS" }
   }
   else {
      $testResults += @{ Test = "Required Parameters"; Result = "FAIL" }
   }
    
   # Test 3: Test diagnostic seul
   Write-TestLog "Testing diagnostic-only execution..." "Info"
   try {
      $result = & $scriptPath -RunDiagnostic
      Write-TestLog "✅ Diagnostic execution completed" "Success"
      $testResults += @{ Test = "Diagnostic Execution"; Result = "PASS" }
   }
   catch {
      Write-TestLog "❌ Diagnostic execution failed: $($_.Exception.Message)" "Error"
      $testResults += @{ Test = "Diagnostic Execution"; Result = "FAIL" }
   }
    
   return $testResults
}

function Test-VSCodeIntegration {
   Write-TestHeader "Testing VSCode Integration"
    
   $testResults = @()
   $extensionPath = ".\.vscode\extension"
    
   # Test 1: Vérifier l'existence de l'extension
   Write-TestLog "Testing extension existence..." "Info"
   if (Test-Path $extensionPath) {
      Write-TestLog "✅ VSCode extension directory found" "Success"
      $testResults += @{ Test = "Extension Directory"; Result = "PASS" }
   }
   else {
      Write-TestLog "❌ VSCode extension directory not found" "Error"
      $testResults += @{ Test = "Extension Directory"; Result = "FAIL" }
      return $testResults
   }
    
   # Test 2: Vérifier package.json
   Write-TestLog "Testing package.json configuration..." "Info"
   $packageJsonPath = "$extensionPath\package.json"
   if (Test-Path $packageJsonPath) {
      $packageJson = Get-Content $packageJsonPath | ConvertFrom-Json
      $commandFound = $false
        
      foreach ($command in $packageJson.contributes.commands) {
         if ($command.command -eq "smartEmailSender.runEmergencyDiagnostic") {
            Write-TestLog "✅ Emergency diagnostic command found in package.json" "Success"
            $commandFound = $true
            break
         }
      }
        
      if ($commandFound) {
         $testResults += @{ Test = "Package.json Command"; Result = "PASS" }
      }
      else {
         Write-TestLog "❌ Emergency diagnostic command not found in package.json" "Error"
         $testResults += @{ Test = "Package.json Command"; Result = "FAIL" }
      }
   }
   else {
      Write-TestLog "❌ package.json not found" "Error"
      $testResults += @{ Test = "Package.json Command"; Result = "FAIL" }
   }
    
   # Test 3: Vérifier extension.ts
   Write-TestLog "Testing extension.ts implementation..." "Info"
   $extensionTsPath = "$extensionPath\src\extension.ts"
   if (Test-Path $extensionTsPath) {
      $extensionContent = Get-Content $extensionTsPath -Raw
        
      if ($extensionContent -match "runEmergencyDiagnostic" -and 
         $extensionContent -match "SystemHealthIndicator") {
         Write-TestLog "✅ Emergency diagnostic and health indicator implemented" "Success"
         $testResults += @{ Test = "Extension Implementation"; Result = "PASS" }
      }
      else {
         Write-TestLog "❌ Emergency diagnostic or health indicator not implemented" "Error"
         $testResults += @{ Test = "Extension Implementation"; Result = "FAIL" }
      }
   }
   else {
      Write-TestLog "❌ extension.ts not found" "Error"
      $testResults += @{ Test = "Extension Implementation"; Result = "FAIL" }
   }
    
   # Test 4: Test compilation
   Write-TestLog "Testing TypeScript compilation..." "Info"
   try {
      Push-Location $extensionPath
      $compileResult = npm run compile 2>&1
      if ($LASTEXITCODE -eq 0) {
         Write-TestLog "✅ TypeScript compilation successful" "Success"
         $testResults += @{ Test = "TypeScript Compilation"; Result = "PASS" }
      }
      else {
         Write-TestLog "❌ TypeScript compilation failed" "Error"
         $testResults += @{ Test = "TypeScript Compilation"; Result = "FAIL" }
      }
   }
   catch {
      Write-TestLog "❌ Compilation test failed: $($_.Exception.Message)" "Error"
      $testResults += @{ Test = "TypeScript Compilation"; Result = "FAIL" }
   }
   finally {
      Pop-Location
   }
    
   return $testResults
}

function Generate-TestReport {
   param([array]$ScriptResults, [array]$VSCodeResults)
    
   Write-TestHeader "Test Report - Phase 0.6 Integration"
    
   $allResults = @()
   $allResults += $ScriptResults
   $allResults += $VSCodeResults
    
   $totalTests = $allResults.Count
   $passedTests = ($allResults | Where-Object { $_.Result -eq "PASS" }).Count
   $failedTests = $totalTests - $passedTests
    
   Write-TestLog "📊 PHASE 0.6 TEST SUMMARY" "Header"
   Write-TestLog "Total Tests: $totalTests" "Info"
   Write-TestLog "Passed: $passedTests" "Success"
   Write-TestLog "Failed: $failedTests" $(if ($failedTests -eq 0) { "Success" } else { "Error" })
   Write-TestLog "Success Rate: $([Math]::Round(($passedTests / $totalTests) * 100, 1))%" "Info"
    
   Write-Host "`n📋 DETAILED RESULTS:" -ForegroundColor $Colors.Header
   foreach ($result in $allResults) {
      $status = if ($result.Result -eq "PASS") { "✅" } else { "❌" }
      $color = if ($result.Result -eq "PASS") { $Colors.Success } else { $Colors.Error }
      Write-Host "$status $($result.Test): $($result.Result)" -ForegroundColor $color
   }
    
   # Générer rapport JSON
   $reportData = @{
      Timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
      Phase       = "0.6"
      Description = "Scripts et Outils Automatisés"
      TotalTests  = $totalTests
      PassedTests = $passedTests
      FailedTests = $failedTests
      SuccessRate = [Math]::Round(($passedTests / $totalTests) * 100, 1)
      Results     = $allResults
   }
    
   $reportPath = "phase06-integration-test-report.json"
   $reportData | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding UTF8
   Write-TestLog "📄 Report saved to: $reportPath" "Info"
    
   if ($failedTests -eq 0) {
      Write-TestLog "🎉 ALL TESTS PASSED - Phase 0.6 Implementation Complete!" "Success"
      return $true
   }
   else {
      Write-TestLog "⚠️ Some tests failed - Review and fix issues" "Warning"
      return $false
   }
}

# Main execution
if (-not ($TestScript -or $TestVSCode -or $GenerateReport -or $RunAll)) {
   $RunAll = $true
}

$scriptResults = @()
$vscodeResults = @()

if ($RunAll -or $TestScript) {
   $scriptResults = Test-EmergencyDiagnosticScript
}

if ($RunAll -or $TestVSCode) {
   $vscodeResults = Test-VSCodeIntegration
}

if ($RunAll -or $GenerateReport) {
   $success = Generate-TestReport -ScriptResults $scriptResults -VSCodeResults $vscodeResults
    
   if ($success) {
      Write-TestLog "✅ Phase 0.6 implementation verification complete!" "Success"
      exit 0
   }
   else {
      Write-TestLog "❌ Phase 0.6 implementation needs fixes!" "Error"
      exit 1
   }
}

Write-TestLog "🏁 Phase 0.6 testing completed" "Info"
