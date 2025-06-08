# Deployment Status Monitor
# Ultra-Advanced 8-Level Branching Framework - Real-time Deployment Monitoring
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("all", "aws", "azure", "gcp", "cloudflare", "kubernetes", "applications")]
    [string]$Component = "all",
    
    [Parameter(Mandatory = $false)]
    [int]$RefreshInterval = 30, # seconds
    
    [Parameter(Mandatory = $false)]
    [switch]$ContinuousMode,
    
    [Parameter(Mandatory = $false)]
    [switch]$AlertsEnabled,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFormat = "console", # console, json, html
    
    [Parameter(Mandatory = $false)]
    [string]$KubeConfig = "$env:USERPROFILE\.kube\config"
)

# Initialize logging and monitoring
$LogFile = ".\logs\deployment-monitor-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$MetricsFile = ".\metrics\deployment-metrics-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$null = New-Item -Path ".\logs" -ItemType Directory -Force -ErrorAction SilentlyContinue
$null = New-Item -Path ".\metrics" -ItemType Directory -Force -ErrorAction SilentlyContinue

# Global monitoring state
$Global:MonitoringData = @{
    StartTime = Get-Date
    LastUpdate = Get-Date
    Components = @{}
    Alerts = @()
    Metrics = @{}
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $(switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "CRITICAL" { "Magenta" }
        default { "White" }
    })
    Add-Content -Path $LogFile -Value $LogEntry -ErrorAction SilentlyContinue
}

function Test-Prerequisites {
    Write-Log "Checking monitoring prerequisites..." "INFO"
    
    $prerequisites = @{
        kubectl = $false
        helm = $false
        terraform = $false
        aws = $false
        azure = $false
        gcloud = $false
    }
    
    # Check kubectl
    try {
        $null = kubectl version --client=true 2>$null
        $prerequisites.kubectl = ($LASTEXITCODE -eq 0)
    } catch { }
    
    # Check helm
    try {
        $null = helm version --short 2>$null
        $prerequisites.helm = ($LASTEXITCODE -eq 0)
    } catch { }
    
    # Check terraform
    try {
        $null = terraform version 2>$null
        $prerequisites.terraform = ($LASTEXITCODE -eq 0)
    } catch { }
    
    # Check AWS CLI
    try {
        $null = aws --version 2>$null
        $prerequisites.aws = ($LASTEXITCODE -eq 0)
    } catch { }
    
    # Check Azure CLI
    try {
        $null = az version 2>$null
        $prerequisites.azure = ($LASTEXITCODE -eq 0)
    } catch { }
    
    # Check Google Cloud CLI
    try {
        $null = gcloud version 2>$null
        $prerequisites.gcloud = ($LASTEXITCODE -eq 0)
    } catch { }
    
    $Global:MonitoringData.Prerequisites = $prerequisites
    
    foreach ($tool in $prerequisites.Keys) {
        $status = if ($prerequisites[$tool]) { "OK" } else { "MISSING" }
        $level = if ($prerequisites[$tool]) { "SUCCESS" } else { "WARN" }
        Write-Log "$tool: $status" $level
    }
    
    return $prerequisites
}

