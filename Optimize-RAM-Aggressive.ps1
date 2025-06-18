# Optimize-RAM-Aggressive.ps1
# Optimisation agressive de la RAM pour atteindre <= 6GB

Write-Host "=== OPTIMISATION RAM AGRESSIVE ===" -ForegroundColor Yellow

# 1. Fermer les extensions VS Code non essentielles
Write-Host "1. Fermeture des processus VS Code en double..." -ForegroundColor Cyan
$codeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue
$mainCodeProcess = $codeProcesses | Sort-Object StartTime | Select-Object -First 1
$duplicateProcesses = $codeProcesses | Where-Object { $_.Id -ne $mainCodeProcess.Id -and $_.WorkingSet64 -lt 200MB }

foreach ($proc in $duplicateProcesses) {
   try {
      Write-Host "  Fermeture processus Code.exe (PID: $($proc.Id)) - RAM: $([math]::Round($proc.WorkingSet64/1MB,2))MB"
      $proc.CloseMainWindow()
      Start-Sleep -Seconds 2
      if (!$proc.HasExited) {
         $proc.Kill()
      }
   }
   catch {
      Write-Host "    Erreur: $($_.Exception.Message)" -ForegroundColor Red
   }
}

# 2. Optimiser Brave Browser
Write-Host "2. Optimisation Brave Browser..." -ForegroundColor Cyan
$braveProcesses = Get-Process -Name "brave" -ErrorAction SilentlyContinue | Sort-Object WorkingSet64 -Descending
$braveToKeep = 3
if ($braveProcesses.Count -gt $braveToKeep) {
   $braveToClose = $braveProcesses | Select-Object -Skip $braveToKeep
   foreach ($proc in $braveToClose) {
      try {
         if ($proc.WorkingSet64 -lt 100MB) {
            Write-Host "  Fermeture processus Brave (PID: $($proc.Id)) - RAM: $([math]::Round($proc.WorkingSet64/1MB,2))MB"
            $proc.CloseMainWindow()
            Start-Sleep -Seconds 1
         }
      }
      catch {
         Write-Host "    Erreur: $($_.Exception.Message)" -ForegroundColor Red
      }
   }
}

# 3. Nettoyer YouTube Music si pas nécessaire
Write-Host "3. Optimisation YouTube Music..." -ForegroundColor Cyan
$ytMusic = Get-Process -Name "YouTube Music" -ErrorAction SilentlyContinue
if ($ytMusic -and $ytMusic.WorkingSet64 -gt 200MB) {
   try {
      Write-Host "  Suspension YouTube Music pour économiser RAM..."
      $ytMusic.CloseMainWindow()
   }
   catch {
      Write-Host "    Erreur: $($_.Exception.Message)" -ForegroundColor Red
   }
}

# 4. Forcer le garbage collection
Write-Host "4. Garbage collection forcé..." -ForegroundColor Cyan
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

# 5. Vider les caches Windows
Write-Host "5. Vidage des caches système..." -ForegroundColor Cyan
if (Get-Command "sfc" -ErrorAction SilentlyContinue) {
   Start-Process -FilePath "cleanmgr" -ArgumentList "/sagerun:1" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}

# 6. Compacter la mémoire
Write-Host "6. Compactage mémoire..." -ForegroundColor Cyan
try {
   Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class MemoryManagement {
        [DllImport("psapi.dll")]
        public static extern int EmptyWorkingSet(IntPtr hwProc);
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetCurrentProcess();
    }
"@
   $currentProcess = [MemoryManagement]::GetCurrentProcess()
   [MemoryManagement]::EmptyWorkingSet($currentProcess) | Out-Null
}
catch {
   Write-Host "    Compactage mémoire non disponible" -ForegroundColor Yellow
}

# 7. Analyse RAM après optimisation
Write-Host "7. Analyse RAM après optimisation..." -ForegroundColor Cyan
$totalRAM = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
$availableRAM = (Get-Counter "\Memory\Available Bytes").CounterSamples.CookedValue / 1GB
$usedRAM = $totalRAM - $availableRAM

Write-Host "=== RÉSULTATS OPTIMISATION ===" -ForegroundColor Green
Write-Host "RAM totale: $([math]::Round($totalRAM, 2)) GB"
Write-Host "RAM utilisée: $([math]::Round($usedRAM, 2)) GB"
Write-Host "RAM disponible: $([math]::Round($availableRAM, 2)) GB"

if ($usedRAM -le 6) {
   Write-Host "✅ OBJECTIF ATTEINT: RAM <= 6GB" -ForegroundColor Green
}
else {
   Write-Host "⚠️  OBJECTIF NON ATTEINT: RAM > 6GB (Réduction de $([math]::Round($usedRAM - 6, 2))GB nécessaire)" -ForegroundColor Yellow
}

# 8. Top 10 des processus les plus consommateurs
Write-Host "`n=== TOP 10 PROCESSUS RAM ===" -ForegroundColor Yellow
Get-Process | Where-Object { $_.WorkingSet64 -gt 50MB } | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 ProcessName, @{Name = "RAM(MB)"; Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) } } | Format-Table -AutoSize
