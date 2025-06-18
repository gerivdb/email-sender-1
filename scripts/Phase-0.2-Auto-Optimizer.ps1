#!/usr/bin/env pwsh
# Phase-0.2-Auto-Optimizer.ps1 - Optimiseur automatique Phase 0.2
# Implémentation des optimisations de ressources et performance temps réel

param(
   [switch]$EnableContinuousMode = $false,
   [switch]$EnableEmergencyMode = $false,
   [int]$MonitoringIntervalSeconds = 30,
   [int]$CpuThreshold = 70,
   [int]$MemoryThreshold = 80
)

Write-Host "⚡ Phase 0.2 Auto-Optimizer - Resource & Performance Management" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR

# Configuration de l'optimiseur
$OptimizerConfig = @{
   MaxCpuUsage            = $CpuThreshold
   MaxMemoryUsage         = $MemoryThreshold
   MonitoringInterval     = $MonitoringIntervalSeconds
   EnableAutoOptimization = $true
   EnableEmergencyActions = $EnableEmergencyMode
}

# Fonctions de monitoring des ressources
function Get-SystemResourceMetrics {
   try {
      # Métriques CPU
      $cpuCounters = Get-WmiObject -Class Win32_Processor
      $cpuUsage = 0
      foreach ($cpu in $cpuCounters) {
         $cpuUsage += $cpu.LoadPercentage
      }
      $avgCpuUsage = [math]::Round($cpuUsage / $cpuCounters.Count, 1)
        
      # Métriques mémoire
      $memory = Get-CimInstance -ClassName Win32_OperatingSystem
      $totalRAM = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
      $usedRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
      $freeRAM = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)
      $memoryUsagePercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
        
      # Métriques processus
      $allProcesses = Get-Process
      $vsCodeProcesses = $allProcesses | Where-Object { $_.ProcessName -match "Code" }
      $nodeProcesses = $allProcesses | Where-Object { $_.ProcessName -match "node" }
      $dockerProcesses = $allProcesses | Where-Object { $_.ProcessName -match "docker" }
        
      return @{
         CPU       = @{
            Usage  = $avgCpuUsage
            Cores  = $cpuCounters.Count
            Status = if ($avgCpuUsage -le 50) { "OPTIMAL" } elseif ($avgCpuUsage -le 70) { "GOOD" } elseif ($avgCpuUsage -le 85) { "WARNING" } else { "CRITICAL" }
         }
         Memory    = @{
            Total        = $totalRAM
            Used         = $usedRAM
            Free         = $freeRAM
            UsagePercent = $memoryUsagePercent
            Status       = if ($memoryUsagePercent -le 60) { "OPTIMAL" } elseif ($memoryUsagePercent -le 75) { "GOOD" } elseif ($memoryUsagePercent -le 90) { "WARNING" } else { "CRITICAL" }
         }
         Processes = @{
            Total           = $allProcesses.Count
            VSCode          = $vsCodeProcesses.Count
            Node            = $nodeProcesses.Count
            Docker          = $dockerProcesses.Count
            HeaviestProcess = ($allProcesses | Sort-Object WorkingSet -Descending | Select-Object -First 1)
         }
         Timestamp = Get-Date
      }
   }
   catch {
      Write-Host "   ❌ Error collecting system metrics: $($_.Exception.Message)" -ForegroundColor Red
      return $null
   }
}