function Get-CloudResourceStatus {
    param([string]$Provider)
    
    $status = @{
        Provider = $Provider
        Regions = @{}
        Status = "Unknown"
        LastCheck = Get-Date
    }
    
    switch ($Provider) {
        "aws" {
            if ($Global:MonitoringData.Prerequisites.aws) {
                try {
                    # Get EKS clusters
                    $regions = @("us-east-1", "us-west-2", "eu-west-1", "ap-southeast-1", "ap-southeast-2", "sa-east-1")
                    foreach ($region in $regions) {
                        $clusters = aws eks list-clusters --region $region --output json 2>$null | ConvertFrom-Json
                        if ($clusters) {
                            $regionStatus = @{
                                EKS = @{
                                    Clusters = $clusters.clusters.Count
                                    Status = "Active"
                                }
                                LoadBalancers = @()
                                Databases = @()
                            }
                            
                            # Get load balancers
                            $lbs = aws elbv2 describe-load-balancers --region $region --output json 2>$null | ConvertFrom-Json
                            if ($lbs) {
                                $regionStatus.LoadBalancers = $lbs.LoadBalancers | ForEach-Object {
                                    @{
                                        Name = $_.LoadBalancerName
                                        State = $_.State.Code
                                        Type = $_.Type
                                    }
                                }
                            }
                            
                            # Get RDS instances
                            $rds = aws rds describe-db-instances --region $region --output json 2>$null | ConvertFrom-Json
                            if ($rds) {
                                $regionStatus.Databases = $rds.DBInstances | ForEach-Object {
                                    @{
                                        Name = $_.DBInstanceIdentifier
                                        Status = $_.DBInstanceStatus
                                        Engine = $_.Engine
                                        MultiAZ = $_.MultiAZ
                                    }
                                }
                            }
                            
                            $status.Regions[$region] = $regionStatus
                        }
                    }
                    $status.Status = "Active"
                } catch {
                    Write-Log "AWS monitoring error: $($_.Exception.Message)" "ERROR"
                    $status.Status = "Error"
                }
            }
        }
        
        "azure" {
            if ($Global:MonitoringData.Prerequisites.azure) {
                try {
                    # Get AKS clusters
                    $clusters = az aks list --output json 2>$null | ConvertFrom-Json
                    if ($clusters) {
                        foreach ($cluster in $clusters) {
                            $regionStatus = @{
                                AKS = @{
                                    Name = $cluster.name
                                    Status = $cluster.provisioningState
                                    KubernetesVersion = $cluster.kubernetesVersion
                                    NodePools = $cluster.agentPoolProfiles.Count
                                }
                                Databases = @()
                            }
                            
                            # Get PostgreSQL servers
                            $postgres = az postgres flexible-server list --output json 2>$null | ConvertFrom-Json
                            if ($postgres) {
                                $regionStatus.Databases = $postgres | ForEach-Object {
                                    @{
                                        Name = $_.name
                                        Status = $_.state
                                        Version = $_.version
                                        Location = $_.location
                                    }
                                }
                            }
                            
                            $status.Regions[$cluster.location] = $regionStatus
                        }
                    }
                    $status.Status = "Active"
                } catch {
                    Write-Log "Azure monitoring error: $($_.Exception.Message)" "ERROR"
                    $status.Status = "Error"
                }
            }
        }
        
        "gcp" {
            if ($Global:MonitoringData.Prerequisites.gcloud) {
                try {
                    # Get GKE clusters
                    $clusters = gcloud container clusters list --format=json 2>$null | ConvertFrom-Json
                    if ($clusters) {
                        foreach ($cluster in $clusters) {
                            $regionStatus = @{
                                GKE = @{
                                    Name = $cluster.name
                                    Status = $cluster.status
                                    Version = $cluster.currentMasterVersion
                                    Nodes = $cluster.currentNodeCount
                                    Location = $cluster.location
                                }
                                Databases = @()
                            }
                            
                            $status.Regions[$cluster.location] = $regionStatus
                        }
                    }
                    $status.Status = "Active"
                } catch {
                    Write-Log "GCP monitoring error: $($_.Exception.Message)" "ERROR"
                    $status.Status = "Error"
                }
            }
        }
    }
    
    return $status
}

