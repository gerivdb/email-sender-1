# Test-PowerShellBridge.ps1
# Test script for PowerShell-ErrorManager Bridge integration
# Section 1.4 - Implementation des Recommandations

[CmdletBinding()]
param(
   [Parameter(Mandatory = $false)]
   [string]$BridgeUrl = "http://localhost:8081",
    
   [Parameter(Mandatory = $false)]
   [switch]$RunIntegrationTests,
    
   [Parameter(Mandatory = $false)]
   [switch]$StartBridge
)

# Import the ErrorManager Bridge module
$moduleRoot = Split-Path $MyInvocation.MyCommand.Path
Import-Module "$moduleRoot\ErrorManagerBridge.psm1" -Force

Write-Host "🚀 PowerShell ErrorManager Bridge Test Suite" -ForegroundColor Cyan
Write-Host "Section 1.4 - Implementation des Recommandations" -ForegroundColor Gray
Write-Host ""

# Configure the bridge
Set-ErrorManagerConfig -BaseUrl $BridgeUrl -Timeout 30 -EnableFallback $true

function Test-BridgeConnectivity {
   Write-Host "📡 Testing bridge connectivity..." -ForegroundColor Yellow
    
   $connectivity = Test-ErrorManagerConnectivity
    
   if ($connectivity.Success) {
      Write-Host "✅ Bridge is reachable at $BridgeUrl" -ForegroundColor Green
      Write-Host "   Status: $($connectivity.Status)" -ForegroundColor Gray
      return $true
   }
   else {
      Write-Host "❌ Bridge is not reachable" -ForegroundColor Red
      Write-Host "   Error: $($connectivity.Message)" -ForegroundColor Red
        
      if ($StartBridge) {
         Write-Host "🔧 Starting bridge server..." -ForegroundColor Yellow
         Start-BridgeServer
         Start-Sleep -Seconds 5
         return Test-ErrorManagerConnectivity | Select-Object -ExpandProperty Success
      }
        
      return $false
   }
}

function Start-BridgeServer {
   $bridgeDir = Split-Path $MyInvocation.MyCommand.Path
   $bridgeExe = Join-Path $bridgeDir "bridge_server.exe"
    
   if (-not (Test-Path $bridgeExe)) {
      Write-Host "🔨 Building bridge server..." -ForegroundColor Yellow
      Set-Location $bridgeDir
      & go build -o bridge_server.exe bridge_server.go
        
      if ($LASTEXITCODE -ne 0) {
         Write-Error "Failed to build bridge server"
         return
      }
   }
    
   Write-Host "🚀 Starting bridge server in background..." -ForegroundColor Yellow
   Start-Process -FilePath $bridgeExe -WindowStyle Hidden
}

