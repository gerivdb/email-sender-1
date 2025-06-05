// filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\script-manager\Test-ScriptManager.ps1
# Test Suite for Script Manager with ErrorManager Integration
# Section 1.4 - Implementation des Recommandations - Phase 1

#Requires -Version 5.1

[CmdletBinding()]
param(
   [Parameter(Mandatory = $false)]
   [string]$TestCategory = "All",
    
   [Parameter(Mandatory = $false)]
   [switch]$Verbose,
    
   [Parameter(Mandatory = $false)]
   [switch]$GenerateReport
)

# Test configuration
$script:TestConfig = @{
   ScriptManagerPath = "$PSScriptRoot\script_manager.go"
   ExecutorsPath     = "$PSScriptRoot\executors.go"
   TestOutputDir     = "$PSScriptRoot\test-results"
   LogLevel          = if ($Verbose) { "DEBUG" } else { "INFO" }
}

# Test results tracking
$script:TestResults = @{
   Total   = 0
   Passed  = 0
   Failed  = 0
   Skipped = 0
   Tests   = @()
}

function Write-TestLog {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [string]$Message,
        
      [Parameter(Mandatory = $false)]
      [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
      [string]$Level = "INFO"
   )
    
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $colorMap = @{
      "INFO"    = "White"
      "WARN"    = "Yellow"
      "ERROR"   = "Red"
      "SUCCESS" = "Green"
      "DEBUG"   = "Cyan"
   }
    
   $color = $colorMap[$Level]
   Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    
   # Log to file if verbose
   if ($script:TestConfig.LogLevel -eq "DEBUG") {
      Add-Content -Path "$($script:TestConfig.TestOutputDir)\test.log" -Value "[$timestamp] [$Level] $Message"
   }
}

function Invoke-Test {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [string]$TestName,
        
      [Parameter(Mandatory = $true)]
      [scriptblock]$TestScript,
        
      [Parameter(Mandatory = $false)]
      [string]$Category = "General",
        
      [Parameter(Mandatory = $false)]
      [string]$Description = ""
   )
    
   if ($TestCategory -ne "All" -and $Category -ne $TestCategory) {
      Write-TestLog "Skipping test: $TestName (Category: $Category)" -Level "DEBUG"
      $script:TestResults.Skipped++
      return
   }
    
   $script:TestResults.Total++
   $testStart = Get-Date
    
   Write-TestLog "Running test: $TestName" -Level "INFO"
   if ($Description) {
      Write-TestLog "Description: $Description" -Level "DEBUG"
   }
    
   try {
      $testResult = & $TestScript
      $testEnd = Get-Date
      $duration = ($testEnd - $testStart).TotalMilliseconds
        
      if ($testResult) {
         Write-TestLog "✅ PASSED: $TestName ($([math]::Round($duration, 2))ms)" -Level "SUCCESS"
         $script:TestResults.Passed++
         $status = "PASSED"
      }
      else {
         Write-TestLog "❌ FAILED: $TestName ($([math]::Round($duration, 2))ms)" -Level "ERROR"
         $script:TestResults.Failed++
         $status = "FAILED"
      }
        
      $script:TestResults.Tests += @{
         Name        = $TestName
         Category    = $Category
         Status      = $status
         Duration    = $duration
         Description = $Description
         Timestamp   = $testStart
      }
        
   }
   catch {
      $testEnd = Get-Date
      $duration = ($testEnd - $testStart).TotalMilliseconds
        
      Write-TestLog "❌ ERROR: $TestName - $($_.Exception.Message)" -Level "ERROR"
      $script:TestResults.Failed++
        
      $script:TestResults.Tests += @{
         Name        = $TestName
         Category    = $Category
         Status      = "ERROR"
         Duration    = $duration
         Description = $Description
         Error       = $_.Exception.Message
         Timestamp   = $testStart
      }
   }
}