function Get-KubernetesStatus {
    param([string]$Context = "")
    
    $status = @{
        Clusters = @{}
        Applications = @{}
        Status = "Unknown"
        LastCheck = Get-Date
    }
    
    if ($Global:MonitoringData.Prerequisites.kubectl) {
        try {
            # Get contexts
            $contexts = kubectl config get-contexts --output=name 2>$null
            if ($contexts) {
                foreach ($context in $contexts) {
                    if ($context -and $context.Trim()) {
                        $clusterStatus = @{
                            Context = $context
                            Nodes = @()
                            Namespaces = @()
                            Pods = @{}
                            Services = @{}
                        }
                        
                        # Get nodes
                        $nodes = kubectl get nodes --context=$context --output=json 2>$null | ConvertFrom-Json
                        if ($nodes -and $nodes.items) {
                            $clusterStatus.Nodes = $nodes.items | ForEach-Object {
                                @{
                                    Name = $_.metadata.name
                                    Status = ($_.status.conditions | Where-Object { $_.type -eq "Ready" }).status
                                    Version = $_.status.nodeInfo.kubeletVersion
                                    OS = $_.status.nodeInfo.osImage
                                }
                            }
                        }
                        
                        # Get namespaces
                        $namespaces = kubectl get namespaces --context=$context --output=json 2>$null | ConvertFrom-Json
                        if ($namespaces -and $namespaces.items) {
                            $clusterStatus.Namespaces = $namespaces.items | ForEach-Object {
                                @{
                                    Name = $_.metadata.name
                                    Status = $_.status.phase
                                    Age = $_.metadata.creationTimestamp
                                }
                            }
                        }
                        
                        # Get pods in branching-framework namespace
                        $pods = kubectl get pods -n branching-framework-enterprise --context=$context --output=json 2>$null | ConvertFrom-Json
                        if ($pods -and $pods.items) {
                            $clusterStatus.Pods = @{
                                Total = $pods.items.Count
                                Running = ($pods.items | Where-Object { $_.status.phase -eq "Running" }).Count
                                Pending = ($pods.items | Where-Object { $_.status.phase -eq "Pending" }).Count
                                Failed = ($pods.items | Where-Object { $_.status.phase -eq "Failed" }).Count
                                Details = $pods.items | ForEach-Object {
                                    @{
                                        Name = $_.metadata.name
                                        Status = $_.status.phase
                                        Ready = ($_.status.containerStatuses | Where-Object { $_.ready -eq $true }).Count
                                        Restarts = ($_.status.containerStatuses | Measure-Object -Property restartCount -Sum).Sum
                                    }
                                }
                            }
                        }
                        
                        # Get services
                        $services = kubectl get services -n branching-framework-enterprise --context=$context --output=json 2>$null | ConvertFrom-Json
                        if ($services -and $services.items) {
                            $clusterStatus.Services = $services.items | ForEach-Object {
                                @{
                                    Name = $_.metadata.name
                                    Type = $_.spec.type
                                    ClusterIP = $_.spec.clusterIP
                                    ExternalIP = $_.status.loadBalancer.ingress[0].ip
                                    Ports = $_.spec.ports | ForEach-Object { "$($_.port):$($_.targetPort)/$($_.protocol)" }
                                }
                            }
                        }
                        
                        $status.Clusters[$context] = $clusterStatus
                    }
                }
            }
            $status.Status = "Active"
        } catch {
            Write-Log "Kubernetes monitoring error: $($_.Exception.Message)" "ERROR"
            $status.Status = "Error"
        }
    }
    
    return $status
}

function Get-ApplicationHealth {
    $health = @{
        Framework = @{
            Status = "Unknown"
            Version = "Unknown"
            Endpoints = @{}
            Metrics = @{}
        }
        Components = @{}
        LastCheck = Get-Date
    }
    
    # Check main framework endpoint
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 10 -ErrorAction Stop
        $health.Framework.Status = $response.status
        $health.Framework.Version = $response.version
        $health.Framework.Endpoints = $response.endpoints
    } catch {
        $health.Framework.Status = "Unhealthy"
        Write-Log "Framework health check failed: $($_.Exception.Message)" "WARN"
    }
    
    # Check component health
    $components = @("api-gateway", "authentication", "branching-manager", "ai-optimizer", "load-balancer")
    foreach ($component in $components) {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:8080/health/$component" -TimeoutSec 5 -ErrorAction Stop
            $health.Components[$component] = @{
                Status = $response.status
                ResponseTime = $response.responseTime
                Metrics = $response.metrics
            }
        } catch {
            $health.Components[$component] = @{
                Status = "Unhealthy"
                ResponseTime = "N/A"
                Error = $_.Exception.Message
            }
        }
    }
    
    return $health
}

