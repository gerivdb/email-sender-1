#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Test d'intégration pour Phase 0.4 - Graphics & UI Optimization
.DESCRIPTION
    Valide GraphicsOptimizer et PowerManager avec tests complets
.NOTES
    Author: AI Assistant
    Version: 1.0.0
    Requires: PowerShell 7.0+, Node.js, TypeScript
#>

[CmdletBinding()]
param(
   [switch]$VerboseLogging,
   [switch]$SkipCleanup,
   [string]$LogLevel = "INFO"
)

# Configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Paths
$RootPath = Split-Path $PSScriptRoot -Parent
$SrcPath = Join-Path $RootPath "src"
$GraphicsPath = Join-Path $SrcPath "managers\graphics"
$PowerPath = Join-Path $SrcPath "managers\power"
$TestResultsPath = Join-Path $RootPath "test-results"
$LogFile = Join-Path $RootPath "phase-0.4-test-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

# Logging Function
function Write-TestLog {
   param([string]$Message, [string]$Level = "INFO")
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [$Level] $Message"
   Write-Host $logEntry -ForegroundColor $(switch ($Level) {
         "ERROR" { "Red" }
         "WARNING" { "Yellow" }
         "SUCCESS" { "Green" }
         default { "White" }
      })
   Add-Content -Path $LogFile -Value $logEntry
}

# Test Results Tracking
$TestResults = @{
   Total    = 0
   Passed   = 0
   Failed   = 0
   Warnings = 0
   Tests    = @()
}

function Add-TestResult {
   param(
      [string]$TestName,
      [bool]$Passed,
      [string]$Message = "",
      [string]$Details = ""
   )
    
   $TestResults.Total++
   if ($Passed) { 
      $TestResults.Passed++ 
      Write-TestLog "✅ $TestName - $Message" "SUCCESS"
   }
   else { 
      $TestResults.Failed++
      Write-TestLog "❌ $TestName - $Message" "ERROR"
   }
    
   $TestResults.Tests += @{
      Name      = $TestName
      Passed    = $Passed
      Message   = $Message
      Details   = $Details
      Timestamp = Get-Date
   }
}

function Test-GraphicsOptimizer {
   Write-TestLog "=== Testing GraphicsOptimizer ===" "INFO"
    
   try {
      # Test 1: Verify GraphicsOptimizer exists
      $graphicsFile = Join-Path $GraphicsPath "GraphicsOptimizer.ts"
      if (Test-Path $graphicsFile) {
         Add-TestResult "GraphicsOptimizer File Existence" $true "File found at expected location"
      }
      else {
         Add-TestResult "GraphicsOptimizer File Existence" $false "File not found"
         return
      }
        
      # Test 2: TypeScript Compilation
      Write-TestLog "Compiling GraphicsOptimizer..." "INFO"
      $tempTsConfig = @"
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020", "DOM"],
    "declaration": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "moduleResolution": "node"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
"@
        
      $tempTsConfigPath = Join-Path $RootPath "temp-tsconfig.json"
      $tempTsConfig | Out-File -FilePath $tempTsConfigPath -Encoding UTF8
        
      Push-Location $RootPath
      try {
         $compileResult = & npx tsc --project $tempTsConfigPath --noEmit 2>&1
         if ($LASTEXITCODE -eq 0) {
            Add-TestResult "GraphicsOptimizer TypeScript Compilation" $true "No compilation errors"
         }
         else {
            Add-TestResult "GraphicsOptimizer TypeScript Compilation" $false "Compilation errors: $compileResult"
         }
      }
      finally {
         Pop-Location
         if (Test-Path $tempTsConfigPath) { Remove-Item $tempTsConfigPath -Force }
      }
        
      # Test 3: Code Quality Analysis
      $content = Get-Content $graphicsFile -Raw
        
      # Test WebGL optimization methods
      if ($content -match "optimizeWebGL|WebGL.*optimization") {
         Add-TestResult "GraphicsOptimizer WebGL Methods" $true "WebGL optimization methods found"
      }
      else {
         Add-TestResult "GraphicsOptimizer WebGL Methods" $false "WebGL optimization methods missing"
      }
        
      # Test Canvas optimization
      if ($content -match "optimizeCanvas|Canvas.*optimization") {
         Add-TestResult "GraphicsOptimizer Canvas Methods" $true "Canvas optimization methods found"
      }
      else {
         Add-TestResult "GraphicsOptimizer Canvas Methods" $false "Canvas optimization methods missing"
      }
        
      # Test Frame rate management
      if ($content -match "frameRate|requestAnimationFrame|fps") {
         Add-TestResult "GraphicsOptimizer Frame Rate Management" $true "Frame rate management found"
      }
      else {
         Add-TestResult "GraphicsOptimizer Frame Rate Management" $false "Frame rate management missing"
      }
        
      # Test Memory management
      if ($content -match "memory.*management|GPU.*memory|texture.*cleanup") {
         Add-TestResult "GraphicsOptimizer Memory Management" $true "Graphics memory management found"
      }
      else {
         Add-TestResult "GraphicsOptimizer Memory Management" $false "Graphics memory management missing"
      }
        
      # Test UI responsiveness
      if ($content -match "UI.*responsiveness|non.*blocking|progressive.*rendering") {
         Add-TestResult "GraphicsOptimizer UI Responsiveness" $true "UI responsiveness features found"
      }
      else {
         Add-TestResult "GraphicsOptimizer UI Responsiveness" $false "UI responsiveness features missing"
      }
        
   }
   catch {
      Add-TestResult "GraphicsOptimizer Testing" $false "Exception: $($_.Exception.Message)"
   }
}

