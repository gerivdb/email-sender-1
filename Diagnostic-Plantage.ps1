Write-Host "DIAGNOSTIC RAPIDE - Identification des problèmes" -ForegroundColor Red
Write-Host "=================================================" -ForegroundColor Red

# 1. Vérifier l'API Server
Write-Host "`n1. API SERVER STATUS:" -ForegroundColor Yellow
$apiProcess = Get-Process | Where-Object { $_.ProcessName -eq "api-server-fixed" }
if ($apiProcess) {
   Write-Host "   ✅ Running (PID: $($apiProcess.Id))" -ForegroundColor Green
}
else {
   Write-Host "   ❌ NOT RUNNING - C'EST ÇA QUI PLANTE!" -ForegroundColor Red
   Write-Host "   💡 Solution: Redémarrer l'API Server" -ForegroundColor Yellow
}

# 2. Test des endpoints critiques
Write-Host "`n2. ENDPOINTS TEST:" -ForegroundColor Yellow
try {
   $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/infrastructure/status" -TimeoutSec 3
   Write-Host "   ✅ Extension endpoints: OK" -ForegroundColor Green
}
catch {
   Write-Host "   ❌ Extension endpoints: FAILED - C'EST ÇA QUI PLANTE!" -ForegroundColor Red
   Write-Host "   💡 Solution: Redémarrer l'API Server" -ForegroundColor Yellow
}

# 3. RAM Status
Write-Host "`n3. RAM STATUS:" -ForegroundColor Yellow
$memory = Get-CimInstance -ClassName Win32_OperatingSystem
$usedRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
Write-Host "   📊 Used RAM: $usedRAM GB" -ForegroundColor White

if ($usedRAM -gt 10) {
   Write-Host "   ⚠️ RAM élevée - Peut causer des ralentissements" -ForegroundColor Yellow
}
else {
   Write-Host "   ✅ RAM acceptable" -ForegroundColor Green
}

# 4. Processus suspects
Write-Host "`n4. PROCESSUS SUSPECTS:" -ForegroundColor Yellow
$highRamProcesses = Get-Process | Where-Object { $_.WorkingSet -gt 300MB } | Sort-Object WorkingSet -Descending | Select-Object -First 5
foreach ($proc in $highRamProcesses) {
   $ramMB = [math]::Round($proc.WorkingSet / 1MB, 1)
   Write-Host "   🔍 $($proc.ProcessName) (PID: $($proc.Id)): $ramMB MB" -ForegroundColor White
}

Write-Host "`n=================================================" -ForegroundColor Red
Write-Host "SOLUTION RAPIDE:" -ForegroundColor Green
Write-Host "1. L'API Server doit toujours tourner en arrière-plan" -ForegroundColor White
Write-Host "2. Si il s'arrête, l'extension VSCode plante (HTTP 404)" -ForegroundColor White
Write-Host "3. Commande de redémarrage: cd cmd\\simple-api-server-fixed && .\\api-server-fixed.exe" -ForegroundColor White
Write-Host "=================================================" -ForegroundColor Red
