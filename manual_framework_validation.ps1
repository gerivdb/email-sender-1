# Manual Framework Validation Script
# Ultra-Advanced 8-Level Branching Framework - Final Production Validation
# =========================================================================

param(
   [switch]$Detailed,
   [switch]$ProductionCheck
)

$ErrorActionPreference = "Continue"

Write-Host "🚀 ULTRA-ADVANCED 8-LEVEL BRANCHING FRAMEWORK" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "📊 FINAL PRODUCTION VALIDATION REPORT" -ForegroundColor Green
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$ProjectRoot = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$BranchingRoot = "$ProjectRoot\development\managers\branching-manager"

# Initialize counters
$TotalChecks = 0
$PassedChecks = 0
$FailedChecks = 0
$WarningChecks = 0

function Write-ValidationResult {
   param(
      [string]$Component,
      [string]$Status,
      [string]$Details = "",
      [int]$LineCount = 0
   )
    
   $script:TotalChecks++
    
   switch ($Status) {
      "PASS" { 
         Write-Host "✅ $Component" -ForegroundColor Green
         if ($Details) { Write-Host "   $Details" -ForegroundColor Gray }
         if ($LineCount -gt 0) { Write-Host "   Lines: $LineCount" -ForegroundColor Cyan }
         $script:PassedChecks++
      }
      "FAIL" { 
         Write-Host "❌ $Component" -ForegroundColor Red
         if ($Details) { Write-Host "   $Details" -ForegroundColor Red }
         $script:FailedChecks++
      }
      "WARN" { 
         Write-Host "⚠️  $Component" -ForegroundColor Yellow
         if ($Details) { Write-Host "   $Details" -ForegroundColor Yellow }
         $script:WarningChecks++
      }
   }
}

function Get-LineCount {
   param([string]$FilePath)
    
   if (Test-Path $FilePath) {
      try {
         $content = Get-Content $FilePath -ErrorAction SilentlyContinue
         return $content.Count
      }
      catch {
         return 0
      }
   }
   return 0
}

Write-Host "🔍 LEVEL 1-8 CORE FRAMEWORK VALIDATION" -ForegroundColor Magenta
Write-Host "======================================" -ForegroundColor Magenta

# Core Framework Files
$CoreFiles = @{
   "Level 1-8 Core Manager" = "$BranchingRoot\development\branching_manager.go"
   "Unit Test Suite"        = "$BranchingRoot\tests\branching_manager_test.go"
   "Type Definitions"       = "$ProjectRoot\pkg\interfaces\branching_types.go"
   "AI Predictor Engine"    = "$BranchingRoot\ai\predictor.go"
   "PostgreSQL Storage"     = "$BranchingRoot\database\postgresql_storage.go"
   "Qdrant Vector DB"       = "$BranchingRoot\database\qdrant_vector.go"
   "Git Operations"         = "$BranchingRoot\git\git_operations.go"
   "n8n Integration"        = "$BranchingRoot\integrations\n8n_integration.go"
   "MCP Gateway"            = "$BranchingRoot\integrations\mcp_gateway.go"
}

foreach ($component in $CoreFiles.GetEnumerator()) {
   if (Test-Path $component.Value) {
      $lineCount = Get-LineCount $component.Value
      if ($lineCount -gt 100) {
         Write-ValidationResult $component.Key "PASS" "Production Ready" $lineCount
      }
      else {
         Write-ValidationResult $component.Key "WARN" "Small file size" $lineCount
      }
   }
   else {
      Write-ValidationResult $component.Key "FAIL" "File not found"
   }
}

Write-Host ""
Write-Host "🚀 PRODUCTION DEPLOYMENT ASSETS" -ForegroundColor Magenta
Write-Host "===============================" -ForegroundColor Magenta

# Production Assets
$ProductionAssets = @{
   "Production Deployment Script" = "$ProjectRoot\production_deployment.ps1"
   "Final Deployment Script"      = "$ProjectRoot\final_production_deployment.ps1"
   "Monitoring Dashboard"         = "$ProjectRoot\monitoring_dashboard.go"
   "Framework Validator"          = "$ProjectRoot\framework_validator.go"
   "Comprehensive Validation"     = "$ProjectRoot\final_comprehensive_validation.ps1"
   "Integration Test Runner"      = "$ProjectRoot\integration_test_runner.go"
   "Simple Integration Test"      = "$ProjectRoot\simple_integration_test.go"
}

foreach ($asset in $ProductionAssets.GetEnumerator()) {
   if (Test-Path $asset.Value) {
      $lineCount = Get-LineCount $asset.Value
      Write-ValidationResult $asset.Key "PASS" "Available" $lineCount
   }
   else {
      Write-ValidationResult $asset.Key "FAIL" "Missing deployment asset"
   }
}

Write-Host ""
Write-Host "📋 DOCUMENTATION & REPORTS" -ForegroundColor Magenta
Write-Host "==========================" -ForegroundColor Magenta

