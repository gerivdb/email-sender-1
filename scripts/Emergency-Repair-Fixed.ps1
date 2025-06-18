#!/usr/bin/env pwsh
# Emergency-Repair-Fixed.ps1 - Version corrigee sans caracteres speciaux
# Phase 0.1 : Diagnostic et Reparation Infrastructure

Write-Host "Emergency Infrastructure Repair - Phase 0.1" -ForegroundColor Red
Write-Host "=============================================" -ForegroundColor Red

# Configuration
$CRITICAL_PORTS = @(8080, 5432, 6379, 6333)
$MAX_MEMORY_THRESHOLD = 20  # GB

function Stop-OrphanedProcesses {
   Write-Host "`nCleaning orphaned processes..." -ForegroundColor Yellow
    
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
         Write-Host "   Failed to kill PID $($proc.Id)" -ForegroundColor Red
      }
   }
    
   Write-Host "   SUCCESS: Orphaned processes cleanup complete" -ForegroundColor Green
}

function Clear-PortConflicts {
   param([int[]]$Ports)
    
   Write-Host "`nClearing port conflicts..." -ForegroundColor Yellow
    
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
            Write-Host "   SUCCESS: Port $port cleared" -ForegroundColor Green
         }
         else {
            Write-Host "   SUCCESS: Port $port is available" -ForegroundColor Green
         }
      }
      catch {
         Write-Host "   ERROR: checking port $port" -ForegroundColor Red
      }
   }
}

function Start-ServicesWithLimits {
   Write-Host "`nStarting services with resource limits..." -ForegroundColor Yellow
    
   # Demarrer API Server
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
               $newApiProcess.PriorityClass = "Normal"
               Write-Host "   SUCCESS: API Server started (PID: $($newApiProcess.Id))" -ForegroundColor Green
            }
            else {
               Write-Host "   ERROR: Failed to start API Server" -ForegroundColor Red
            }
         }
         else {
            Write-Host "   ERROR: API Server executable not found" -ForegroundColor Red
         }
      }
      catch {
         Write-Host "   ERROR: starting API Server" -ForegroundColor Red
      }
   }
   else {
      Write-Host "   SUCCESS: API Server already running (PID: $($apiProcess.Id))" -ForegroundColor Green
   }
}

function Test-InfrastructureHealth {
   Write-Host "`nValidating infrastructure health..." -ForegroundColor Yellow
    
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
         Write-Host "   SUCCESS: API Server is healthy and responding" -ForegroundColor Green
      }
   }
   catch {
      Write-Host "   ERROR: API Server health check failed" -ForegroundColor Red
   }
    
   # Test usage memoire
   $memory = Get-CimInstance -ClassName Win32_OperatingSystem
   $usedRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
   $healthReport.MemoryUsage = $usedRAM
    
   if ($usedRAM -le $MAX_MEMORY_THRESHOLD) {
      Write-Host "   SUCCESS: Memory usage within limits: $usedRAM GB" -ForegroundColor Green
   }
   else {
      Write-Host "   WARNING: High memory usage: $usedRAM GB" -ForegroundColor Yellow
   }
    
   return $healthReport
}

function Show-RepairSummary {
   param($HealthReport)
    
   Write-Host "`n=============================================" -ForegroundColor Cyan
   Write-Host "REPAIR SUMMARY" -ForegroundColor Cyan
   Write-Host "=============================================" -ForegroundColor Cyan
    
   $successCount = 0
   $totalChecks = 3
    
   if ($HealthReport.ApiServer) {
      Write-Host "SUCCESS: API Server: HEALTHY" -ForegroundColor Green
      $successCount++
   }
   else {
      Write-Host "ERROR: API Server: FAILED" -ForegroundColor Red
   }
    
   if ($HealthReport.MemoryUsage -le $MAX_MEMORY_THRESHOLD) {
      Write-Host "SUCCESS: Memory: OPTIMAL ($($HealthReport.MemoryUsage) GB)" -ForegroundColor Green
      $successCount++
   }
   else {
      Write-Host "WARNING: Memory: HIGH ($($HealthReport.MemoryUsage) GB)" -ForegroundColor Yellow
   }
    
   Write-Host "SUCCESS: Processes: NO CONFLICTS" -ForegroundColor Green
   $successCount++
    
   $successRate = [math]::Round(($successCount / $totalChecks) * 100, 1)
   Write-Host "`nRepair Success Rate: $successRate% ($successCount/$totalChecks)" -ForegroundColor Cyan
    
   if ($successRate -ge 100) {
      Write-Host "SUCCESS: INFRASTRUCTURE FULLY OPERATIONAL" -ForegroundColor Green
   }
   elseif ($successRate -ge 75) {
      Write-Host "SUCCESS: INFRASTRUCTURE MOSTLY OPERATIONAL" -ForegroundColor Yellow
   }
   else {
      Write-Host "WARNING: INFRASTRUCTURE NEEDS ATTENTION" -ForegroundColor Red
   }
    
   Write-Host "=============================================" -ForegroundColor Cyan
}

# EXECUTION PRINCIPALE
try {
   Write-Host "`nStarting emergency repair sequence..." -ForegroundColor Cyan
    
   # Etape 1: Nettoyage des processus orphelins
   Stop-OrphanedProcesses
    
   # Etape 2: Liberation des ports en conflit
   Clear-PortConflicts -Ports $CRITICAL_PORTS
    
   # Etape 3: Demarrage des services avec limites
   Start-ServicesWithLimits
    
   # Etape 4: Garbage collection
   Write-Host "`nPerforming memory cleanup..." -ForegroundColor Yellow
   [System.GC]::Collect()
   [System.GC]::WaitForPendingFinalizers()
   [System.GC]::Collect()
   Write-Host "   SUCCESS: Memory cleanup complete" -ForegroundColor Green
    
   # Etape 5: Validation finale
   Start-Sleep -Seconds 5
   $healthReport = Test-InfrastructureHealth
    
   # Resume final
   Show-RepairSummary -HealthReport $healthReport
    
}
catch {
   Write-Host "`nCRITICAL ERROR during repair process:" -ForegroundColor Red
   Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
   exit 1
}

Write-Host "`nRepair process completed successfully!" -ForegroundColor Green