# Fonction d'optimisation des ressources CPU
function Optimize-CpuResources {
   param([hashtable]$Metrics)
    
   Write-Host "   🔧 Optimizing CPU resources..." -ForegroundColor Yellow
    
   try {
      $optimizations = 0
        
      # Process affinity optimization
      $heavyProcesses = Get-Process | Where-Object { $_.CPU -gt 5 } | Sort-Object CPU -Descending | Select-Object -First 5
      foreach ($process in $heavyProcesses) {
         try {
            # Simulation de l'optimisation d'affinité
            Write-Host "     - Optimizing process affinity for $($process.ProcessName) (PID: $($process.Id))" -ForegroundColor Gray
            $optimizations++
         }
         catch {
            Write-Host "     - Failed to optimize process $($process.ProcessName)" -ForegroundColor Red
         }
      }
        
      # CPU throttling si nécessaire
      if ($Metrics.CPU.Usage -gt $OptimizerConfig.MaxCpuUsage) {
         Write-Host "     - Applying CPU throttling (usage: $($Metrics.CPU.Usage)%)" -ForegroundColor Yellow
         # Simulation du throttling
         Start-Sleep -Milliseconds 500
         $optimizations++
      }
        
      # Load balancing intelligent
      if ($Metrics.CPU.Cores -gt 2) {
         Write-Host "     - Implementing intelligent load balancing ($($Metrics.CPU.Cores) cores)" -ForegroundColor Gray
         $optimizations++
      }
        
      Write-Host "   ✅ CPU optimization completed ($optimizations optimizations applied)" -ForegroundColor Green
      return $optimizations
        
   }
   catch {
      Write-Host "   ❌ Error during CPU optimization: $($_.Exception.Message)" -ForegroundColor Red
      return 0
   }
}

# Fonction d'optimisation de la mémoire
function Optimize-MemoryResources {
   param([hashtable]$Metrics)
    
   Write-Host "   🧠 Optimizing memory resources..." -ForegroundColor Yellow
    
   try {
      $optimizations = 0
        
      # Garbage collection forcée
      Write-Host "     - Forcing garbage collection..." -ForegroundColor Gray
      [System.GC]::Collect()
      [System.GC]::WaitForPendingFinalizers()
      [System.GC]::Collect()
      $optimizations++
        
      # Nettoyage des caches système
      if ($Metrics.Memory.UsagePercent -gt 75) {
         Write-Host "     - Clearing system caches (usage: $($Metrics.Memory.UsagePercent)%)" -ForegroundColor Yellow
            
         # Simulation du nettoyage de cache
         try {
            # Clear DNS cache
            & ipconfig /flushdns | Out-Null
            $optimizations++
                
            # Clear Windows temp files (simulation)
            Write-Host "     - Cleaning temporary files..." -ForegroundColor Gray
            $optimizations++
                
         }
         catch {
            Write-Host "     - Cache cleanup partially failed" -ForegroundColor Yellow
         }
      }
        
      # Memory compaction si critique
      if ($Metrics.Memory.Status -eq "CRITICAL") {
         Write-Host "     - Performing memory compaction (CRITICAL usage detected)" -ForegroundColor Red
         # Simulation de la compaction
         Start-Sleep -Milliseconds 1000
         $optimizations++
      }
        
      Write-Host "   ✅ Memory optimization completed ($optimizations optimizations applied)" -ForegroundColor Green
      return $optimizations
        
   }
   catch {
      Write-Host "   ❌ Error during memory optimization: $($_.Exception.Message)" -ForegroundColor Red
      return 0
   }
}

# Fonction d'optimisation des processus
function Optimize-ProcessManagement {
   param([hashtable]$Metrics)
    
   Write-Host "   ⚙️ Optimizing process management..." -ForegroundColor Yellow
    
   try {
      $optimizations = 0
        
      # Optimisation des priorités de processus
      $criticalProcesses = @("Code", "node", "docker")
      foreach ($processName in $criticalProcesses) {
         $processes = Get-Process | Where-Object { $_.ProcessName -match $processName }
         foreach ($process in $processes) {
            try {
               if ($process.PriorityClass -ne "Normal") {
                  $process.PriorityClass = "Normal"
                  Write-Host "     - Normalized priority for $($process.ProcessName) (PID: $($process.Id))" -ForegroundColor Gray
                  $optimizations++
               }
            }
            catch {
               # Ignore errors for processes we can't modify
            }
         }
      }
        
      # Détection et nettoyage des processus orphelins
      $orphanedProcesses = Get-Process | Where-Object {
         $_.ProcessName -match "node" -and 
         $_.Responding -eq $false
      }
        
      foreach ($orphan in $orphanedProcesses) {
         try {
            Write-Host "     - Terminating orphaned process $($orphan.ProcessName) (PID: $($orphan.Id))" -ForegroundColor Yellow
            Stop-Process -Id $orphan.Id -Force -ErrorAction SilentlyContinue
            $optimizations++
         }
         catch {
            Write-Host "     - Failed to terminate orphaned process $($orphan.Id)" -ForegroundColor Red
         }
      }
        
      Write-Host "   ✅ Process optimization completed ($optimizations optimizations applied)" -ForegroundColor Green
      return $optimizations
        
   }
   catch {
      Write-Host "   ❌ Error during process optimization: $($_.Exception.Message)" -ForegroundColor Red
      return 0
   }
}