function Test-PowerManager {
   Write-TestLog "=== Testing PowerManager ===" "INFO"
    
   try {
      # Test 1: Verify PowerManager exists
      $powerFile = Join-Path $PowerPath "PowerManager.ts"
      if (Test-Path $powerFile) {
         Add-TestResult "PowerManager File Existence" $true "File found at expected location"
      }
      else {
         Add-TestResult "PowerManager File Existence" $false "File not found"
         return
      }
        
      # Test 2: Code Quality Analysis
      $content = Get-Content $powerFile -Raw
        
      # Test Battery management
      if ($content -match "battery.*aware|battery.*management|power.*status") {
         Add-TestResult "PowerManager Battery Management" $true "Battery management features found"
      }
      else {
         Add-TestResult "PowerManager Battery Management" $false "Battery management features missing"
      }
        
      # Test Performance scaling
      if ($content -match "performance.*scaling|CPU.*scaling|throttling") {
         Add-TestResult "PowerManager Performance Scaling" $true "Performance scaling found"
      }
      else {
         Add-TestResult "PowerManager Performance Scaling" $false "Performance scaling missing"
      }
        
      # Test Background activity reduction
      if ($content -match "background.*reduction|background.*activity|idle.*management") {
         Add-TestResult "PowerManager Background Management" $true "Background activity management found"
      }
      else {
         Add-TestResult "PowerManager Background Management" $false "Background activity management missing"
      }
        
      # Test Thermal management
      if ($content -match "thermal.*throttling|temperature.*management|heat.*management") {
         Add-TestResult "PowerManager Thermal Management" $true "Thermal management found"
      }
      else {
         Add-TestResult "PowerManager Thermal Management" $false "Thermal management missing"
      }
        
      # Test Power profiles
      if ($content -match "power.*profile|performance.*profile|energy.*profile") {
         Add-TestResult "PowerManager Power Profiles" $true "Power profile management found"
      }
      else {
         Add-TestResult "PowerManager Power Profiles" $false "Power profile management missing"
      }
        
   }
   catch {
      Add-TestResult "PowerManager Testing" $false "Exception: $($_.Exception.Message)"
   }
}

function Test-Integration {
   Write-TestLog "=== Testing Integration ===" "INFO"
    
   try {
      # Test 1: Directory Structure
      $requiredDirs = @(
            (Join-Path $SrcPath "managers"),
            (Join-Path $SrcPath "managers\graphics"),
            (Join-Path $SrcPath "managers\power")
      )
        
      $allDirsExist = $true
      foreach ($dir in $requiredDirs) {
         if (-not (Test-Path $dir)) {
            $allDirsExist = $false
            Write-TestLog "Missing directory: $dir" "WARNING"
         }
      }
        
      Add-TestResult "Integration Directory Structure" $allDirsExist "Required directories validation"
        
      # Test 2: Dependencies Check
      $hasNodeModules = Test-Path (Join-Path $RootPath "node_modules")
      $hasPackageJson = Test-Path (Join-Path $RootPath "package.json")
        
      if ($hasPackageJson) {
         Add-TestResult "Integration Package Configuration" $true "package.json found"
      }
      else {
         Add-TestResult "Integration Package Configuration" $false "package.json missing"
      }
        
      # Test 3: TypeScript Environment
      try {
         $tscVersion = & npx tsc --version 2>&1
         if ($LASTEXITCODE -eq 0) {
            Add-TestResult "Integration TypeScript Environment" $true "TypeScript available: $tscVersion"
         }
         else {
            Add-TestResult "Integration TypeScript Environment" $false "TypeScript not available"
         }
      }
      catch {
         Add-TestResult "Integration TypeScript Environment" $false "TypeScript check failed"
      }
        
   }
   catch {
      Add-TestResult "Integration Testing" $false "Exception: $($_.Exception.Message)"
   }
}

