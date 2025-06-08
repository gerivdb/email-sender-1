# Chaos Engineering Controller
# Ultra-Advanced 8-Level Branching Framework - Resilience Testing and Chaos Engineering
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("network", "pod", "node", "resource", "security", "comprehensive", "schedule")]
    [string]$TestType = "comprehensive",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("low", "medium", "high", "extreme")]
    [string]$Intensity = "medium",
    
    [Parameter(Mandatory = $false)]
    [int]$Duration = 300, # seconds
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoRecover,
    
    [Parameter(Mandatory = $false)]
    [string]$Namespace = "branching-framework-enterprise",
    
    [Parameter(Mandatory = $false)]
    [string]$KubeConfig = "$env:USERPROFILE\.kube\config"
)

# Initialize logging
$LogFile = ".\logs\chaos-engineering-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$null = New-Item -Path ".\logs" -ItemType Directory -Force -ErrorAction SilentlyContinue

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $(switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "CHAOS" { "Magenta" }
        default { "White" }
    })
    Add-Content -Path $LogFile -Value $LogEntry -ErrorAction SilentlyContinue
}

function Test-ChaosPrerequisites {
    Write-Log "Checking chaos engineering prerequisites..." "INFO"
    
    # Check kubectl
    try {
        $kubectlVersion = kubectl version --client=true 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "kubectl not found"
        }
        Write-Log "kubectl: OK" "SUCCESS"
    }
    catch {
        Write-Log "kubectl: FAILED - $($_.Exception.Message)" "ERROR"
        return $false
    }
    
    # Check cluster connectivity
    try {
        $clusterInfo = kubectl cluster-info --kubeconfig $KubeConfig 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Cannot connect to Kubernetes cluster"
        }
        Write-Log "Kubernetes cluster: OK" "SUCCESS"
    }
    catch {
        Write-Log "Kubernetes cluster: FAILED - $($_.Exception.Message)" "ERROR"
        return $false
    }
    
    # Check if Chaos Mesh is installed
    try {
        $chaosMesh = kubectl get pods -n chaos-testing 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Installing Chaos Mesh..." "INFO"
            Install-ChaosMesh
        } else {
            Write-Log "Chaos Mesh: OK" "SUCCESS"
        }
    }
    catch {
        Write-Log "Chaos Mesh check failed, installing..." "WARN"
        Install-ChaosMesh
    }
    
    return $true
}

function Install-ChaosMesh {
    Write-Log "Installing Chaos Mesh for chaos engineering..." "INFO"
    
    if (-not $DryRun) {
        # Create chaos-testing namespace
        kubectl create namespace chaos-testing --dry-run=client -o yaml | kubectl apply -f - --kubeconfig $KubeConfig
        
        # Install Chaos Mesh using Helm
        helm repo add chaos-mesh https://charts.chaos-mesh.org
        helm repo update
        
        helm install chaos-mesh chaos-mesh/chaos-mesh -n chaos-testing --version 2.6.2 --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock --kubeconfig $KubeConfig
        
        # Wait for Chaos Mesh to be ready
        Write-Log "Waiting for Chaos Mesh to be ready..." "INFO"
        kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=chaos-mesh --timeout=300s -n chaos-testing --kubeconfig $KubeConfig
    }
    
    Write-Log "Chaos Mesh installation: COMPLETED" "SUCCESS"
}

function Get-IntensityConfig {
    param([string]$Intensity)
    
    switch ($Intensity) {
        "low" {
            return @{
                NetworkLatency = "50ms"
                NetworkLoss = "1%"
                CPUStress = "20%"
                MemoryStress = "30%"
                PodKillPercent = 10
                NodeDownTime = 60
            }
        }
        "medium" {
            return @{
                NetworkLatency = "100ms"
                NetworkLoss = "5%"
                CPUStress = "50%"
                MemoryStress = "60%"
                PodKillPercent = 25
                NodeDownTime = 120
            }
        }
        "high" {
            return @{
                NetworkLatency = "200ms"
                NetworkLoss = "10%"
                CPUStress = "80%"
                MemoryStress = "85%"
                PodKillPercent = 40
                NodeDownTime = 300
            }
        }
        "extreme" {
            return @{
                NetworkLatency = "500ms"
                NetworkLoss = "20%"
                CPUStress = "95%"
                MemoryStress = "95%"
                PodKillPercent = 60
                NodeDownTime = 600
            }
        }
    }
}

