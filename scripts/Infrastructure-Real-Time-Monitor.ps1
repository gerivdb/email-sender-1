#!/usr/bin/env pwsh
# Infrastructure-Real-Time-Monitor.ps1 - Monitoring temps réel Phase 0.1
# Surveillance continue de l'infrastructure avec alertes automatiques

param(
   [int]$RefreshIntervalSeconds = 30,
   [switch]$EnableAutoRepair = $false,
   [string]$LogPath = "infrastructure-monitor.log"
)

# Configuration
$CRITICAL_PORTS = @(8080, 5432, 6379, 6333)
$MEMORY_WARNING_THRESHOLD = 18  # GB
$MEMORY_CRITICAL_THRESHOLD = 22 # GB
$API_TIMEOUT_SECONDS = 10

# Couleurs pour l'affichage
$Colors = @{
   Header  = "Cyan"
   Success = "Green" 
   Warning = "Yellow"
   Error   = "Red"
   Info    = "White"
}

function Write-MonitorLog {
   param([string]$Message, [string]$Level = "INFO")
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [$Level] $Message"
   Add-Content -Path $LogPath -Value $logEntry
    
   $color = switch ($Level) {
      "SUCCESS" { $Colors.Success }
      "WARNING" { $Colors.Warning }
      "ERROR" { $Colors.Error }
      default { $Colors.Info }
   }
    
   Write-Host $logEntry -ForegroundColor $color
}

function Get-SystemMetrics {
   try {
      $memory = Get-CimInstance -ClassName Win32_OperatingSystem
      $cpu = Get-CimInstance -ClassName Win32_Processor
        
      $totalRAM = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
      $usedRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
      $freeRAM = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)
      $usagePercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
        
      # CPU load average (approximation via LoadPercentage)
      $cpuLoad = ($cpu | Measure-Object -Property LoadPercentage -Average).Average
        
      return @{
         TotalRAM     = $totalRAM
         UsedRAM      = $usedRAM
         FreeRAM      = $freeRAM
         UsagePercent = $usagePercent
         CPULoad      = [math]::Round($cpuLoad, 1)
      }
   }
   catch {
      Write-MonitorLog "Error getting system metrics: $($_.Exception.Message)" "ERROR"
      return $null
   }
}

function Test-ApiServerStatus {
   try {
      $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec $API_TIMEOUT_SECONDS -ErrorAction Stop
      return @{
         IsHealthy    = ($response.status -eq "healthy")
         ResponseTime = (Measure-Command { Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec $API_TIMEOUT_SECONDS }).TotalMilliseconds
         Status       = $response.status
      }
   }
   catch {
      return @{
         IsHealthy    = $false
         ResponseTime = -1
         Status       = "unreachable"
         Error        = $_.Exception.Message
      }
   }
}

function Test-PortsStatus {
   $portStatus = @{}
    
   foreach ($port in $CRITICAL_PORTS) {
      try {
         $connections = netstat -ano | Select-String ":$port\s"
         $portStatus[$port] = @{
            IsOccupied   = ($connections -ne $null)
            ProcessCount = if ($connections) { $connections.Count } else { 0 }
         }
      }
      catch {
         $portStatus[$port] = @{
            IsOccupied   = $false
            ProcessCount = 0
            Error        = $_.Exception.Message
         }
      }
   }
    
   return $portStatus
}

function Test-ProcessHealth {
   try {
      # Vérifier les processus critiques
      $criticalProcesses = @("api-server-fixed")
      $processStatus = @{}
        
      foreach ($processName in $criticalProcesses) {
         $processes = Get-Process | Where-Object { $_.ProcessName -match $processName }
         $processStatus[$processName] = @{
            IsRunning    = ($processes.Count -gt 0)
            ProcessCount = $processes.Count
            PIDs         = if ($processes) { $processes.Id } else { @() }
            MemoryUsage  = if ($processes) { [math]::Round(($processes | Measure-Object WorkingSet -Sum).Sum / 1MB, 1) } else { 0 }
         }
      }
        
      return $processStatus
   }
   catch {
      Write-MonitorLog "Error checking process health: $($_.Exception.Message)" "ERROR"
      return @{}
   }
}

function Invoke-AutoRepair {
   param([hashtable]$Issues)
    
   if (-not $EnableAutoRepair) {
      Write-MonitorLog "Auto-repair disabled. Manual intervention required." "WARNING"
      return
   }
    
   Write-MonitorLog "🔧 INITIATING AUTO-REPAIR..." "WARNING"
    
   try {
      $scriptPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "Emergency-Repair-Fixed.ps1"
      if (Test-Path $scriptPath) {
         & $scriptPath
         Write-MonitorLog "Auto-repair script executed successfully" "SUCCESS"
      }
      else {
         Write-MonitorLog "Emergency repair script not found: $scriptPath" "ERROR"
      }
   }
   catch {
      Write-MonitorLog "Auto-repair failed: $($_.Exception.Message)" "ERROR"
   }
}

