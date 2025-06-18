# Emergency-Diagnostic.ps1
# Script de diagnostic et réparation complète pour Phase 0
# Réparation infrastructure, optimisation ressources, prévention freeze IDE

param(
   [switch]$RunDiagnostic,
   [switch]$RunRepair,
   [switch]$OptimizeResources,
   [switch]$EmergencyStop,
   [switch]$AllPhases
)

# Configuration globale
$CONFIG = @{
   MaxCPUUsage       = 70        # Pourcentage max CPU
   MaxRAMUsageGB     = 6       # GB max RAM
   CriticalPorts     = @(8080, 5432, 6379, 6333, 3000, 9000)
   ServiceTimeoutSec = 30  # Timeout services
   LogFile           = "emergency-diagnostic.log"
}

# Colors for output
$Colors = @{
   Error    = 'Red'
   Warning  = 'Yellow'
   Success  = 'Green'
   Info     = 'Cyan'
   Critical = 'Magenta'
}

function Write-DiagnosticHeader {
   param([string]$Title)
   Write-Host "`n" + "="*60 -ForegroundColor $Colors.Info
   Write-Host "🚨 EMERGENCY DIAGNOSTIC: $Title" -ForegroundColor $Colors.Critical
   Write-Host "="*60 + "`n" -ForegroundColor $Colors.Info
}

function Test-ApiServerStatus {
   Write-DiagnosticHeader "API Server Status Check"
    
   try {
      # Test localhost:8080
      $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 5 -ErrorAction Stop
      Write-Host "✅ API Server running on localhost:8080" -ForegroundColor $Colors.Success
      return $true
   }
   catch {
      Write-Host "❌ API Server NOT running on localhost:8080" -ForegroundColor $Colors.Error
      Write-Host "Error: $($_.Exception.Message)" -ForegroundColor $Colors.Error
      return $false
   }
}

function Test-PortAvailability {
   Write-DiagnosticHeader "Port Availability Check"
    
   $criticalPorts = @(8080, 5432, 6379, 6333)
   $portStatus = @{}
    
   foreach ($port in $criticalPorts) {
      try {
         $tcpClient = New-Object System.Net.Sockets.TcpClient
         $tcpClient.Connect('localhost', $port)
         $tcpClient.Close()
         Write-Host "🟢 Port $port is OCCUPIED" -ForegroundColor $Colors.Warning
         $portStatus[$port] = "occupied"
      }
      catch {
         Write-Host "🔴 Port $port is FREE" -ForegroundColor $Colors.Info
         $portStatus[$port] = "free"
      }
   }
    
   return $portStatus
}

function Get-ResourceUsage {
   Write-DiagnosticHeader "System Resource Usage"
    
   # CPU Usage
   $cpu = Get-Counter '\Processor(_Total)\% Processor Time' | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue
   $cpuUsage = [math]::Round(100 - $cpu, 2)
    
   # RAM Usage
   $ram = Get-CimInstance -ClassName Win32_OperatingSystem
   $totalRam = [math]::Round($ram.TotalVisibleMemorySize / 1MB, 2)
   $freeRam = [math]::Round($ram.FreePhysicalMemory / 1MB, 2)
   $usedRam = [math]::Round($totalRam - $freeRam, 2)
   $ramPercent = [math]::Round(($usedRam / $totalRam) * 100, 2)
    
   Write-Host "💻 CPU Usage: $cpuUsage%" -ForegroundColor $(if ($cpuUsage -gt 80) { $Colors.Error } elseif ($cpuUsage -gt 60) { $Colors.Warning } else { $Colors.Success })
   Write-Host "🧠 RAM Usage: $usedRam GB / $totalRam GB ($ramPercent%)" -ForegroundColor $(if ($ramPercent -gt 85) { $Colors.Error } elseif ($ramPercent -gt 70) { $Colors.Warning } else { $Colors.Success })
    
   return @{
      CPU = $cpuUsage
      RAM = @{
         Used    = $usedRam
         Total   = $totalRam
         Percent = $ramPercent
      }
   }
}