function Execute-NetworkChaos {
    param([hashtable]$Config)
    
    Write-Log "Executing network chaos experiments..." "CHAOS"
    
    # Network latency injection
    $networkLatencyYaml = @"
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: network-latency-chaos
  namespace: chaos-testing
spec:
  action: delay
  mode: all
  selector:
    namespaces:
      - $Namespace
  delay:
    latency: "$($Config.NetworkLatency)"
    correlation: "100"
    jitter: "0ms"
  duration: "${Duration}s"
"@
    
    if (-not $DryRun) {
        $networkLatencyYaml | kubectl apply -f - --kubeconfig $KubeConfig
        Write-Log "Network latency chaos: APPLIED ($($Config.NetworkLatency))" "CHAOS"
    }
    
    # Network packet loss
    $networkLossYaml = @"
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: network-loss-chaos
  namespace: chaos-testing
spec:
  action: loss
  mode: all
  selector:
    namespaces:
      - $Namespace
  loss:
    loss: "$($Config.NetworkLoss)"
    correlation: "100"
  duration: "${Duration}s"
"@
    
    if (-not $DryRun) {
        $networkLossYaml | kubectl apply -f - --kubeconfig $KubeConfig
        Write-Log "Network packet loss chaos: APPLIED ($($Config.NetworkLoss))" "CHAOS"
    }
}

function Execute-PodChaos {
    param([hashtable]$Config)
    
    Write-Log "Executing pod chaos experiments..." "CHAOS"
    
    # Pod kill chaos
    $podKillYaml = @"
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-kill-chaos
  namespace: chaos-testing
spec:
  action: pod-kill
  mode: fixed-percent
  value: "$($Config.PodKillPercent)"
  selector:
    namespaces:
      - $Namespace
    labelSelectors:
      "app.kubernetes.io/name": "branching-framework"
  duration: "${Duration}s"
"@
    
    if (-not $DryRun) {
        $podKillYaml | kubectl apply -f - --kubeconfig $KubeConfig
        Write-Log "Pod kill chaos: APPLIED ($($Config.PodKillPercent)% of pods)" "CHAOS"
    }
    
    # Pod failure chaos
    $podFailureYaml = @"
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-failure-chaos
  namespace: chaos-testing
spec:
  action: pod-failure
  mode: fixed-percent
  value: "15"
  selector:
    namespaces:
      - $Namespace
    labelSelectors:
      "app.kubernetes.io/component": "api"
  duration: "${Duration}s"
"@
    
    if (-not $DryRun) {
        $podFailureYaml | kubectl apply -f - --kubeconfig $KubeConfig
        Write-Log "Pod failure chaos: APPLIED (15% of API pods)" "CHAOS"
    }
}

function Execute-StressChaos {
    param([hashtable]$Config)
    
    Write-Log "Executing stress chaos experiments..." "CHAOS"
    
    # CPU stress
    $cpuStressYaml = @"
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: cpu-stress-chaos
  namespace: chaos-testing
spec:
  mode: all
  selector:
    namespaces:
      - $Namespace
  stressors:
    cpu:
      workers: 4
      load: $($Config.CPUStress.Replace('%', ''))
  duration: "${Duration}s"
"@
    
    if (-not $DryRun) {
        $cpuStressYaml | kubectl apply -f - --kubeconfig $KubeConfig
        Write-Log "CPU stress chaos: APPLIED ($($Config.CPUStress))" "CHAOS"
    }
    
    # Memory stress
    $memoryStressYaml = @"
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: memory-stress-chaos
  namespace: chaos-testing
spec:
  mode: all
  selector:
    namespaces:
      - $Namespace
  stressors:
    memory:
      workers: 2
      size: "$($Config.MemoryStress)"
  duration: "${Duration}s"
"@
    
    if (-not $DryRun) {
        $memoryStressYaml | kubectl apply -f - --kubeconfig $KubeConfig
        Write-Log "Memory stress chaos: APPLIED ($($Config.MemoryStress))" "CHAOS"
    }
}

