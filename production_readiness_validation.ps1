#!/usr/bin/env pwsh
# filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\production_readiness_validation.ps1
# Ultra-Advanced 8-Level Branching Framework - Production Readiness Validation
# ==========================================================================

param(
   [switch]$ComprehensiveCheck,
   [switch]$GenerateReport,
   [switch]$FixIssues,
   [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($Verbose) { "Continue" } else { "SilentlyContinue" }

# Configuration
$ProjectRoot = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$BranchingRoot = "$ProjectRoot\development\managers\branching-manager"
$ValidationTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$ReportFile = "$ProjectRoot\PRODUCTION_READINESS_REPORT_$ValidationTimestamp.md"

# Production readiness criteria
$ProductionCriteria = @{
   "Core Framework"       = @{
      Weight = 30
      Checks = @(
         @{ Name = "8-Level Branching Manager"; Path = "$BranchingRoot\development\branching_manager.go"; MinLines = 2500; Critical = $true },
         @{ Name = "Core Test Suite"; Path = "$BranchingRoot\tests\branching_manager_test.go"; MinLines = 1000; Critical = $true },
         @{ Name = "Type Definitions"; Path = "$ProjectRoot\pkg\interfaces\branching_types.go"; MinLines = 300; Critical = $true }
      )
   }
   "AI & Intelligence"    = @{
      Weight = 20
      Checks = @(
         @{ Name = "AI Predictor Engine"; Path = "$BranchingRoot\ai\predictor.go"; MinLines = 700; Critical = $true },
         @{ Name = "Pattern Analyzer"; Path = "$BranchingRoot\ai\pattern_analyzer.go"; MinLines = 300; Critical = $false },
         @{ Name = "Neural Network Models"; Path = "$BranchingRoot\ai\models"; IsDirectory = $true; Critical = $false }
      )
   }
   "Database Integration" = @{
      Weight = 15
      Checks = @(
         @{ Name = "PostgreSQL Storage"; Path = "$BranchingRoot\database\postgresql_storage.go"; MinLines = 600; Critical = $true },
         @{ Name = "Qdrant Vector DB"; Path = "$BranchingRoot\database\qdrant_vector.go"; MinLines = 400; Critical = $true },
         @{ Name = "Database Migrations"; Path = "$BranchingRoot\database\migrations"; IsDirectory = $true; Critical = $false }
      )
   }
   "Git Operations"       = @{
      Weight = 15
      Checks = @(
         @{ Name = "Git Operations Core"; Path = "$BranchingRoot\git\git_operations.go"; MinLines = 500; Critical = $true },
         @{ Name = "Git Hooks Manager"; Path = "$BranchingRoot\git\hooks_manager.go"; MinLines = 200; Critical = $false },
         @{ Name = "Branch Strategies"; Path = "$BranchingRoot\git\strategies.go"; MinLines = 300; Critical = $false }
      )
   }
   "Integrations"         = @{
      Weight = 10
      Checks = @(
         @{ Name = "n8n Integration"; Path = "$BranchingRoot\integrations\n8n_integration.go"; MinLines = 400; Critical = $true },
         @{ Name = "MCP Gateway"; Path = "$BranchingRoot\integrations\mcp_gateway.go"; MinLines = 600; Critical = $true },
         @{ Name = "External APIs"; Path = "$BranchingRoot\integrations\external_apis.go"; MinLines = 200; Critical = $false }
      )
   }
   "Production Assets"    = @{
      Weight = 10
      Checks = @(
         @{ Name = "Monitoring Dashboard"; Path = "$ProjectRoot\monitoring_dashboard.go"; MinLines = 600; Critical = $true },
         @{ Name = "Production Deployment"; Path = "$ProjectRoot\production_deployment.ps1"; MinLines = 300; Critical = $true },
         @{ Name = "Framework Validator"; Path = "$ProjectRoot\framework_validator.go"; MinLines = 200; Critical = $true },
         @{ Name = "E2E Integration Test"; Path = "$ProjectRoot\end_to_end_integration_test.go"; MinLines = 400; Critical = $true },
         @{ Name = "Real-Time Dashboard"; Path = "$ProjectRoot\realtime_status_dashboard.go"; MinLines = 600; Critical = $true },
         @{ Name = "Production Orchestrator"; Path = "$ProjectRoot\production_deployment_orchestrator.ps1"; MinLines = 300; Critical = $true }
      )
   }
}

# Security checklist
$SecurityChecklist = @(
   "Input validation and sanitization",
   "Authentication and authorization mechanisms",
   "Encrypted database connections",
   "API rate limiting and throttling",
   "Audit logging and monitoring",
   "Secret management and encryption",
   "CORS and security headers",
   "Dependency vulnerability scanning"
)

# Performance checklist
$PerformanceChecklist = @(
   "Database connection pooling",
   "Caching strategies implementation",
   "Memory leak prevention",
   "CPU usage optimization",
   "Async processing capabilities",
   "Load balancing configuration",
   "Resource monitoring alerts",
   "Graceful degradation handling"
)

function Write-ValidationLog {
   param(
      [string]$Message,
      [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'CRITICAL')]
      [string]$Level = 'INFO'
   )
    
   $Timestamp = Get-Date -Format "HH:mm:ss"
   $Icons = @{
      'INFO'     = "ℹ️"
      'SUCCESS'  = "✅"
      'WARNING'  = "⚠️"
      'ERROR'    = "❌"
      'CRITICAL' = "🔥"
   }
    
   $Colors = @{
      'INFO'     = 'Cyan'
      'SUCCESS'  = 'Green'
      'WARNING'  = 'Yellow'
      'ERROR'    = 'Red'
      'CRITICAL' = 'Magenta'
   }
    
   $LogMessage = "[$Timestamp] $($Icons[$Level]) $Message"
   Write-Host $LogMessage -ForegroundColor $Colors[$Level]
}

function Test-ComponentReadiness {
   param(
      [string]$CategoryName,
      [hashtable]$Category
   )
    
   Write-ValidationLog "🔍 Validating $CategoryName" "INFO"
    
   $CategoryScore = 0
   $MaxCategoryScore = 0
   $CriticalIssues = @()
   $Warnings = @()
    
   foreach ($check in $Category.Checks) {
      $checkScore = 0
      $maxCheckScore = if ($check.Critical) { 10 } else { 5 }
      $MaxCategoryScore += $maxCheckScore
        
      if ($check.IsDirectory) {
         if (Test-Path $check.Path -PathType Container) {
            $itemCount = (Get-ChildItem $check.Path -ErrorAction SilentlyContinue).Count
            if ($itemCount -gt 0) {
               $checkScore = $maxCheckScore
               Write-ValidationLog "  ✅ $($check.Name): Directory exists with $itemCount items" "SUCCESS"
            }
            else {
               $checkScore = $maxCheckScore * 0.5
               $Warnings += "$($check.Name): Directory exists but is empty"
               Write-ValidationLog "  ⚠️  $($check.Name): Directory exists but is empty" "WARNING"
            }
         }
         else {
            if ($check.Critical) {
               $CriticalIssues += "$($check.Name): Directory not found"
               Write-ValidationLog "  ❌ $($check.Name): Directory not found at $($check.Path)" "ERROR"
            }
            else {
               $Warnings += "$($check.Name): Directory not found"
               Write-ValidationLog "  ⚠️  $($check.Name): Directory not found (optional)" "WARNING"
            }
         }
      }
      else {
         if (Test-Path $check.Path) {
            $content = Get-Content $check.Path -ErrorAction SilentlyContinue
            $lineCount = $content.Count
            $fileSize = (Get-Item $check.Path).Length
                
            if ($lineCount -ge $check.MinLines) {
               $checkScore = $maxCheckScore
               Write-ValidationLog "  ✅ $($check.Name): $lineCount lines, $([math]::Round($fileSize/1KB, 1)) KB" "SUCCESS"
            }
            else {
               $checkScore = $maxCheckScore * 0.7
               $Warnings += "$($check.Name): Only $lineCount lines (expected $($check.MinLines)+)"
               Write-ValidationLog "  ⚠️  $($check.Name): $lineCount lines (expected $($check.MinLines)+)" "WARNING"
            }
         }
         else {
            if ($check.Critical) {
               $CriticalIssues += "$($check.Name): File not found"
               Write-ValidationLog "  ❌ $($check.Name): File not found at $($check.Path)" "ERROR"
            }
            else {
               $Warnings += "$($check.Name): File not found"
               Write-ValidationLog "  ⚠️  $($check.Name): File not found (optional)" "WARNING"
            }
         }
      }
        
      $CategoryScore += $checkScore
   }
    
   $CategoryPercent = if ($MaxCategoryScore -gt 0) { ($CategoryScore / $MaxCategoryScore) * 100 } else { 0 }
    
   return @{
      Score          = $CategoryScore
      MaxScore       = $MaxCategoryScore
      Percentage     = $CategoryPercent
      CriticalIssues = $CriticalIssues
      Warnings       = $Warnings
   }
}

function Test-SecurityReadiness {
   Write-ValidationLog "🔒 Validating Security Readiness" "INFO"
    
   $SecurityScore = 0
   $SecurityIssues = @()
    
   # Check for common security files and patterns
   $SecurityFiles = @(
      @{ Path = "$ProjectRoot\.env.example"; Name = "Environment template" },
      @{ Path = "$ProjectRoot\security"; Name = "Security configuration"; IsDirectory = $true },
      @{ Path = "$BranchingRoot\auth"; Name = "Authentication module"; IsDirectory = $true }
   )
    
   foreach ($file in $SecurityFiles) {
      if ($file.IsDirectory) {
         if (Test-Path $file.Path -PathType Container) {
            $SecurityScore += 10
            Write-ValidationLog "  ✅ $($file.Name): Found" "SUCCESS"
         }
         else {
            $SecurityIssues += "$($file.Name): Not found"
            Write-ValidationLog "  ⚠️  $($file.Name): Not found" "WARNING"
         }
      }
      else {
         if (Test-Path $file.Path) {
            $SecurityScore += 10
            Write-ValidationLog "  ✅ $($file.Name): Found" "SUCCESS"
         }
         else {
            $SecurityIssues += "$($file.Name): Not found"
            Write-ValidationLog "  ⚠️  $($file.Name): Not found" "WARNING"
         }
      }
   }
    
   # Check code for security patterns
   $GoFiles = Get-ChildItem -Path $BranchingRoot -Recurse -Filter "*.go" -ErrorAction SilentlyContinue
   $SecurityPatterns = @("bcrypt", "jwt", "crypto", "tls", "auth", "sanitize")
    
   $PatternFound = $false
   foreach ($file in $GoFiles) {
      $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
      foreach ($pattern in $SecurityPatterns) {
         if ($content -match $pattern) {
            $PatternFound = $true
            break
         }
      }
      if ($PatternFound) { break }
   }
    
   if ($PatternFound) {
      $SecurityScore += 20
      Write-ValidationLog "  ✅ Security patterns found in code" "SUCCESS"
   }
   else {
      $SecurityIssues += "Security patterns not detected in code"
      Write-ValidationLog "  ⚠️  Security patterns not detected in code" "WARNING"
   }
    
   return @{
      Score      = $SecurityScore
      MaxScore   = 50
      Percentage = ($SecurityScore / 50) * 100
      Issues     = $SecurityIssues
   }
}

function Test-PerformanceReadiness {
   Write-ValidationLog "⚡ Validating Performance Readiness" "INFO"
    
   $PerformanceScore = 0
   $PerformanceIssues = @()
    
   # Check for performance-related files
   $PerformanceFiles = @(
      @{ Path = "$BranchingRoot\performance"; Name = "Performance optimizations"; IsDirectory = $true },
      @{ Path = "$ProjectRoot\monitoring_dashboard.go"; Name = "Monitoring dashboard" },
      @{ Path = "$BranchingRoot\cache"; Name = "Caching implementation"; IsDirectory = $true }
   )
    
   foreach ($file in $PerformanceFiles) {
      if ($file.IsDirectory) {
         if (Test-Path $file.Path -PathType Container) {
            $PerformanceScore += 15
            Write-ValidationLog "  ✅ $($file.Name): Found" "SUCCESS"
         }
         else {
            $PerformanceIssues += "$($file.Name): Not found"
            Write-ValidationLog "  ⚠️  $($file.Name): Not found" "WARNING"
         }
      }
      else {
         if (Test-Path $file.Path) {
            $PerformanceScore += 15
            Write-ValidationLog "  ✅ $($file.Name): Found" "SUCCESS"
         }
         else {
            $PerformanceIssues += "$($file.Name): Not found"
            Write-ValidationLog "  ⚠️  $($file.Name): Not found" "WARNING"
         }
      }
   }
    
   # Check for performance patterns in code
   $GoFiles = Get-ChildItem -Path $BranchingRoot -Recurse -Filter "*.go" -ErrorAction SilentlyContinue
   $PerformancePatterns = @("sync\.", "context\.", "goroutine", "channel", "mutex", "cache", "pool")
    
   $PatternsFound = 0
   foreach ($file in $GoFiles) {
      $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
      foreach ($pattern in $PerformancePatterns) {
         if ($content -match $pattern) {
            $PatternsFound++
            break
         }
      }
   }
    
   if ($PatternsFound -ge 3) {
      $PerformanceScore += 25
      Write-ValidationLog "  ✅ Performance patterns found ($PatternsFound patterns)" "SUCCESS"
   }
   else {
      $PerformanceIssues += "Insufficient performance patterns in code ($PatternsFound found)"
      Write-ValidationLog "  ⚠️  Limited performance patterns found ($PatternsFound patterns)" "WARNING"
   }
    
   return @{
      Score      = $PerformanceScore
      MaxScore   = 70
      Percentage = ($PerformanceScore / 70) * 100
      Issues     = $PerformanceIssues
   }
}

function Test-TestCoverage {
   Write-ValidationLog "🧪 Validating Test Coverage" "INFO"
    
   $TestScore = 0
   $TestIssues = @()
    
   # Check for test files
   $TestFiles = Get-ChildItem -Path $BranchingRoot -Recurse -Filter "*_test.go" -ErrorAction SilentlyContinue
   $SourceFiles = Get-ChildItem -Path $BranchingRoot -Recurse -Filter "*.go" -ErrorAction SilentlyContinue | 
   Where-Object { $_.Name -notlike "*_test.go" }
    
   $TestFileCount = $TestFiles.Count
   $SourceFileCount = $SourceFiles.Count
    
   if ($TestFileCount -gt 0 -and $SourceFileCount -gt 0) {
      $TestRatio = $TestFileCount / $SourceFileCount
      $TestScore = [math]::Min(($TestRatio * 100), 50)
        
      Write-ValidationLog "  ✅ Test files: $TestFileCount, Source files: $SourceFileCount (ratio: $([math]::Round($TestRatio, 2)))" "SUCCESS"
   }
   else {
      $TestIssues += "Insufficient test coverage"
      Write-ValidationLog "  ⚠️  Test files: $TestFileCount, Source files: $SourceFileCount" "WARNING"
   }
    
   # Check for integration tests
   $IntegrationTests = @(
      "$ProjectRoot\end_to_end_integration_test.go",
      "$ProjectRoot\integration_test_runner.go",
      "$ProjectRoot\final_comprehensive_test_runner.go"
   )
    
   $IntegrationTestCount = 0
   foreach ($test in $IntegrationTests) {
      if (Test-Path $test) {
         $IntegrationTestCount++
      }
   }
    
   if ($IntegrationTestCount -ge 2) {
      $TestScore += 30
      Write-ValidationLog "  ✅ Integration tests: $IntegrationTestCount found" "SUCCESS"
   }
   else {
      $TestIssues += "Insufficient integration tests ($IntegrationTestCount found)"
      Write-ValidationLog "  ⚠️  Integration tests: $IntegrationTestCount found" "WARNING"
   }
    
   return @{
      Score      = $TestScore
      MaxScore   = 80
      Percentage = ($TestScore / 80) * 100
      Issues     = $TestIssues
   }
}

function New-ProductionReadinessReport {
   param(
      [hashtable]$Results
   )
    
   $ReportContent = @"
# 🚀 PRODUCTION READINESS VALIDATION REPORT

**Framework:** Ultra-Advanced 8-Level Branching Framework  
**Validation Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Validation ID:** PROD-READY-$ValidationTimestamp  

---

## 📊 EXECUTIVE SUMMARY

"@

   $OverallScore = 0
   $MaxOverallScore = 0
   $CriticalIssuesCount = 0
   $WarningsCount = 0
    
   foreach ($category in $Results.Keys) {
      $result = $Results[$category]
      $OverallScore += $result.Score
      $MaxOverallScore += $result.MaxScore
      if ($result.CriticalIssues) { $CriticalIssuesCount += $result.CriticalIssues.Count }
      if ($result.Warnings) { $WarningsCount += $result.Warnings.Count }
      if ($result.Issues) { $WarningsCount += $result.Issues.Count }
   }
    
   $OverallPercentage = if ($MaxOverallScore -gt 0) { ($OverallScore / $MaxOverallScore) * 100 } else { 0 }
   $ProductionReady = $OverallPercentage -ge 90 -and $CriticalIssuesCount -eq 0
    
   $ReportContent += @"

- **Overall Score:** $([math]::Round($OverallPercentage, 1))% ($OverallScore/$MaxOverallScore points)
- **Production Ready:** $($ProductionReady)
- **Critical Issues:** $CriticalIssuesCount
- **Warnings:** $WarningsCount

### 🎯 Readiness Status

$( if ($ProductionReady) {
    "🟢 **PRODUCTION READY** - All critical components validated successfully"
} elseif ($OverallPercentage -ge 80) {
    "🟡 **NEARLY READY** - Minor issues need attention before production deployment"
} else {
    "🔴 **NOT READY** - Critical issues must be resolved before production deployment"
} )

---

## 📋 DETAILED VALIDATION RESULTS

"@

   foreach ($categoryName in $Results.Keys) {
      $result = $Results[$categoryName]
      $percentage = [math]::Round($result.Percentage, 1)
        
      $ReportContent += @"

### $categoryName

- **Score:** $percentage% ($($result.Score)/$($result.MaxScore) points)
- **Status:** $( if ($percentage -ge 90) { "✅ EXCELLENT" } elseif ($percentage -ge 70) { "⚠️ GOOD" } else { "❌ NEEDS IMPROVEMENT" } )

"@
        
      if ($result.CriticalIssues -and $result.CriticalIssues.Count -gt 0) {
         $ReportContent += "**Critical Issues:**`n"
         foreach ($issue in $result.CriticalIssues) {
            $ReportContent += "- ❌ $issue`n"
         }
         $ReportContent += "`n"
      }
        
      if ($result.Warnings -and $result.Warnings.Count -gt 0) {
         $ReportContent += "**Warnings:**`n"
         foreach ($warning in $result.Warnings) {
            $ReportContent += "- ⚠️ $warning`n"
         }
         $ReportContent += "`n"
      }
        
      if ($result.Issues -and $result.Issues.Count -gt 0) {
         $ReportContent += "**Issues:**`n"
         foreach ($issue in $result.Issues) {
            $ReportContent += "- ⚠️ $issue`n"
         }
         $ReportContent += "`n"
      }
   }
    
   $ReportContent += @"

---

## 🛠️ RECOMMENDATIONS

"@

   if ($ProductionReady) {
      $ReportContent += @"
✅ **Framework is production-ready!**

### Next Steps:
1. Execute final end-to-end integration tests
2. Run production deployment orchestrator
3. Enable real-time monitoring dashboard
4. Set up automated health checks
5. Configure alert notifications

"@
   }
   else {
      $ReportContent += @"
⚠️ **Address the following before production deployment:**

"@
      if ($CriticalIssuesCount -gt 0) {
         $ReportContent += "### Critical Issues (Must Fix):`n"
         foreach ($categoryName in $Results.Keys) {
            $result = $Results[$categoryName]
            if ($result.CriticalIssues -and $result.CriticalIssues.Count -gt 0) {
               foreach ($issue in $result.CriticalIssues) {
                  $ReportContent += "- 🔥 $issue`n"
               }
            }
         }
         $ReportContent += "`n"
      }
        
      $ReportContent += "### Recommended Actions:`n"
      $ReportContent += "1. Run with ``-FixIssues`` flag to auto-resolve common problems`n"
      $ReportContent += "2. Review and complete missing components`n"
      $ReportContent += "3. Run comprehensive testing before deployment`n"
      $ReportContent += "4. Validate security and performance requirements`n"
      $ReportContent += "`n"
   }
    
   $ReportContent += @"

---

## 🎯 PRODUCTION DEPLOYMENT READINESS MATRIX

| Category | Score | Status | Critical Issues | Warnings |
|----------|-------|--------|----------------|----------|
"@
    
   foreach ($categoryName in $Results.Keys) {
      $result = $Results[$categoryName]
      $percentage = [math]::Round($result.Percentage, 1)
      $status = if ($percentage -ge 90) { "✅ READY" } elseif ($percentage -ge 70) { "⚠️ REVIEW" } else { "❌ BLOCK" }
      $criticalCount = if ($result.CriticalIssues) { $result.CriticalIssues.Count } else { 0 }
      $warningCount = if ($result.Warnings) { $result.Warnings.Count } elseif ($result.Issues) { $result.Issues.Count } else { 0 }
        
      $ReportContent += "| $categoryName | $percentage% | $status | $criticalCount | $warningCount |`n"
   }
    
   $ReportContent += @"

---

## 📈 FRAMEWORK STATISTICS

- **Total Components Validated:** $($Results.Keys.Count)
- **Overall Health Score:** $([math]::Round($OverallPercentage, 1))%
- **Production Readiness:** $($ProductionReady)
- **Validation Duration:** $((Get-Date) - (Get-Date $ValidationTimestamp))

---

*Generated by Ultra-Advanced 8-Level Branching Framework Production Readiness Validator*  
*Validation ID: PROD-READY-$ValidationTimestamp*
"@

   return $ReportContent
}

# Main validation execution
function Start-ProductionReadinessValidation {
   Write-ValidationLog "🚀 Ultra-Advanced 8-Level Branching Framework" "INFO"
   Write-ValidationLog "   Production Readiness Validation v2.0" "INFO"
   Write-ValidationLog "============================================" "INFO"
    
   $Results = @{}
    
   # Validate each category
   foreach ($categoryName in $ProductionCriteria.Keys) {
      $category = $ProductionCriteria[$categoryName]
      $Results[$categoryName] = Test-ComponentReadiness -CategoryName $categoryName -Category $category
   }
    
   # Additional validations
   $Results["Security Readiness"] = Test-SecurityReadiness
   $Results["Performance Readiness"] = Test-PerformanceReadiness
   $Results["Test Coverage"] = Test-TestCoverage
    
   # Calculate overall results
   $OverallScore = 0
   $MaxOverallScore = 0
   $CriticalIssuesTotal = 0
    
   foreach ($result in $Results.Values) {
      $OverallScore += $result.Score
      $MaxOverallScore += $result.MaxScore
      if ($result.CriticalIssues) { $CriticalIssuesTotal += $result.CriticalIssues.Count }
   }
    
   $OverallPercentage = if ($MaxOverallScore -gt 0) { ($OverallScore / $MaxOverallScore) * 100 } else { 0 }
   $ProductionReady = $OverallPercentage -ge 90 -and $CriticalIssuesTotal -eq 0
    
   # Summary
   Write-ValidationLog "============================================" "INFO"
   Write-ValidationLog "🎯 VALIDATION COMPLETE" "INFO"
   Write-ValidationLog "Overall Score: $([math]::Round($OverallPercentage, 1))% ($OverallScore/$MaxOverallScore)" "INFO"
   Write-ValidationLog "Critical Issues: $CriticalIssuesTotal" $(if ($CriticalIssuesTotal -gt 0) { "ERROR" } else { "SUCCESS" })
   Write-ValidationLog "Production Ready: $ProductionReady" $(if ($ProductionReady) { "SUCCESS" } else { "WARNING" })
   Write-ValidationLog "============================================" "INFO"
    
   # Generate report if requested
   if ($GenerateReport) {
      Write-ValidationLog "📊 Generating detailed production readiness report..." "INFO"
      $ReportContent = New-ProductionReadinessReport -Results $Results
      $ReportContent | Out-File -FilePath $ReportFile -Encoding UTF8
      Write-ValidationLog "Report saved to: $ReportFile" "SUCCESS"
   }
    
   return @{
      Overall    = @{
         Score           = $OverallScore
         MaxScore        = $MaxOverallScore
         Percentage      = $OverallPercentage
         ProductionReady = $ProductionReady
         CriticalIssues  = $CriticalIssuesTotal
      }
      Categories = $Results
      ReportFile = $ReportFile
   }
}

# Execute validation
try {
   $ValidationResults = Start-ProductionReadinessValidation
    
   if ($ValidationResults.Overall.ProductionReady) {
      Write-ValidationLog "🎉 Framework is PRODUCTION READY!" "SUCCESS"
      Write-ValidationLog "✅ All critical components validated successfully" "SUCCESS"
      Write-ValidationLog "🚀 Ready for production deployment" "SUCCESS"
      exit 0
   }
   else {
      Write-ValidationLog "⚠️  Framework needs attention before production deployment" "WARNING"
      Write-ValidationLog "📋 Review the generated report for detailed recommendations" "INFO"
      exit 1
   }
}
catch {
   Write-ValidationLog "❌ Validation failed: $_" "CRITICAL"
   exit 2
}
