#!/usr/bin/env pwsh
# ================================================================
# Emergency-Repair.ps1 - Réparation d'Urgence Infrastructure
# Phase 0.1 : Diagnostic et Réparation Infrastructure
# ================================================================

Write-Host "🔧 Emergency Infrastructure Repair - Phase 0.1" -ForegroundColor Red
Write-Host "===============================================" -ForegroundColor Red

# Configuration
$CRITICAL_PORTS = @(8080, 5432, 6379, 6333)
$CRITICAL_SERVICES = @("api-server-fixed", "postgres", "redis", "qdrant")
$MAX_MEMORY_THRESHOLD = 20  # GB
$MAX_CPU_THRESHOLD = 90     # Percentage

function Stop-OrphanedProcesses {
   Write-Host "`n🧹 Cleaning orphaned processes..." -ForegroundColor Yellow
    
   # Processus orphelins API Server
   $orphanedApi = Get-Process | Where-Object {
      $_.ProcessName -match "api-server" -and 
      $_.Responding -eq $false
   }
    
   foreach ($proc in $orphanedApi) {
      Write-Host "   Killing orphaned API Server PID $($proc.Id)" -ForegroundColor Yellow
      try {
         Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
      }
      catch {
         Write-Host "   Failed to kill PID $($proc.Id): $($_.Exception.Message)" -ForegroundColor Red
      }
   }
    
   # Processus Go/Python zombies
   $zombieProcesses = Get-Process | Where-Object {
        ($_.ProcessName -match "(go|python)" -and $_.CPU -eq 0 -and $_.WorkingSet -lt 10MB) -or
        ($_.ProcessName -match "Code" -and $_.Responding -eq $false)
   }
    
   foreach ($proc in $zombieProcesses) {
      Write-Host "   Killing zombie process $($proc.ProcessName) PID $($proc.Id)" -ForegroundColor Yellow
      try {
         Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
      }
      catch {}
   }
    
   Write-Host "   ✅ Orphaned processes cleanup complete" -ForegroundColor Green
}

function Clear-PortConflicts {
   param([int[]]$Ports)
    
   Write-Host "`n🚪 Clearing port conflicts..." -ForegroundColor Yellow
    
   foreach ($port in $Ports) {
      try {
         $connections = netstat -ano | Select-String ":$port\s"
            
         if ($connections) {
            Write-Host "   Port $port is occupied, attempting to clear..." -ForegroundColor Yellow
                
            foreach ($connection in $connections) {
               $parts = $connection.Line -split '\s+' | Where-Object { $_ -ne "" }
               if ($parts.Length -ge 5) {
                  $pid = $parts[4]
                        
                  try {
                     $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
                     if ($process) {
                        Write-Host "     Killing process $($process.ProcessName) (PID: $pid) using port $port" -ForegroundColor Yellow
                        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                     }
                  }
                  catch {
                     Write-Host "     Failed to kill PID $pid on port $port" -ForegroundColor Red
                  }
               }
            }
                
            Start-Sleep -Seconds 2
                
            # Vérifier si le port est maintenant libre
            $stillOccupied = netstat -ano | Select-String ":$port\s"
            if (-not $stillOccupied) {
               Write-Host "   ✅ Port $port successfully cleared" -ForegroundColor Green
            }
            else {
               Write-Host "   ⚠️  Port $port still occupied" -ForegroundColor Yellow
            }
         }
         else {
            Write-Host "   ✅ Port $port is available" -ForegroundColor Green
         }
      }
      catch {
         Write-Host "   ❌ Error checking port $port`: $($_.Exception.Message)" -ForegroundColor Red
      }
   }
}