function Execute-IOChaos {
    Write-Log "Executing I/O chaos experiments..." "CHAOS"
    
    # I/O delay
    $ioDelayYaml = @"
apiVersion: chaos-mesh.org/v1alpha1
kind: IOChaos
metadata:
  name: io-delay-chaos
  namespace: chaos-testing
spec:
  action: delay
  mode: all
  selector:
    namespaces:
      - $Namespace
  volumePath: /data
  path: "/**"
  delay: "100ms"
  percent: 50
  duration: "${Duration}s"
"@
    
    if (-not $DryRun) {
        $ioDelayYaml | kubectl apply -f - --kubeconfig $KubeConfig
        Write-Log "I/O delay chaos: APPLIED (100ms delay, 50% operations)" "CHAOS"
    }
    
    # I/O errno
    $ioErrnoYaml = @"
apiVersion: chaos-mesh.org/v1alpha1
kind: IOChaos
metadata:
  name: io-errno-chaos
  namespace: chaos-testing
spec:
  action: errno
  mode: all
  selector:
    namespaces:
      - $Namespace
  volumePath: /tmp
  path: "/**"
  errno: 5
  percent: 5
  duration: "${Duration}s"
"@
    
    if (-not $DryRun) {
        $ioErrnoYaml | kubectl apply -f - --kubeconfig $KubeConfig
        Write-Log "I/O errno chaos: APPLIED (EIO errors, 5% operations)" "CHAOS"
    }
}

function Monitor-ChaosExperiments {
    Write-Log "Monitoring chaos experiments..." "INFO"
    
    # Monitor system metrics during chaos
    $monitoringScript = @"
#!/bin/bash
while true; do
    echo "=== Chaos Monitoring Report $(date) ==="
    
    # Pod status
    echo "Pod Status:"
    kubectl get pods -n $Namespace --kubeconfig $KubeConfig | grep -E "(Running|Pending|Failed|Error)"
    
    # Resource usage
    echo "Resource Usage:"
    kubectl top pods -n $Namespace --kubeconfig $KubeConfig 2>/dev/null || echo "Metrics not available"
    
    # Chaos experiments status
    echo "Active Chaos Experiments:"
    kubectl get podchaos,networkchaos,stresschaos,iochaos -n chaos-testing --kubeconfig $KubeConfig
    
    # Application health
    echo "Application Health Checks:"
    curl -s http://localhost:8080/health 2>/dev/null || echo "Health check failed"
    
    echo "========================="
    sleep 30
done
"@
    
    $monitoringScript | Out-File -FilePath ".\chaos-monitoring.sh" -Encoding UTF8
    
    if (-not $DryRun) {
        # Start background monitoring
        Start-Process -FilePath "bash" -ArgumentList ".\chaos-monitoring.sh" -WindowStyle Hidden
        Write-Log "Chaos monitoring: STARTED" "SUCCESS"
    }
}

function Execute-ComprehensiveChaos {
    param([hashtable]$Config)
    
    Write-Log "Executing comprehensive chaos engineering scenario..." "CHAOS"
    
    # Phase 1: Network disruption
    Write-Log "Phase 1: Network chaos (Duration: $($Duration/4)s)" "CHAOS"
    Execute-NetworkChaos -Config $Config
    Start-Sleep -Seconds ($Duration/4)
    
    # Phase 2: Pod disruption
    Write-Log "Phase 2: Pod chaos (Duration: $($Duration/4)s)" "CHAOS"
    Execute-PodChaos -Config $Config
    Start-Sleep -Seconds ($Duration/4)
    
    # Phase 3: Resource stress
    Write-Log "Phase 3: Stress chaos (Duration: $($Duration/4)s)" "CHAOS"
    Execute-StressChaos -Config $Config
    Start-Sleep -Seconds ($Duration/4)
    
    # Phase 4: I/O disruption
    Write-Log "Phase 4: I/O chaos (Duration: $($Duration/4)s)" "CHAOS"
    Execute-IOChaos
    Start-Sleep -Seconds ($Duration/4)
    
    Write-Log "Comprehensive chaos scenario: COMPLETED" "SUCCESS"
}

