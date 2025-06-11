# PowerShell Validation Script for Planning Ecosystem Sync
# Plan-dev-v55 Branch Architecture Implementation
# Version: 2.0 - June 11, 2025

param([string]$Action = "all")

$ProjectRoot = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$SyncBranchPath = "$ProjectRoot\planning-ecosystem-sync"

function Write-Status {
   param([string]$Message, [string]$Type = "Info")
   $time = Get-Date -Format "HH:mm:ss"
    
   switch ($Type) {
      "Success" { Write-Host "[$time] [OK] $Message" -ForegroundColor Green }
      "Error" { Write-Host "[$time] [ERROR] $Message" -ForegroundColor Red }
      default { Write-Host "[$time] [INFO] $Message" -ForegroundColor Cyan }
   }
}

function Test-Architecture {
   Write-Status "Validating branch architecture structure..."
    
   $dirs = @("docs", "tools", "config", "scripts", "tests")
   $missing = @()
    
   foreach ($dir in $dirs) {
      $path = "$SyncBranchPath\$dir"
      if (Test-Path $path) {
         Write-Status "Directory exists: $dir" "Success"
      }
      else {
         $missing += $dir
      }
   }
    
   if ($missing.Count -gt 0) {
      Write-Status "Missing directories: $($missing -join ', ')" "Error"
      return $false
   }
    
   Write-Status "Architecture validation: PASSED" "Success"
   return $true
}

function Test-Configuration {
   Write-Status "Validating configuration files..."
    
   $files = @("sync-config.yaml", "validation-rules.yaml")
   $missing = @()
    
   foreach ($file in $files) {
      $path = "$SyncBranchPath\config\$file"
      if (Test-Path $path) {
         Write-Status "Config file exists: $file" "Success"
      }
      else {
         $missing += $file
      }
   }
    
   if ($missing.Count -gt 0) {
      Write-Status "Missing config files: $($missing -join ', ')" "Error"
      return $false
   }
    
   Write-Status "Configuration validation: PASSED" "Success"
   return $true
}

function Test-UnitTests {
   Write-Status "Running unit tests..."
    
   $testDir = "$SyncBranchPath\tests"
   if (-not (Test-Path "$testDir\go.mod")) {
      Write-Status "Go module not found in tests directory" "Error"
      return $false
   }
    
   try {
      Push-Location $testDir
      $output = go test -v 2>&1
      $exitCode = $LASTEXITCODE
        
      if ($exitCode -eq 0) {
         Write-Status "Unit tests: PASSED" "Success"
         return $true
      }
      else {
         Write-Status "Unit tests: FAILED (exit code: $exitCode)" "Error"
         return $false
      }
   }
   finally {
      Pop-Location
   }
}

# Main execution
Write-Status "Planning Ecosystem Sync - Validation Script v2.0"
Write-Status "Action: $Action"

$results = @{
   "Architecture"  = Test-Architecture
   "Configuration" = Test-Configuration  
   "Unit Tests"    = Test-UnitTests
}

$passed = 0
foreach ($test in $results.Keys) {
   if ($results[$test]) {
      $passed++
   }
}

Write-Status "Validation Results: $passed/$($results.Count) tests passed"

if ($passed -eq $results.Count) {
   Write-Status "ALL VALIDATIONS PASSED - Implementation COMPLETE!" "Success"
   exit 0
}
else {
   Write-Status "Some validations failed" "Error"
   exit 1
}
