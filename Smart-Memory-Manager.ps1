#!/usr/bin/env pwsh
# ================================================================
# Smart-Memory-Manager.ps1 - Gestion intelligente 20GB Dev / 4GB Système
# ================================================================

Write-Host "🧠 Smart Memory Manager - 20GB Dev / 4GB System" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

# Configuration cible
$TARGET_DEV_RAM_GB = 20
$TARGET_SYSTEM_RAM_GB = 4
$TOTAL_RAM_GB = 24

# 1. État initial
$memory = Get-CimInstance -ClassName Win32_OperatingSystem
$totalRAM = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
$usedRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
$freeRAM = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)

Write-Host "`n📊 ÉTAT INITIAL:" -ForegroundColor Yellow
Write-Host "   Total RAM: $totalRAM GB" -ForegroundColor White
Write-Host "   Used RAM:  $usedRAM GB" -ForegroundColor White
Write-Host "   Free RAM:  $freeRAM GB" -ForegroundColor White

# 2. Analyse par catégorie
$allProcesses = Get-Process | Where-Object { $_.WorkingSet -gt 10MB }

$devProcesses = $allProcesses | Where-Object { $_.ProcessName -match "(Code|vscode|go|python|docker|node|gopls|api-server)" }
$systemProcesses = $allProcesses | Where-Object { $_.ProcessName -notmatch "(Code|vscode|go|python|docker|node|gopls|api-server)" }

$devRAM = [math]::Round(($devProcesses | Measure-Object WorkingSet -Sum).Sum / 1GB, 1)
$systemRAM = [math]::Round(($systemProcesses | Measure-Object WorkingSet -Sum).Sum / 1GB, 1)

Write-Host "`n📋 RÉPARTITION ACTUELLE:" -ForegroundColor Yellow
Write-Host "   Dev processes (VSCode+Docker+Python+Go): $devRAM GB" -ForegroundColor White
Write-Host "   System processes: $systemRAM GB" -ForegroundColor White

# 3. Analyse VSCode spécifique
$vscodeProcesses = $allProcesses | Where-Object { $_.ProcessName -eq "Code" }
$vscodeRAM = [math]::Round(($vscodeProcesses | Measure-Object WorkingSet -Sum).Sum / 1GB, 1)

Write-Host "`n🔍 DÉTAIL VSCODE:" -ForegroundColor Yellow
Write-Host "   Instances VSCode: $($vscodeProcesses.Count)" -ForegroundColor White
Write-Host "   RAM VSCode total: $vscodeRAM GB" -ForegroundColor White

# Afficher les plus gros consommateurs VSCode
$bigVSCode = $vscodeProcesses | Sort-Object WorkingSet -Descending | Select-Object -First 5
foreach ($proc in $bigVSCode) {
   $ramMB = [math]::Round($proc.WorkingSet / 1MB, 1)
   Write-Host "     PID $($proc.Id): $ramMB MB" -ForegroundColor Gray
}

# 4. Optimisation intelligente
Write-Host "`n🎯 OPTIMISATION INTELLIGENTE:" -ForegroundColor Yellow

# Si VSCode utilise plus de 15GB, optimiser
if ($vscodeRAM -gt 15) {
   Write-Host "   ⚠️  VSCode utilise $vscodeRAM GB (>15GB limite)" -ForegroundColor Yellow
   Write-Host "   🔄 Optimisation des instances VSCode..." -ForegroundColor Yellow
    
   # Garder les 3 plus gros processus VSCode, fermer les petits
   $vscodeToKeep = $vscodeProcesses | Sort-Object WorkingSet -Descending | Select-Object -First 3
   $vscodeToClose = $vscodeProcesses | Where-Object { $_.Id -notin $vscodeToKeep.Id -and $_.WorkingSet -lt 300MB }
    
   foreach ($proc in $vscodeToClose) {
      $ramMB = [math]::Round($proc.WorkingSet / 1MB, 1)
      Write-Host "     Fermeture PID $($proc.Id): $ramMB MB" -ForegroundColor Yellow
      try {
         Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
      }
      catch {}
   }
}

# 5. Optimisation système si nécessaire
if ($systemRAM -gt 6) {
   Write-Host "   ⚠️  Processus système utilisent $systemRAM GB (>6GB)" -ForegroundColor Yellow
   Write-Host "   🔄 Optimisation processus système..." -ForegroundColor Yellow
    
   # Identifier les gros consommateurs non essentiels
   $bigSystemProcesses = $systemProcesses | Where-Object {
      $_.WorkingSet -gt 200MB -and 
      $_.ProcessName -notmatch "(dwm|winlogon|csrss|lsass|explorer|svchost|antimalware|aswEngSrv)" -and
      $_.ProcessName -match "(chrome|brave|firefox|spotify|discord|teams)"
   } | Sort-Object WorkingSet -Descending | Select-Object -First 3
    
   foreach ($proc in $bigSystemProcesses) {
      $ramMB = [math]::Round($proc.WorkingSet / 1MB, 1)
      Write-Host "     Gros consommateur détecté: $($proc.ProcessName) PID $($proc.Id): $ramMB MB" -ForegroundColor Gray
      Write-Host "     💡 Considérez fermer manuellement si non nécessaire" -ForegroundColor Cyan
   }
}

# 6. Garbage Collection forcé
Write-Host "`n🗑️  NETTOYAGE MÉMOIRE:" -ForegroundColor Yellow
Write-Host "   Garbage collection forcé..." -ForegroundColor White
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

# 7. État final
Start-Sleep -Seconds 3
$memory = Get-CimInstance -ClassName Win32_OperatingSystem
$finalUsedRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
$finalFreeRAM = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)

Write-Host "`n📊 ÉTAT FINAL:" -ForegroundColor Green
Write-Host "   Used RAM: $finalUsedRAM GB" -ForegroundColor White
Write-Host "   Free RAM: $finalFreeRAM GB" -ForegroundColor White

# Vérifier si on respecte les limites
if ($finalUsedRAM -le 20) {
   Write-Host "   ✅ Objectif atteint: RAM ≤ 20GB pour dev" -ForegroundColor Green
}
else {
   Write-Host "   ⚠️  RAM encore élevée: $finalUsedRAM GB" -ForegroundColor Yellow
}

Write-Host "`n💡 RECOMMANDATIONS:" -ForegroundColor Cyan
Write-Host "   - VSCode dev: Max 15GB recommandé" -ForegroundColor White
Write-Host "   - Docker containers: Max 3GB recommandé" -ForegroundColor White  
Write-Host "   - Go/Python: Max 2GB recommandé" -ForegroundColor White
Write-Host "   - Système: Max 4GB pour stabilité" -ForegroundColor White

Write-Host "`n===============================================" -ForegroundColor Cyan