function Get-TerraformStatus {
    $status = @{
        Workspaces = @{}
        Status = "Unknown"
        LastCheck = Get-Date
    }
    
    if ($Global:MonitoringData.Prerequisites.terraform) {
        try {
            # Get workspace list
            $workspaces = terraform workspace list 2>$null
            if ($workspaces) {
                foreach ($workspace in $workspaces) {
                    $wsName = $workspace.Trim().Replace("*", "").Trim()
                    if ($wsName -and $wsName -ne "") {
                        $wsStatus = @{
                            Name = $wsName
                            State = "Unknown"
                            Resources = 0
                            LastApplied = "Unknown"
                        }
                        
                        # Get state info
                        $stateInfo = terraform show -json 2>$null | ConvertFrom-Json
                        if ($stateInfo) {
                            $wsStatus.Resources = $stateInfo.values.root_module.resources.Count
                        }
                        
                        $status.Workspaces[$wsName] = $wsStatus
                    }
                }
            }
            $status.Status = "Active"
        } catch {
            Write-Log "Terraform monitoring error: $($_.Exception.Message)" "ERROR"
            $status.Status = "Error"
        }
    }
    
    return $status
}

function Generate-StatusReport {
    $report = @{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        OverallStatus = "Unknown"
        Components = @{}
        Summary = @{
            TotalClusters = 0
            HealthyClusters = 0
            TotalPods = 0
            RunningPods = 0
            TotalServices = 0
            HealthyServices = 0
        }
        Alerts = $Global:MonitoringData.Alerts
    }
    
    # Collect component statuses
    if ($Component -eq "all" -or $Component -eq "aws") {
        $report.Components.AWS = Get-CloudResourceStatus -Provider "aws"
    }
    
    if ($Component -eq "all" -or $Component -eq "azure") {
        $report.Components.Azure = Get-CloudResourceStatus -Provider "azure"
    }
    
    if ($Component -eq "all" -or $Component -eq "gcp") {
        $report.Components.GCP = Get-CloudResourceStatus -Provider "gcp"
    }
    
    if ($Component -eq "all" -or $Component -eq "kubernetes") {
        $report.Components.Kubernetes = Get-KubernetesStatus
        
        # Update summary
        foreach ($cluster in $report.Components.Kubernetes.Clusters.Values) {
            $report.Summary.TotalClusters++
            if ($cluster.Nodes.Count -gt 0 -and ($cluster.Nodes | Where-Object { $_.Status -eq "True" }).Count -eq $cluster.Nodes.Count) {
                $report.Summary.HealthyClusters++
            }
            $report.Summary.TotalPods += $cluster.Pods.Total
            $report.Summary.RunningPods += $cluster.Pods.Running
            $report.Summary.TotalServices += $cluster.Services.Count
        }
    }
    
    if ($Component -eq "all" -or $Component -eq "applications") {
        $report.Components.Applications = Get-ApplicationHealth
    }
    
    # Determine overall status
    $healthyComponents = 0
    $totalComponents = 0
    
    foreach ($comp in $report.Components.Values) {
        $totalComponents++
        if ($comp.Status -eq "Active" -or $comp.Status -eq "Healthy") {
            $healthyComponents++
        }
    }
    
    if ($totalComponents -eq 0) {
        $report.OverallStatus = "Unknown"
    } elseif ($healthyComponents -eq $totalComponents) {
        $report.OverallStatus = "Healthy"
    } elseif ($healthyComponents -gt ($totalComponents / 2)) {
        $report.OverallStatus = "Degraded"
    } else {
        $report.OverallStatus = "Critical"
    }
    
    # Check for alerts
    if ($AlertsEnabled) {
        Check-AlertConditions -Report $report
    }
    
    return $report
}

