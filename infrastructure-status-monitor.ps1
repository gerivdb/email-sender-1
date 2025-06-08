#!/usr/bin/env pwsh
# Ultra-Advanced 8-Level Framework - Comprehensive Infrastructure Status Monitor
# ==============================================================================

param(
   [Parameter(Mandatory = $false)]
   [ValidateSet("development", "staging", "production")]
   [string]$Environment = "development",
    
   [Parameter(Mandatory = $false)]
   [ValidateSet("basic", "detailed", "comprehensive")]
   [string]$CheckLevel = "comprehensive",
    
   [Parameter(Mandatory = $false)]
   [switch]$ContinuousMode,
    
   [Parameter(Mandatory = $false)]
   [int]$RefreshIntervalSeconds = 30,
    
   [Parameter(Mandatory = $false)]
   [switch]$GenerateReport,
    
   [Parameter(Mandatory = $false)]
   [switch]$AutoRemediation
)

$ErrorActionPreference = "Stop"

# Global Configuration
$global:StatusConfig = @{
   ExecutionId   = "status-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
   StartTime     = Get-Date
   Environment   = $Environment
   CheckLevel    = $CheckLevel
   Components    = @()
   OverallStatus = "Unknown"
   LastUpdate    = Get-Date
}

# Component Health Status
$global:ComponentStatus = @{
   Framework  = @{ Status = "Unknown"; Health = 0; LastCheck = $null; Details = @() }
   Docker     = @{ Status = "Unknown"; Health = 0; LastCheck = $null; Details = @() }
   Kubernetes = @{ Status = "Unknown"; Health = 0; LastCheck = $null; Details = @() }
   Database   = @{ Status = "Unknown"; Health = 0; LastCheck = $null; Details = @() }
   Network    = @{ Status = "Unknown"; Health = 0; LastCheck = $null; Details = @() }
   Storage    = @{ Status = "Unknown"; Health = 0; LastCheck = $null; Details = @() }
   Security   = @{ Status = "Unknown"; Health = 0; LastCheck = $null; Details = @() }
   Monitoring = @{ Status = "Unknown"; Health = 0; LastCheck = $null; Details = @() }
}

# Logging Function
function Write-StatusLog {
   param(
      [string]$Message,
      [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "HEALTH", "STATUS")]
      [string]$Level = "INFO"
   )
    
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
   $logMessage = "[$timestamp] [$Level] $Message"
    
   $colors = @{
      "INFO"    = "White"
      "WARN"    = "Yellow"
      "ERROR"   = "Red"
      "SUCCESS" = "Green"
      "HEALTH"  = "Cyan"
      "STATUS"  = "Magenta"
   }
    
   Write-Host $logMessage -ForegroundColor $colors[$Level]
    
   # Log to file
   $logFile = "logs/infrastructure-status-$($global:StatusConfig.ExecutionId).log"
   if (!(Test-Path "logs")) { New-Item -ItemType Directory -Path "logs" -Force | Out-Null }
   Add-Content -Path $logFile -Value $logMessage
}

# Framework Health Check
function Test-FrameworkHealth {
   Write-StatusLog "Checking 8-Level Framework core components..." "HEALTH"
    
   $frameworkHealth = @{
      Status     = "Healthy"
      Health     = 100
      Components = @()
      Issues     = @()
   }
    
   # Check core configuration files
   $coreFiles = @(
      "config/enterprise-config.json",
      "container-build-pipeline.ps1",
      "kubernetes-deployment-validator.ps1",
      "ai-model-training-pipeline.ps1",
      "global-load-testing-orchestrator.ps1",
      "chaos-engineering-controller.ps1",
      "global-certificate-dns-manager.ps1",
      "performance-analytics-engine.ps1"
   )
    
   $filesFound = 0
   foreach ($file in $coreFiles) {
      if (Test-Path $file) {
         $filesFound++
         $frameworkHealth.Components += @{
            Name   = $file
            Status = "Available"
            Health = 100
         }
      }
      else {
         $frameworkHealth.Components += @{
            Name   = $file
            Status = "Missing"
            Health = 0
         }
         $frameworkHealth.Issues += "Core file missing: $file"
      }
   }
    
   # Calculate overall framework health
   $frameworkHealth.Health = [math]::Round(($filesFound / $coreFiles.Count) * 100, 0)
    
   if ($frameworkHealth.Health -lt 80) {
      $frameworkHealth.Status = "Degraded"
   }
   elseif ($frameworkHealth.Health -lt 60) {
      $frameworkHealth.Status = "Critical"
   }
    
   # Check framework processes
   try {
      $frameworkProcesses = Get-Process | Where-Object { $_.ProcessName -like "*framework*" -or $_.ProcessName -like "*branch*" }
      if ($frameworkProcesses.Count -gt 0) {
         $frameworkHealth.Components += @{
            Name   = "Framework Processes"
            Status = "Running"
            Health = 100
            Count  = $frameworkProcesses.Count
         }
      }
      else {
         $frameworkHealth.Components += @{
            Name   = "Framework Processes"
            Status = "Not Running"
            Health = 50
            Count  = 0
         }
      }
   }
   catch {
      $frameworkHealth.Issues += "Could not check framework processes"
   }
    
   $global:ComponentStatus.Framework = $frameworkHealth
   $global:ComponentStatus.Framework.LastCheck = Get-Date
    
   Write-StatusLog "Framework Health: $($frameworkHealth.Health)% - $($frameworkHealth.Status)" "HEALTH"
   return $frameworkHealth
}