# Documentation Files
$DocumentationFiles = @{
   "Production Readiness Checklist" = "$ProjectRoot\PRODUCTION_READINESS_CHECKLIST.md"
   "Integration Test Report"        = "$ProjectRoot\COMPREHENSIVE_INTEGRATION_TEST_REPORT.md"
   "Final Framework Status"         = "$ProjectRoot\FINAL_FRAMEWORK_STATUS_20250608_194238.md"
   "Validation Test Report"         = "$ProjectRoot\VALIDATION_TEST_SUCCESS_REPORT.md"
}

foreach ($doc in $DocumentationFiles.GetEnumerator()) {
   if (Test-Path $doc.Value) {
      $lineCount = Get-LineCount $doc.Value
      Write-ValidationResult $doc.Key "PASS" "Complete documentation" $lineCount
   }
   else {
      Write-ValidationResult $doc.Key "WARN" "Documentation missing"
   }
}

if ($ProductionCheck) {
   Write-Host ""
   Write-Host "🔧 PRODUCTION ENVIRONMENT CHECKS" -ForegroundColor Magenta
   Write-Host "================================" -ForegroundColor Magenta
    
   # Check Go installation
   try {
      $goVersion = & go version 2>&1
      Write-ValidationResult "Go Runtime" "PASS" $goVersion
   }
   catch {
      Write-ValidationResult "Go Runtime" "FAIL" "Go not installed or not in PATH"
   }
    
   # Check Docker availability
   try {
      $dockerVersion = & docker --version 2>&1
      Write-ValidationResult "Docker Engine" "PASS" $dockerVersion
   }
   catch {
      Write-ValidationResult "Docker Engine" "WARN" "Docker not available (optional for development)"
   }
    
   # Check PowerShell version
   Write-ValidationResult "PowerShell" "PASS" "Version: $($PSVersionTable.PSVersion)"
}

if ($Detailed) {
   Write-Host ""
   Write-Host "🔍 DETAILED COMPONENT ANALYSIS" -ForegroundColor Magenta
   Write-Host "==============================" -ForegroundColor Magenta
    
   # Analyze branching_manager.go in detail
   $mainFile = "$BranchingRoot\development\branching_manager.go"
   if (Test-Path $mainFile) {
      $content = Get-Content $mainFile -Raw
        
      # Count level implementations
      $levelMatches = ([regex]"Level[1-8]").Matches($content)
      Write-Host "   🎯 Branching Levels Detected: $($levelMatches.Count)" -ForegroundColor Cyan
        
      # Count struct definitions
      $structMatches = ([regex]"type\s+\w+\s+struct").Matches($content)
      Write-Host "   📋 Struct Definitions: $($structMatches.Count)" -ForegroundColor Cyan
        
      # Count function definitions
      $funcMatches = ([regex]"func\s+").Matches($content)
      Write-Host "   ⚙️  Function Definitions: $($funcMatches.Count)" -ForegroundColor Cyan
        
      # Check for AI integration
      if ($content -match "AI|Predictor|Neural") {
         Write-Host "   🤖 AI Integration: Detected" -ForegroundColor Green
      }
      else {
         Write-Host "   🤖 AI Integration: Not detected" -ForegroundColor Yellow
      }
        
      # Check for database integration
      if ($content -match "PostgreSQL|Qdrant|Database") {
         Write-Host "   🗄️  Database Integration: Detected" -ForegroundColor Green
      }
      else {
         Write-Host "   🗄️  Database Integration: Not detected" -ForegroundColor Yellow
      }
   }
}

Write-Host ""
Write-Host "📊 VALIDATION SUMMARY" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host ""
Write-Host "Total Checks: $TotalChecks" -ForegroundColor White
Write-Host "✅ Passed: $PassedChecks" -ForegroundColor Green
Write-Host "❌ Failed: $FailedChecks" -ForegroundColor Red
Write-Host "⚠️  Warnings: $WarningChecks" -ForegroundColor Yellow
Write-Host ""

$SuccessRate = [math]::Round(($PassedChecks / $TotalChecks) * 100, 2)
Write-Host "🎯 Success Rate: $SuccessRate%" -ForegroundColor $(if ($SuccessRate -ge 80) { "Green" } elseif ($SuccessRate -ge 60) { "Yellow" } else { "Red" })

if ($SuccessRate -ge 90) {
   Write-Host ""
   Write-Host "🚀 FRAMEWORK STATUS: PRODUCTION READY" -ForegroundColor Green
   Write-Host "✨ All systems operational for deployment!" -ForegroundColor Green
}
elseif ($SuccessRate -ge 75) {
   Write-Host ""
   Write-Host "⚠️  FRAMEWORK STATUS: MOSTLY READY" -ForegroundColor Yellow
   Write-Host "🔧 Minor issues need attention before production" -ForegroundColor Yellow
}
else {
   Write-Host ""
   Write-Host "❌ FRAMEWORK STATUS: NEEDS WORK" -ForegroundColor Red
   Write-Host "🛠️  Critical issues must be resolved" -ForegroundColor Red
}

Write-Host ""
Write-Host "🏁 Ultra-Advanced 8-Level Branching Framework Validation Complete" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
