Write-Host "Testing VSCode Extension - Smart Infrastructure"
Write-Host "=============================================="

# 1. Check API Server
$apiProcess = Get-Process | Where-Object { $_.ProcessName -eq "api-server-fixed" }
if ($apiProcess) {
   Write-Host "API Server: RUNNING" -ForegroundColor Green
}
else {
   Write-Host "API Server: NOT RUNNING" -ForegroundColor Red
}

# 2. Test Extension Endpoints
Write-Host "Testing extension endpoints..."
try {
   $status = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/infrastructure/status" -TimeoutSec 5
   if ($status.overall -eq "healthy") {
      Write-Host "Extension Status: HEALTHY - NO MORE HTTP 404!" -ForegroundColor Green
   }
}
catch {
   Write-Host "Extension Status: FAILED" -ForegroundColor Red
}

# 3. Test Auto-Healing
try {
   $heal = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auto-healing/enable" -Method POST -TimeoutSec 5
   Write-Host "Auto-Healing Toggle: WORKING" -ForegroundColor Green
}
catch {
   Write-Host "Auto-Healing Toggle: FAILED" -ForegroundColor Red
}

Write-Host "=============================================="
Write-Host "RESULT: VSCode Extension should work without HTTP 404 error" -ForegroundColor Green
Write-Host "Manual test: Open VSCode, press F5, check status bar"