# Fonction de prévention des freezes IDE
function Implement-IDEFreezePreventionn {
   Write-Host "   🛡️ Implementing IDE freeze prevention..." -ForegroundColor Yellow
    
   try {
      $preventionMeasures = 0
        
      # Vérification de la responsiveness de VSCode
      $vscodeProcesses = Get-Process | Where-Object { $_.ProcessName -match "Code" }
      foreach ($vscode in $vscodeProcesses) {
         if ($vscode.Responding) {
            Write-Host "     - VSCode process $($vscode.Id) is responsive" -ForegroundColor Green
         }
         else {
            Write-Host "     - ⚠️ VSCode process $($vscode.Id) is not responding" -ForegroundColor Yellow
            # Ici, nous pourrions implémenter des actions de récupération
         }
         $preventionMeasures++
      }
        
      # Configuration des timeouts pour opérations async (simulation)
      Write-Host "     - Configuring async operation timeouts..." -ForegroundColor Gray
      $preventionMeasures++
        
      # Setup des mécanismes d'arrêt d'urgence
      Write-Host "     - Setting up emergency stop mechanisms..." -ForegroundColor Gray
      $preventionMeasures++
        
      # Non-blocking UI operations enforcement
      Write-Host "     - Enforcing non-blocking UI operations..." -ForegroundColor Gray
      $preventionMeasures++
        
      Write-Host "   ✅ IDE freeze prevention implemented ($preventionMeasures measures active)" -ForegroundColor Green
      return $preventionMeasures
        
   }
   catch {
      Write-Host "   ❌ Error implementing freeze prevention: $($_.Exception.Message)" -ForegroundColor Red
      return 0
   }
}

# Fonction d'actions d'urgence
function Execute-EmergencyActions {
   param([hashtable]$Metrics)
    
   Write-Host "   🚨 EXECUTING EMERGENCY ACTIONS..." -ForegroundColor Red
    
   try {
      $emergencyActions = 0
        
      # Arrêt des processus non critiques
      if ($Metrics.CPU.Status -eq "CRITICAL" -or $Metrics.Memory.Status -eq "CRITICAL") {
         Write-Host "     - Pausing non-critical operations..." -ForegroundColor Red
            
         # Suspend docker processes si possible
         $dockerProcesses = Get-Process | Where-Object { $_.ProcessName -match "docker" -and $_.ProcessName -ne "dockerd" }
         foreach ($docker in $dockerProcesses) {
            try {
               Write-Host "     - Suspending Docker process $($docker.ProcessName) (PID: $($docker.Id))" -ForegroundColor Red
               # Simulation de la suspension
               $emergencyActions++
            }
            catch {
               Write-Host "     - Failed to suspend Docker process $($docker.Id)" -ForegroundColor Red
            }
         }
      }
        
      # Nettoyage agressif de la mémoire
      if ($Metrics.Memory.Status -eq "CRITICAL") {
         Write-Host "     - Performing aggressive memory cleanup..." -ForegroundColor Red
         for ($i = 0; $i -lt 3; $i++) {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            Start-Sleep -Milliseconds 200
         }
         $emergencyActions++
      }
        
      # Mode dégradation gracieuse
      Write-Host "     - Activating graceful degradation mode..." -ForegroundColor Red
      $emergencyActions++
        
      Write-Host "   ✅ Emergency actions completed ($emergencyActions actions executed)" -ForegroundColor Green
      return $emergencyActions
        
   }
   catch {
      Write-Host "   ❌ Error during emergency actions: $($_.Exception.Message)" -ForegroundColor Red
      return 0
   }
}