function Test-FileStructure {
   Write-TestLog "Testing Script Manager file structure..." -Level "INFO"
    
   $requiredFiles = @(
      "$PSScriptRoot\script_manager.go",
      "$PSScriptRoot\executors.go",
      "$PSScriptRoot\go.mod"
   )
    
   $allExist = $true
   foreach ($file in $requiredFiles) {
      if (-not (Test-Path $file)) {
         Write-TestLog "Missing required file: $file" -Level "ERROR"
         $allExist = $false
      }
      else {
         Write-TestLog "Found required file: $file" -Level "DEBUG"
      }
   }
    
   return $allExist
}

function Test-GoModuleStructure {
   Write-TestLog "Testing Go module structure..." -Level "INFO"
    
   try {
      $goModContent = Get-Content "$PSScriptRoot\go.mod" -Raw
        
      $checks = @(
         @{ Pattern = "module scriptmanager"; Description = "Module declaration" },
         @{ Pattern = "go 1\.21"; Description = "Go version specification" },
         @{ Pattern = "github\.com/google/uuid"; Description = "UUID dependency" },
         @{ Pattern = "go\.uber\.org/zap"; Description = "Zap logging dependency" }
      )
        
      $allPassed = $true
      foreach ($check in $checks) {
         if ($goModContent -match $check.Pattern) {
            Write-TestLog "✅ $($check.Description) found" -Level "DEBUG"
         }
         else {
            Write-TestLog "❌ $($check.Description) missing" -Level "ERROR"
            $allPassed = $false
         }
      }
        
      return $allPassed
   }
   catch {
      Write-TestLog "Failed to read go.mod: $($_.Exception.Message)" -Level "ERROR"
      return $false
   }
}

function Test-ScriptManagerStructure {
   Write-TestLog "Testing Script Manager Go structure..." -Level "INFO"
    
   try {
      $scriptManagerContent = Get-Content "$PSScriptRoot\script_manager.go" -Raw
        
      $requiredStructures = @(
         "type ScriptManager struct",
         "type ManagedScript struct",
         "type ScriptModule struct",
         "type ScriptTemplate struct",
         "type Config struct",
         "type ErrorManager struct",
         "func NewScriptManager",
         "func (sm *ScriptManager) ExecuteScript",
         "func (sm *ScriptManager) ListScripts",
         "func (em *ErrorManager) ProcessError"
      )
        
      $allFound = $true
      foreach ($structure in $requiredStructures) {
         if ($scriptManagerContent -match [regex]::Escape($structure)) {
            Write-TestLog "✅ Found: $structure" -Level "DEBUG"
         }
         else {
            Write-TestLog "❌ Missing: $structure" -Level "ERROR"
            $allFound = $false
         }
      }
        
      return $allFound
   }
   catch {
      Write-TestLog "Failed to analyze script_manager.go: $($_.Exception.Message)" -Level "ERROR"
      return $false
   }
}

function Test-ExecutorImplementation {
   Write-TestLog "Testing executor implementations..." -Level "INFO"
    
   try {
      $executorsContent = Get-Content "$PSScriptRoot\executors.go" -Raw
        
      $requiredExecutors = @(
         "type PowerShellExecutor struct",
         "type PythonExecutor struct", 
         "type JavaScriptExecutor struct",
         "type BashExecutor struct",
         "type BatchExecutor struct"
      )
        
      $requiredMethods = @(
         "func (pse *PowerShellExecutor) Execute",
         "func (pe *PythonExecutor) Execute",
         "func (jse *JavaScriptExecutor) Execute",
         "func (be *BashExecutor) Execute",
         "func (bte *BatchExecutor) Execute"
      )
        
      $allFound = $true
      foreach ($executor in $requiredExecutors) {
         if ($executorsContent -match [regex]::Escape($executor)) {
            Write-TestLog "✅ Found executor: $executor" -Level "DEBUG"
         }
         else {
            Write-TestLog "❌ Missing executor: $executor" -Level "ERROR"
            $allFound = $false
         }
      }
        
      foreach ($method in $requiredMethods) {
         if ($executorsContent -match [regex]::Escape($method)) {
            Write-TestLog "✅ Found method: $method" -Level "DEBUG"
         }
         else {
            Write-TestLog "❌ Missing method: $method" -Level "ERROR"
            $allFound = $false
         }
      }
        
      return $allFound
   }
   catch {
      Write-TestLog "Failed to analyze executors.go: $($_.Exception.Message)" -Level "ERROR"
      return $false
   }
}

