# Optimize-RAM.ps1
# Optimisation ciblée de la RAM pour réduire de 15.9GB à 6GB

param(
   [switch]$AnalyzeOnly,
   [switch]$OptimizeBrowsers,
   [switch]$OptimizeVSCode,
   [switch]$OptimizeSystem,
   [switch]$ForceCleanup
)

Write-Host "🔍 RAM OPTIMIZATION ANALYSIS" -ForegroundColor Cyan

function Get-RAMHoggers {
   $processes = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 15
   $totalRAM = 0
    
   Write-Host "`n📊 TOP RAM CONSUMERS:" -ForegroundColor Yellow
    
   foreach ($proc in $processes) {
      $ramMB = [math]::Round($proc.WorkingSet / 1MB, 1)
      $totalRAM += $ramMB
        
      $color = switch ($ramMB) {
         { $_ -gt 500 } { "Red" }
         { $_ -gt 200 } { "Yellow" }
         default { "White" }
      }
        
      Write-Host "  $($proc.Name) (PID: $($proc.Id)): ${ramMB}MB" -ForegroundColor $color
   }
    
   Write-Host "`n📈 Total RAM by top 15 processes: ${totalRAM}MB" -ForegroundColor Cyan
   return $processes
}

function Optimize-ChromeProcesses {
   Write-Host "`n🌐 OPTIMIZING CHROME PROCESSES..." -ForegroundColor Yellow
    
   $chromeProcesses = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
   $optimizedCount = 0
    
   if ($chromeProcesses.Count -gt 5) {
      Write-Host "⚠️ $($chromeProcesses.Count) Chrome processes detected" -ForegroundColor Warning
        
      # Trier par RAM pour garder les plus légers
      $chromeByRAM = $chromeProcesses | Sort-Object WorkingSet -Descending
      $heavyChrome = $chromeByRAM | Select-Object -First ($chromeProcesses.Count - 3)  # Garder 3 plus légers
        
      foreach ($proc in $heavyChrome) {
         $ramMB = [math]::Round($proc.WorkingSet / 1MB, 1)
         if ($ramMB -gt 300) {
            # Seulement les très lourds
            try {
               Write-Host "  🗑️ Stopping heavy Chrome process: ${ramMB}MB (PID: $($proc.Id))" -ForegroundColor Red
               Stop-Process -Id $proc.Id -Force
               $optimizedCount++
            }
            catch {
               Write-Host "  ⚠️ Could not stop Chrome PID $($proc.Id)" -ForegroundColor Yellow
            }
         }
      }
   }
    
   Write-Host "📊 Optimized $optimizedCount Chrome processes" -ForegroundColor Green
   return $optimizedCount
}

function Optimize-VSCodeProcesses {
   Write-Host "`n🖥️ OPTIMIZING VSCODE PROCESSES..." -ForegroundColor Yellow
    
   $vscodeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue
   $optimizedCount = 0
    
   if ($vscodeProcesses.Count -gt 1) {
      Write-Host "⚠️ $($vscodeProcesses.Count) VSCode processes detected" -ForegroundColor Warning
        
      # Identifier le processus principal (avec fenêtre)
      $mainVSCode = $null
      $heavyProcesses = @()
        
      foreach ($proc in $vscodeProcesses) {
         $ramMB = [math]::Round($proc.WorkingSet / 1MB, 1)
            
         if ($proc.MainWindowTitle -and $proc.MainWindowTitle -like "*EMAIL_SENDER*") {
            $mainVSCode = $proc
            Write-Host "  ✅ Main VSCode (our project): ${ramMB}MB (PID: $($proc.Id))" -ForegroundColor Green
         }
         elseif ($ramMB -gt 500) {
            $heavyProcesses += $proc
            Write-Host "  ⚠️ Heavy VSCode process: ${ramMB}MB (PID: $($proc.Id))" -ForegroundColor Yellow
         }
      }
        
      # Optimiser les processus lourds non-principaux
      foreach ($proc in $heavyProcesses) {
         if ($proc.Id -ne $mainVSCode.Id) {
            try {
               $proc.PriorityClass = "BelowNormal"
               Write-Host "  ⚡ Reduced priority for VSCode PID $($proc.Id)" -ForegroundColor Green
               $optimizedCount++
            }
            catch {
               Write-Host "  ⚠️ Could not optimize VSCode PID $($proc.Id)" -ForegroundColor Yellow
            }
         }
      }
   }
    
   Write-Host "📊 Optimized $optimizedCount VSCode processes" -ForegroundColor Green
   return $optimizedCount
}

function Clear-SystemMemory {
   Write-Host "`n🧹 CLEARING SYSTEM MEMORY..." -ForegroundColor Yellow
    
   $freedMB = 0
    
   # .NET Garbage Collection
   [System.GC]::Collect()
   [System.GC]::WaitForPendingFinalizers()
   [System.GC]::Collect()
   Write-Host "  ✅ .NET Garbage Collection completed" -ForegroundColor Green
    
   # Clear PowerShell history in memory
   Clear-History
   Write-Host "  ✅ PowerShell history cleared" -ForegroundColor Green
    
   # Clear DNS cache (peut libérer quelques MB)
   try {
      Clear-DnsClientCache
      Write-Host "  ✅ DNS cache cleared" -ForegroundColor Green
      $freedMB += 10
   }
   catch {
      Write-Host "  ⚠️ Could not clear DNS cache" -ForegroundColor Yellow
   }
    
   # Clear Windows event logs (anciens)
   try {
      $oldLogs = Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -gt 1000 }
      $clearedLogs = 0
      foreach ($log in $oldLogs | Select-Object -First 3) {
         # Limiter à 3 pour sécurité
         if ($log.LogName -notlike "*Security*" -and $log.LogName -notlike "*System*") {
            try {
               Clear-WinEvent -LogName $log.LogName
               $clearedLogs++
            }
            catch {
               # Ignore errors for protected logs
            }
         }
      }
      if ($clearedLogs -gt 0) {
         Write-Host "  ✅ Cleared $clearedLogs event logs" -ForegroundColor Green
         $freedMB += $clearedLogs * 5
      }
   }
   catch {
      Write-Host "  ⚠️ Could not clear event logs" -ForegroundColor Yellow
   }
    
   Write-Host "📊 Estimated memory freed: ${freedMB}MB" -ForegroundColor Green
   return $freedMB
}