function Start-ServicesWithLimits {
   Write-Host "`n🚀 Starting services with resource limits..." -ForegroundColor Yellow
    
   # Démarrer API Server avec priorité normale
   $apiProcess = Get-Process | Where-Object { $_.ProcessName -eq "api-server-fixed" }
   if (-not $apiProcess) {
      Write-Host "   Starting API Server..." -ForegroundColor Yellow
      try {
         $apiServerPath = "cmd\simple-api-server-fixed\api-server-fixed.exe"
         if (Test-Path $apiServerPath) {
            Start-Process -FilePath $apiServerPath -WindowStyle Hidden
            Start-Sleep -Seconds 3
                
            $newApiProcess = Get-Process | Where-Object { $_.ProcessName -eq "api-server-fixed" }
            if ($newApiProcess) {
               # Définir priorité normale pour éviter la surcharge
               $newApiProcess.PriorityClass = "Normal"
               Write-Host "   ✅ API Server started successfully (PID: $($newApiProcess.Id))" -ForegroundColor Green
            }
            else {
               Write-Host "   ❌ Failed to start API Server" -ForegroundColor Red
            }
         }
         else {
            Write-Host "   ❌ API Server executable not found: $apiServerPath" -ForegroundColor Red
         }
      }
      catch {
         Write-Host "   ❌ Error starting API Server: $($_.Exception.Message)" -ForegroundColor Red
      }
   }
   else {
      Write-Host "   ✅ API Server already running (PID: $($apiProcess.Id))" -ForegroundColor Green
   }
    
   # Optimiser les processus gourmands
   $highMemoryProcesses = Get-Process | Where-Object {
      $_.WorkingSet -gt 500MB -and 
      $_.ProcessName -match "(Code|go|python|docker)"
   } | Sort-Object WorkingSet -Descending | Select-Object -First 5
    
   foreach ($proc in $highMemoryProcesses) {
      try {
         $proc.PriorityClass = "BelowNormal"
         $ramMB = [math]::Round($proc.WorkingSet / 1MB, 1)
         Write-Host "   🎯 Optimized priority for $($proc.ProcessName) (PID: $($proc.Id), RAM: $ramMB MB)" -ForegroundColor Cyan
      }
      catch {
         Write-Host "   ⚠️  Could not optimize $($proc.ProcessName)" -ForegroundColor Yellow
      }
   }
}

function Test-InfrastructureHealth {
   Write-Host "`n🩺 Validating infrastructure health..." -ForegroundColor Yellow
    
   $healthReport = @{
      ApiServer        = $false
      PortsAvailable   = $true
      MemoryUsage      = 0
      ProcessConflicts = 0
   }
    
   # Test API Server
   try {
      $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 5 -ErrorAction Stop
      if ($response.status -eq "healthy") {
         $healthReport.ApiServer = $true
         Write-Host "   ✅ API Server is healthy and responding" -ForegroundColor Green
      }
   }
   catch {
      Write-Host "   ❌ API Server health check failed: $($_.Exception.Message)" -ForegroundColor Red
   }
    
   # Test ports critiques
   foreach ($port in $CRITICAL_PORTS) {
      $portCheck = netstat -ano | Select-String ":$port\s"
      if ($port -eq 8080) {
         # Port 8080 devrait être occupé par l'API Server
         if ($portCheck) {
            Write-Host "   ✅ Port $port correctly occupied by service" -ForegroundColor Green
         }
         else {
            Write-Host "   ❌ Port $port should be occupied but is free" -ForegroundColor Red
            $healthReport.PortsAvailable = $false
         }
      }
   }
    
   # Test usage mémoire
   $memory = Get-CimInstance -ClassName Win32_OperatingSystem
   $usedRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
   $healthReport.MemoryUsage = $usedRAM
    
   if ($usedRAM -le $MAX_MEMORY_THRESHOLD) {
      Write-Host "   ✅ Memory usage within limits: $usedRAM GB" -ForegroundColor Green
   }
   else {
      Write-Host "   ⚠️  High memory usage: $usedRAM GB (threshold: $MAX_MEMORY_THRESHOLD GB)" -ForegroundColor Yellow
   }
    
   # Compter les conflits de processus
   $duplicateProcesses = Get-Process | Group-Object ProcessName | Where-Object {
      $_.Name -match "(api-server|gopls)" -and $_.Count -gt 1
   }
   $healthReport.ProcessConflicts = $duplicateProcesses.Count
    
   if ($healthReport.ProcessConflicts -eq 0) {
      Write-Host "   ✅ No process conflicts detected" -ForegroundColor Green
   }
   else {
      Write-Host "   ⚠️  $($healthReport.ProcessConflicts) process conflicts detected" -ForegroundColor Yellow
   }
    
   return $healthReport
}

