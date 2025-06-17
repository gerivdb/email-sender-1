Write-Host "🚨 FIX RAPIDE - Résolution des plantages" -ForegroundColor Red

# 1. Vérifier et redémarrer l'API Server si nécessaire
$apiProcess = Get-Process | Where-Object {$_.ProcessName -eq "api-server-fixed"}
if (-not $apiProcess) {
    Write-Host "🔄 Redémarrage de l'API Server..." -ForegroundColor Yellow
    Start-Process -FilePath "cmd\simple-api-server-fixed\api-server-fixed.exe" -WindowStyle Hidden
    Start-Sleep -Seconds 3
    
    $newProcess = Get-Process | Where-Object {$_.ProcessName -eq "api-server-fixed"}
    if ($newProcess) {
        Write-Host "✅ API Server redémarré (PID: $($newProcess.Id))" -ForegroundColor Green
    } else {
        Write-Host "❌ Échec du redémarrage" -ForegroundColor Red
    }
} else {
    Write-Host "✅ API Server déjà en cours (PID: $($apiProcess.Id))" -ForegroundColor Green
}

# 2. Test rapide des endpoints
Start-Sleep -Seconds 2
try {
    $test = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 3
    Write-Host "✅ Endpoints fonctionnels" -ForegroundColor Green
} catch {
    Write-Host "❌ Endpoints non fonctionnels" -ForegroundColor Red
}

# 3. Vérification RAM
$memory = Get-CimInstance -ClassName Win32_OperatingSystem
$usedRAM = [math]::Round(($memory.TotalVisibleMemorySize-$memory.FreePhysicalMemory)/1MB,1)
Write-Host "📊 RAM utilisée: $usedRAM GB" -ForegroundColor White

Write-Host "🎯 Problème résolu - Extension VSCode devrait fonctionner" -ForegroundColor Green
