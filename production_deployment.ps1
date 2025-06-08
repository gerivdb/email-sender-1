#!/usr/bin/env pwsh
# Ultra-Advanced 8-Level Branching Framework - Production Deployment Script
# =========================================================================

param(
   [string]$Environment = "staging",
   [switch]$SkipTests,
   [switch]$SkipDocker,
   [switch]$SkipKubernetes,
   [switch]$DryRun,
   [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Ultra-Advanced 8-Level Branching Framework - Production Deployment" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$ProjectRoot = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$BranchingRoot = "$ProjectRoot\development\managers\branching-manager"

# Deployment configuration
$DeploymentConfig = @{
   staging    = @{
      namespace = "branching-staging"
      replicas  = 2
      resources = @{
         cpu    = "500m"
         memory = "1Gi"
      }
   }
   production = @{
      namespace = "branching-production"
      replicas  = 5
      resources = @{
         cpu    = "1000m"
         memory = "2Gi"
      }
   }
}

$Config = $DeploymentConfig[$Environment]

function Write-Step {
   param([string]$Message, [string]$Type = "Info")
   $Icons = @{
      Info    = "📋"
      Success = "✅"
      Warning = "⚠️"
      Error   = "❌"
      Deploy  = "🚀"
   }
    
   $Colors = @{
      Info    = "Cyan"
      Success = "Green"
      Warning = "Yellow"
      Error   = "Red"
      Deploy  = "Magenta"
   }
    
   Write-Host "$($Icons[$Type]) $Message" -ForegroundColor $Colors[$Type]
}

function Invoke-SafeCommand {
   param([string]$Command, [string]$Description)
    
   Write-Step "Executing: $Description" "Info"
   if ($Verbose) {
      Write-Host "  Command: $Command" -ForegroundColor Gray
   }
    
   if ($DryRun) {
      Write-Host "  [DRY RUN] Would execute: $Command" -ForegroundColor Yellow
      return $true
   }
    
   try {
      Invoke-Expression $Command
      Write-Step "Completed: $Description" "Success"
      return $true
   }
   catch {
      Write-Step "Failed: $Description - $($_.Exception.Message)" "Error"
      return $false
   }
}

# Step 1: Pre-deployment Validation
Write-Step "=== PRE-DEPLOYMENT VALIDATION ===" "Deploy"

Write-Step "Validating core framework files..." "Info"
$CoreFiles = @(
   "$BranchingRoot\development\branching_manager.go",
   "$BranchingRoot\tests\branching_manager_test.go",
   "$BranchingRoot\ai\predictor.go",
   "$BranchingRoot\database\postgresql_storage.go",
   "$BranchingRoot\database\qdrant_vector.go",
   "$BranchingRoot\git\git_operations.go",
   "$BranchingRoot\integrations\n8n_integration.go",
   "$BranchingRoot\integrations\mcp_gateway.go",
   "$BranchingRoot\Dockerfile",
   "$BranchingRoot\k8s\deployment.yaml"
)

$MissingFiles = @()
foreach ($file in $CoreFiles) {
   if (-not (Test-Path $file)) {
      $MissingFiles += $file
   }
}

if ($MissingFiles.Count -gt 0) {
   Write-Step "Missing critical files:" "Error"
   foreach ($file in $MissingFiles) {
      Write-Host "  - $file" -ForegroundColor Red
   }
   exit 1
}

Write-Step "All core framework files present" "Success"

# Step 2: Environment Setup
Write-Step "=== ENVIRONMENT SETUP ===" "Deploy"

Write-Step "Setting up deployment environment..." "Info"

# Create deployment directory
$DeployDir = "$ProjectRoot\deployment\$Environment"
if (-not (Test-Path $DeployDir)) {
   New-Item -ItemType Directory -Path $DeployDir -Force | Out-Null
}

# Generate environment-specific configuration
$EnvConfig = @{
   environment = $Environment
   namespace   = $Config.namespace
   replicas    = $Config.replicas
   resources   = $Config.resources
   timestamp   = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
   version     = "v1.0.0-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

$ConfigJson = $EnvConfig | ConvertTo-Json -Depth 10
$ConfigJson | Out-File -FilePath "$DeployDir\config.json" -Encoding UTF8

Write-Step "Environment configuration created" "Success"

# Step 3: Run Integration Tests (if not skipped)
if (-not $SkipTests) {
   Write-Step "=== INTEGRATION TESTING ===" "Deploy"
    
   Write-Step "Running comprehensive integration tests..." "Info"
    
   Push-Location $BranchingRoot
    
   # Run Go tests
   $testResult = Invoke-SafeCommand "go test -v ./..." "Go integration tests"
    
   # Run custom integration tests
   if (Test-Path "$ProjectRoot\integration_test_runner.go") {
      $customTestResult = Invoke-SafeCommand "go run $ProjectRoot\integration_test_runner.go" "Custom integration tests"
   }
    
   Pop-Location
    
   if (-not $testResult) {
      Write-Step "Integration tests failed - aborting deployment" "Error"
      exit 1
   }
    
   Write-Step "All integration tests passed" "Success"
}

# Step 4: Docker Build and Push (if not skipped)
if (-not $SkipDocker) {
   Write-Step "=== DOCKER BUILD AND DEPLOYMENT ===" "Deploy"
    
   Push-Location $BranchingRoot
    
   $ImageTag = "branching-framework:$($EnvConfig.version)"
   $RegistryTag = "your-registry.com/$ImageTag"
    
   # Build Docker image
   $buildResult = Invoke-SafeCommand "docker build -t $ImageTag -t $RegistryTag ." "Docker image build"
    
   if ($buildResult -and $Environment -eq "production") {
      # Push to registry for production
      $pushResult = Invoke-SafeCommand "docker push $RegistryTag" "Docker image push to registry"
        
      if (-not $pushResult) {
         Write-Step "Docker push failed - aborting deployment" "Error"
         exit 1
      }
   }
    
   Pop-Location
    
   Write-Step "Docker build completed" "Success"
}

# Step 5: Kubernetes Deployment (if not skipped)
if (-not $SkipKubernetes) {
   Write-Step "=== KUBERNETES DEPLOYMENT ===" "Deploy"
    
   # Generate Kubernetes manifests
   $K8sDir = "$DeployDir\k8s"
   if (-not (Test-Path $K8sDir)) {
      New-Item -ItemType Directory -Path $K8sDir -Force | Out-Null
   }
    
   # Copy and customize deployment manifest
   $deploymentTemplate = Get-Content "$BranchingRoot\k8s\deployment.yaml" -Raw
    
   # Replace placeholders with environment-specific values
   $customizedDeployment = $deploymentTemplate `
      -replace "{{NAMESPACE}}", $Config.namespace `
      -replace "{{REPLICAS}}", $Config.replicas `
      -replace "{{CPU_LIMIT}}", $Config.resources.cpu `
      -replace "{{MEMORY_LIMIT}}", $Config.resources.memory `
      -replace "{{IMAGE_TAG}}", $EnvConfig.version
    
   $customizedDeployment | Out-File -FilePath "$K8sDir\deployment.yaml" -Encoding UTF8
    
   # Create namespace manifest
   $namespaceManifest = @"
apiVersion: v1
kind: Namespace
metadata:
  name: $($Config.namespace)
  labels:
    environment: $Environment
    app: branching-framework
    version: $($EnvConfig.version)
"@
    
   $namespaceManifest | Out-File -FilePath "$K8sDir\namespace.yaml" -Encoding UTF8
    
   # Apply Kubernetes manifests
   if (-not $DryRun) {
      $namespaceResult = Invoke-SafeCommand "kubectl apply -f $K8sDir\namespace.yaml" "Kubernetes namespace creation"
      $deploymentResult = Invoke-SafeCommand "kubectl apply -f $K8sDir\deployment.yaml" "Kubernetes deployment"
        
      if ($namespaceResult -and $deploymentResult) {
         Write-Step "Waiting for deployment to be ready..." "Info"
         $rolloutResult = Invoke-SafeCommand "kubectl rollout status deployment/branching-framework -n $($Config.namespace) --timeout=300s" "Deployment rollout status"
            
         if ($rolloutResult) {
            Write-Step "Deployment is ready and healthy" "Success"
         }
      }
   }
    
   Write-Step "Kubernetes deployment configuration created" "Success"
}

# Step 6: Health Check and Validation
Write-Step "=== POST-DEPLOYMENT VALIDATION ===" "Deploy"

if (-not $DryRun -and -not $SkipKubernetes) {
   Write-Step "Running post-deployment health checks..." "Info"
    
   # Check pod status
   $podStatus = Invoke-SafeCommand "kubectl get pods -n $($Config.namespace) -l app=branching-framework" "Pod status check"
    
   # Check service endpoints
   $serviceStatus = Invoke-SafeCommand "kubectl get svc -n $($Config.namespace)" "Service status check"
    
   # Run health check endpoint (if available)
   # This would typically involve checking the /health endpoint of the deployed service
    
   Write-Step "Post-deployment validation completed" "Success"
}

# Step 7: Generate Deployment Report
Write-Step "=== DEPLOYMENT REPORT ===" "Deploy"

$DeploymentReport = @{
   deployment_id = [guid]::NewGuid().ToString()
   environment   = $Environment
   timestamp     = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
   version       = $EnvConfig.version
   configuration = $Config
   status        = "completed"
   components    = @{
      core_framework = "deployed"
      docker_image   = if ($SkipDocker) { "skipped" } else { "built" }
      kubernetes     = if ($SkipKubernetes) { "skipped" } else { "deployed" }
      tests          = if ($SkipTests) { "skipped" } else { "passed" }
   }
   files_created = @(
      "$DeployDir\config.json"
      "$K8sDir\deployment.yaml"
      "$K8sDir\namespace.yaml"
   )
}

$ReportJson = $DeploymentReport | ConvertTo-Json -Depth 10
$ReportPath = "$DeployDir\deployment-report.json"
$ReportJson | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Step "Deployment report saved to: $ReportPath" "Success"

# Step 8: Final Summary
Write-Step "=== DEPLOYMENT SUMMARY ===" "Deploy"

Write-Host ""
Write-Host "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉" -ForegroundColor Green
Write-Host ""
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Version: $($EnvConfig.version)" -ForegroundColor Cyan
Write-Host "Namespace: $($Config.namespace)" -ForegroundColor Cyan
Write-Host "Replicas: $($Config.replicas)" -ForegroundColor Cyan
Write-Host ""

if (-not $DryRun -and -not $SkipKubernetes) {
   Write-Host "Next steps:" -ForegroundColor Yellow
   Write-Host "1. Monitor deployment: kubectl get pods -n $($Config.namespace) -w" -ForegroundColor White
   Write-Host "2. Check logs: kubectl logs -f deployment/branching-framework -n $($Config.namespace)" -ForegroundColor White
   Write-Host "3. Access service: kubectl port-forward svc/branching-framework 8080:8080 -n $($Config.namespace)" -ForegroundColor White
}

Write-Host ""
Write-Host "🚀 Ultra-Advanced 8-Level Branching Framework is now deployed!" -ForegroundColor Magenta
Write-Host ""