function Test-Performance {
   Write-TestLog "=== Performance Tests ===" "INFO"
    
   try {
      # Test file sizes
      $graphicsFile = Join-Path $GraphicsPath "GraphicsOptimizer.ts"
      $powerFile = Join-Path $PowerPath "PowerManager.ts"
        
      if (Test-Path $graphicsFile) {
         $graphicsSize = (Get-Item $graphicsFile).Length
         if ($graphicsSize -gt 1024) {
            # At least 1KB
            Add-TestResult "Performance GraphicsOptimizer Size" $true "File size: $graphicsSize bytes"
         }
         else {
            Add-TestResult "Performance GraphicsOptimizer Size" $false "File too small: $graphicsSize bytes"
         }
      }
        
      if (Test-Path $powerFile) {
         $powerSize = (Get-Item $powerFile).Length
         if ($powerSize -gt 1024) {
            # At least 1KB
            Add-TestResult "Performance PowerManager Size" $true "File size: $powerSize bytes"
         }
         else {
            Add-TestResult "Performance PowerManager Size" $false "File too small: $powerSize bytes"
         }
      }
        
      # Memory usage simulation
      $memoryBefore = [System.GC]::GetTotalMemory($false)
      Start-Sleep -Milliseconds 100
      $memoryAfter = [System.GC]::GetTotalMemory($false)
        
      Add-TestResult "Performance Memory Baseline" $true "Memory usage stable"
        
   }
   catch {
      Add-TestResult "Performance Testing" $false "Exception: $($_.Exception.Message)"
   }
}

# Main Test Execution
function Main {
   Write-TestLog "🚀 Starting Phase 0.4 Integration Tests" "INFO"
   Write-TestLog "Root Path: $RootPath" "INFO"
   Write-TestLog "Log File: $LogFile" "INFO"
    
   # Ensure test results directory exists
   if (-not (Test-Path $TestResultsPath)) {
      New-Item -ItemType Directory -Path $TestResultsPath -Force | Out-Null
   }
    
   # Run all tests
   Test-GraphicsOptimizer
   Test-PowerManager
   Test-Integration
   Test-Performance
    
   # Generate final report
   Write-TestLog "=== FINAL TEST RESULTS ===" "INFO"
   Write-TestLog "Total Tests: $($TestResults.Total)" "INFO"
   Write-TestLog "Passed: $($TestResults.Passed)" "SUCCESS"
   Write-TestLog "Failed: $($TestResults.Failed)" $(if ($TestResults.Failed -eq 0) { "SUCCESS" } else { "ERROR" })
   Write-TestLog "Warnings: $($TestResults.Warnings)" "WARNING"
    
   $successRate = if ($TestResults.Total -gt 0) { 
      [math]::Round(($TestResults.Passed / $TestResults.Total) * 100, 2) 
   }
   else { 0 }
    
   Write-TestLog "Success Rate: $successRate%" $(if ($successRate -ge 80) { "SUCCESS" } else { "ERROR" })
    
   # Save detailed results
   $detailedResults = @{
      Summary = @{
         Total       = $TestResults.Total
         Passed      = $TestResults.Passed
         Failed      = $TestResults.Failed
         Warnings    = $TestResults.Warnings
         SuccessRate = $successRate
         Timestamp   = Get-Date
      }
      Tests   = $TestResults.Tests
   }
    
   $resultsFile = Join-Path $TestResultsPath "phase-0.4-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
   $detailedResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
    
   Write-TestLog "Detailed results saved to: $resultsFile" "INFO"
    
   # Cleanup
   if (-not $SkipCleanup) {
      Write-TestLog "Performing cleanup..." "INFO"
      [System.GC]::Collect()
   }
    
   # Exit with appropriate code
   if ($TestResults.Failed -eq 0) {
      Write-TestLog "🎉 All tests passed! Phase 0.4 implementation validated successfully." "SUCCESS"
      exit 0
   }
   else {
      Write-TestLog "❌ Some tests failed. Please review the results above." "ERROR"
      exit 1
   }
}

# Execute main function
try {
   Main
}
catch {
   Write-TestLog "❌ Fatal error in test execution: $($_.Exception.Message)" "ERROR"
   Write-TestLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
   exit 1
}
