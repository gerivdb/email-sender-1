Write-Host "EMERGENCY MEMORY MANAGEMENT - 20GB Dev Allocation" -ForegroundColor Red
Write-Host "=================================================" -ForegroundColor Red

# 1. État initial critique
$memory = Get-CimInstance -ClassName Win32_OperatingSystem
$usedRAM = [math]::Round(($memory.TotalVisibleMemorySize-$memory.FreePhysicalMemory)/1MB,1)

Write-Host "Current RAM usage: $usedRAM GB / 24 GB total" -ForegroundColor Yellow

if ($usedRAM -gt 20) {
    Write-Host "CRITICAL: Memory usage exceeds 20GB allocation!" -ForegroundColor Red
    
    # Action d'urgence 1: Optimiser VSCode
    Write-Host "Emergency VSCode optimization..." -ForegroundColor Yellow
    $vscodeProcesses = Get-Process | Where-Object {$_.ProcessName -eq "Code"}
    
    # Fermer les instances VSCode les plus petites
    $smallVSCode = $vscodeProcesses | Where-Object {$_.WorkingSet -lt 100MB} | Select-Object -First 5
    foreach ($proc in $smallVSCode) {
        Write-Host "Closing small VSCode instance PID $($proc.Id)" -ForegroundColor Yellow
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
    
    # Action d'urgence 2: Limiter les navigateurs
    $browsers = Get-Process | Where-Object {$_.ProcessName -match "(chrome|brave|firefox)" -and $_.WorkingSet -gt 200MB}
    $bigBrowsers = $browsers | Sort-Object WorkingSet -Descending | Select-Object -Skip 2  # Garder 2 gros processus
    foreach ($proc in $bigBrowsers | Select-Object -First 3) {
        Write-Host "Closing browser process $($proc.ProcessName) PID $($proc.Id)" -ForegroundColor Yellow
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}

# 2. Garbage collection massif
Write-Host "Performing intensive garbage collection..." -ForegroundColor Yellow
for ($i = 1; $i -le 3; $i++) {
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Start-Sleep -Seconds 1
}

# 3. Vérification API Server
$apiProcess = Get-Process | Where-Object {$_.ProcessName -eq "api-server-fixed"}
if (-not $apiProcess) {
    Write-Host "Restarting API Server..." -ForegroundColor Yellow
    Start-Process "cmd\simple-api-server-fixed\api-server-fixed.exe" -WindowStyle Hidden
}

# 4. État final
Start-Sleep -Seconds 5
$memory = Get-CimInstance -ClassName Win32_OperatingSystem
$finalRAM = [math]::Round(($memory.TotalVisibleMemorySize-$memory.FreePhysicalMemory)/1MB,1)
$freeRAM = [math]::Round($memory.FreePhysicalMemory/1MB,1)

Write-Host "=================================================" -ForegroundColor Green
Write-Host "FINAL STATUS:" -ForegroundColor Green
Write-Host "Used RAM: $finalRAM GB" -ForegroundColor White
Write-Host "Free RAM: $freeRAM GB" -ForegroundColor White

# Analyse par processus de dev
$devProcesses = Get-Process | Where-Object {$_.ProcessName -match "(Code|go|python|docker|node)"}
$devRAM = [math]::Round(($devProcesses | Measure-Object WorkingSet -Sum).Sum / 1GB, 1)
Write-Host "Dev processes total: $devRAM GB" -ForegroundColor White

if ($finalRAM -le 20) {
    Write-Host "SUCCESS: Within 20GB dev allocation!" -ForegroundColor Green
} else {
    Write-Host "WARNING: Still exceeding 20GB target" -ForegroundColor Yellow
}

Write-Host "=================================================" -ForegroundColor Green
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Monitor with: .\Memory-Crash-Monitor.ps1" -ForegroundColor White
Write-Host "2. Use optimized Docker: docker-compose.memory-optimized.yml" -ForegroundColor White
Write-Host "3. Apply VSCode settings: vscode-memory-optimized-settings.json" -ForegroundColor White
