#!/usr/bin/env pwsh
# Performance Metrics Collector
# Collecte automatique des métriques de performance

param(
    [Parameter(Mandatory = $false)]
    [int]$IntervalSeconds = 60,
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "metrics/data",
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "metrics/config/collector-config.json",
    [Parameter(Mandatory = $false)]
    [switch]$RunOnce
)

# Create output directory
New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null

# Default configuration
$defaultConfig = @{
    Enabled = $true
    Metrics = @{
        Performance = @{
            CPU = $true
            Memory = $true
            Disk = $true
            Network = $true
        }
        Application = @{
            EmailSender = $true
            Qdrant = $true
            MockServices = $true
        }
    }
    Thresholds = @{
        CPUWarning = 80
        CPUCritical = 90
        MemoryWarning = 80
        MemoryCritical = 90
    }
    Retention = @{
        Days = 30
        MaxFiles = 1000
    }
}

function Collect-SystemMetrics {
    param([hashtable]$Config)
    
    $metrics = @{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        System = @{}
        Application = @{}
    }
    
    # CPU metrics
    if ($Config.Metrics.Performance.CPU) {
        $cpu = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average
        $metrics.System.CPU = @{
            Usage = [math]::Round($cpu.Average, 2)
            Cores = $env:NUMBER_OF_PROCESSORS
        }
    }
    
    # Memory metrics
    if ($Config.Metrics.Performance.Memory) {
        $totalRAM = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory
        $freeRAM = (Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory * 1KB
        $usedRAM = $totalRAM - $freeRAM
        $memoryUsage = [math]::Round(($usedRAM / $totalRAM) * 100, 2)
        
        $metrics.System.Memory = @{
            Total = [math]::Round($totalRAM / 1GB, 2)
            Used = [math]::Round($usedRAM / 1GB, 2)
            Free = [math]::Round($freeRAM / 1GB, 2)
            Usage = $memoryUsage
        }
    }
    
    # Disk metrics
    if ($Config.Metrics.Performance.Disk) {
        $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | Where-Object { $_.DeviceID -eq "C:" }
        $diskUsage = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
        
        $metrics.System.Disk = @{
            Total = [math]::Round($disk.Size / 1GB, 2)
            Free = [math]::Round($disk.FreeSpace / 1GB, 2)
            Usage = $diskUsage
        }
    }
    
    # Application-specific metrics
    if ($Config.Metrics.Application.EmailSender) {
        $emailMetrics = Collect-EmailSenderMetrics
        $metrics.Application.EmailSender = $emailMetrics
    }
    
    if ($Config.Metrics.Application.Qdrant) {
        $qdrantMetrics = Collect-QdrantMetrics
        $metrics.Application.Qdrant = $qdrantMetrics
    }
    
    return $metrics
}

function Collect-EmailSenderMetrics {
    # Collect email sender specific metrics
    $metrics = @{
        ProcessCount = (Get-Process | Where-Object { $_.ProcessName -like "*email*" }).Count
        Status = "Running"
        LastRun = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    }
    
    # Check if email sender logs exist
    if (Test-Path "logs/daily") {
        $logFiles = Get-ChildItem "logs/daily" -Filter "*.log" | Sort-Object LastWriteTime -Descending
        if ($logFiles.Count -gt 0) {
            $metrics.LastLogUpdate = $logFiles[0].LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss")
        }
    }
    
    return $metrics
}

function Collect-QdrantMetrics {
    # Collect Qdrant specific metrics
    $metrics = @{
        Status = "Unknown"
        Collections = 0
        VectorCount = 0
    }
    
    try {
        # Try to get Qdrant status (if running)
        $qdrantProcess = Get-Process | Where-Object { $_.ProcessName -like "*qdrant*" }
        if ($qdrantProcess) {
            $metrics.Status = "Running"
            $metrics.ProcessId = $qdrantProcess.Id
        }
        
        # Check data directory
        if (Test-Path "data/qdrant") {
            $dataSize = (Get-ChildItem "data/qdrant" -Recurse | Measure-Object -Property Length -Sum).Sum
            $metrics.DataSize = [math]::Round($dataSize / 1MB, 2)
        }
    }
    catch {
        $metrics.Status = "Error"
        $metrics.Error = $_.Exception.Message
    }
    
    return $metrics
}

function Test-MetricAlerts {
    param([hashtable]$Metrics, [hashtable]$Config)
    
    $alerts = @()
    
    # CPU alerts
    if ($Metrics.System.CPU.Usage -gt $Config.Thresholds.CPUCritical) {
        $alerts += @{
            Type = "Critical"
            Metric = "CPU"
            Value = $Metrics.System.CPU.Usage
            Threshold = $Config.Thresholds.CPUCritical
            Message = "CPU usage critical: $($Metrics.System.CPU.Usage)%"
        }
    }
    elseif ($Metrics.System.CPU.Usage -gt $Config.Thresholds.CPUWarning) {
        $alerts += @{
            Type = "Warning"
            Metric = "CPU" 
            Value = $Metrics.System.CPU.Usage
            Threshold = $Config.Thresholds.CPUWarning
            Message = "CPU usage warning: $($Metrics.System.CPU.Usage)%"
        }
    }
    
    # Memory alerts
    if ($Metrics.System.Memory.Usage -gt $Config.Thresholds.MemoryCritical) {
        $alerts += @{
            Type = "Critical"
            Metric = "Memory"
            Value = $Metrics.System.Memory.Usage
            Threshold = $Config.Thresholds.MemoryCritical
            Message = "Memory usage critical: $($Metrics.System.Memory.Usage)%"
        }
    }
    elseif ($Metrics.System.Memory.Usage -gt $Config.Thresholds.MemoryWarning) {
        $alerts += @{
            Type = "Warning"
            Metric = "Memory"
            Value = $Metrics.System.Memory.Usage
            Threshold = $Config.Thresholds.MemoryWarning
            Message = "Memory usage warning: $($Metrics.System.Memory.Usage)%"
        }
    }
    
    return $alerts
}

# Load configuration
if (Test-Path $ConfigPath) {
    $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable
} else {
    $config = $defaultConfig
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath
    Write-Host "Configuration created: $ConfigPath" -ForegroundColor Yellow
}

# Main collection loop
Write-Host "Starting Performance Metrics Collection" -ForegroundColor Cyan
Write-Host "Output: $OutputPath" -ForegroundColor Gray
Write-Host "Interval: $IntervalSeconds seconds" -ForegroundColor Gray

do {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $outputFile = Join-Path $OutputPath "metrics_$timestamp.json"
    
    # Collect metrics
    $metrics = Collect-SystemMetrics -Config $config
    
    # Check alerts
    $alerts = Test-MetricAlerts -Metrics $metrics -Config $config
    if ($alerts.Count -gt 0) {
        $metrics.Alerts = $alerts
        foreach ($alert in $alerts) {
            Write-Host "ALERT [$($alert.Type)]: $($alert.Message)" -ForegroundColor Red
        }
    }
    
    # Save metrics
    $metrics | ConvertTo-Json -Depth 10 | Set-Content -Path $outputFile
    Write-Host "Metrics collected: $outputFile" -ForegroundColor Green
    
    if (-not $RunOnce) {
        Start-Sleep -Seconds $IntervalSeconds
    }
} while (-not $RunOnce)

Write-Host "Metrics collection completed" -ForegroundColor Green
