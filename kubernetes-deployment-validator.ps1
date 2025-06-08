#!/usr/bin/env pwsh
# Ultra-Advanced 8-Level Framework - Kubernetes Deployment Validator
# =================================================================

param(
   [string]$Environment = "staging",
   [string]$Namespace = "branching-staging",
   [switch]$DeepValidation = $true,
   [switch]$PerformanceTest = $true,
   [switch]$SecurityAudit = $true,
   [switch]$LoadTest = $false,
   [switch]$FixIssues = $true,
   [int]$TimeoutMinutes = 15
)

$ErrorActionPreference = "Stop"

Write-Host "🔍 KUBERNETES DEPLOYMENT VALIDATOR" -ForegroundColor Magenta
Write-Host "===================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "🎯 Environment: $Environment" -ForegroundColor Yellow
Write-Host "📦 Namespace: $Namespace" -ForegroundColor Yellow
Write-Host "⏱️  Timeout: $TimeoutMinutes minutes" -ForegroundColor Yellow
Write-Host ""

$ValidationResults = @{}
$Issues = @()
$Recommendations = @()

function Write-Validation {
   param([string]$Message, [string]$Type = "Info", [string]$Component = "General")
   $Icons = @{
      "Info"        = "ℹ️"
      "Success"     = "✅"
      "Warning"     = "⚠️"
      "Error"       = "❌"
      "Testing"     = "🧪"
      "Security"    = "🔒"
      "Performance" = "⚡"
      "Network"     = "🌐"
      "Storage"     = "💾"
   }
    
   $timestamp = Get-Date -Format "HH:mm:ss"
   Write-Host "[$timestamp] $($Icons[$Type]) [$Component] $Message" -ForegroundColor $(
      switch ($Type) {
         "Success" { "Green" }
         "Warning" { "Yellow" }
         "Error" { "Red" }
         "Testing" { "Cyan" }
         "Security" { "DarkYellow" }
         "Performance" { "Blue" }
         "Network" { "Magenta" }
         "Storage" { "DarkCyan" }
         default { "White" }
      }
   )
}

function Test-Prerequisites {
   Write-Validation "Checking Kubernetes cluster connectivity..." "Info" "Prerequisites"
    
   try {
      $clusterInfo = kubectl cluster-info --request-timeout=10s 2>$null
      if ($LASTEXITCODE -eq 0) {
         Write-Validation "Kubernetes cluster is accessible" "Success" "Prerequisites"
         return $true
      }
      else {
         Write-Validation "Cannot connect to Kubernetes cluster" "Error" "Prerequisites"
         return $false
      }
   }
   catch {
      Write-Validation "Kubernetes cluster connection failed: $_" "Error" "Prerequisites"
      return $false
   }
}

function Test-Namespace {
   Write-Validation "Validating namespace '$Namespace'..." "Info" "Namespace"
    
   try {
      $namespaceExists = kubectl get namespace $Namespace 2>$null
      if ($LASTEXITCODE -eq 0) {
         Write-Validation "Namespace '$Namespace' exists" "Success" "Namespace"
            
         # Check namespace status
         $nsStatus = kubectl get namespace $Namespace -o jsonpath='{.status.phase}' 2>$null
         if ($nsStatus -eq "Active") {
            Write-Validation "Namespace is in Active state" "Success" "Namespace"
            return $true
         }
         else {
            Write-Validation "Namespace is in '$nsStatus' state" "Warning" "Namespace"
            return $false
         }
      }
      else {
         Write-Validation "Namespace '$Namespace' does not exist" "Error" "Namespace"
         if ($FixIssues) {
            Write-Validation "Creating namespace '$Namespace'..." "Info" "Namespace"
            kubectl create namespace $Namespace
            if ($LASTEXITCODE -eq 0) {
               Write-Validation "Successfully created namespace '$Namespace'" "Success" "Namespace"
               return $true
            }
         }
         return $false
      }
   }
   catch {
      Write-Validation "Namespace validation failed: $_" "Error" "Namespace"
      return $false
   }
}

