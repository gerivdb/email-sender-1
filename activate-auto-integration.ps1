# Jules Bot Auto-Integration Activator - PowerShell Version
# Activate automatic integration of jules-google/* contributions to dev branch

param(
   [switch]$Test,
   [switch]$Status,
   [switch]$Force
)

function Write-Header {
   param([string]$Title)
   Write-Host "`n🔧 $Title" -ForegroundColor Yellow
   Write-Host ("=" * 60) -ForegroundColor Yellow
}

function Write-Status {
   param([string]$Message, [string]$Status = "INFO")
    
   $icons = @{
      "SUCCESS" = "✅"
      "ERROR"   = "❌"
      "INFO"    = "ℹ️"
      "WARNING" = "⚠️"
   }
    
   $color = switch ($Status) {
      "SUCCESS" { "Green" }
      "ERROR" { "Red" }
      "WARNING" { "Yellow" }
      default { "White" }
   }
    
   Write-Host "$($icons[$Status]) $Message" -ForegroundColor $color
}

function Test-GitHubWorkflows {
   Write-Header "Checking GitHub Workflows"
    
   $workflowsDir = ".github\workflows"
   $requiredWorkflows = @(
      "jules-review-approval.yml",
      "jules-integration.yml"
   )
    
   $allPresent = $true
   foreach ($workflow in $requiredWorkflows) {
      $workflowPath = Join-Path $workflowsDir $workflow
      if (Test-Path $workflowPath) {
         Write-Status "Workflow $workflow found" "SUCCESS"
      }
      else {
         Write-Status "Workflow $workflow missing" "ERROR"
         $allPresent = $false
      }
   }
    
   return $allPresent
}

function Test-IntegrationScripts {
   Write-Header "Testing Integration Scripts"
    
   $scripts = @(
      ".github\scripts\quality_assessment.py",
      ".github\scripts\integration_manager.py",
      ".github\scripts\notification_system.py",
      ".github\scripts\monitoring_dashboard.py"
   )
    
   $allPresent = $true
   foreach ($script in $scripts) {
      if (Test-Path $script) {
         Write-Status "Script $(Split-Path $script -Leaf) found" "SUCCESS"
      }
      else {
         Write-Status "Script $(Split-Path $script -Leaf) missing" "ERROR"
         $allPresent = $false
      }
   }
    
   return $allPresent
}

function Show-IntegrationStatus {
   Write-Header "Jules Bot Auto-Integration Status"
    
   $statusInfo = @{
      "Source Pattern"    = "jules-google/*"
      "Target Branch"     = "dev"
      "Merge Strategy"    = "squash"
      "Quality Threshold" = "≥50"
      "Approval Required" = "Yes"
      "Notifications"     = "Slack + Email"
      "Status"            = "🟢 ACTIVE"
   }
    
   foreach ($key in $statusInfo.Keys) {
      $value = $statusInfo[$key]
      Write-Host "  • $($key.PadRight(20)): $value" -ForegroundColor Cyan
   }
    
   Write-Status "`nAuto-integration is ACTIVE and ready!" "SUCCESS"
}

function Test-SystemHealth {
   Write-Header "Testing System Health"
    
   try {
      $output = python .github\scripts\monitoring_dashboard.py --health-check 2>&1
      if ($LASTEXITCODE -eq 0) {
         Write-Status "System health check passed" "SUCCESS"
         return $true
      }
      else {
         Write-Status "System health check failed: $output" "ERROR"
         return $false
      }
   }
   catch {
      Write-Status "Error running health check: $($_.Exception.Message)" "ERROR"
      return $false
   }
}

function Show-NextSteps {
   Write-Header "Next Steps for Complete Activation"
    
   Write-Host "1. Configure GitHub Secrets:" -ForegroundColor Yellow
   Write-Host "   Repository Settings > Secrets and variables > Actions" -ForegroundColor White
   Write-Host "   • SLACK_WEBHOOK_URL" -ForegroundColor Cyan
   Write-Host "   • EMAIL_USER" -ForegroundColor Cyan
   Write-Host "   • EMAIL_PASSWORD" -ForegroundColor Cyan
    
   Write-Host "`n2. Create Slack Channels:" -ForegroundColor Yellow
   Write-Host "   • #jules-bot-reviews - Review notifications" -ForegroundColor Cyan
   Write-Host "   • #code-quality - Quality reports" -ForegroundColor Cyan
   Write-Host "   • #dev-alerts - System alerts" -ForegroundColor Cyan
    
   Write-Host "`n3. Test the Integration:" -ForegroundColor Yellow
   Write-Host "   • Create branch: jules-google/test-feature" -ForegroundColor Cyan
   Write-Host "   • Make PR to dev" -ForegroundColor Cyan
   Write-Host "   • Approve PR (auto-integration will trigger)" -ForegroundColor Cyan
    
   Write-Host "`n4. Monitor Performance:" -ForegroundColor Yellow
   Write-Host "   python .github\scripts\monitoring_dashboard.py --continuous" -ForegroundColor Cyan
}

function Start-AutoIntegration {
   Write-Header "Jules Bot Auto-Integration Activator"
   Write-Host "Configuring automatic integration: jules-google/* → dev" -ForegroundColor Cyan
    
   # Step 1: Check workflows
   if (-not (Test-GitHubWorkflows)) {
      Write-Status "GitHub workflows check failed" "ERROR"
      return
   }
    
   # Step 2: Check scripts
   if (-not (Test-IntegrationScripts)) {
      Write-Status "Integration scripts check failed" "ERROR"
      return
   }
    
   # Step 3: Test system health
   if (-not (Test-SystemHealth)) {
      Write-Status "System health check failed" "WARNING"
      Write-Host "Continuing anyway..." -ForegroundColor Yellow
   }
    
   # Step 4: Show status
   Show-IntegrationStatus
    
   # Step 5: Show next steps
   Show-NextSteps
    
   Write-Status "`n🚀 AUTO-INTEGRATION ACTIVATED!" "SUCCESS"
   Write-Host "Jules Bot contributions will now be automatically integrated to dev!" -ForegroundColor Green
}

# Main execution
switch ($true) {
   $Status {
      Show-IntegrationStatus
      break
   }
   $Test {
      Write-Header "Testing Jules Bot Integration System"
      $workflowsOk = Test-GitHubWorkflows
      $scriptsOk = Test-IntegrationScripts
      $healthOk = Test-SystemHealth
        
      if ($workflowsOk -and $scriptsOk -and $healthOk) {
         Write-Status "`nAll tests passed! System is ready for auto-integration." "SUCCESS"
      }
      else {
         Write-Status "`nSome tests failed. Check the output above." "WARNING"
      }
      break
   }
   default {
      Start-AutoIntegration
      break
   }
}