function Test-ErrorManagerIntegration {
   Write-TestLog "Testing ErrorManager integration..." -Level "INFO"
    
   try {
      $scriptManagerContent = Get-Content "$PSScriptRoot\script_manager.go" -Raw
        
      $integrationChecks = @(
         "errormanager\.ErrorEntry",
         "errormanager\.ValidateErrorEntry",
         "errormanager\.CatalogError",
         "func \(em \*ErrorManager\) ProcessError",
         "func \(em \*ErrorManager\) determineSeverity"
      )
        
      $allFound = $true
      foreach ($check in $integrationChecks) {
         if ($scriptManagerContent -match $check) {
            Write-TestLog "✅ Found ErrorManager integration: $check" -Level "DEBUG"
         }
         else {
            Write-TestLog "❌ Missing ErrorManager integration: $check" -Level "ERROR"
            $allFound = $false
         }
      }
        
      # Check for proper error handling patterns
      $errorHandlingPatterns = @(
         "hooks := &ErrorHooks",
         "sm\.errorManager\.ProcessError",
         "entry := errormanager\.ErrorEntry"
      )
        
      foreach ($pattern in $errorHandlingPatterns) {
         if ($scriptManagerContent -match [regex]::Escape($pattern)) {
            Write-TestLog "✅ Found error handling pattern: $pattern" -Level "DEBUG"
         }
         else {
            Write-TestLog "❌ Missing error handling pattern: $pattern" -Level "ERROR"
            $allFound = $false
         }
      }
        
      return $allFound
   }
   catch {
      Write-TestLog "Failed to analyze ErrorManager integration: $($_.Exception.Message)" -Level "ERROR"
      return $false
   }
}

function Test-ScriptTypeSupport {
   Write-TestLog "Testing script type support..." -Level "INFO"
    
   try {
      $content = Get-Content "$PSScriptRoot\script_manager.go" -Raw
        
      $scriptTypes = @(
         "ScriptTypePowerShell",
         "ScriptTypePython",
         "ScriptTypeJavaScript",
         "ScriptTypeBash",
         "ScriptTypeBatch"
      )
        
      $allFound = $true
      foreach ($scriptType in $scriptTypes) {
         if ($content -match [regex]::Escape($scriptType)) {
            Write-TestLog "✅ Found script type: $scriptType" -Level "DEBUG"
         }
         else {
            Write-TestLog "❌ Missing script type: $scriptType" -Level "ERROR"
            $allFound = $false
         }
      }
        
      return $allFound
   }
   catch {
      Write-TestLog "Failed to analyze script type support: $($_.Exception.Message)" -Level "ERROR"
      return $false
   }
}

function Test-CircuitBreakerIntegration {
   Write-TestLog "Testing circuit breaker integration..." -Level "INFO"
    
   try {
      $content = Get-Content "$PSScriptRoot\script_manager.go" -Raw
        
      $circuitBreakerChecks = @(
         "circuitBreaker \*CircuitBreaker",
         "type CircuitBreaker struct"
      )
        
      $allFound = $true
      foreach ($check in $circuitBreakerChecks) {
         if ($content -match [regex]::Escape($check)) {
            Write-TestLog "✅ Found circuit breaker integration: $check" -Level "DEBUG"
         }
         else {
            Write-TestLog "❌ Missing circuit breaker integration: $check" -Level "ERROR"
            $allFound = $false
         }
      }
        
      return $allFound
   }
   catch {
      Write-TestLog "Failed to analyze circuit breaker integration: $($_.Exception.Message)" -Level "ERROR"
      return $false
   }
}