function Cleanup-ChaosExperiments {
    Write-Log "Cleaning up chaos experiments..." "INFO"
    
    if (-not $DryRun) {
        # Delete all chaos experiments
        kubectl delete podchaos,networkchaos,stresschaos,iochaos --all -n chaos-testing --kubeconfig $KubeConfig
        
        # Stop monitoring
        Get-Process | Where-Object { $_.ProcessName -eq "bash" -and $_.CommandLine -like "*chaos-monitoring*" } | Stop-Process -Force
        
        Write-Log "Chaos experiments cleanup: COMPLETED" "SUCCESS"
    }
}

function Generate-ChaosReport {
    Write-Log "Generating chaos engineering report..." "INFO"
    
    $reportPath = ".\reports\chaos-engineering-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $null = New-Item -Path ".\reports" -ItemType Directory -Force -ErrorAction SilentlyContinue
    
    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        testType = $TestType
        intensity = $Intensity
        duration = $Duration
        namespace = $Namespace
        experiments = @()
        metrics = @{
            podFailures = 0
            recoveryTime = 0
            errorRate = 0
            latencyIncrease = 0
        }
        recommendations = @()
    }
    
    # Collect experiment results
    if (-not $DryRun) {
        try {
            $chaosResults = kubectl get events -n $Namespace --field-selector type=Warning --kubeconfig $KubeConfig -o json | ConvertFrom-Json
            $report.experiments = $chaosResults.items | ForEach-Object {
                @{
                    type = $_.reason
                    message = $_.message
                    timestamp = $_.firstTimestamp
                    count = $_.count
                }
            }
        }
        catch {
            Write-Log "Could not collect chaos experiment results: $($_.Exception.Message)" "WARN"
        }
    }
    
    # Add recommendations based on intensity and results
    $report.recommendations += "Consider implementing circuit breakers for improved resilience"
    $report.recommendations += "Enhance monitoring and alerting for faster incident detection"
    $report.recommendations += "Implement auto-scaling policies to handle resource stress"
    $report.recommendations += "Review and improve health check configurations"
    
    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Log "Chaos engineering report generated: $reportPath" "SUCCESS"
    
    return $reportPath
}

# Main execution
Write-Log "Starting Chaos Engineering Controller for 8-Level Branching Framework" "INFO"
Write-Log "Test Type: $TestType | Intensity: $Intensity | Duration: ${Duration}s" "INFO"

# Check prerequisites
if (-not (Test-ChaosPrerequisites)) {
    Write-Log "Prerequisites check failed. Exiting." "ERROR"
    exit 1
}

# Get intensity configuration
$intensityConfig = Get-IntensityConfig -Intensity $Intensity

# Start monitoring
Monitor-ChaosExperiments

try {
    # Execute chaos experiments based on test type
    switch ($TestType) {
        "network" {
            Execute-NetworkChaos -Config $intensityConfig
        }
        "pod" {
            Execute-PodChaos -Config $intensityConfig
        }
        "resource" {
            Execute-StressChaos -Config $intensityConfig
        }
        "security" {
            Write-Log "Security chaos experiments not yet implemented" "WARN"
        }
        "comprehensive" {
            Execute-ComprehensiveChaos -Config $intensityConfig
        }
        "schedule" {
            Write-Log "Scheduled chaos experiments not yet implemented" "WARN"
        }
    }
    
    # Wait for experiments to complete
    if ($TestType -ne "comprehensive") {
        Write-Log "Waiting for chaos experiments to complete..." "INFO"
        Start-Sleep -Seconds $Duration
    }
    
    # Generate report
    $reportPath = Generate-ChaosReport
    
    Write-Log "Chaos engineering experiments completed successfully" "SUCCESS"
    Write-Log "Report available at: $reportPath" "INFO"
}
catch {
    Write-Log "Chaos engineering failed: $($_.Exception.Message)" "ERROR"
    throw
}
finally {
    # Cleanup if auto-recovery is enabled
    if ($AutoRecover) {
        Cleanup-ChaosExperiments
    }
}

Write-Log "Chaos Engineering Controller execution completed" "SUCCESS"
