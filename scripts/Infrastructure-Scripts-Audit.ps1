#!/usr/bin/env pwsh
# ================================================================
# Infrastructure-Scripts-Audit.ps1 - Audit des scripts existants
# Phase 0.1 : PowerShell Scripts Debugging
# ================================================================

Write-Host "🔍 Infrastructure Scripts Audit - Phase 0.1" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Configuration
$SCRIPTS_TO_AUDIT = @(
   "Start-FullStack.ps1",
   "Emergency-Diagnostic-v2.ps1",
   "Optimize-ProjectResources.ps1",
   "Quick-Fix.ps1",
   "Advanced-RAM-Optimizer.ps1",
   "Memory-Manager-Simple.ps1"
)

$AUDIT_RESULTS = @()

function Test-ScriptExistence {
   param([string]$ScriptName)
    
   Write-Host "`n📋 Auditing: $ScriptName" -ForegroundColor Yellow
    
   $scriptPath = Get-ChildItem -Path . -Name $ScriptName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    
   if ($scriptPath) {
      Write-Host "   ✅ Found: $scriptPath" -ForegroundColor Green
      return @{
         Name         = $ScriptName
         Exists       = $true
         Path         = $scriptPath
         Size         = (Get-Item $scriptPath).Length
         LastModified = (Get-Item $scriptPath).LastWriteTime
      }
   }
   else {
      Write-Host "   ❌ Not found: $ScriptName" -ForegroundColor Red
      return @{
         Name         = $ScriptName
         Exists       = $false
         Path         = $null
         Size         = 0
         LastModified = $null
      }
   }
}

function Test-ScriptSyntax {
   param([string]$ScriptPath)
    
   if (-not $ScriptPath -or -not (Test-Path $ScriptPath)) {
      return @{ IsValid = $false; Errors = @("Script not found") }
   }
    
   try {
      $errors = @()
      $warnings = @()
        
      # Test de syntaxe PowerShell
      $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $ScriptPath -Raw), [ref]$errors)
        
      # Vérifications spécifiques
      $content = Get-Content $ScriptPath -Raw
        
      # Check pour error handling
      if ($content -notmatch "try\s*\{|catch\s*\{|\-ErrorAction") {
         $warnings += "Limited error handling detected"
      }
        
      # Check pour Write-Host vs Write-Output
      if ($content -match "Write-Host.*\$") {
         $warnings += "Potential variable interpolation issues in Write-Host"
      }
        
      # Check pour processus cleanup
      if ($content -match "Stop-Process" -and $content -notmatch "\-ErrorAction") {
         $warnings += "Stop-Process without error handling"
      }
        
      return @{
         IsValid  = $errors.Count -eq 0
         Errors   = $errors | ForEach-Object { $_.Message }
         Warnings = $warnings
      }
   }
   catch {
      return @{
         IsValid  = $false
         Errors   = @($_.Exception.Message)
         Warnings = @()
      }
   }
}