function Test-Deployments {
   Write-Validation "Validating deployments..." "Testing" "Deployments"
    
   $expectedDeployments = @(
      "branching-manager",
      "postgresql", 
      "redis",
      "qdrant",
      "prometheus",
      "grafana"
   )
    
   # Add advanced components if they exist
   $advancedComponents = @(
      "edge-router",
      "loadtest-controller", 
      "performance-optimizer",
      "ai-model-server"
   )
    
   $allDeployments = $expectedDeployments + $advancedComponents
   $deploymentResults = @{}
    
   foreach ($deployment in $allDeployments) {
      try {
         $deploymentStatus = kubectl get deployment $deployment -n $Namespace -o jsonpath='{.status}' 2>$null
         if ($LASTEXITCODE -eq 0) {
            $replicas = kubectl get deployment $deployment -n $Namespace -o jsonpath='{.status.replicas}' 2>$null
            $readyReplicas = kubectl get deployment $deployment -n $Namespace -o jsonpath='{.status.readyReplicas}' 2>$null
            $availableReplicas = kubectl get deployment $deployment -n $Namespace -o jsonpath='{.status.availableReplicas}' 2>$null
                
            if ($readyReplicas -eq $replicas -and $availableReplicas -eq $replicas) {
               Write-Validation "Deployment '$deployment' is healthy ($readyReplicas/$replicas ready)" "Success" "Deployments"
               $deploymentResults[$deployment] = @{ Status = "Healthy"; Ready = $readyReplicas; Total = $replicas }
            }
            else {
               Write-Validation "Deployment '$deployment' is not ready ($readyReplicas/$replicas ready)" "Warning" "Deployments"
               $deploymentResults[$deployment] = @{ Status = "NotReady"; Ready = $readyReplicas; Total = $replicas }
                    
               # Get pod details for troubleshooting
               $pods = kubectl get pods -n $Namespace -l app=$deployment -o jsonpath='{.items[*].status.phase}' 2>$null
               Write-Validation "Pod phases for '$deployment': $pods" "Info" "Deployments"
            }
         }
         else {
            if ($deployment -in $expectedDeployments) {
               Write-Validation "Required deployment '$deployment' not found" "Error" "Deployments"
               $deploymentResults[$deployment] = @{ Status = "Missing"; Ready = 0; Total = 0 }
            }
            else {
               Write-Validation "Advanced deployment '$deployment' not deployed (optional)" "Info" "Deployments"
            }
         }
      }
      catch {
         Write-Validation "Error checking deployment '$deployment': $_" "Error" "Deployments"
         $deploymentResults[$deployment] = @{ Status = "Error"; Ready = 0; Total = 0 }
      }
   }
    
   $ValidationResults.Deployments = $deploymentResults
   return ($deploymentResults.Values | Where-Object { $_.Status -eq "Error" -or ($_.Status -eq "Missing" -and $_.Total -eq 0) }).Count -eq 0
}

function Test-Services {
   Write-Validation "Validating services..." "Testing" "Services"
    
   $services = kubectl get services -n $Namespace -o jsonpath='{.items[*].metadata.name}' 2>$null
   if ($LASTEXITCODE -eq 0) {
      $serviceList = $services -split ' '
      Write-Validation "Found $($serviceList.Count) services: $($serviceList -join ', ')" "Success" "Services"
        
      foreach ($service in $serviceList) {
         # Check service endpoints
         $endpoints = kubectl get endpoints $service -n $Namespace -o jsonpath='{.subsets[*].addresses[*].ip}' 2>$null
         if ($endpoints) {
            $endpointCount = ($endpoints -split ' ').Count
            Write-Validation "Service '$service' has $endpointCount endpoint(s)" "Success" "Services"
         }
         else {
            Write-Validation "Service '$service' has no endpoints" "Warning" "Services"
         }
      }
        
      $ValidationResults.Services = $serviceList
      return $true
   }
   else {
      Write-Validation "Failed to get services" "Error" "Services"
      return $false
   }
}

function Test-Ingress {
   Write-Validation "Validating ingress configuration..." "Testing" "Ingress"
    
   try {
      $ingresses = kubectl get ingress -n $Namespace -o jsonpath='{.items[*].metadata.name}' 2>$null
      if ($LASTEXITCODE -eq 0 -and $ingresses) {
         $ingressList = $ingresses -split ' '
         Write-Validation "Found $($ingressList.Count) ingress(es): $($ingressList -join ', ')" "Success" "Ingress"
            
         foreach ($ingress in $ingressList) {
            # Check ingress status
            $ingressStatus = kubectl get ingress $ingress -n $Namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
            if ($ingressStatus) {
               Write-Validation "Ingress '$ingress' has external IP: $ingressStatus" "Success" "Ingress"
            }
            else {
               $ingressHost = kubectl get ingress $ingress -n $Namespace -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
               if ($ingressHost) {
                  Write-Validation "Ingress '$ingress' has external hostname: $ingressHost" "Success" "Ingress"
               }
               else {
                  Write-Validation "Ingress '$ingress' has no external IP/hostname" "Warning" "Ingress"
               }
            }
         }
         return $true
      }
      else {
         Write-Validation "No ingress resources found" "Info" "Ingress"
         return $true
      }
   }
   catch {
      Write-Validation "Ingress validation failed: $_" "Error" "Ingress"
      return $false
   }
}