function Force-MemoryOptimization {
   Write-Host "`n🔥 FORCE MEMORY OPTIMIZATION..." -ForegroundColor Red
    
   $optimizedCount = 0
    
   # Arrêter processus non-critiques qui consomment beaucoup
   $nonCriticalHeavy = Get-Process | Where-Object { 
      $_.WorkingSet -gt 200MB -and 
      $_.Name -notlike "*Code*" -and 
      $_.Name -notlike "*chrome*" -and
      $_.Name -notlike "*docker*" -and
      $_.Name -notlike "*postgres*" -and
      $_.Name -notlike "*redis*" -and
      $_.Name -notlike "*system*" -and
      $_.Name -notlike "*windows*"
   }
    
   foreach ($proc in $nonCriticalHeavy) {
      $ramMB = [math]::Round($proc.WorkingSet / 1MB, 1)
      Write-Host "  🎯 Non-critical heavy process: $($proc.Name) - ${ramMB}MB" -ForegroundColor Yellow
        
      # Demander confirmation pour les gros processus
      if ($ramMB -gt 500) {
         $response = Read-Host "    Stop $($proc.Name) (${ramMB}MB)? (y/N)"
         if ($response -eq "y" -or $response -eq "Y") {
            try {
               Stop-Process -Id $proc.Id -Force
               Write-Host "    ✅ Stopped $($proc.Name)" -ForegroundColor Green
               $optimizedCount++
            }
            catch {
               Write-Host "    ⚠️ Could not stop $($proc.Name)" -ForegroundColor Yellow
            }
         }
      }
   }
    
   Write-Host "📊 Force-optimized $optimizedCount processes" -ForegroundColor Green
   return $optimizedCount
}

# === MAIN EXECUTION ===

$ramBefore = Get-CimInstance -ClassName Win32_OperatingSystem
$usedBefore = [Math]::Round(($ramBefore.TotalVisibleMemorySize - $ramBefore.FreePhysicalMemory) / 1MB, 2)

Write-Host "🎯 INITIAL RAM USAGE: ${usedBefore}GB" -ForegroundColor Cyan
Write-Host "🎯 TARGET: 6GB (need to free $([Math]::Round($usedBefore - 6, 2))GB)" -ForegroundColor Yellow

$ramHoggers = Get-RAMHoggers

if ($AnalyzeOnly) {
   Write-Host "`n📋 ANALYSIS ONLY - No optimizations applied" -ForegroundColor Gray
   exit 0
}

$totalOptimizations = 0

if ($OptimizeBrowsers -or !$OptimizeVSCode -and !$OptimizeSystem -and !$ForceCleanup) {
   $totalOptimizations += Optimize-ChromeProcesses
}

if ($OptimizeVSCode -or !$OptimizeBrowsers -and !$OptimizeSystem -and !$ForceCleanup) {
   $totalOptimizations += Optimize-VSCodeProcesses
}

if ($OptimizeSystem -or !$OptimizeBrowsers -and !$OptimizeVSCode -and !$ForceCleanup) {
   $totalOptimizations += Clear-SystemMemory
}

if ($ForceCleanup) {
   $totalOptimizations += Force-MemoryOptimization
}

# Default: run all optimizations if no specific flag
if (!$OptimizeBrowsers -and !$OptimizeVSCode -and !$OptimizeSystem -and !$ForceCleanup) {
   Write-Host "`n🚀 RUNNING ALL OPTIMIZATIONS..." -ForegroundColor Cyan
   $totalOptimizations += Optimize-ChromeProcesses
   Start-Sleep -Seconds 2
   $totalOptimizations += Optimize-VSCodeProcesses  
   Start-Sleep -Seconds 2
   $totalOptimizations += Clear-SystemMemory
}

# Wait and measure results
Write-Host "`n⏳ Waiting 5 seconds for memory to stabilize..." -ForegroundColor Gray
Start-Sleep -Seconds 5

$ramAfter = Get-CimInstance -ClassName Win32_OperatingSystem
$usedAfter = [Math]::Round(($ramAfter.TotalVisibleMemorySize - $ramAfter.FreePhysicalMemory) / 1MB, 2)
$improvement = [Math]::Round($usedBefore - $usedAfter, 2)

Write-Host "`n📊 FINAL RESULTS:" -ForegroundColor Green
Write-Host "  RAM Before: ${usedBefore}GB" -ForegroundColor White
Write-Host "  RAM After: ${usedAfter}GB" -ForegroundColor White
Write-Host "  Improvement: ${improvement}GB" -ForegroundColor $(if ($improvement -gt 0) { "Green" }else { "Yellow" })
Write-Host "  Target: 6GB" -ForegroundColor Gray
Write-Host "  Status: $(if($usedAfter -le 6){"✅ TARGET ACHIEVED"}else{"⚠️ Still $([Math]::Round($usedAfter - 6, 2))GB over target"})" -ForegroundColor $(if ($usedAfter -le 6) { "Green" }else { "Yellow" })

Write-Host "`n🎯 Total optimizations applied: $totalOptimizations" -ForegroundColor Cyan