function Get-HeavyProcesses {
   Write-DiagnosticHeader "Heavy Processes Analysis"
    
   $heavyProcesses = Get-Process | Where-Object { $_.WorkingSet -gt 100MB } | 
   Sort-Object WorkingSet -Descending | 
   Select-Object -First 10 Name, Id, @{Name = "RAM(MB)"; Expression = { [math]::Round($_.WorkingSet / 1MB, 2) } }, @{Name = "CPU(%)"; Expression = { $_.CPU } }
    
   foreach ($process in $heavyProcesses) {
      $color = if ($process.'RAM(MB)' -gt 1000) { $Colors.Error } elseif ($process.'RAM(MB)' -gt 500) { $Colors.Warning } else { $Colors.Success }
      Write-Host "🔄 $($process.Name) (PID: $($process.Id)): $($process.'RAM(MB)') MB" -ForegroundColor $color
   }
    
   return $heavyProcesses
}

function Test-DockerStatus {
   Write-DiagnosticHeader "Docker & Containers Status"
    
   try {
      $dockerVersion = docker version --format "{{.Server.Version}}" 2>$null
      if ($dockerVersion) {
         Write-Host "✅ Docker Engine running (v$dockerVersion)" -ForegroundColor $Colors.Success
            
         # Check containers
         $containers = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>$null
         if ($containers) {
            Write-Host "📦 Active containers:" -ForegroundColor $Colors.Info
            Write-Host $containers
         }
         else {
            Write-Host "⚠️ No active containers" -ForegroundColor $Colors.Warning
         }
      }
      else {
         throw "Docker not responding"
      }
   }
   catch {
      Write-Host "❌ Docker Engine not running or not accessible" -ForegroundColor $Colors.Error
      return $false
   }
   return $true
}

function Test-DatabaseConnections {
   Write-DiagnosticHeader "Database Connections Test"
    
   # Test Redis
   try {
      redis-cli ping 2>$null | Out-Null
      Write-Host "✅ Redis connection OK" -ForegroundColor $Colors.Success
   }
   catch {
      Write-Host "❌ Redis connection FAILED" -ForegroundColor $Colors.Error
   }
    
   # Test Qdrant
   try {
      $qdrantResponse = Invoke-WebRequest -Uri "http://localhost:6333/health" -TimeoutSec 3 -ErrorAction Stop
      Write-Host "✅ Qdrant connection OK" -ForegroundColor $Colors.Success
   }
   catch {
      Write-Host "❌ Qdrant connection FAILED" -ForegroundColor $Colors.Error
   }
    
   # Test PostgreSQL
   try {
      $pgTest = pg_isready -h localhost -p 5432 2>$null
      if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ PostgreSQL connection OK" -ForegroundColor $Colors.Success
      }
      else {
         Write-Host "❌ PostgreSQL connection FAILED" -ForegroundColor $Colors.Error
      }
   }
   catch {
      Write-Host "❌ PostgreSQL test command failed" -ForegroundColor $Colors.Error
   }
}