function Show-MonitorDashboard {
   param(
      [hashtable]$SystemMetrics,
      [hashtable]$ApiStatus,
      [hashtable]$PortsStatus,
      [hashtable]$ProcessStatus
   )
    
   Clear-Host
    
   # Header
   Write-Host "🔧 INFRASTRUCTURE REAL-TIME MONITOR - Phase 0.1" -ForegroundColor $Colors.Header
   Write-Host "=============================================" -ForegroundColor $Colors.Header
   Write-Host "Last Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $Colors.Info
   Write-Host "Refresh Interval: $RefreshIntervalSeconds seconds | Auto-Repair: $EnableAutoRepair" -ForegroundColor $Colors.Info
   Write-Host ""
    
   # System Metrics
   Write-Host "📊 SYSTEM METRICS" -ForegroundColor $Colors.Header
   Write-Host "=================" -ForegroundColor $Colors.Header
    
   if ($SystemMetrics) {
      $memoryColor = if ($SystemMetrics.UsedRAM -ge $MEMORY_CRITICAL_THRESHOLD) { $Colors.Error }
      elseif ($SystemMetrics.UsedRAM -ge $MEMORY_WARNING_THRESHOLD) { $Colors.Warning }
      else { $Colors.Success }
        
      Write-Host "Memory: $($SystemMetrics.UsedRAM) GB / $($SystemMetrics.TotalRAM) GB ($($SystemMetrics.UsagePercent)%)" -ForegroundColor $memoryColor
      Write-Host "CPU Load: $($SystemMetrics.CPULoad)%" -ForegroundColor $(if ($SystemMetrics.CPULoad -gt 80) { $Colors.Warning } else { $Colors.Success })
      Write-Host ""
   }
    
   # API Server Status
   Write-Host "🌐 API SERVER STATUS" -ForegroundColor $Colors.Header
   Write-Host "===================" -ForegroundColor $Colors.Header
    
   if ($ApiStatus) {
      $apiColor = if ($ApiStatus.IsHealthy) { $Colors.Success } else { $Colors.Error }
      Write-Host "Status: $($ApiStatus.Status.ToUpper())" -ForegroundColor $apiColor
      if ($ApiStatus.ResponseTime -gt 0) {
         Write-Host "Response Time: $([math]::Round($ApiStatus.ResponseTime, 2)) ms" -ForegroundColor $Colors.Info
      }
      if ($ApiStatus.Error) {
         Write-Host "Error: $($ApiStatus.Error)" -ForegroundColor $Colors.Error
      }
      Write-Host ""
   }
    
   # Ports Status
   Write-Host "🔌 PORTS STATUS" -ForegroundColor $Colors.Header
   Write-Host "===============" -ForegroundColor $Colors.Header
    
   foreach ($port in $CRITICAL_PORTS) {
      if ($PortsStatus.ContainsKey($port)) {
         $status = $PortsStatus[$port]
         $portColor = if ($status.IsOccupied) { $Colors.Success } else { $Colors.Warning }
         $statusText = if ($status.IsOccupied) { "OCCUPIED" } else { "AVAILABLE" }
         Write-Host "Port $port : $statusText ($($status.ProcessCount) processes)" -ForegroundColor $portColor
      }
   }
   Write-Host ""
    
   # Process Status
   Write-Host "⚙️ CRITICAL PROCESSES" -ForegroundColor $Colors.Header
   Write-Host "=====================" -ForegroundColor $Colors.Header
    
   foreach ($processName in $ProcessStatus.Keys) {
      $process = $ProcessStatus[$processName]
      $processColor = if ($process.IsRunning) { $Colors.Success } else { $Colors.Error }
      $statusText = if ($process.IsRunning) { "RUNNING" } else { "STOPPED" }
      Write-Host "$processName : $statusText" -ForegroundColor $processColor
      if ($process.IsRunning) {
         Write-Host "  PIDs: $($process.PIDs -join ', ') | Memory: $($process.MemoryUsage) MB" -ForegroundColor $Colors.Info
      }
   }
   Write-Host ""
    
   # Health Summary
   $healthyComponents = 0
   $totalComponents = 4
    
   if ($SystemMetrics -and $SystemMetrics.UsedRAM -lt $MEMORY_CRITICAL_THRESHOLD) { $healthyComponents++ }
   if ($ApiStatus -and $ApiStatus.IsHealthy) { $healthyComponents++ }
   if ($PortsStatus -and ($PortsStatus.Values | Where-Object { $_.IsOccupied }).Count -ge 2) { $healthyComponents++ }
   if ($ProcessStatus -and ($ProcessStatus.Values | Where-Object { $_.IsRunning }).Count -gt 0) { $healthyComponents++ }
    
   $healthPercent = [math]::Round(($healthyComponents / $totalComponents) * 100, 1)
   $healthColor = if ($healthPercent -ge 90) { $Colors.Success }
   elseif ($healthPercent -ge 70) { $Colors.Warning }
   else { $Colors.Error }
    
   Write-Host "🏥 INFRASTRUCTURE HEALTH: $healthPercent% ($healthyComponents/$totalComponents)" -ForegroundColor $healthColor
   Write-Host ""
    
   # Controls
   Write-Host "📋 CONTROLS" -ForegroundColor $Colors.Header
   Write-Host "===========" -ForegroundColor $Colors.Header
   Write-Host "Press 'R' to force repair | 'Q' to quit | 'S' to toggle auto-repair" -ForegroundColor $Colors.Info
   Write-Host ""
}