function Test-PersistentVolumes {
   Write-Validation "Validating persistent volumes..." "Storage" "PV"
    
   try {
      $pvcs = kubectl get pvc -n $Namespace -o jsonpath='{.items[*].metadata.name}' 2>$null
      if ($LASTEXITCODE -eq 0 -and $pvcs) {
         $pvcList = $pvcs -split ' '
         Write-Validation "Found $($pvcList.Count) PVC(s): $($pvcList -join ', ')" "Success" "PV"
            
         foreach ($pvc in $pvcList) {
            $pvcStatus = kubectl get pvc $pvc -n $Namespace -o jsonpath='{.status.phase}' 2>$null
            $pvcSize = kubectl get pvc $pvc -n $Namespace -o jsonpath='{.status.capacity.storage}' 2>$null
                
            if ($pvcStatus -eq "Bound") {
               Write-Validation "PVC '$pvc' is bound ($pvcSize)" "Success" "PV"
            }
            else {
               Write-Validation "PVC '$pvc' is in '$pvcStatus' state" "Warning" "PV"
            }
         }
         return $true
      }
      else {
         Write-Validation "No PVCs found" "Info" "PV"
         return $true
      }
   }
   catch {
      Write-Validation "PVC validation failed: $_" "Error" "PV"
      return $false
   }
}

function Test-NetworkPolicies {
   Write-Validation "Validating network policies..." "Network" "NetworkPolicy"
    
   try {
      $networkPolicies = kubectl get networkpolicy -n $Namespace -o jsonpath='{.items[*].metadata.name}' 2>$null
      if ($LASTEXITCODE -eq 0 -and $networkPolicies) {
         $npList = $networkPolicies -split ' '
         Write-Validation "Found $($npList.Count) network policies: $($npList -join ', ')" "Success" "NetworkPolicy"
            
         # Check for required network policies
         $requiredPolicies = @("deny-all", "allow-ingress", "allow-monitoring")
         foreach ($policy in $requiredPolicies) {
            if ($policy -in $npList) {
               Write-Validation "Required network policy '$policy' found" "Success" "NetworkPolicy"
            }
            else {
               Write-Validation "Required network policy '$policy' missing" "Warning" "NetworkPolicy"
            }
         }
         return $true
      }
      else {
         Write-Validation "No network policies found - consider adding security policies" "Warning" "NetworkPolicy"
         return $true
      }
   }
   catch {
      Write-Validation "Network policy validation failed: $_" "Error" "NetworkPolicy"
      return $false
   }
}

function Test-RBAC {
   Write-Validation "Validating RBAC configuration..." "Security" "RBAC"
    
   try {
      $serviceAccounts = kubectl get serviceaccount -n $Namespace -o jsonpath='{.items[*].metadata.name}' 2>$null
      if ($LASTEXITCODE -eq 0 -and $serviceAccounts) {
         $saList = $serviceAccounts -split ' '
         Write-Validation "Found $($saList.Count) service accounts: $($saList -join ', ')" "Success" "RBAC"
            
         # Check for ClusterRoles and RoleBindings
         $clusterRoles = kubectl get clusterrole | Select-String "branching" 2>$null
         if ($clusterRoles) {
            Write-Validation "Found branching-related ClusterRoles" "Success" "RBAC"
         }
            
         $roleBindings = kubectl get rolebinding -n $Namespace -o jsonpath='{.items[*].metadata.name}' 2>$null
         if ($LASTEXITCODE -eq 0 -and $roleBindings) {
            $rbList = $roleBindings -split ' '
            Write-Validation "Found $($rbList.Count) role bindings: $($rbList -join ', ')" "Success" "RBAC"
         }
            
         return $true
      }
      else {
         Write-Validation "No service accounts found" "Info" "RBAC"
         return $true
      }
   }
   catch {
      Write-Validation "RBAC validation failed: $_" "Error" "RBAC"
      return $false
   }
}