function Test-BasicErrorProcessing {
   Write-Host "`n🧪 Testing basic error processing..." -ForegroundColor Yellow
    
   try {
      $result = Invoke-ErrorManagerProcess `
         -ErrorMessage "Test error from PowerShell" `
         -Component "test-module" `
         -Severity "Medium" `
         -Category "TEST" `
         -Operation "test_basic_processing"
        
      if ($result.Success) {
         Write-Host "✅ Basic error processing successful" -ForegroundColor Green
         Write-Host "   Error ID: $($result.ErrorId)" -ForegroundColor Gray
         Write-Host "   Recovery Action: $($result.RecoveryAction)" -ForegroundColor Gray
      }
      else {
         Write-Host "❌ Basic error processing failed" -ForegroundColor Red
         Write-Host "   Message: $($result.Message)" -ForegroundColor Red
      }
        
      return $result.Success
   }
   catch {
      Write-Host "❌ Exception during basic error processing: $($_.Exception.Message)" -ForegroundColor Red
      return $false
   }
}

function Test-ErrorWithContext {
   Write-Host "`n🔍 Testing error with rich context..." -ForegroundColor Yellow
    
   $context = @{
      database_name     = "TestDB"
      connection_string = "Server=localhost;Database=TestDB"
      retry_count       = 3
      last_attempt      = Get-Date
      custom_data       = @{
         nested_value = "test"
         array_data   = @(1, 2, 3)
      }
   }
    
   try {
      $result = Invoke-ErrorManagerProcess `
         -ErrorMessage "Database connection timeout" `
         -Component "database-connector" `
         -Context $context `
         -Severity "High" `
         -Category "DATABASE" `
         -Operation "connect_database"
        
      if ($result.Success) {
         Write-Host "✅ Context-rich error processing successful" -ForegroundColor Green
         Write-Host "   Error ID: $($result.ErrorId)" -ForegroundColor Gray
         Write-Host "   Recovery Action: $($result.RecoveryAction)" -ForegroundColor Gray
      }
      else {
         Write-Host "❌ Context-rich error processing failed" -ForegroundColor Red
      }
        
      return $result.Success
   }
   catch {
      Write-Host "❌ Exception during context-rich error processing: $($_.Exception.Message)" -ForegroundColor Red
      return $false
   }
}

function Test-ErrorWrapper {
   Write-Host "`n🔄 Testing error wrapper functionality..." -ForegroundColor Yellow
    
   try {
      # Test wrapper with successful operation
      $result1 = Invoke-ErrorManagerWrapper -Component "test-wrapper" -ScriptBlock {
         return "Success!"
      }
        
      if ($result1 -eq "Success!") {
         Write-Host "✅ Wrapper with successful operation works" -ForegroundColor Green
      }
        
      # Test wrapper with failing operation (will throw)
      try {
         Invoke-ErrorManagerWrapper -Component "test-wrapper" -EnableRetry -MaxRetries 2 -ScriptBlock {
            throw "Simulated failure"
         }
      }
      catch {
         Write-Host "✅ Wrapper correctly processed and re-threw error after retries" -ForegroundColor Green
      }
        
      return $true
   }
   catch {
      Write-Host "❌ Exception during wrapper testing: $($_.Exception.Message)" -ForegroundColor Red
      return $false
   }
}

function Test-BridgeStats {
   Write-Host "`n📊 Testing bridge statistics..." -ForegroundColor Yellow
    
   try {
      $response = Invoke-RestMethod -Uri "$BridgeUrl/api/v1/stats" -Method GET -TimeoutSec 10
        
      Write-Host "✅ Bridge statistics retrieved" -ForegroundColor Green
      Write-Host "   Requests Processed: $($response.requests_processed)" -ForegroundColor Gray
      Write-Host "   Errors Processed: $($response.errors_processed)" -ForegroundColor Gray
      Write-Host "   Successful Requests: $($response.successful_requests)" -ForegroundColor Gray
      Write-Host "   Failed Requests: $($response.failed_requests)" -ForegroundColor Gray
      Write-Host "   Uptime: $((Get-Date) - [datetime]$response.start_time)" -ForegroundColor Gray
        
      return $true
   }
   catch {
      Write-Host "❌ Failed to retrieve bridge statistics: $($_.Exception.Message)" -ForegroundColor Red
      return $false
   }
}

function Test-DifferentSeverityLevels {
   Write-Host "`n🎯 Testing different severity levels..." -ForegroundColor Yellow
    
   $severities = @("Low", "Medium", "High", "Critical")
   $successes = 0
    
   foreach ($severity in $severities) {
      try {
         $result = Invoke-ErrorManagerProcess `
            -ErrorMessage "Test $severity severity error" `
            -Component "severity-test" `
            -Severity $severity `
            -Category "TEST" `
            -Operation "test_severity"
            
         if ($result.Success) {
            Write-Host "✅ $severity severity processed successfully" -ForegroundColor Green
            $successes++
         }
         else {
            Write-Host "❌ $severity severity processing failed" -ForegroundColor Red
         }
      }
      catch {
         Write-Host "❌ Exception with $severity severity: $($_.Exception.Message)" -ForegroundColor Red
      }
   }
    
   Write-Host "📈 Severity test results: $successes/$($severities.Count) successful" -ForegroundColor Cyan
   return $successes -eq $severities.Count
}

function Show-Configuration {
   Write-Host "`n⚙️ Current ErrorManager Bridge Configuration:" -ForegroundColor Yellow
   $config = Get-ErrorManagerConfig
    
   $config.GetEnumerator() | ForEach-Object {
      Write-Host "   $($_.Key): $($_.Value)" -ForegroundColor Gray
   }
}

# Main test execution
function Run-AllTests {
   Write-Host "🧪 Running comprehensive test suite..." -ForegroundColor Cyan
    
   $tests = @(
      @{ Name = "Bridge Connectivity"; Function = { Test-BridgeConnectivity } },
      @{ Name = "Basic Error Processing"; Function = { Test-BasicErrorProcessing } },
      @{ Name = "Error with Context"; Function = { Test-ErrorWithContext } },
      @{ Name = "Error Wrapper"; Function = { Test-ErrorWrapper } },
      @{ Name = "Different Severity Levels"; Function = { Test-DifferentSeverityLevels } },
      @{ Name = "Bridge Statistics"; Function = { Test-BridgeStats } }
   )
    
   $results = @()
    
   foreach ($test in $tests) {
      $startTime = Get-Date
      $success = & $test.Function
      $duration = (Get-Date) - $startTime
        
      $results += @{
         Name     = $test.Name
         Success  = $success
         Duration = $duration
      }
   }
    
   # Summary
   Write-Host "`n📋 Test Summary:" -ForegroundColor Cyan
   $successCount = ($results | Where-Object { $_.Success }).Count
    
   foreach ($result in $results) {
      $status = if ($result.Success) { "✅" } else { "❌" }
      $duration = [math]::Round($result.Duration.TotalSeconds, 2)
      Write-Host "   $status $($result.Name) ($duration s)" -ForegroundColor $(if ($result.Success) { "Green" } else { "Red" })
   }
    
   Write-Host "`n🎯 Overall Result: $successCount/$($results.Count) tests passed" -ForegroundColor $(if ($successCount -eq $results.Count) { "Green" } else { "Yellow" })
    
   if ($successCount -eq $results.Count) {
      Write-Host "🎉 All tests passed! PowerShell-ErrorManager bridge is working correctly." -ForegroundColor Green
   }
   else {
      Write-Host "⚠️ Some tests failed. Please review the bridge configuration and connectivity." -ForegroundColor Yellow
   }
}

# Execute tests
Show-Configuration

if ($RunIntegrationTests) {
   Run-AllTests
}
else {
   # Quick connectivity test
   if (Test-BridgeConnectivity) {
      Write-Host "`n💡 Use -RunIntegrationTests to run the full test suite" -ForegroundColor Cyan
   }
}

Write-Host "`n✅ PowerShell Bridge test completed" -ForegroundColor Green