function Check-AlertConditions {
    param($Report)
    
    $alerts = @()
    
    # Check overall health
    if ($Report.OverallStatus -eq "Critical") {
        $alerts += @{
            Level = "Critical"
            Component = "Overall"
            Message = "System is in critical state"
            Timestamp = Get-Date
        }
    }
    
    # Check cluster health
    if ($Report.Summary.TotalClusters -gt 0 -and $Report.Summary.HealthyClusters -lt $Report.Summary.TotalClusters) {
        $unhealthy = $Report.Summary.TotalClusters - $Report.Summary.HealthyClusters
        $alerts += @{
            Level = "Warning"
            Component = "Kubernetes"
            Message = "$unhealthy out of $($Report.Summary.TotalClusters) clusters are unhealthy"
            Timestamp = Get-Date
        }
    }
    
    # Check pod health
    if ($Report.Summary.TotalPods -gt 0) {
        $healthyPercent = ($Report.Summary.RunningPods / $Report.Summary.TotalPods) * 100
        if ($healthyPercent -lt 80) {
            $alerts += @{
                Level = "Warning"
                Component = "Applications"
                Message = "Only $([math]::Round($healthyPercent, 2))% of pods are running"
                Timestamp = Get-Date
            }
        }
    }
    
    # Add new alerts to global state
    $Global:MonitoringData.Alerts += $alerts
    
    # Keep only last 100 alerts
    if ($Global:MonitoringData.Alerts.Count -gt 100) {
        $Global:MonitoringData.Alerts = $Global:MonitoringData.Alerts | Select-Object -Last 100
    }
}