# Docker Health Check
function Test-DockerHealth {
   Write-StatusLog "Checking Docker environment health..." "HEALTH"
    
   $dockerHealth = @{
      Status     = "Unknown"
      Health     = 0
      Components = @()
      Issues     = @()
   }
    
   try {
      # Check Docker daemon
      $dockerVersion = docker version --format "{{.Server.Version}}" 2>$null
      if ($dockerVersion) {
         $dockerHealth.Components += @{
            Name    = "Docker Daemon"
            Status  = "Running"
            Health  = 100
            Version = $dockerVersion
         }
         $dockerHealth.Health += 25
      }
      else {
         $dockerHealth.Components += @{
            Name   = "Docker Daemon"
            Status = "Not Running"
            Health = 0
         }
         $dockerHealth.Issues += "Docker daemon not accessible"
      }
        
      # Check containers
      $containers = docker ps -a --format "{{.Names}};{{.Status}}" 2>$null
      if ($containers) {
         $runningContainers = ($containers | Where-Object { $_ -like "*Up*" }).Count
         $totalContainers = $containers.Count
            
         $dockerHealth.Components += @{
            Name    = "Containers"
            Status  = "Available"
            Health  = if ($totalContainers -gt 0) { [math]::Round(($runningContainers / $totalContainers) * 100, 0) } else { 100 }
            Running = $runningContainers
            Total   = $totalContainers
         }
         $dockerHealth.Health += 25
      }
      else {
         $dockerHealth.Components += @{
            Name    = "Containers"
            Status  = "None"
            Health  = 50
            Running = 0
            Total   = 0
         }
      }
        
      # Check images
      $images = docker images -q 2>$null
      if ($images) {
         $dockerHealth.Components += @{
            Name   = "Images"
            Status = "Available"
            Health = 100
            Count  = $images.Count
         }
         $dockerHealth.Health += 25
      }
      else {
         $dockerHealth.Components += @{
            Name   = "Images"
            Status = "None"
            Health = 50
            Count  = 0
         }
      }
        
      # Check networks
      $networks = docker network ls -q 2>$null
      if ($networks) {
         $dockerHealth.Components += @{
            Name   = "Networks"
            Status = "Available"
            Health = 100
            Count  = $networks.Count
         }
         $dockerHealth.Health += 25
      }
      else {
         $dockerHealth.Components += @{
            Name   = "Networks"
            Status = "Limited"
            Health = 75
            Count  = 0
         }
      }
        
      # Determine overall status
      if ($dockerHealth.Health -gt 80) {
         $dockerHealth.Status = "Healthy"
      }
      elseif ($dockerHealth.Health -gt 60) {
         $dockerHealth.Status = "Degraded"
      }
      else {
         $dockerHealth.Status = "Critical"
      }
        
   }
   catch {
      $dockerHealth.Status = "Error"
      $dockerHealth.Health = 0
      $dockerHealth.Issues += "Docker health check failed: $($_.Exception.Message)"
   }
    
   $global:ComponentStatus.Docker = $dockerHealth
   $global:ComponentStatus.Docker.LastCheck = Get-Date
    
   Write-StatusLog "Docker Health: $($dockerHealth.Health)% - $($dockerHealth.Status)" "HEALTH"
   return $dockerHealth
}

