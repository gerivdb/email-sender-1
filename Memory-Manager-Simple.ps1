Write-Host "Smart Memory Manager - 20GB Dev / 4GB System" -ForegroundColor Cyan

# État initial
$memory = Get-CimInstance -ClassName Win32_OperatingSystem
$usedRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
$freeRAM = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)

Write-Host "Initial - Used: $usedRAM GB, Free: $freeRAM GB"

# Processus VSCode
$vscodeProcesses = Get-Process | Where-Object { $_.ProcessName -eq "Code" }
$vscodeRAM = [math]::Round(($vscodeProcesses | Measure-Object WorkingSet -Sum).Sum / 1GB, 1)

Write-Host "VSCode processes: $($vscodeProcesses.Count) instances using $vscodeRAM GB"

# Si VSCode utilise plus de 15GB, optimiser
if ($vscodeRAM -gt 15) {
   Write-Host "VSCode uses too much RAM ($vscodeRAM GB) - Optimizing..." -ForegroundColor Yellow
    
   # Garder les 3 plus gros, fermer les petits
   $vscodeToKeep = $vscodeProcesses | Sort-Object WorkingSet -Descending | Select-Object -First 3
   $vscodeToClose = $vscodeProcesses | Where-Object { $_.Id -notin $vscodeToKeep.Id -and $_.WorkingSet -lt 300MB }
    
   foreach ($proc in $vscodeToClose) {
      $ramMB = [math]::Round($proc.WorkingSet / 1MB, 1)
      Write-Host "Closing PID $($proc.Id): $ramMB MB" -ForegroundColor Yellow
      try {
         Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
      }
      catch {}
   }
}

# Processus de développement
$devProcesses = Get-Process | Where-Object { $_.ProcessName -match "(Code|go|python|docker|node|gopls)" }
$devRAM = [math]::Round(($devProcesses | Measure-Object WorkingSet -Sum).Sum / 1GB, 1)

Write-Host "Total Dev processes: $devRAM GB"

# Garbage collection
Write-Host "Running garbage collection..."
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

# État final
Start-Sleep -Seconds 3
$memory = Get-CimInstance -ClassName Win32_OperatingSystem
$finalUsedRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
$finalFreeRAM = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)

Write-Host "Final - Used: $finalUsedRAM GB, Free: $finalFreeRAM GB" -ForegroundColor Green

if ($finalUsedRAM -le 20) {
   Write-Host "SUCCESS: RAM within 20GB target!" -ForegroundColor Green
}
else {
   Write-Host "WARNING: RAM still high ($finalUsedRAM GB)" -ForegroundColor Yellow
}

Write-Host "Recommendations:" -ForegroundColor Cyan
Write-Host "- VSCode max: 15GB" -ForegroundColor White
Write-Host "- Docker max: 3GB" -ForegroundColor White  
Write-Host "- Go/Python max: 2GB" -ForegroundColor White