function Format-StatusOutput {
    param($Report, [string]$Format)
    
    switch ($Format) {
        "json" {
            return $Report | ConvertTo-Json -Depth 10
        }
        "html" {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>8-Level Branching Framework - Deployment Status</title>
    <meta http-equiv="refresh" content="$RefreshInterval">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; }
        .status-card { background: white; padding: 20px; margin: 10px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .status-healthy { border-left: 5px solid #4CAF50; }
        .status-degraded { border-left: 5px solid #FF9800; }
        .status-critical { border-left: 5px solid #f44336; }
        .status-unknown { border-left: 5px solid #9E9E9E; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }
        .metric { text-align: center; padding: 15px; background: #f9f9f9; border-radius: 5px; }
        .metric-value { font-size: 2em; font-weight: bold; color: #333; }
        .metric-label { color: #666; margin-top: 5px; }
        .alerts { margin-top: 20px; }
        .alert { padding: 10px; margin: 5px 0; border-radius: 5px; }
        .alert-critical { background: #ffebee; border: 1px solid #f44336; color: #d32f2f; }
        .alert-warning { background: #fff3e0; border: 1px solid #ff9800; color: #f57c00; }
        .timestamp { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 8-Level Branching Framework</h1>
            <h2>Deployment Status Dashboard</h2>
            <p>Last Updated: $($Report.Timestamp)</p>
        </div>
        
        <div class="status-card status-$($Report.OverallStatus.ToLower())">
            <h2>Overall Status: $($Report.OverallStatus)</h2>
            <div class="metrics">
                <div class="metric">
                    <div class="metric-value">$($Report.Summary.HealthyClusters)/$($Report.Summary.TotalClusters)</div>
                    <div class="metric-label">Healthy Clusters</div>
                </div>
                <div class="metric">
                    <div class="metric-value">$($Report.Summary.RunningPods)/$($Report.Summary.TotalPods)</div>
                    <div class="metric-label">Running Pods</div>
                </div>
                <div class="metric">
                    <div class="metric-value">$($Report.Summary.TotalServices)</div>
                    <div class="metric-label">Total Services</div>
                </div>
            </div>
        </div>
"@
            
            foreach ($comp in $Report.Components.Keys) {
                $component = $Report.Components[$comp]
                $html += @"
        <div class="status-card status-$($component.Status.ToLower())">
            <h3>$comp Status: $($component.Status)</h3>
            <p class="timestamp">Last Check: $($component.LastCheck)</p>
        </div>
"@
            }
            
            if ($Report.Alerts.Count -gt 0) {
                $html += @"
        <div class="alerts">
            <h3>Recent Alerts</h3>
"@
                foreach ($alert in ($Report.Alerts | Select-Object -Last 10)) {
                    $alertClass = $alert.Level.ToLower()
                    $html += @"
            <div class="alert alert-$alertClass">
                <strong>$($alert.Level):</strong> $($alert.Message)
                <br><span class="timestamp">$($alert.Timestamp)</span>
            </div>
"@
                }
                $html += "</div>"
            }
            
            $html += @"
    </div>
</body>
</html>
"@
            return $html
        }
        default {
            # Console format
            $output = @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                    8-LEVEL BRANCHING FRAMEWORK                               ║
║                        DEPLOYMENT STATUS MONITOR                            ║
╚══════════════════════════════════════════════════════════════════════════════╝

📊 OVERALL STATUS: $($Report.OverallStatus)
🕐 Last Updated: $($Report.Timestamp)

📈 SUMMARY METRICS:
├─ Clusters: $($Report.Summary.HealthyClusters)/$($Report.Summary.TotalClusters) Healthy
├─ Pods: $($Report.Summary.RunningPods)/$($Report.Summary.TotalPods) Running
└─ Services: $($Report.Summary.TotalServices) Total

🔧 COMPONENT STATUS:
"@
            
            foreach ($comp in $Report.Components.Keys) {
                $component = $Report.Components[$comp]
                $icon = switch ($component.Status) {
                    "Active" { "✅" }
                    "Healthy" { "✅" }
                    "Degraded" { "⚠️" }
                    "Critical" { "❌" }
                    default { "❓" }
                }
                $output += "`n├─ $icon $comp`: $($component.Status)"
            }
            
            if ($Report.Alerts.Count -gt 0) {
                $output += "`n`n🚨 RECENT ALERTS:"
                foreach ($alert in ($Report.Alerts | Select-Object -Last 5)) {
                    $alertIcon = if ($alert.Level -eq "Critical") { "🔴" } else { "🟡" }
                    $output += "`n├─ $alertIcon [$($alert.Level)] $($alert.Message)"
                }
            }
            
            $output += "`n"
            return $output
        }
    }
}

function Save-Metrics {
    param($Report)
    
    $metrics = @{
        timestamp = $Report.Timestamp
        overall_status = $Report.OverallStatus
        summary = $Report.Summary
        component_count = $Report.Components.Count
        alert_count = $Report.Alerts.Count
    }
    
    $metrics | ConvertTo-Json -Depth 5 | Add-Content -Path $MetricsFile
}

# Main execution
Write-Log "Starting Deployment Status Monitor for 8-Level Branching Framework" "INFO"
Write-Log "Component: $Component | Refresh: ${RefreshInterval}s | Continuous: $ContinuousMode" "INFO"

# Check prerequisites
$prerequisites = Test-Prerequisites

do {
    try {
        Clear-Host
        
        # Generate status report
        $report = Generate-StatusReport
        $Global:MonitoringData.LastUpdate = Get-Date
        
        # Format and display output
        $output = Format-StatusOutput -Report $report -Format $OutputFormat
        
        if ($OutputFormat -eq "html") {
            $htmlFile = ".\reports\status-dashboard.html"
            $null = New-Item -Path ".\reports" -ItemType Directory -Force -ErrorAction SilentlyContinue
            $output | Out-File -FilePath $htmlFile -Encoding UTF8
            Write-Log "HTML dashboard updated: $htmlFile" "INFO"
        } elseif ($OutputFormat -eq "json") {
            $jsonFile = ".\reports\status-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            $null = New-Item -Path ".\reports" -ItemType Directory -Force -ErrorAction SilentlyContinue
            $output | Out-File -FilePath $jsonFile -Encoding UTF8
            Write-Log "JSON report saved: $jsonFile" "INFO"
        } else {
            Write-Host $output
        }
        
        # Save metrics
        Save-Metrics -Report $report
        
        # Check for alerts
        if ($AlertsEnabled -and $report.Alerts.Count -gt 0) {
            $newAlerts = $report.Alerts | Where-Object { $_.Timestamp -gt (Get-Date).AddSeconds(-$RefreshInterval) }
            foreach ($alert in $newAlerts) {
                Write-Log "ALERT [$($alert.Level)]: $($alert.Message)" "CRITICAL"
            }
        }
        
        if ($ContinuousMode) {
            Write-Log "Next update in $RefreshInterval seconds... (Press Ctrl+C to stop)" "INFO"
            Start-Sleep -Seconds $RefreshInterval
        }
    }
    catch {
        Write-Log "Monitoring error: $($_.Exception.Message)" "ERROR"
        if ($ContinuousMode) {
            Start-Sleep -Seconds $RefreshInterval
        }
    }
} while ($ContinuousMode)

Write-Log "Deployment Status Monitor completed" "SUCCESS"
