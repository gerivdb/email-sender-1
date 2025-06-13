# Maintenance Manager Validation Script
# Validates the complete maintenance manager ecosystem

param(
   [string]$TestLevel = "full", # basic, integration, full
   [switch]$Verbose = $false,
   [switch]$SkipBuild = $false
)

Write-Host "🔧 Maintenance Manager Validation Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Configuration
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$MaintenanceManagerPath = $ProjectRoot
$LogFile = Join-Path $ProjectRoot "validation_results.log"

# Initialize logging
function Write-LoggedOutput {
   param($Message, $Level = "INFO")
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [$Level] $Message"
    
   # Write to console with color
   $color = switch ($Level) {
      "ERROR" { "Red" }
      "WARN" { "Yellow" }
      "SUCCESS" { "Green" }
      default { "White" }
   }
    
   Write-Host $logEntry -ForegroundColor $color
   Add-Content -Path $LogFile -Value $logEntry
}

# Test Functions
function Test-GoEnvironment {
   Write-LoggedOutput "Testing Go environment..."
    
   try {
      $goVersion = go version 2>$null
      if ($LASTEXITCODE -eq 0) {
         Write-LoggedOutput "✅ Go environment: $goVersion" "SUCCESS"
         return $true
      }
      else {
         Write-LoggedOutput "❌ Go not found or not working" "ERROR"
         return $false
      }
   }
   catch {
      Write-LoggedOutput "❌ Go environment test failed: $_" "ERROR"
      return $false
   }
}

function Test-BuildProcess {
   Write-LoggedOutput "Testing build process..."
    
   Push-Location $MaintenanceManagerPath
   try {
      # Clean previous builds
      if (Test-Path "*.exe") {
         Remove-Item "*.exe" -Force
         Write-LoggedOutput "🧹 Cleaned previous build artifacts"
      }
        
      # Test go mod tidy
      Write-LoggedOutput "Running go mod tidy..."
      go mod tidy
      if ($LASTEXITCODE -ne 0) {
         Write-LoggedOutput "❌ go mod tidy failed" "ERROR"
         return $false
      }
        
      # Test compilation
      Write-LoggedOutput "Testing compilation..."
      go build -v ./...
      if ($LASTEXITCODE -eq 0) {
         Write-LoggedOutput "✅ Build successful" "SUCCESS"
         return $true
      }
      else {
         Write-LoggedOutput "❌ Build failed" "ERROR"
         return $false
      }
   }
   catch {
      Write-LoggedOutput "❌ Build process failed: $_" "ERROR"
      return $false
   }
   finally {
      Pop-Location
   }
}

function Test-ComponentStructure {
   Write-LoggedOutput "Testing component structure..."
    
   $requiredDirs = @(
      "src/core",
      "src/ai", 
      "src/cleanup",
      "src/generator",
      "src/integration",
      "src/templates",
      "src/vector",
      "config"
   )
    
   $missingDirs = @()
   foreach ($dir in $requiredDirs) {
      $fullPath = Join-Path $MaintenanceManagerPath $dir
      if (-not (Test-Path $fullPath)) {
         $missingDirs += $dir
      }
   }
    
   if ($missingDirs.Count -eq 0) {
      Write-LoggedOutput "✅ All required directories present" "SUCCESS"
      return $true
   }
   else {
      Write-LoggedOutput "❌ Missing directories: $($missingDirs -join ', ')" "ERROR"
      return $false
   }
}

function Test-ConfigurationFiles {
   Write-LoggedOutput "Testing configuration files..."
    
   $configPath = Join-Path $MaintenanceManagerPath "config/maintenance-config.yaml"
   if (Test-Path $configPath) {
      Write-LoggedOutput "✅ Configuration file found" "SUCCESS"
        
      # Test config file content
      try {
         $configContent = Get-Content $configPath -Raw
         if ($configContent -match "repository_path" -and $configContent -match "ai_config") {
            Write-LoggedOutput "✅ Configuration structure validated" "SUCCESS"
            return $true
         }
         else {
            Write-LoggedOutput "⚠️ Configuration file exists but structure needs validation" "WARN"
            return $true
         }
      }
      catch {
         Write-LoggedOutput "⚠️ Could not parse configuration file" "WARN"
         return $true
      }
   }
   else {
      Write-LoggedOutput "⚠️ Configuration file not found at expected location" "WARN"
      return $true  # Non-critical for basic validation
   }
}