# Kubernetes Health Check
function Test-KubernetesHealth {
   Write-StatusLog "Checking Kubernetes cluster health..." "HEALTH"
    
   $k8sHealth = @{
      Status     = "Unknown"
      Health     = 0
      Components = @()
      Issues     = @()
   }
    
   try {
      # Check kubectl connectivity
      $context = kubectl config current-context 2>$null
      if ($context) {
         $k8sHealth.Components += @{
            Name    = "kubectl Context"
            Status  = "Connected"
            Health  = 100
            Context = $context
         }
         $k8sHealth.Health += 20
      }
      else {
         $k8sHealth.Components += @{
            Name   = "kubectl Context"
            Status = "Not Available"
            Health = 0
         }
         $k8sHealth.Issues += "No Kubernetes context available"
      }
        
      # Check cluster nodes
      $nodes = kubectl get nodes --no-headers 2>$null
      if ($nodes) {
         $readyNodes = ($nodes | Where-Object { $_ -like "*Ready*" }).Count
         $totalNodes = $nodes.Count
            
         $k8sHealth.Components += @{
            Name   = "Cluster Nodes"
            Status = "Available"
            Health = if ($totalNodes -gt 0) { [math]::Round(($readyNodes / $totalNodes) * 100, 0) } else { 0 }
            Ready  = $readyNodes
            Total  = $totalNodes
         }
         $k8sHealth.Health += 30
      }
      else {
         $k8sHealth.Components += @{
            Name   = "Cluster Nodes"
            Status = "Not Available"
            Health = 0
            Ready  = 0
            Total  = 0
         }
      }
        
      # Check pods
      $pods = kubectl get pods --all-namespaces --no-headers 2>$null
      if ($pods) {
         $runningPods = ($pods | Where-Object { $_ -like "*Running*" }).Count
         $totalPods = $pods.Count
            
         $k8sHealth.Components += @{
            Name    = "Pods"
            Status  = "Available"
            Health  = if ($totalPods -gt 0) { [math]::Round(($runningPods / $totalPods) * 100, 0) } else { 100 }
            Running = $runningPods
            Total   = $totalPods
         }
         $k8sHealth.Health += 25
      }
      else {
         $k8sHealth.Components += @{
            Name    = "Pods"
            Status  = "None"
            Health  = 50
            Running = 0
            Total   = 0
         }
      }
        
      # Check services
      $services = kubectl get services --all-namespaces --no-headers 2>$null
      if ($services) {
         $k8sHealth.Components += @{
            Name   = "Services"
            Status = "Available"
            Health = 100
            Count  = $services.Count
         }
         $k8sHealth.Health += 25
      }
      else {
         $k8sHealth.Components += @{
            Name   = "Services"
            Status = "None"
            Health = 50
            Count  = 0
         }
      }
        
      # Determine overall status
      if ($k8sHealth.Health -gt 80) {
         $k8sHealth.Status = "Healthy"
      }
      elseif ($k8sHealth.Health -gt 60) {
         $k8sHealth.Status = "Degraded"
      }
      elseif ($k8sHealth.Health -gt 0) {
         $k8sHealth.Status = "Limited"
      }
      else {
         $k8sHealth.Status = "Not Available"
      }
        
   }
   catch {
      $k8sHealth.Status = "Error"
      $k8sHealth.Health = 0
      $k8sHealth.Issues += "Kubernetes health check failed: $($_.Exception.Message)"
   }
    
   $global:ComponentStatus.Kubernetes = $k8sHealth
   $global:ComponentStatus.Kubernetes.LastCheck = Get-Date
    
   Write-StatusLog "Kubernetes Health: $($k8sHealth.Health)% - $($k8sHealth.Status)" "HEALTH"
   return $k8sHealth
}