function Test-ScriptFunctionality {
   param([string]$ScriptPath, [string]$ScriptName)
    
   if (-not (Test-Path $ScriptPath)) {
      return @{ FunctionalityTest = "SKIP"; Details = "Script not found" }
   }
    
   $content = Get-Content $ScriptPath -Raw
   $functionalityScore = 0
   $maxScore = 5
   $details = @()
    
   # Test 1: Resource monitoring
   if ($content -match "(Get-Process|Get-CimInstance|memory|RAM|CPU)") {
      $functionalityScore++
      $details += "✅ Resource monitoring capabilities"
   }
   else {
      $details += "❌ No resource monitoring"
   }
    
   # Test 2: Process management
   if ($content -match "(Start-Process|Stop-Process|Get-Process)") {
      $functionalityScore++
      $details += "✅ Process management capabilities"
   }
   else {
      $details += "❌ No process management"
   }
    
   # Test 3: Error handling
   if ($content -match "(try|catch|ErrorAction|ErrorVariable)") {
      $functionalityScore++
      $details += "✅ Error handling present"
   }
   else {
      $details += "❌ Limited error handling"
   }
    
   # Test 4: Logging/Output
   if ($content -match "(Write-Host|Write-Output|Write-Information)") {
      $functionalityScore++
      $details += "✅ Logging/output capabilities"
   }
   else {
      $details += "❌ No logging capabilities"
   }
    
   # Test 5: Infrastructure specific
   if ($content -match "(api-server|docker|localhost|8080|infrastructure)") {
      $functionalityScore++
      $details += "✅ Infrastructure-specific logic"
   }
   else {
      $details += "❌ No infrastructure-specific logic"
   }
    
   $percentage = [math]::Round(($functionalityScore / $maxScore) * 100, 1)
    
   if ($percentage -ge 80) {
      $status = "EXCELLENT"
   }
   elseif ($percentage -ge 60) {
      $status = "GOOD"
   }
   elseif ($percentage -ge 40) {
      $status = "AVERAGE"
   }
   else {
      $status = "POOR"
   }
    
   return @{
      FunctionalityTest = $status
      Score             = "$functionalityScore/$maxScore ($percentage%)"
      Details           = $details
   }
}

function Generate-AuditReport {
   param([array]$AuditResults)
    
   Write-Host "`n===============================================" -ForegroundColor Cyan
   Write-Host "📊 INFRASTRUCTURE SCRIPTS AUDIT REPORT" -ForegroundColor Cyan
   Write-Host "===============================================" -ForegroundColor Cyan
    
   $totalScripts = $AuditResults.Count
   $existingScripts = ($AuditResults | Where-Object { $_.Exists }).Count
   $validScripts = ($AuditResults | Where-Object { $_.SyntaxCheck.IsValid }).Count
    
   Write-Host "`n📈 SUMMARY STATISTICS:" -ForegroundColor Yellow
   Write-Host "   Total Scripts Audited: $totalScripts" -ForegroundColor White
   Write-Host "   Scripts Found: $existingScripts" -ForegroundColor White
   Write-Host "   Syntactically Valid: $validScripts" -ForegroundColor White
   Write-Host "   Missing Scripts: $($totalScripts - $existingScripts)" -ForegroundColor White
    
   Write-Host "`n📋 DETAILED RESULTS:" -ForegroundColor Yellow
    
   foreach ($result in $AuditResults) {
      Write-Host "`n🔸 $($result.Name)" -ForegroundColor Cyan
        
      if ($result.Exists) {
         Write-Host "   ✅ Status: Found" -ForegroundColor Green
         Write-Host "   📁 Path: $($result.Path)" -ForegroundColor Gray
         Write-Host "   📏 Size: $([math]::Round($result.Size/1KB, 1)) KB" -ForegroundColor Gray
         Write-Host "   📅 Modified: $($result.LastModified)" -ForegroundColor Gray
            
         if ($result.SyntaxCheck.IsValid) {
            Write-Host "   ✅ Syntax: Valid" -ForegroundColor Green
         }
         else {
            Write-Host "   ❌ Syntax: Invalid" -ForegroundColor Red
            foreach ($error in $result.SyntaxCheck.Errors) {
               Write-Host "     Error: $error" -ForegroundColor Red
            }
         }
            
         if ($result.SyntaxCheck.Warnings.Count -gt 0) {
            Write-Host "   ⚠️  Warnings:" -ForegroundColor Yellow
            foreach ($warning in $result.SyntaxCheck.Warnings) {
               Write-Host "     $warning" -ForegroundColor Yellow
            }
         }
            
         Write-Host "   🎯 Functionality: $($result.FunctionalityTest.FunctionalityTest) ($($result.FunctionalityTest.Score))" -ForegroundColor Cyan
      }
      else {
         Write-Host "   ❌ Status: Missing" -ForegroundColor Red
         Write-Host "   💡 Recommendation: Create this script for infrastructure management" -ForegroundColor Yellow
      }
   }
    
   Write-Host "`n🎯 RECOMMENDATIONS:" -ForegroundColor Yellow
    
   $missingScripts = $AuditResults | Where-Object { -not $_.Exists }
   if ($missingScripts.Count -gt 0) {
      Write-Host "   📝 Create missing scripts:" -ForegroundColor Yellow
      foreach ($missing in $missingScripts) {
         Write-Host "     - $($missing.Name)" -ForegroundColor Gray
      }
   }
    
   $scriptsWithErrors = $AuditResults | Where-Object { $_.Exists -and -not $_.SyntaxCheck.IsValid }
   if ($scriptsWithErrors.Count -gt 0) {
      Write-Host "   🔧 Fix syntax errors in:" -ForegroundColor Yellow
      foreach ($errorScript in $scriptsWithErrors) {
         Write-Host "     - $($errorScript.Name)" -ForegroundColor Gray
      }
   }
    
   $scriptsWithWarnings = $AuditResults | Where-Object { $_.Exists -and $_.SyntaxCheck.Warnings.Count -gt 0 }
   if ($scriptsWithWarnings.Count -gt 0) {
      Write-Host "   ⚠️  Address warnings in:" -ForegroundColor Yellow
      foreach ($warningScript in $scriptsWithWarnings) {
         Write-Host "     - $($warningScript.Name)" -ForegroundColor Gray
      }
   }
    
   Write-Host "`n===============================================" -ForegroundColor Cyan
   $overallHealth = [math]::Round(($validScripts / $totalScripts) * 100, 1)
   Write-Host "📊 OVERALL INFRASTRUCTURE SCRIPTS HEALTH: $overallHealth%" -ForegroundColor Cyan
    
   if ($overallHealth -ge 80) {
      Write-Host "🎉 EXCELLENT - Scripts are in good condition" -ForegroundColor Green
   }
   elseif ($overallHealth -ge 60) {
      Write-Host "✅ GOOD - Minor improvements needed" -ForegroundColor Yellow
   }
   else {
      Write-Host "⚠️  NEEDS ATTENTION - Significant improvements required" -ForegroundColor Red
   }
    
   Write-Host "===============================================" -ForegroundColor Cyan
}