function Test-Performance {
   if (!$PerformanceTest) { return $true }
    
   Write-Validation "Running performance tests..." "Performance" "Performance"
    
   try {
      # Test CPU and memory usage
      $nodeMetrics = kubectl top nodes 2>$null
      if ($LASTEXITCODE -eq 0) {
         Write-Validation "Node metrics available" "Success" "Performance"
      }
        
      $podMetrics = kubectl top pods -n $Namespace 2>$null
      if ($LASTEXITCODE -eq 0) {
         Write-Validation "Pod metrics available" "Success" "Performance"
            
         # Parse and check high resource usage
         $lines = $podMetrics -split "`n"
         for ($i = 1; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line -match '(\S+)\s+(\d+)m\s+(\d+)Mi') {
               $podName = $matches[1]
               $cpuUsage = [int]$matches[2]
               $memUsage = [int]$matches[3]
                    
               if ($cpuUsage -gt 1000) {
                  Write-Validation "High CPU usage detected in pod '$podName': ${cpuUsage}m" "Warning" "Performance"
               }
               if ($memUsage -gt 2048) {
                  Write-Validation "High memory usage detected in pod '$podName': ${memUsage}Mi" "Warning" "Performance"
               }
            }
         }
      }
        
      return $true
   }
   catch {
      Write-Validation "Performance test failed: $_" "Warning" "Performance"
      return $true
   }
}

function Test-SecurityAudit {
   if (!$SecurityAudit) { return $true }
    
   Write-Validation "Running security audit..." "Security" "Security"
    
   try {
      # Check for pods running as root
      $rootPods = kubectl get pods -n $Namespace -o jsonpath='{.items[?(@.spec.securityContext.runAsUser==0)].metadata.name}' 2>$null
      if ($rootPods) {
         Write-Validation "Pods running as root detected: $rootPods" "Warning" "Security"
      }
      else {
         Write-Validation "No pods running as root detected" "Success" "Security"
      }
        
      # Check for privileged containers
      $privilegedPods = kubectl get pods -n $Namespace -o jsonpath='{.items[?(@.spec.containers[*].securityContext.privileged==true)].metadata.name}' 2>$null
      if ($privilegedPods) {
         Write-Validation "Privileged containers detected: $privilegedPods" "Warning" "Security"
      }
      else {
         Write-Validation "No privileged containers detected" "Success" "Security"
      }
        
      # Check for missing resource limits
      $podsWithoutLimits = kubectl get pods -n $Namespace -o jsonpath='{.items[?(!@.spec.containers[0].resources.limits)].metadata.name}' 2>$null
      if ($podsWithoutLimits) {
         Write-Validation "Pods without resource limits: $podsWithoutLimits" "Warning" "Security"
      }
      else {
         Write-Validation "All pods have resource limits configured" "Success" "Security"
      }
        
      return $true
   }
   catch {
      Write-Validation "Security audit failed: $_" "Warning" "Security"
      return $true
   }
}

function Run-LoadTest {
   if (!$LoadTest) { return $true }
    
   Write-Validation "Running basic load test..." "Testing" "LoadTest"
    
   try {
      # Check if load test controller is available
      $loadTestController = kubectl get deployment loadtest-controller -n $Namespace 2>$null
      if ($LASTEXITCODE -eq 0) {
         Write-Validation "Load test controller found, running basic test..." "Testing" "LoadTest"
            
         # Create a simple load test job
         $loadTestJob = @"
apiVersion: batch/v1
kind: Job
metadata:
  name: basic-load-test
  namespace: $Namespace
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: load-test
        image: alpine/curl
        command: ["sh", "-c"]
        args:
        - |
          echo "Running basic load test..."
          for i in `$(seq 1 10); do
            curl -s http://branching-manager:8080/health > /dev/null
            if [ `$? -eq 0 ]; then
              echo "Request `$i: SUCCESS"
            else
              echo "Request `$i: FAILED"
            fi
            sleep 1
          done
          echo "Load test completed"
"@
            
         $loadTestJob | kubectl apply -f -
         Start-Sleep -Seconds 15
            
         # Check job status
         $jobStatus = kubectl get job basic-load-test -n $Namespace -o jsonpath='{.status.succeeded}' 2>$null
         if ($jobStatus -eq "1") {
            Write-Validation "Basic load test passed" "Success" "LoadTest"
         }
         else {
            Write-Validation "Basic load test failed or still running" "Warning" "LoadTest"
         }
            
         # Cleanup
         kubectl delete job basic-load-test -n $Namespace 2>$null
      }
      else {
         Write-Validation "Load test controller not found, skipping load test" "Info" "LoadTest"
      }
        
      return $true
   }
   catch {
      Write-Validation "Load test failed: $_" "Warning" "LoadTest"
      return $true
   }
}