# Network Health Check
function Test-NetworkHealth {
   Write-StatusLog "Checking network connectivity and performance..." "HEALTH"
    
   $networkHealth = @{
      Status     = "Unknown"
      Health     = 0
      Components = @()
      Issues     = @()
   }
    
   try {
      # Check network interfaces
      $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
      if ($adapters.Count -gt 0) {
         $networkHealth.Components += @{
            Name   = "Network Interfaces"
            Status = "Up"
            Health = 100
            Count  = $adapters.Count
         }
         $networkHealth.Health += 25
      }
      else {
         $networkHealth.Components += @{
            Name   = "Network Interfaces"
            Status = "Down"
            Health = 0
            Count  = 0
         }
         $networkHealth.Issues += "No active network interfaces"
      }
        
      # Check internet connectivity
      try {
         $ping = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet
         if ($ping) {
            $networkHealth.Components += @{
               Name   = "Internet Connectivity"
               Status = "Connected"
               Health = 100
            }
            $networkHealth.Health += 25
         }
         else {
            $networkHealth.Components += @{
               Name   = "Internet Connectivity"
               Status = "Limited"
               Health = 50
            }
            $networkHealth.Issues += "Limited internet connectivity"
         }
      }
      catch {
         $networkHealth.Components += @{
            Name   = "Internet Connectivity"
            Status = "Unknown"
            Health = 25
         }
      }
        
      # Check DNS resolution
      try {
         $dnsTest = Resolve-DnsName -Name "google.com" -ErrorAction SilentlyContinue
         if ($dnsTest) {
            $networkHealth.Components += @{
               Name   = "DNS Resolution"
               Status = "Working"
               Health = 100
            }
            $networkHealth.Health += 25
         }
         else {
            $networkHealth.Components += @{
               Name   = "DNS Resolution"
               Status = "Failed"
               Health = 0
            }
            $networkHealth.Issues += "DNS resolution failed"
         }
      }
      catch {
         $networkHealth.Components += @{
            Name   = "DNS Resolution"
            Status = "Error"
            Health = 0
         }
      }
        
      # Check local ports
      $commonPorts = @(80, 443, 3000, 5432, 6379, 8080)
      $openPorts = 0
      foreach ($port in $commonPorts) {
         try {
            $connection = Test-NetConnection -ComputerName "localhost" -Port $port -InformationLevel Quiet
            if ($connection) {
               $openPorts++
            }
         }
         catch {
            # Port not open, continue
         }
      }
        
      $networkHealth.Components += @{
         Name         = "Local Services"
         Status       = "Available"
         Health       = [math]::Round(($openPorts / $commonPorts.Count) * 100, 0)
         OpenPorts    = $openPorts
         TotalChecked = $commonPorts.Count
      }
      $networkHealth.Health += 25
        
      # Determine overall status
      if ($networkHealth.Health -gt 80) {
         $networkHealth.Status = "Healthy"
      }
      elseif ($networkHealth.Health -gt 60) {
         $networkHealth.Status = "Degraded"
      }
      else {
         $networkHealth.Status = "Limited"
      }
        
   }
   catch {
      $networkHealth.Status = "Error"
      $networkHealth.Health = 0
      $networkHealth.Issues += "Network health check failed: $($_.Exception.Message)"
   }
    
   $global:ComponentStatus.Network = $networkHealth
   $global:ComponentStatus.Network.LastCheck = Get-Date
    
   Write-StatusLog "Network Health: $($networkHealth.Health)% - $($networkHealth.Status)" "HEALTH"
   return $networkHealth
}

# Calculate Overall System Health
function Get-OverallSystemHealth {
   $totalHealth = 0
   $componentCount = 0
   $criticalIssues = 0
   $warnings = 0
    
   foreach ($component in $global:ComponentStatus.Keys) {
      $health = $global:ComponentStatus[$component].Health
      $status = $global:ComponentStatus[$component].Status
        
      $totalHealth += $health
      $componentCount++
        
      if ($status -eq "Critical" -or $health -lt 30) {
         $criticalIssues++
      }
      elseif ($status -eq "Degraded" -or $health -lt 70) {
         $warnings++
      }
   }
    
   $overallHealth = if ($componentCount -gt 0) { [math]::Round($totalHealth / $componentCount, 0) } else { 0 }
    
   $overallStatus = if ($criticalIssues -gt 0) {
      "Critical"
   }
   elseif ($warnings -gt 0) {
      "Warning"
   }
   elseif ($overallHealth -gt 90) {
      "Excellent"
   }
   elseif ($overallHealth -gt 80) {
      "Good"
   }
   elseif ($overallHealth -gt 60) {
      "Fair"
   }
   else {
      "Poor"
   }
    
   $global:StatusConfig.OverallStatus = $overallStatus
   $global:StatusConfig.LastUpdate = Get-Date
    
   return @{
      Health         = $overallHealth
      Status         = $overallStatus
      CriticalIssues = $criticalIssues
      Warnings       = $warnings
      ComponentCount = $componentCount
   }
}

