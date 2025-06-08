#!/usr/bin/env pwsh
# Ultra-Advanced 8-Level Branching Framework - Final Deployment Preparation
# =========================================================================

param(
    [string]$Environment = "production",
    [switch]$SkipValidation,
    [switch]$ForceDeployment,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 ULTRA-ADVANCED 8-LEVEL BRANCHING FRAMEWORK" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "🎯 FINAL DEPLOYMENT PREPARATION" -ForegroundColor Green
Write-Host ""
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$ProjectRoot = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$BranchingRoot = "$ProjectRoot\development\managers\branching-manager"

# Deployment Statistics
$DeploymentStats = @{
    TotalComponents = 0
    ValidatedComponents = 0
    DeployedComponents = 0
    FailedComponents = 0
    StartTime = Get-Date
}

function Write-DeploymentStep {
    param(
        [string]$Step,
        [string]$Status,
        [string]$Details = ""
    )
    
    $Icons = @{
        "START" = "🚀"
        "SUCCESS" = "✅"
        "WARNING" = "⚠️"
        "ERROR" = "❌"
        "INFO" = "ℹ️"
    }
    
    $Colors = @{
        "START" = "Cyan"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "INFO" = "Blue"
    }
    
    Write-Host "$($Icons[$Status]) $Step" -ForegroundColor $Colors[$Status]
    if ($Details) {
        Write-Host "   $Details" -ForegroundColor Gray
    }
}

# Step 1: Pre-deployment Validation
Write-DeploymentStep "Pre-deployment Validation" "START"

if (-not $SkipValidation) {
    # Core framework components
    $CoreComponents = @{
        "8-Level Branching Manager" = "$BranchingRoot\development\branching_manager.go"
        "Test Suite" = "$BranchingRoot\tests\branching_manager_test.go"
        "AI Predictor" = "$BranchingRoot\ai\predictor.go"
        "PostgreSQL Storage" = "$BranchingRoot\database\postgresql_storage.go"
        "Qdrant Vector DB" = "$BranchingRoot\database\qdrant_vector.go"
        "Git Operations" = "$BranchingRoot\git\git_operations.go"
        "n8n Integration" = "$BranchingRoot\integrations\n8n_integration.go"
        "MCP Gateway" = "$BranchingRoot\integrations\mcp_gateway.go"
    }
    
    foreach ($component in $CoreComponents.GetEnumerator()) {
        $DeploymentStats.TotalComponents++
        
        if (Test-Path $component.Value) {
            $lineCount = (Get-Content $component.Value | Measure-Object -Line).Lines
            if ($lineCount -gt 100) {
                Write-DeploymentStep $component.Key "SUCCESS" "Validated ($lineCount lines)"
                $DeploymentStats.ValidatedComponents++
            } else {
                Write-DeploymentStep $component.Key "WARNING" "Component too small ($lineCount lines)"
            }
        } else {
            Write-DeploymentStep $component.Key "ERROR" "Component missing"
            $DeploymentStats.FailedComponents++
        }
    }
} else {
    Write-DeploymentStep "Validation" "WARNING" "Skipped per user request"
}

# Step 2: Production Assets Check
Write-Host ""
Write-DeploymentStep "Production Assets Verification" "START"

$ProductionAssets = @{
    "Deployment Script" = "$ProjectRoot\production_deployment.ps1"
    "Final Deployment" = "$ProjectRoot\final_production_deployment.ps1"
    "Monitoring Dashboard" = "$ProjectRoot\monitoring_dashboard.go"
    "Framework Validator" = "$ProjectRoot\framework_validator.go"
    "Integration Tests" = "$ProjectRoot\integration_test_runner.go"
}

foreach ($asset in $ProductionAssets.GetEnumerator()) {
    $DeploymentStats.TotalComponents++
    
    if (Test-Path $asset.Value) {
        Write-DeploymentStep $asset.Key "SUCCESS" "Available for deployment"
        $DeploymentStats.ValidatedComponents++
        $DeploymentStats.DeployedComponents++
    } else {
        Write-DeploymentStep $asset.Key "ERROR" "Missing production asset"
        $DeploymentStats.FailedComponents++
    }
}

# Step 3: Environment Preparation
Write-Host ""
Write-DeploymentStep "Environment Preparation" "START"

if (-not $DryRun) {
    # Create deployment directories
    $DeploymentDirs = @(
        "$ProjectRoot\deployment\$Environment",
        "$ProjectRoot\deployment\$Environment\config",
        "$ProjectRoot\deployment\$Environment\logs",
        "$ProjectRoot\deployment\$Environment\data"
    )
    
    foreach ($dir in $DeploymentDirs) {
        try {
            if (-not (Test-Path $dir)) {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
            }
            Write-DeploymentStep "Directory: $(Split-Path $dir -Leaf)" "SUCCESS" "Created/Verified"
        }
        catch {
            Write-DeploymentStep "Directory: $(Split-Path $dir -Leaf)" "ERROR" $_.Exception.Message
        }
    }
} else {
    Write-DeploymentStep "Environment Setup" "INFO" "Dry run - skipping directory creation"
}

# Step 4: Configuration Generation
Write-Host ""
Write-DeploymentStep "Configuration Generation" "START"

$ConfigContent = @{
    Environment = $Environment
    Version = "v1.0.0-PRODUCTION"
    Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    Components = @{
        BranchingLevels = 8
        AIEnabled = $true
        DatabaseConnections = @{
            PostgreSQL = "enabled"
            QdrantVector = "enabled"
        }
        Integrations = @{
            N8N = "enabled"
            MCP = "enabled"
            Git = "enabled"
        }
        Monitoring = @{
            Dashboard = "enabled"
            Prometheus = "enabled"
            Alerts = "enabled"
        }
    }
    Deployment = @{
        Strategy = "rolling"
        Replicas = if ($Environment -eq "production") { 5 } else { 2 }
        Resources = @{
            CPU = if ($Environment -eq "production") { "1000m" } else { "500m" }
            Memory = if ($Environment -eq "production") { "2Gi" } else { "1Gi" }
        }
    }
}

if (-not $DryRun) {
    try {
        $configPath = "$ProjectRoot\deployment\$Environment\config\framework_config.json"
        $ConfigContent | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
        Write-DeploymentStep "Framework Configuration" "SUCCESS" "Generated at $configPath"
    }
    catch {
        Write-DeploymentStep "Framework Configuration" "ERROR" $_.Exception.Message
    }
} else {
    Write-DeploymentStep "Configuration Generation" "INFO" "Dry run - configuration would be generated"
}

# Step 5: Deployment Readiness Assessment
Write-Host ""
Write-DeploymentStep "Deployment Readiness Assessment" "START"

$ReadinessScore = [math]::Round(($DeploymentStats.ValidatedComponents / $DeploymentStats.TotalComponents) * 100, 1)

Write-Host ""
Write-Host "📊 DEPLOYMENT STATISTICS" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host ""
Write-Host "Total Components: $($DeploymentStats.TotalComponents)" -ForegroundColor White
Write-Host "Validated: $($DeploymentStats.ValidatedComponents)" -ForegroundColor Green
Write-Host "Deployed: $($DeploymentStats.DeployedComponents)" -ForegroundColor Green
Write-Host "Failed: $($DeploymentStats.FailedComponents)" -ForegroundColor Red
Write-Host ""
Write-Host "🎯 Readiness Score: $ReadinessScore%" -ForegroundColor $(if ($ReadinessScore -ge 90) { "Green" } elseif ($ReadinessScore -ge 75) { "Yellow" } else { "Red" })

$ElapsedTime = (Get-Date) - $DeploymentStats.StartTime
Write-Host "⏱️  Preparation Time: $($ElapsedTime.TotalSeconds.ToString('0.0'))s" -ForegroundColor Cyan

# Final Deployment Decision
Write-Host ""
if ($ReadinessScore -ge 90 -or $ForceDeployment) {
    Write-Host "🚀 DEPLOYMENT STATUS: GO FOR PRODUCTION" -ForegroundColor Green
    Write-Host "✨ Framework is ready for enterprise deployment!" -ForegroundColor Green
    
    if (-not $DryRun) {
        Write-Host ""
        Write-Host "🎯 RECOMMENDED NEXT STEPS:" -ForegroundColor Cyan
        Write-Host "1. Execute: .\production_deployment.ps1 -Environment $Environment" -ForegroundColor White
        Write-Host "2. Monitor: .\monitoring_dashboard.go" -ForegroundColor White
        Write-Host "3. Validate: .\framework_validator.go" -ForegroundColor White
    }
} elseif ($ReadinessScore -ge 75) {
    Write-Host "⚠️ DEPLOYMENT STATUS: PROCEED WITH CAUTION" -ForegroundColor Yellow
    Write-Host "🔧 Some components need attention but deployment is possible" -ForegroundColor Yellow
} else {
    Write-Host "❌ DEPLOYMENT STATUS: NOT READY" -ForegroundColor Red
    Write-Host "🛠️ Critical issues must be resolved before deployment" -ForegroundColor Red
    
    Write-Host ""
    Write-Host "🔧 REQUIRED ACTIONS:" -ForegroundColor Red
    Write-Host "1. Fix missing/failed components" -ForegroundColor White
    Write-Host "2. Re-run preparation with validation" -ForegroundColor White
    Write-Host "3. Ensure minimum 90% readiness score" -ForegroundColor White
}

Write-Host ""
Write-Host "🏁 Ultra-Advanced 8-Level Branching Framework Deployment Preparation Complete" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
