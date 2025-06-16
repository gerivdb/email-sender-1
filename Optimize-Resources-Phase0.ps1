# Optimize-Resources-Phase0.ps1
# Script d'optimisation ciblée des ressources pour Phase 0

param(
   [switch]$KillHeavyProcesses,
   [switch]$OptimizeVSCode,
   [switch]$OptimizeGo,
   [switch]$MonitorOnly,
   [switch]$All
)

$Colors = @{
   Error    = "Red"
   Warning  = "Yellow" 
   Success  = "Green"
   Info     = "Cyan"
   Critical = "Magenta"
}

function Write-OptimLog {
   param([string]$Message, [string]$Level = "Info")
   $timestamp = Get-Date -Format "HH:mm:ss"
   Write-Host "[$timestamp] $Message" -ForegroundColor $Colors[$Level]
}

function Get-ResourceSummary {
   Write-OptimLog "📊 Analyzing system resources..." "Info"
    
   # CPU Usage
   $cpuCounter = Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1
   $cpuUsage = [Math]::Round(100 - $cpuCounter.CounterSamples.CookedValue, 1)
    
   # Memory Usage
   $memory = Get-CimInstance -ClassName Win32_OperatingSystem
   $ramUsedGB = [Math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 2)
   $ramTotalGB = [Math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    
   # Process Analysis
   $heavyProcesses = Get-Process | Where-Object { $_.CPU -gt 100 -or ($_.WorkingSet / 1MB) -gt 500 } | 
   Sort-Object CPU -Descending | Select-Object -First 10
    
   Write-OptimLog "💾 System Status:" "Info"
   Write-OptimLog "   CPU: $cpuUsage%" $(if ($cpuUsage -gt 70) { "Warning" } else { "Success" })
   Write-OptimLog "   RAM: $ramUsedGB GB / $ramTotalGB GB" $(if ($ramUsedGB -gt 6) { "Warning" } else { "Success" })
   Write-OptimLog "   Heavy Processes: $($heavyProcesses.Count)" $(if ($heavyProcesses.Count -gt 5) { "Warning" } else { "Success" })
    
   return @{
      CPU            = $cpuUsage
      RAMUsedGB      = $ramUsedGB
      RAMTotalGB     = $ramTotalGB
      HeavyProcesses = $heavyProcesses
   }
}

function Optimize-VSCodeProcesses {
   Write-OptimLog "🔧 Optimizing VSCode processes..." "Warning"
    
   $vscodeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue
   if (-not $vscodeProcesses) {
      Write-OptimLog "No VSCode processes found" "Info"
      return 0
   }
    
   Write-OptimLog "Found $($vscodeProcesses.Count) VSCode processes" "Info"
    
   # Identifier le processus principal (celui avec le plus de RAM)
   $mainProcess = $vscodeProcesses | Sort-Object WorkingSet -Descending | Select-Object -First 1
   Write-OptimLog "Main VSCode process: PID $($mainProcess.Id) - $([Math]::Round($mainProcess.WorkingSet/1MB,2))MB" "Info"
    
   $optimized = 0
   foreach ($process in $vscodeProcesses) {
      try {
         # Garder priorité normale pour le processus principal
         if ($process.Id -eq $mainProcess.Id) {
            $process.PriorityClass = "Normal"
            Write-OptimLog "Kept normal priority for main process PID $($process.Id)" "Success"
         }
         else {
            # Réduire priorité pour les processus auxiliaires
            $process.PriorityClass = "BelowNormal"
            Write-OptimLog "Reduced priority for auxiliary process PID $($process.Id)" "Success"
            $optimized++
         }
      }
      catch {
         Write-OptimLog "Failed to optimize process PID $($process.Id): $($_.Exception.Message)" "Error"
      }
   }
    
   Write-OptimLog "✅ Optimized $optimized VSCode auxiliary processes" "Success"
   return $optimized
}

function Optimize-GoProcesses {
   Write-OptimLog "🔧 Optimizing Go processes..." "Warning"
    
   # Processus Go
   $goProcesses = Get-Process | Where-Object { $_.ProcessName -eq "go" }
   Write-OptimLog "Found $($goProcesses.Count) Go processes" "Info"
    
   $killedGo = 0
   foreach ($process in $goProcesses) {
      # Tuer les processus Go qui semblent être des tests ou compilation
      if ($process.CPU -gt 5) {
         try {
            Write-OptimLog "Killing heavy Go process PID $($process.Id) (CPU: $($process.CPU))" "Warning"
            Stop-Process -Id $process.Id -Force
            $killedGo++
         }
         catch {
            Write-OptimLog "Failed to kill Go process PID $($process.Id)" "Error"
         }
      }
   }
    
   # Processus gopls (Go Language Server)
   $goplsProcesses = Get-Process -Name "gopls" -ErrorAction SilentlyContinue
   Write-OptimLog "Found $($goplsProcesses.Count) gopls processes" "Info"
    
   $optimizedGopls = 0
   foreach ($process in $goplsProcesses) {
      try {
         # Réduire priorité mais ne pas tuer (nécessaire pour VSCode Go extension)
         if ($process.CPU -gt 1000) {
            Write-OptimLog "Heavy gopls detected PID $($process.Id) - CPU: $($process.CPU)" "Warning"
            $process.PriorityClass = "BelowNormal"
            $optimizedGopls++
         }
         else {
            $process.PriorityClass = "Normal"
         }
      }
      catch {
         Write-OptimLog "Failed to optimize gopls process PID $($process.Id)" "Error"
      }
   }
    
   Write-OptimLog "✅ Killed $killedGo Go processes, optimized $optimizedGopls gopls processes" "Success"
   return @{ KilledGo = $killedGo; OptimizedGopls = $optimizedGopls }
}

function Kill-HeavyProcesses {
   Write-OptimLog "🚨 Killing heavy non-essential processes..." "Critical"
    
   $summary = Get-ResourceSummary
   $killed = 0
    
   # Processus à tuer si trop lourds
   $killTargets = @(
      @{ Pattern = "chrome"; CPUThreshold = 15000; RAMThresholdMB = 800; KeepCount = 3 },
      @{ Pattern = "go"; CPUThreshold = 10; RAMThresholdMB = 50; KeepCount = 0 },
      @{ Pattern = "node"; CPUThreshold = 1000; RAMThresholdMB = 500; KeepCount = 1 }
   )
    
   foreach ($target in $killTargets) {
      $processes = Get-Process | Where-Object { $_.ProcessName -like "*$($target.Pattern)*" } |
      Sort-Object CPU -Descending
        
      if ($processes.Count -gt $target.KeepCount) {
         $toKill = $processes | Select-Object -Skip $target.KeepCount | Where-Object {
            $_.CPU -gt $target.CPUThreshold -or ($_.WorkingSet / 1MB) -gt $target.RAMThresholdMB
         }
            
         foreach ($process in $toKill) {
            try {
               Write-OptimLog "Killing heavy $($target.Pattern) process PID $($process.Id) - CPU: $($process.CPU), RAM: $([Math]::Round($process.WorkingSet/1MB,2))MB" "Warning"
               Stop-Process -Id $process.Id -Force
               $killed++
            }
            catch {
               Write-OptimLog "Failed to kill $($target.Pattern) process PID $($process.Id)" "Error"
            }
         }
      }
   }
    
   Write-OptimLog "🚨 Killed $killed heavy processes" "Critical"
   return $killed
}

function Start-ContinuousMonitoring {
   Write-OptimLog "📊 Starting continuous resource monitoring..." "Info"
    
   $monitoringJob = Start-Job -ScriptBlock {
      while ($true) {
         $cpuCounter = Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1
         $cpuUsage = [Math]::Round(100 - $cpuCounter.CounterSamples.CookedValue, 1)
            
         $memory = Get-CimInstance -ClassName Win32_OperatingSystem
         $ramUsedGB = [Math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 2)
            
         $timestamp = Get-Date -Format "HH:mm:ss"
         Write-Output "[$timestamp] CPU: $cpuUsage%, RAM: $ramUsedGB GB"
            
         if ($cpuUsage -gt 80 -or $ramUsedGB -gt 8) {
            Write-Output "[$timestamp] [ALERT] High resource usage detected!"
         }
            
         Start-Sleep -Seconds 30
      }
   }
    
   Write-OptimLog "Monitoring job started (ID: $($monitoringJob.Id))" "Success"
   Write-OptimLog "Use 'Receive-Job $($monitoringJob.Id)' to see monitoring output" "Info"
    
   return $monitoringJob
}

# === MAIN EXECUTION ===

Write-Host "`n⚡ RESOURCE OPTIMIZATION PHASE 0" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow

$initialSummary = Get-ResourceSummary

$results = @{
   OptimizedVSCode = 0
   OptimizedGo     = @{ KilledGo = 0; OptimizedGopls = 0 }
   KilledHeavy     = 0
   MonitoringJob   = $null
}

if ($OptimizeVSCode -or $All) {
   $results.OptimizedVSCode = Optimize-VSCodeProcesses
   Start-Sleep -Seconds 2
}

if ($OptimizeGo -or $All) {
   $results.OptimizedGo = Optimize-GoProcesses
   Start-Sleep -Seconds 2
}

if ($KillHeavyProcesses -or $All) {
   $results.KilledHeavy = Kill-HeavyProcesses
   Start-Sleep -Seconds 3
}

if ($MonitorOnly -or $All) {
   $results.MonitoringJob = Start-ContinuousMonitoring
}

# Force garbage collection
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

Start-Sleep -Seconds 5

Write-OptimLog "`n📋 OPTIMIZATION RESULTS:" "Info"
Write-OptimLog "VSCode processes optimized: $($results.OptimizedVSCode)" "Success"
Write-OptimLog "Go processes killed: $($results.OptimizedGo.KilledGo)" "Success"
Write-OptimLog "Gopls processes optimized: $($results.OptimizedGo.OptimizedGopls)" "Success"
Write-OptimLog "Heavy processes killed: $($results.KilledHeavy)" "Success"

$finalSummary = Get-ResourceSummary

if ($finalSummary.CPU -lt $initialSummary.CPU) {
   $cpuImprovement = [Math]::Round($initialSummary.CPU - $finalSummary.CPU, 1)
   Write-OptimLog "🎉 CPU usage improved by $cpuImprovement%" "Success"
}

if ($finalSummary.RAMUsedGB -lt $initialSummary.RAMUsedGB) {
   $ramImprovement = [Math]::Round($initialSummary.RAMUsedGB - $finalSummary.RAMUsedGB, 2)
   Write-OptimLog "🎉 RAM usage improved by $ramImprovement GB" "Success"
}

Write-OptimLog "`n✅ Resource optimization completed!" "Success"

# Usage examples
Write-Host "`n💡 USAGE EXAMPLES:" -ForegroundColor Cyan
Write-Host "  .\Optimize-Resources-Phase0.ps1 -OptimizeVSCode" -ForegroundColor Cyan
Write-Host "  .\Optimize-Resources-Phase0.ps1 -KillHeavyProcesses" -ForegroundColor Cyan
Write-Host "  .\Optimize-Resources-Phase0.ps1 -All" -ForegroundColor Cyan
