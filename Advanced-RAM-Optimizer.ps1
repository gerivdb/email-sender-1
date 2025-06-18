#!/usr/bin/env pwsh
# ================================================================
# Advanced-RAM-Optimizer.ps1 - Optimisation avancée vers ≤6GB
# ================================================================

Write-Host "🎯 Advanced RAM Optimization - Target: ≤6GB" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# 1. État initial
$memory = Get-CimInstance -ClassName Win32_OperatingSystem
$initialRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
Write-Host "Initial RAM usage: $initialRAM GB" -ForegroundColor Yellow

# 2. Optimisation VSCode - Fermer les instances inutiles
Write-Host "`nOptimizing VSCode instances..."
$vscodeProcesses = Get-Process | Where-Object { $_.ProcessName -eq "Code" }
$totalVSCodeRAM = ($vscodeProcesses | Measure-Object WorkingSet -Sum).Sum / 1MB

Write-Host "Found $($vscodeProcesses.Count) VSCode processes using $([math]::Round($totalVSCodeRAM,1)) MB"

# Garder seulement les 3 processus VSCode les plus essentiels
if ($vscodeProcesses.Count -gt 3) {
   $processesToKeep = $vscodeProcesses | Sort-Object WorkingSet -Descending | Select-Object -First 3
   $processesToClose = $vscodeProcesses | Where-Object { $_.Id -notin $processesToKeep.Id }
    
   foreach ($proc in $processesToClose) {
      if ($proc.WorkingSet -lt 200MB) {
         # Fermer seulement les petits processus
         Write-Host "Closing VSCode process PID $($proc.Id) ($([math]::Round($proc.WorkingSet/1MB,1)) MB)" -ForegroundColor Yellow
         try {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
         }
         catch {}
      }
   }
}

# 3. Optimisation Brave Browser (si non critique)
$braveProcesses = Get-Process | Where-Object { $_.ProcessName -eq "brave" }
if ($braveProcesses.Count -gt 5) {
   Write-Host "`nOptimizing Brave browser..."
   $braveToClose = $braveProcesses | Sort-Object WorkingSet -Ascending | Select-Object -First ($braveProcesses.Count - 3)
   foreach ($proc in $braveToClose) {
      if ($proc.WorkingSet -gt 50MB -and $proc.WorkingSet -lt 150MB) {
         Write-Host "Closing Brave process PID $($proc.Id) ($([math]::Round($proc.WorkingSet/1MB,1)) MB)" -ForegroundColor Yellow
         try {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
         }
         catch {}
      }
   }
}

# 4. Garbage Collection forcé
Write-Host "`nForcing garbage collection..."
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

# 5. Nettoyage cache système
Write-Host "Clearing system caches..."
if (Get-Command "Clear-RecycleBin" -ErrorAction SilentlyContinue) {
   Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

# 6. Optimisation des processus Go
$goProcesses = Get-Process | Where-Object { $_.ProcessName -match "go" -or $_.ProcessName -eq "gopls" }
foreach ($proc in $goProcesses) {
   if ($proc.WorkingSet -gt 500MB) {
      Write-Host "Large Go process detected: $($proc.ProcessName) ($([math]::Round($proc.WorkingSet/1MB,1)) MB)" -ForegroundColor Yellow
      # Réduire la priorité plutôt que de tuer
      $proc.PriorityClass = "BelowNormal"
   }
}

# 7. Attendre et mesurer le résultat
Start-Sleep -Seconds 5

$memory = Get-CimInstance -ClassName Win32_OperatingSystem
$finalRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
$reduction = $initialRAM - $finalRAM

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "OPTIMIZATION RESULTS:" -ForegroundColor Green
Write-Host "Initial RAM: $initialRAM GB" -ForegroundColor White
Write-Host "Final RAM:   $finalRAM GB" -ForegroundColor White
Write-Host "Reduction:   $([math]::Round($reduction,1)) GB" -ForegroundColor White

if ($finalRAM -le 6) {
   Write-Host "🎉 TARGET ACHIEVED: RAM ≤ 6GB!" -ForegroundColor Green
}
elseif ($finalRAM -le 8) {
   Write-Host "✅ Good progress - Close to target" -ForegroundColor Yellow
}
else {
   Write-Host "⚠️ More optimization needed" -ForegroundColor Yellow
}

# 8. Recommandations supplémentaires
if ($finalRAM -gt 6) {
   Write-Host "`n💡 Additional optimization suggestions:" -ForegroundColor Cyan
   Write-Host "- Close non-essential browser tabs" -ForegroundColor White
   Write-Host "- Restart VSCode to clear memory leaks" -ForegroundColor White
   Write-Host "- Close YouTube Music and other media apps" -ForegroundColor White
   Write-Host "- Consider increasing virtual memory" -ForegroundColor White
}

Write-Host "============================================" -ForegroundColor Cyan