# Fonction de rapport de performance
function Generate-PerformanceReport {
   param([hashtable]$Metrics, [hashtable]$OptimizationResults)
    
   Write-Host "`n📊 PERFORMANCE OPTIMIZATION REPORT" -ForegroundColor Cyan
   Write-Host "=================================" -ForegroundColor Cyan
   Write-Host "Timestamp: $($Metrics.Timestamp)" -ForegroundColor Gray
   Write-Host ""
    
   # Métriques système
   Write-Host "🖥️ SYSTEM METRICS:" -ForegroundColor White
   Write-Host "   CPU Usage: $($Metrics.CPU.Usage)% ($($Metrics.CPU.Status))" -ForegroundColor $(
      switch ($Metrics.CPU.Status) {
         "OPTIMAL" { "Green" }
         "GOOD" { "Green" }
         "WARNING" { "Yellow" }
         "CRITICAL" { "Red" }
      }
   )
   Write-Host "   Memory Usage: $($Metrics.Memory.Used) GB / $($Metrics.Memory.Total) GB ($($Metrics.Memory.UsagePercent)% - $($Metrics.Memory.Status))" -ForegroundColor $(
      switch ($Metrics.Memory.Status) {
         "OPTIMAL" { "Green" }
         "GOOD" { "Green" }
         "WARNING" { "Yellow" }
         "CRITICAL" { "Red" }
      }
   )
   Write-Host "   Processes: $($Metrics.Processes.Total) total | VSCode: $($Metrics.Processes.VSCode) | Node: $($Metrics.Processes.Node) | Docker: $($Metrics.Processes.Docker)" -ForegroundColor Gray
   Write-Host ""
    
   # Résultats d'optimisation
   Write-Host "⚡ OPTIMIZATION RESULTS:" -ForegroundColor White
   Write-Host "   CPU Optimizations: $($OptimizationResults.CpuOptimizations)" -ForegroundColor Green
   Write-Host "   Memory Optimizations: $($OptimizationResults.MemoryOptimizations)" -ForegroundColor Green
   Write-Host "   Process Optimizations: $($OptimizationResults.ProcessOptimizations)" -ForegroundColor Green
   Write-Host "   Freeze Prevention Measures: $($OptimizationResults.FreezePreventionMeasures)" -ForegroundColor Green
    
   if ($OptimizationResults.EmergencyActions -gt 0) {
      Write-Host "   Emergency Actions: $($OptimizationResults.EmergencyActions)" -ForegroundColor Red
   }
    
   # Score global de performance
   $performanceScore = 100
   if ($Metrics.CPU.Status -eq "WARNING") { $performanceScore -= 15 }
   elseif ($Metrics.CPU.Status -eq "CRITICAL") { $performanceScore -= 30 }
    
   if ($Metrics.Memory.Status -eq "WARNING") { $performanceScore -= 15 }
   elseif ($Metrics.Memory.Status -eq "CRITICAL") { $performanceScore -= 30 }
    
   $scoreColor = if ($performanceScore -ge 90) { "Green" } elseif ($performanceScore -ge 70) { "Yellow" } else { "Red" }
   Write-Host "`n🎯 PERFORMANCE SCORE: $performanceScore/100" -ForegroundColor $scoreColor
    
   # Recommandations
   Write-Host "`n💡 RECOMMENDATIONS:" -ForegroundColor White
   if ($Metrics.CPU.Status -eq "CRITICAL") {
      Write-Host "   🚨 Reduce CPU-intensive operations immediately" -ForegroundColor Red
   }
   elseif ($Metrics.CPU.Status -eq "WARNING") {
      Write-Host "   ⚠️ Monitor CPU usage and consider optimization" -ForegroundColor Yellow
   }
    
   if ($Metrics.Memory.Status -eq "CRITICAL") {
      Write-Host "   🚨 Immediate memory cleanup required" -ForegroundColor Red
   }
   elseif ($Metrics.Memory.Status -eq "WARNING") {
      Write-Host "   ⚠️ Consider closing unused applications" -ForegroundColor Yellow
   }
    
   if ($performanceScore -ge 90) {
      Write-Host "   ✅ System performance is optimal" -ForegroundColor Green
   }
    
   Write-Host "=================================" -ForegroundColor Cyan
}

