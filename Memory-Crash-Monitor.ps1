Write-Host "Memory Crash Prevention Monitor" -ForegroundColor Red
Write-Host "Monitoring every 30 seconds - Press Ctrl+C to stop"

$crashThreshold = 20  # GB
$warningThreshold = 18  # GB

while ($true) {
   $memory = Get-CimInstance -ClassName Win32_OperatingSystem
   $usedRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
   $freeRAM = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)
    
   $timestamp = Get-Date -Format "HH:mm:ss"
    
   if ($usedRAM -gt $crashThreshold) {
      Write-Host "[$timestamp] CRITICAL: $usedRAM GB - CRASH RISK!" -ForegroundColor Red
        
      # Action d'urgence - fermer les petits processus VSCode
      $vscodeProcesses = Get-Process | Where-Object { $_.ProcessName -eq "Code" -and $_.WorkingSet -lt 200MB }
      foreach ($proc in $vscodeProcesses | Select-Object -First 3) {
         Write-Host "Emergency close VSCode PID $($proc.Id)" -ForegroundColor Red
         Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
      }
        
      # Garbage collection d'urgence
      [System.GC]::Collect()
        
   }
   elseif ($usedRAM -gt $warningThreshold) {
      Write-Host "[$timestamp] WARNING: $usedRAM GB (Free: $freeRAM GB)" -ForegroundColor Yellow
   }
   else {
      Write-Host "[$timestamp] OK: $usedRAM GB (Free: $freeRAM GB)" -ForegroundColor Green
   }
    
   # Vérifier VSCode spécifiquement
   $vscodeProcesses = Get-Process | Where-Object { $_.ProcessName -eq "Code" }
   $vscodeRAM = [math]::Round(($vscodeProcesses | Measure-Object WorkingSet -Sum).Sum / 1GB, 1)
    
   if ($vscodeRAM -gt 15) {
      Write-Host "[$timestamp] VSCode high memory: $vscodeRAM GB ($($vscodeProcesses.Count) instances)" -ForegroundColor Yellow
   }
    
   Start-Sleep -Seconds 30
}