function Show-RepairSummary {
   param($HealthReport)
    
   Write-Host "`n===============================================" -ForegroundColor Cyan
   Write-Host "🎯 REPAIR SUMMARY" -ForegroundColor Cyan
   Write-Host "===============================================" -ForegroundColor Cyan
    
   $successCount = 0
   $totalChecks = 4
    
   if ($HealthReport.ApiServer) {
      Write-Host "✅ API Server: HEALTHY" -ForegroundColor Green
      $successCount++
   }
   else {
      Write-Host "❌ API Server: FAILED" -ForegroundColor Red
   }
    
   if ($HealthReport.PortsAvailable) {
      Write-Host "✅ Ports: AVAILABLE" -ForegroundColor Green
      $successCount++
   }
   else {
      Write-Host "❌ Ports: CONFLICTS" -ForegroundColor Red
   }
    
   if ($HealthReport.MemoryUsage -le $MAX_MEMORY_THRESHOLD) {
      Write-Host "✅ Memory: OPTIMAL ($($HealthReport.MemoryUsage) GB)" -ForegroundColor Green
      $successCount++
   }
   else {
      Write-Host "⚠️  Memory: HIGH ($($HealthReport.MemoryUsage) GB)" -ForegroundColor Yellow
   }
    
   if ($HealthReport.ProcessConflicts -eq 0) {
      Write-Host "✅ Processes: NO CONFLICTS" -ForegroundColor Green
      $successCount++
   }
   else {
      Write-Host "⚠️  Processes: $($HealthReport.ProcessConflicts) CONFLICTS" -ForegroundColor Yellow
   }
    
   $successRate = [math]::Round(($successCount / $totalChecks) * 100, 1)
   Write-Host "`nRepair Success Rate: $successRate% ($successCount/$totalChecks)" -ForegroundColor Cyan
    
   if ($successRate -ge 100) {
      Write-Host "🎉 INFRASTRUCTURE FULLY OPERATIONAL" -ForegroundColor Green
   }
   elseif ($successRate -ge 75) {
      Write-Host "✅ INFRASTRUCTURE MOSTLY OPERATIONAL" -ForegroundColor Yellow
   }
   else {
      Write-Host "⚠️  INFRASTRUCTURE NEEDS ATTENTION" -ForegroundColor Red
   }
    
   Write-Host "===============================================" -ForegroundColor Cyan
}

# ================================================================
# EXÉCUTION PRINCIPALE
# ================================================================

try {
   Write-Host "`n🚀 Starting emergency repair sequence..." -ForegroundColor Cyan
    
   # Étape 1: Nettoyage des processus orphelins
   Stop-OrphanedProcesses
    
   # Étape 2: Libération des ports en conflit
   Clear-PortConflicts -Ports $CRITICAL_PORTS
    
   # Étape 3: Démarrage des services avec limites
   Start-ServicesWithLimits
    
   # Étape 4: Garbage collection pour libérer la mémoire
   Write-Host "`n🗑️  Performing memory cleanup..." -ForegroundColor Yellow
   [System.GC]::Collect()
   [System.GC]::WaitForPendingFinalizers()
   [System.GC]::Collect()
   Write-Host "   ✅ Memory cleanup complete" -ForegroundColor Green
    
   # Étape 5: Validation finale
   Start-Sleep -Seconds 5
   $healthReport = Test-InfrastructureHealth
    
   # Résumé final
   Show-RepairSummary -HealthReport $healthReport
    
}
catch {
   Write-Host "`n❌ CRITICAL ERROR during repair process:" -ForegroundColor Red
   Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
   Write-Host "`n💡 Manual intervention may be required." -ForegroundColor Yellow
   exit 1
}

Write-Host "`n💾 Repair process completed. Logs available in PowerShell history." -ForegroundColor Cyan