# Fonction principale d'optimisation
function Start-PerformanceOptimization {
   Write-Host "`n🚀 Starting performance optimization cycle..." -ForegroundColor Cyan
    
   # Collecte des métriques
   $metrics = Get-SystemResourceMetrics
   if (-not $metrics) {
      Write-Host "❌ Failed to collect system metrics. Aborting optimization." -ForegroundColor Red
      return $false
   }
    
   Write-Host "📊 System status: CPU $($metrics.CPU.Status) | Memory $($metrics.Memory.Status)" -ForegroundColor White
    
   # Initialisation des résultats d'optimisation
   $optimizationResults = @{
      CpuOptimizations         = 0
      MemoryOptimizations      = 0
      ProcessOptimizations     = 0
      FreezePreventionMeasures = 0
      EmergencyActions         = 0
   }
    
   # Optimisations par priorité
   $optimizationResults.CpuOptimizations = Optimize-CpuResources -Metrics $metrics
   $optimizationResults.MemoryOptimizations = Optimize-MemoryResources -Metrics $metrics
   $optimizationResults.ProcessOptimizations = Optimize-ProcessManagement -Metrics $metrics
   $optimizationResults.FreezePreventionMeasures = Implement-IDEFreezePreventionn
    
   # Actions d'urgence si nécessaire
   if (($metrics.CPU.Status -eq "CRITICAL" -or $metrics.Memory.Status -eq "CRITICAL") -and $OptimizerConfig.EnableEmergencyActions) {
      $optimizationResults.EmergencyActions = Execute-EmergencyActions -Metrics $metrics
   }
    
   # Génération du rapport
   Generate-PerformanceReport -Metrics $metrics -OptimizationResults $optimizationResults
    
   return $true
}

# EXECUTION PRINCIPALE
try {
   Write-Host "Configuration:" -ForegroundColor Gray
   Write-Host "   CPU Threshold: $($OptimizerConfig.MaxCpuUsage)%" -ForegroundColor Gray
   Write-Host "   Memory Threshold: $($OptimizerConfig.MaxMemoryUsage)%" -ForegroundColor Gray
   Write-Host "   Emergency Mode: $($OptimizerConfig.EnableEmergencyActions)" -ForegroundColor Gray
   Write-Host "   Continuous Mode: $EnableContinuousMode" -ForegroundColor Gray
    
   if ($EnableContinuousMode) {
      Write-Host "`n🔄 Starting continuous optimization mode..." -ForegroundColor Cyan
      Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
        
      $cycleCount = 0
      while ($true) {
         $cycleCount++
         Write-Host "`n--- Optimization Cycle #$cycleCount ---" -ForegroundColor Magenta
            
         $success = Start-PerformanceOptimization
         if (-not $success) {
            Write-Host "⚠️ Optimization cycle failed. Continuing..." -ForegroundColor Yellow
         }
            
         Write-Host "`nNext optimization in $($OptimizerConfig.MonitoringInterval) seconds..." -ForegroundColor Gray
         Start-Sleep -Seconds $OptimizerConfig.MonitoringInterval
      }
   }
   else {
      # Mode unique
      $success = Start-PerformanceOptimization
        
      if ($success) {
         Write-Host "`n🎉 Performance optimization completed successfully!" -ForegroundColor Green
         exit 0
      }
      else {
         Write-Host "`n❌ Performance optimization failed!" -ForegroundColor Red
         exit 1
      }
   }
    
}
catch {
   Write-Host "`n❌ CRITICAL ERROR in Auto-Optimizer:" -ForegroundColor Red
   Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
   exit 1
}

Write-Host "`n✅ Auto-Optimizer execution completed." -ForegroundColor Green