function Test-RetryMechanism {
   Write-TestLog "Testing retry mechanism implementation..." -Level "INFO"
    
   try {
      $content = Get-Content "$PSScriptRoot\script_manager.go" -Raw
        
      $retryChecks = @(
         "type RetryPolicy struct",
         "MaxAttempts int",
         "BackoffType",
         "func \(sm \*ScriptManager\) retryScriptExecution",
         "RetryAttempt int"
      )
        
      $allFound = $true
      foreach ($check in $retryChecks) {
         if ($content -match $check) {
            Write-TestLog "✅ Found retry mechanism: $check" -Level "DEBUG"
         }
         else {
            Write-TestLog "❌ Missing retry mechanism: $check" -Level "ERROR"
            $allFound = $false
         }
      }
        
      return $allFound
   }
   catch {
      Write-TestLog "Failed to analyze retry mechanism: $($_.Exception.Message)" -Level "ERROR"
      return $false
   }
}

function Test-TemplateSupport {
   Write-TestLog "Testing template support..." -Level "INFO"
    
   try {
      $content = Get-Content "$PSScriptRoot\script_manager.go" -Raw
        
      $templateChecks = @(
         "type ScriptTemplate struct",
         "type TemplateParameter struct",
         "func \(sm \*ScriptManager\) CreateScriptFromTemplate",
         "func \(sm \*ScriptManager\) processTemplate"
      )
        
      $allFound = $true
      foreach ($check in $templateChecks) {
         if ($content -match [regex]::Escape($check)) {
            Write-TestLog "✅ Found template support: $check" -Level "DEBUG"
         }
         else {
            Write-TestLog "❌ Missing template support: $check" -Level "ERROR"
            $allFound = $false
         }
      }
        
      return $allFound
   }
   catch {
      Write-TestLog "Failed to analyze template support: $($_.Exception.Message)" -Level "ERROR"
      return $false
   }
}

function Test-MetricsAndMonitoring {
   Write-TestLog "Testing metrics and monitoring..." -Level "INFO"
    
   try {
      $content = Get-Content "$PSScriptRoot\script_manager.go" -Raw
        
      $metricsChecks = @(
         "func \(sm \*ScriptManager\) GetMetrics",
         "RunCount",
         "SuccessCount",
         "ErrorCount",
         "success_rate"
      )
        
      $allFound = $true
      foreach ($check in $metricsChecks) {
         if ($content -match [regex]::Escape($check)) {
            Write-TestLog "✅ Found metrics support: $check" -Level "DEBUG"
         }
         else {
            Write-TestLog "❌ Missing metrics support: $check" -Level "ERROR"
            $allFound = $false
         }
      }
        
      return $allFound
   }
   catch {
      Write-TestLog "Failed to analyze metrics and monitoring: $($_.Exception.Message)" -Level "ERROR"
      return $false
   }
}

function Test-PowerShellExecutorSpecific {
   Write-TestLog "Testing PowerShell executor specifics..." -Level "INFO"
    
   try {
      $content = Get-Content "$PSScriptRoot\executors.go" -Raw
        
      $psChecks = @(
         "buildPowerShellCommand",
         "getPowerShellExecutable",
         "-NoProfile",
         "-ExecutionPolicy",
         "Bypass",
         "pwsh\.exe",
         "powershell\.exe"
      )
        
      $allFound = $true
      foreach ($check in $psChecks) {
         if ($content -match [regex]::Escape($check)) {
            Write-TestLog "✅ Found PowerShell executor feature: $check" -Level "DEBUG"
         }
         else {
            Write-TestLog "❌ Missing PowerShell executor feature: $check" -Level "ERROR"
            $allFound = $false
         }
      }
        
      return $allFound
   }
   catch {
      Write-TestLog "Failed to analyze PowerShell executor: $($_.Exception.Message)" -Level "ERROR"
      return $false
   }
}