function Test-HealthIssues {
   param(
      [hashtable]$SystemMetrics,
      [hashtable]$ApiStatus,
      [hashtable]$PortsStatus,
      [hashtable]$ProcessStatus
   )
    
   $issues = @()
    
   # Vérifier la mémoire
   if ($SystemMetrics -and $SystemMetrics.UsedRAM -ge $MEMORY_CRITICAL_THRESHOLD) {
      $issues += "CRITICAL: Memory usage exceeds safe threshold ($($SystemMetrics.UsedRAM) GB)"
      Write-MonitorLog "CRITICAL: Memory usage at $($SystemMetrics.UsedRAM) GB" "ERROR"
   }
   elseif ($SystemMetrics -and $SystemMetrics.UsedRAM -ge $MEMORY_WARNING_THRESHOLD) {
      $issues += "WARNING: Memory usage approaching threshold ($($SystemMetrics.UsedRAM) GB)"
      Write-MonitorLog "WARNING: High memory usage at $($SystemMetrics.UsedRAM) GB" "WARNING"
   }
    
   # Vérifier l'API Server
   if ($ApiStatus -and -not $ApiStatus.IsHealthy) {
      $issues += "CRITICAL: API Server is not healthy ($($ApiStatus.Status))"
      Write-MonitorLog "CRITICAL: API Server unhealthy - $($ApiStatus.Status)" "ERROR"
   }
    
   # Vérifier les processus critiques
   foreach ($processName in $ProcessStatus.Keys) {
      $process = $ProcessStatus[$processName]
      if (-not $process.IsRunning) {
         $issues += "CRITICAL: Critical process '$processName' is not running"
         Write-MonitorLog "CRITICAL: Process $processName not running" "ERROR"
      }
   }
    
   return $issues
}

# PROGRAMME PRINCIPAL
Write-MonitorLog "Starting Infrastructure Real-Time Monitor..." "INFO"
Write-MonitorLog "Refresh interval: $RefreshIntervalSeconds seconds" "INFO"
Write-MonitorLog "Auto-repair: $EnableAutoRepair" "INFO"

$lastRepairTime = Get-Date
$repairCooldownMinutes = 10

try {
   while ($true) {
      # Collecte des métriques
      $systemMetrics = Get-SystemMetrics
      $apiStatus = Test-ApiServerStatus
      $portsStatus = Test-PortsStatus
      $processStatus = Test-ProcessHealth
        
      # Affichage du dashboard
      Show-MonitorDashboard -SystemMetrics $systemMetrics -ApiStatus $apiStatus -PortsStatus $portsStatus -ProcessStatus $processStatus
        
      # Détection des problèmes
      $issues = Test-HealthIssues -SystemMetrics $systemMetrics -ApiStatus $apiStatus -PortsStatus $portsStatus -ProcessStatus $processStatus
        
      # Auto-réparation si nécessaire
      if ($issues.Count -gt 0 -and $EnableAutoRepair) {
         $timeSinceLastRepair = (Get-Date) - $lastRepairTime
         if ($timeSinceLastRepair.TotalMinutes -ge $repairCooldownMinutes) {
            Invoke-AutoRepair -Issues $issues
            $lastRepairTime = Get-Date
         }
         else {
            Write-MonitorLog "Auto-repair on cooldown ($([math]::Round($repairCooldownMinutes - $timeSinceLastRepair.TotalMinutes, 1)) min remaining)" "INFO"
         }
      }
        
      # Attendre ou traiter les commandes clavier
      $timeout = $RefreshIntervalSeconds * 1000
      if ([System.Console]::KeyAvailable) {
         $key = [System.Console]::ReadKey($true)
         switch ($key.Key) {
            'Q' { 
               Write-MonitorLog "Monitor stopped by user" "INFO"
               exit 0 
            }
            'R' { 
               Write-MonitorLog "Manual repair triggered by user" "INFO"
               Invoke-AutoRepair -Issues @("Manual repair requested")
               $lastRepairTime = Get-Date
            }
            'S' { 
               $EnableAutoRepair = -not $EnableAutoRepair
               Write-MonitorLog "Auto-repair toggled: $EnableAutoRepair" "INFO"
            }
         }
      }
      else {
         Start-Sleep -Seconds $RefreshIntervalSeconds
      }
   }
}
catch {
   Write-MonitorLog "Monitor error: $($_.Exception.Message)" "ERROR"
   Write-Host "Press any key to exit..." -ForegroundColor Red
   [System.Console]::ReadKey() | Out-Null
}