function Repair-InfrastructureStack {
   Write-DiagnosticHeader "EMERGENCY REPAIR PROCEDURES"
    
   Write-Host "🔧 Starting emergency repair..." -ForegroundColor $Colors.Warning
    
   # Kill orphaned processes
   Write-Host "1. Cleaning orphaned processes..." -ForegroundColor $Colors.Info
   Get-Process | Where-Object { $_.Name -like "*api-server*" -or $_.Name -like "*infrastructure*" } | ForEach-Object {
      Write-Host "   Stopping orphaned process: $($_.Name) (PID: $($_.Id))" -ForegroundColor $Colors.Warning
      Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
   }
    
   # Clear port 8080 if occupied
   Write-Host "2. Clearing port conflicts..." -ForegroundColor $Colors.Info
   $port8080Process = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
   if ($port8080Process) {
      $pid = $port8080Process.OwningProcess
      Write-Host "   Killing process on port 8080 (PID: $pid)" -ForegroundColor $Colors.Warning
      Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
   }
    
   # Restart API Server
   Write-Host "3. Restarting API Server..." -ForegroundColor $Colors.Info
   $apiServerPath = ".\cmd\infrastructure-api-server\main.go"
   if (Test-Path $apiServerPath) {
      Start-Process -FilePath "go" -ArgumentList "run", $apiServerPath -WindowStyle Hidden
      Start-Sleep -Seconds 3
        
      # Test if repair worked
      if (Test-ApiServerStatus) {
         Write-Host "✅ API Server repair SUCCESSFUL" -ForegroundColor $Colors.Success
      }
      else {
         Write-Host "❌ API Server repair FAILED" -ForegroundColor $Colors.Error
      }
   }
   else {
      Write-Host "❌ API Server source not found at $apiServerPath" -ForegroundColor $Colors.Error
   }
}

function Optimize-Resources {
   Write-DiagnosticHeader "RESOURCE OPTIMIZATION"
    
   Write-Host "🚀 Optimizing system resources..." -ForegroundColor $Colors.Info
    
   # Set process priorities
   $processes = @("Code", "docker", "qdrant", "postgres", "redis-server")
   foreach ($processName in $processes) {
      $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
      if ($process) {
         try {
            $process.PriorityClass = "Normal"
            Write-Host "✅ Optimized priority for $processName" -ForegroundColor $Colors.Success
         }
         catch {
            Write-Host "⚠️ Could not optimize priority for $processName" -ForegroundColor $Colors.Warning
         }
      }
   }
    
   # Clear system caches
   Write-Host "🧹 Clearing system caches..." -ForegroundColor $Colors.Info
   [System.GC]::Collect()
    
   Write-Host "✅ Resource optimization complete" -ForegroundColor $Colors.Success
}

# Main execution
Write-Host "🚨 EMERGENCY INFRASTRUCTURE DIAGNOSTIC" -ForegroundColor $Colors.Critical
Write-Host "Started at: $(Get-Date)" -ForegroundColor $Colors.Info

# Always run basic diagnostic
$apiStatus = Test-ApiServerStatus
$portStatus = Test-PortAvailability
$resourceUsage = Get-ResourceUsage

if ($FullDiagnostic) {
   $heavyProcesses = Get-HeavyProcesses
   $dockerStatus = Test-DockerStatus
   Test-DatabaseConnections
}

if ($Repair) {
   Repair-InfrastructureStack
}

if ($ResourceOptimization) {
   Optimize-Resources
}

# Summary
Write-DiagnosticHeader "DIAGNOSTIC SUMMARY"
Write-Host "API Server Status: $(if($apiStatus) { '✅ OK' } else { '❌ FAILED' })" -ForegroundColor $(if ($apiStatus) { $Colors.Success } else { $Colors.Error })
Write-Host "Resource Usage: CPU $($resourceUsage.CPU)% | RAM $($resourceUsage.RAM.Percent)%" -ForegroundColor $Colors.Info

if (-not $apiStatus) {
   Write-Host "`n🔧 RECOMMENDED ACTIONS:" -ForegroundColor $Colors.Warning
   Write-Host "1. Run: .\Emergency-Diagnostic.ps1 -Repair" -ForegroundColor $Colors.Info
   Write-Host "2. Run: .\Emergency-Diagnostic.ps1 -ResourceOptimization" -ForegroundColor $Colors.Info
   Write-Host "3. Restart VSCode if issues persist" -ForegroundColor $Colors.Info
}

Write-Host "`nDiagnostic completed at: $(Get-Date)" -ForegroundColor $Colors.Info