# Main test execution
function Invoke-ScriptManagerTests {
   Write-TestLog "Starting Script Manager Test Suite..." -Level "INFO"
   Write-TestLog "Test Category: $TestCategory" -Level "INFO"
    
   # Ensure test output directory exists
   if (-not (Test-Path $script:TestConfig.TestOutputDir)) {
      New-Item -ItemType Directory -Path $script:TestConfig.TestOutputDir -Force | Out-Null
   }
    
   # Run tests by category
   Invoke-Test -TestName "File Structure" -TestScript { Test-FileStructure } -Category "Structure" -Description "Verify all required files exist"
    
   Invoke-Test -TestName "Go Module Structure" -TestScript { Test-GoModuleStructure } -Category "Structure" -Description "Verify go.mod configuration"
    
   Invoke-Test -TestName "Script Manager Structure" -TestScript { Test-ScriptManagerStructure } -Category "Implementation" -Description "Verify Script Manager Go structures"
    
   Invoke-Test -TestName "Executor Implementation" -TestScript { Test-ExecutorImplementation } -Category "Implementation" -Description "Verify all script executors are implemented"
    
   Invoke-Test -TestName "ErrorManager Integration" -TestScript { Test-ErrorManagerIntegration } -Category "Integration" -Description "Verify ErrorManager integration"
    
   Invoke-Test -TestName "Script Type Support" -TestScript { Test-ScriptTypeSupport } -Category "Features" -Description "Verify support for different script types"
    
   Invoke-Test -TestName "Circuit Breaker Integration" -TestScript { Test-CircuitBreakerIntegration } -Category "Integration" -Description "Verify circuit breaker integration"
    
   Invoke-Test -TestName "Retry Mechanism" -TestScript { Test-RetryMechanism } -Category "Features" -Description "Verify retry mechanism implementation"
    
   Invoke-Test -TestName "Template Support" -TestScript { Test-TemplateSupport } -Category "Features" -Description "Verify script template support"
    
   Invoke-Test -TestName "Metrics and Monitoring" -TestScript { Test-MetricsAndMonitoring } -Category "Features" -Description "Verify metrics and monitoring capabilities"
    
   Invoke-Test -TestName "PowerShell Executor Specifics" -TestScript { Test-PowerShellExecutorSpecific } -Category "Executors" -Description "Verify PowerShell executor specific features"
    
   # Generate summary
   Write-TestLog "Test Execution Summary:" -Level "INFO"
   Write-TestLog "Total Tests: $($script:TestResults.Total)" -Level "INFO"
   Write-TestLog "Passed: $($script:TestResults.Passed)" -Level "SUCCESS"
   Write-TestLog "Failed: $($script:TestResults.Failed)" -Level $(if ($script:TestResults.Failed -gt 0) { "ERROR" } else { "INFO" })
   Write-TestLog "Skipped: $($script:TestResults.Skipped)" -Level "INFO"
    
   $successRate = if ($script:TestResults.Total -gt 0) { 
      [math]::Round(($script:TestResults.Passed / $script:TestResults.Total) * 100, 2) 
   }
   else { 0 }
   Write-TestLog "Success Rate: $successRate%" -Level $(if ($successRate -ge 90) { "SUCCESS" } elseif ($successRate -ge 70) { "WARN" } else { "ERROR" })
    
   # Generate report if requested
   if ($GenerateReport) {
      $reportPath = "$($script:TestConfig.TestOutputDir)\test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
      $script:TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
      Write-TestLog "Test report generated: $reportPath" -Level "INFO"
   }
    
   return $script:TestResults.Failed -eq 0
}

# Execute tests
$testsPassed = Invoke-ScriptManagerTests

if ($testsPassed) {
   Write-TestLog "🎉 All tests passed! Script Manager implementation is ready." -Level "SUCCESS"
   exit 0
}
else {
   Write-TestLog "❌ Some tests failed. Please review the implementation." -Level "ERROR"
   exit 1
}