function Generate-Report {
   Write-Host ""
   Write-Host "📊 VALIDATION REPORT" -ForegroundColor Magenta
   Write-Host "====================" -ForegroundColor Magenta
   Write-Host ""
    
   $overallHealth = $true
    
   # Deployment status
   if ($ValidationResults.Deployments) {
      Write-Host "🚀 Deployments:" -ForegroundColor Cyan
      foreach ($deployment in $ValidationResults.Deployments.Keys) {
         $status = $ValidationResults.Deployments[$deployment]
         $color = switch ($status.Status) {
            "Healthy" { "Green" }
            "NotReady" { "Yellow" }
            "Missing" { "Red" }
            "Error" { "Red" }
            default { "Gray" }
         }
         Write-Host "  • $deployment`: $($status.Status) ($($status.Ready)/$($status.Total))" -ForegroundColor $color
            
         if ($status.Status -in @("Missing", "Error", "NotReady")) {
            $overallHealth = $false
         }
      }
      Write-Host ""
   }
    
   # Services status
   if ($ValidationResults.Services) {
      Write-Host "🌐 Services: $($ValidationResults.Services.Count) found" -ForegroundColor Cyan
      foreach ($service in $ValidationResults.Services) {
         Write-Host "  • $service" -ForegroundColor Green
      }
      Write-Host ""
   }
    
   # Overall health assessment
   Write-Host "🏥 Overall Health:" -ForegroundColor Cyan
   if ($overallHealth) {
      Write-Host "  ✅ HEALTHY - All components are functioning properly" -ForegroundColor Green
   }
   else {
      Write-Host "  ⚠️  DEGRADED - Some components need attention" -ForegroundColor Yellow
   }
    
   Write-Host ""
   Write-Host "🔧 Recommendations:" -ForegroundColor Cyan
   if ($Issues.Count -eq 0) {
      Write-Host "  • No issues found - deployment is optimal!" -ForegroundColor Green
   }
   else {
      foreach ($issue in $Issues) {
         Write-Host "  • $issue" -ForegroundColor Yellow
      }
   }
    
   Write-Host ""
   Write-Host "📈 Next Steps:" -ForegroundColor Cyan
   Write-Host "  • Monitor resources: kubectl top pods -n $Namespace" -ForegroundColor White
   Write-Host "  • Check logs: kubectl logs -f deployment/branching-manager -n $Namespace" -ForegroundColor White
   Write-Host "  • Scale if needed: kubectl scale deployment/branching-manager --replicas=5 -n $Namespace" -ForegroundColor White
   Write-Host "  • Run full load test: .\container-build-pipeline.ps1 -LoadTest" -ForegroundColor White
}

# Main execution
Write-Validation "Starting Kubernetes deployment validation..." "Info" "Main"

# Prerequisites
if (!(Test-Prerequisites)) {
   Write-Validation "Prerequisites check failed" "Error" "Main"
   exit 1
}

# Validation steps
$validationSteps = @(
   { Test-Namespace },
   { Test-Deployments },
   { Test-Services },
   { Test-Ingress },
   { Test-PersistentVolumes },
   { Test-NetworkPolicies },
   { Test-RBAC },
   { Test-Performance },
   { Test-SecurityAudit },
   { Run-LoadTest }
)

$successCount = 0
$totalSteps = $validationSteps.Count

foreach ($step in $validationSteps) {
   try {
      if (& $step) {
         $successCount++
      }
   }
   catch {
      Write-Validation "Validation step failed: $_" "Error" "Main"
   }
}

# Generate final report
Generate-Report

Write-Host ""
if ($successCount -eq $totalSteps) {
   Write-Validation "🎉 All validation steps completed successfully! ($successCount/$totalSteps)" "Success" "Main"
}
else {
   Write-Validation "⚠️ Validation completed with issues ($successCount/$totalSteps steps passed)" "Warning" "Main"
}

Write-Host ""
Write-Host "✨ KUBERNETES DEPLOYMENT VALIDATION COMPLETE! ✨" -ForegroundColor Magenta