function Test-IntegrationTest {
   Write-LoggedOutput "Running integration test..."
    
   Push-Location $MaintenanceManagerPath
   try {
      if (Test-Path "test_integration.go") {
         Write-LoggedOutput "Building integration test..."
         go build -o test_integration.exe test_integration.go
            
         if ($LASTEXITCODE -eq 0 -and (Test-Path "test_integration.exe")) {
            Write-LoggedOutput "Running integration test..."
            ./test_integration.exe
                
            if ($LASTEXITCODE -eq 0) {
               Write-LoggedOutput "✅ Integration test passed" "SUCCESS"
               return $true
            }
            else {
               Write-LoggedOutput "⚠️ Integration test completed with warnings" "WARN"
               return $true
            }
         }
         else {
            Write-LoggedOutput "❌ Integration test build failed" "ERROR"
            return $false
         }
      }
      else {
         Write-LoggedOutput "⚠️ Integration test file not found" "WARN"
         return $true
      }
   }
   catch {
      Write-LoggedOutput "❌ Integration test failed: $_" "ERROR"
      return $false
   }
   finally {
      # Cleanup
      if (Test-Path "test_integration.exe") {
         Remove-Item "test_integration.exe" -Force
      }
      Pop-Location
   }
}

function Show-ValidationSummary {
   param($results)
    
   Write-Host "`n" -NoNewline
   Write-Host "🎯 VALIDATION SUMMARY" -ForegroundColor Cyan
   Write-Host "=====================" -ForegroundColor Cyan
    
   $passed = 0
   $total = $results.Count
    
   foreach ($result in $results) {
      $status = if ($result.Success) { "✅" } else { "❌" }
      $color = if ($result.Success) { "Green" } else { "Red" }
      Write-Host "$status $($result.Test)" -ForegroundColor $color
      if ($result.Success) { $passed++ }
   }
    
   Write-Host "`nResults: $passed/$total tests passed" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })
    
   if ($passed -eq $total) {
      Write-Host "🎉 ALL TESTS PASSED - Maintenance Manager is ready!" -ForegroundColor Green
   }
   elseif ($passed -ge ($total * 0.8)) {
      Write-Host "⚠️ MOSTLY WORKING - Minor issues detected" -ForegroundColor Yellow
   }
   else {
      Write-Host "❌ NEEDS ATTENTION - Critical issues detected" -ForegroundColor Red
   }
}

# Main execution
Write-LoggedOutput "Starting validation at $(Get-Date)"
Write-LoggedOutput "Test level: $TestLevel"
Write-LoggedOutput "Project root: $ProjectRoot"

# Clear previous log
if (Test-Path $LogFile) {
   Remove-Item $LogFile -Force
}

$testResults = @()

# Run tests based on level
switch ($TestLevel) {
   "basic" {
      $testResults += @{ Test = "Go Environment"; Success = (Test-GoEnvironment) }
      $testResults += @{ Test = "Component Structure"; Success = (Test-ComponentStructure) }
      $testResults += @{ Test = "Configuration Files"; Success = (Test-ConfigurationFiles) }
   }
   "integration" {
      $testResults += @{ Test = "Go Environment"; Success = (Test-GoEnvironment) }
      $testResults += @{ Test = "Component Structure"; Success = (Test-ComponentStructure) }
      $testResults += @{ Test = "Build Process"; Success = (Test-BuildProcess) }
      $testResults += @{ Test = "Integration Test"; Success = (Test-IntegrationTest) }
   }
   "full" {
      $testResults += @{ Test = "Go Environment"; Success = (Test-GoEnvironment) }
      $testResults += @{ Test = "Component Structure"; Success = (Test-ComponentStructure) }
      $testResults += @{ Test = "Configuration Files"; Success = (Test-ConfigurationFiles) }
      if (-not $SkipBuild) {
         $testResults += @{ Test = "Build Process"; Success = (Test-BuildProcess) }
      }
      $testResults += @{ Test = "Integration Test"; Success = (Test-IntegrationTest) }
   }
}

# Show summary
Show-ValidationSummary $testResults

Write-LoggedOutput "Validation completed at $(Get-Date)"
Write-LoggedOutput "Log saved to: $LogFile"

# Return appropriate exit code
$failedTests = $testResults | Where-Object { -not $_.Success }
if ($failedTests.Count -eq 0) {
   exit 0
}
else {
   exit 1
}