# ================================================================
# EXÉCUTION PRINCIPALE
# ================================================================

try {
   Write-Host "`n🚀 Starting infrastructure scripts audit..." -ForegroundColor Cyan
    
   foreach ($scriptName in $SCRIPTS_TO_AUDIT) {
      $auditResult = Test-ScriptExistence -ScriptName $scriptName
        
      if ($auditResult.Exists) {
         $auditResult.SyntaxCheck = Test-ScriptSyntax -ScriptPath $auditResult.Path
         $auditResult.FunctionalityTest = Test-ScriptFunctionality -ScriptPath $auditResult.Path -ScriptName $scriptName
      }
      else {
         $auditResult.SyntaxCheck = @{ IsValid = $false; Errors = @("Script not found"); Warnings = @() }
         $auditResult.FunctionalityTest = @{ FunctionalityTest = "N/A"; Score = "0/5 (0%)"; Details = @("Script not found") }
      }
        
      $AUDIT_RESULTS += $auditResult
   }
    
   # Générer le rapport d'audit
   Generate-AuditReport -AuditResults $AUDIT_RESULTS
    
   # Sauvegarder le rapport en JSON pour analyse ultérieure
   $reportPath = "infrastructure-audit-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
   $AUDIT_RESULTS | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
   Write-Host "`n💾 Detailed audit report saved to: $reportPath" -ForegroundColor Cyan
    
}
catch {
   Write-Host "`n❌ CRITICAL ERROR during audit process:" -ForegroundColor Red
   Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
   exit 1
}

Write-Host "`n✅ Infrastructure scripts audit completed successfully!" -ForegroundColor Green
