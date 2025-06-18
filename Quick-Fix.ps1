# Quick-Fix.ps1
# Script simple pour réparer les 3 problèmes principaux

Write-Host "🔧 QUICK FIX - 3 Actions Simples" -ForegroundColor Cyan

# 1. RAM - Forcer garbage collection
Write-Host "`n1. 💾 RAM Optimization..." -ForegroundColor Yellow
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()
Write-Host "   ✅ Garbage collection forcée" -ForegroundColor Green

# 2. Arrêter API Server actuel et redémarrer le bon
Write-Host "`n2. 🔧 API Server Fix..." -ForegroundColor Yellow
Get-Process -Name "simple-api" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2

# Compiler et démarrer l'API Server simple sur port 8080
go build -o api-fixed.exe cmd/simple-api-server/main.go
if (Test-Path "api-fixed.exe") {
   Start-Process -FilePath ".\api-fixed.exe" -WindowStyle Hidden
   Start-Sleep 3
    
   # Tester si ça marche
   try {
      $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 3
      Write-Host "   ✅ API Server OK: $($response.status)" -ForegroundColor Green
   }
   catch {
      Write-Host "   ❌ API Server problem: $($_.Exception.Message)" -ForegroundColor Red
   }
}
else {
   Write-Host "   ❌ Compilation failed" -ForegroundColor Red
}

# 3. Vérifier l'extension VSCode
Write-Host "`n3. 🔍 Extension Status..." -ForegroundColor Yellow
$extensionPath = ".vscode\extension"
if (Test-Path $extensionPath) {
   Write-Host "   ✅ Extension path exists" -ForegroundColor Green
    
   # Vérifier le package.json
   $packageJson = Join-Path $extensionPath "package.json"
   if (Test-Path $packageJson) {
      Write-Host "   ✅ package.json found" -ForegroundColor Green
   }
   else {
      Write-Host "   ❌ package.json missing" -ForegroundColor Red
   }
}
else {
   Write-Host "   ❌ Extension path missing" -ForegroundColor Red
}

# Résumé
Write-Host "`n📊 Quick Status Check:" -ForegroundColor Cyan
$memory = Get-CimInstance -ClassName Win32_OperatingSystem
$ramUsedGB = [Math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 2)
Write-Host "   RAM: $ramUsedGB GB" -ForegroundColor White

$cpuLoad = wmic cpu get loadpercentage /value | Select-String "LoadPercentage" | ForEach-Object { $_.ToString().Split('=')[1] }
Write-Host "   CPU: $cpuLoad%" -ForegroundColor White

Write-Host "`n🎯 Quick Fix completed!" -ForegroundColor Green