# Generate Status Dashboard
function New-StatusDashboard {
   param([hashtable]$OverallHealth)
    
   Write-StatusLog "Generating infrastructure status dashboard..." "STATUS"
    
   $dashboard = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Infrastructure Status - Ultra-Advanced 8-Level Framework</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #0a0a0a; color: #fff; }
        .header { background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); padding: 20px; text-align: center; }
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        .status-overview { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .status-card { background: #1a1a1a; border-radius: 10px; padding: 20px; border: 1px solid #333; text-align: center; }
        .status-excellent { border-left: 5px solid #4CAF50; }
        .status-good { border-left: 5px solid #8BC34A; }
        .status-warning { border-left: 5px solid #FF9800; }
        .status-critical { border-left: 5px solid #F44336; }
        .status-unknown { border-left: 5px solid #9E9E9E; }
        .health-score { font-size: 3em; font-weight: bold; margin: 10px 0; }
        .component-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 20px; }
        .component-card { background: #1a1a1a; border-radius: 10px; padding: 20px; border: 1px solid #333; }
        .component-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; }
        .component-title { color: #2196F3; font-size: 1.2em; font-weight: bold; }
        .health-indicator { display: inline-block; width: 12px; height: 12px; border-radius: 50%; margin-left: 10px; }
        .health-excellent { background-color: #4CAF50; }
        .health-good { background-color: #8BC34A; }
        .health-warning { background-color: #FF9800; }
        .health-critical { background-color: #F44336; }
        .health-unknown { background-color: #9E9E9E; }
        .component-details { margin: 10px 0; }
        .detail-row { display: flex; justify-content: space-between; margin: 5px 0; }
        .issue { background: #ff4444; padding: 5px 10px; border-radius: 5px; margin: 5px 0; font-size: 0.9em; }
        .footer { text-align: center; margin-top: 40px; color: #666; }
        .refresh-info { background: #333; padding: 10px; border-radius: 5px; margin: 20px 0; text-align: center; }
        .timestamp { font-size: 0.9em; color: #999; }
    </style>
    <script>
        function refreshStatus() {
            location.reload();
        }
        $(if ($ContinuousMode) { "setInterval(refreshStatus, $($RefreshIntervalSeconds * 1000));" })
    </script>
</head>
<body>
    <div class="header">
        <h1>🏗️ Infrastructure Status Monitor</h1>
        <h2>Ultra-Advanced 8-Level Branching Framework</h2>
        <p class="timestamp">Last Update: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Environment: $Environment | Check Level: $CheckLevel</p>
    </div>

    <div class="container">
        <div class="status-overview">
            <div class="status-card status-$(($OverallHealth.Status).ToLower())">
                <h3>Overall Health</h3>
                <div class="health-score">$($OverallHealth.Health)%</div>
                <p>$($OverallHealth.Status)</p>
            </div>
            <div class="status-card">
                <h3>Components</h3>
                <div class="health-score">$($OverallHealth.ComponentCount)</div>
                <p>Total Monitored</p>
            </div>
            <div class="status-card">
                <h3>Critical Issues</h3>
                <div class="health-score">$($OverallHealth.CriticalIssues)</div>
                <p>Require Attention</p>
            </div>
            <div class="status-card">
                <h3>Warnings</h3>
                <div class="health-score">$($OverallHealth.Warnings)</div>
                <p>Monitor Closely</p>
            </div>
        </div>

        <div class="component-grid">
"@

   # Add component details
   foreach ($componentName in $global:ComponentStatus.Keys) {
      $component = $global:ComponentStatus[$componentName]
      $healthClass = switch ($component.Health) {
         { $_ -gt 90 } { "excellent" }
         { $_ -gt 80 } { "good" }
         { $_ -gt 60 } { "warning" }
         { $_ -gt 30 } { "warning" }
         default { "critical" }
      }
        
      $dashboard += @"
            <div class="component-card">
                <div class="component-header">
                    <span class="component-title">$componentName</span>
                    <span>
                        $($component.Health)%
                        <span class="health-indicator health-$healthClass"></span>
                    </span>
                </div>
                <div class="component-details">
                    <div class="detail-row">
                        <span>Status:</span>
                        <span><strong>$($component.Status)</strong></span>
                    </div>
                    <div class="detail-row">
                        <span>Last Check:</span>
                        <span>$($component.LastCheck.ToString("HH:mm:ss"))</span>
                    </div>
"@

      # Add component-specific details
      if ($component.Components -and $component.Components.Count -gt 0) {
         foreach ($subComponent in $component.Components) {
            $dashboard += @"
                    <div class="detail-row">
                        <span>$($subComponent.Name):</span>
                        <span>$($subComponent.Status)</span>
                    </div>
"@
         }
      }

      # Add issues if any
      if ($component.Issues -and $component.Issues.Count -gt 0) {
         foreach ($issue in $component.Issues) {
            $dashboard += @"
                    <div class="issue">⚠️ $issue</div>
"@
         }
      }

      $dashboard += @"
                </div>
            </div>
"@
   }

   $dashboard += @"
        </div>

        $(if ($ContinuousMode) {
            @"
        <div class="refresh-info">
            🔄 Continuous monitoring enabled - Auto-refresh every $RefreshIntervalSeconds seconds
        </div>
"@
        })

        <div class="footer">
            <p>🚀 Ultra-Advanced 8-Level Branching Framework v2.0.0</p>
            <p>Execution ID: $($global:StatusConfig.ExecutionId)</p>
        </div>
    </div>
</body>
</html>
"@

   # Save dashboard
   $dashboardFile = "status/infrastructure-status-$($global:StatusConfig.ExecutionId).html"
   if (!(Test-Path "status")) { New-Item -ItemType Directory -Path "status" -Force | Out-Null }
   $dashboard | Set-Content -Path $dashboardFile -Encoding UTF8
    
   Write-StatusLog "Status dashboard saved: $dashboardFile" "SUCCESS"
   return $dashboardFile
}

# Main Status Monitor
function Start-InfrastructureMonitor {
   Write-StatusLog "========================================" "INFO"
   Write-StatusLog "INFRASTRUCTURE STATUS MONITOR" "INFO"
   Write-StatusLog "Ultra-Advanced 8-Level Framework" "INFO"
   Write-StatusLog "========================================" "INFO"
   Write-StatusLog "Execution ID: $($global:StatusConfig.ExecutionId)" "INFO"
   Write-StatusLog "Environment: $Environment" "INFO"
   Write-StatusLog "Check Level: $CheckLevel" "INFO"
   Write-StatusLog "Continuous Mode: $ContinuousMode" "INFO"
   Write-StatusLog "========================================" "INFO"
    
   do {
      Write-StatusLog "Starting comprehensive infrastructure health check..." "STATUS"
        
      # Perform health checks
      Test-FrameworkHealth | Out-Null
      Test-DockerHealth | Out-Null
      Test-KubernetesHealth | Out-Null
      Test-NetworkHealth | Out-Null
        
      # Calculate overall health
      $overallHealth = Get-OverallSystemHealth
        
      # Generate dashboard
      $dashboardFile = New-StatusDashboard -OverallHealth $overallHealth
        
      # Display summary
      Write-StatusLog "========================================" "SUCCESS"
      Write-StatusLog "INFRASTRUCTURE STATUS SUMMARY" "SUCCESS"
      Write-StatusLog "========================================" "SUCCESS"
      Write-StatusLog "Overall Health: $($overallHealth.Health)% - $($overallHealth.Status)" "STATUS"
      Write-StatusLog "Critical Issues: $($overallHealth.CriticalIssues)" "STATUS"
      Write-StatusLog "Warnings: $($overallHealth.Warnings)" "STATUS"
      Write-StatusLog "Dashboard: $dashboardFile" "SUCCESS"
      Write-StatusLog "========================================" "SUCCESS"
        
      if ($ContinuousMode) {
         Write-StatusLog "Waiting $RefreshIntervalSeconds seconds before next check..." "INFO"
         Start-Sleep -Seconds $RefreshIntervalSeconds
      }
        
   } while ($ContinuousMode)
    
   return @{
      OverallHealth    = $overallHealth
      ComponentStatus  = $global:ComponentStatus
      Dashboard        = $dashboardFile
      ExecutionSummary = $global:StatusConfig
   }
}

# Execute infrastructure monitor
try {
   $result = Start-InfrastructureMonitor
    
   Write-StatusLog "Infrastructure status monitoring completed successfully!" "SUCCESS"
   return $result
}
catch {
   Write-StatusLog "Infrastructure status monitoring failed: $($_.Exception.Message)" "ERROR"
   exit 1
}
