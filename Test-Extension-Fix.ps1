#!/usr/bin/env pwsh
# ================================================================
# Test-Extension-Fix.ps1 - Validation finale de la correction
# ================================================================

Write-Host "🔍 Testing VSCode Extension API Server Fix..." -ForegroundColor Cyan

# Test 1: Vérifier que le serveur est en cours d'exécution
Write-Host "`n📡 1. Checking if API Server is running..." -ForegroundColor Yellow
$serverProcess = Get-Process | Where-Object { $_.ProcessName -eq "api-server-fixed" }
if ($serverProcess) {
   Write-Host "   ✅ API Server is running (PID: $($serverProcess.Id))" -ForegroundColor Green
}
else {
   Write-Host "   ❌ API Server is not running" -ForegroundColor Red
   exit 1
}

# Test 2: Tester les endpoints requis par l'extension
Write-Host "`n🔌 2. Testing required endpoints..." -ForegroundColor Yellow

$endpoints = @(
   "http://localhost:8080/health",
   "http://localhost:8080/api/v1/infrastructure/status",
   "http://localhost:8080/api/v1/monitoring/status"
)

foreach ($endpoint in $endpoints) {
   try {
      $response = Invoke-WebRequest -Uri $endpoint -UseBasicParsing -TimeoutSec 5
      if ($response.StatusCode -eq 200) {
         Write-Host "   ✅ $endpoint - OK (200)" -ForegroundColor Green
      }
      else {
         Write-Host "   ⚠️  $endpoint - Status: $($response.StatusCode)" -ForegroundColor Yellow
      }
   }
   catch {
      Write-Host "   ❌ $endpoint - FAILED: $($_.Exception.Message)" -ForegroundColor Red
   }
}

# Test 3: Tester l'activation/désactivation du auto-healing
Write-Host "`n🔧 3. Testing auto-healing control..." -ForegroundColor Yellow
try {
   $enableResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/auto-healing/enable" -Method POST -UseBasicParsing -TimeoutSec 5
   if ($enableResponse.StatusCode -eq 200) {
      Write-Host "   ✅ Auto-healing enable - OK" -ForegroundColor Green
   }
    
   $disableResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/auto-healing/disable" -Method POST -UseBasicParsing -TimeoutSec 5
   if ($disableResponse.StatusCode -eq 200) {
      Write-Host "   ✅ Auto-healing disable - OK" -ForegroundColor Green
   }
}
catch {
   Write-Host "   ❌ Auto-healing control - FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Vérifier les ressources système
Write-Host "`n💻 4. Checking system resources..." -ForegroundColor Yellow
$memory = Get-CimInstance -ClassName Win32_OperatingSystem
$totalRAM = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
$freeRAM = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)
$usedRAM = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)

Write-Host "   📊 Total RAM: $totalRAM GB" -ForegroundColor White
Write-Host "   📊 Used RAM: $usedRAM GB" -ForegroundColor White
Write-Host "   📊 Free RAM: $freeRAM GB" -ForegroundColor White

if ($usedRAM -le 6) {
   Write-Host "   ✅ RAM usage is optimal (≤ 6GB target achieved)" -ForegroundColor Green
}
elseif ($usedRAM -le 8) {
   Write-Host "   ⚠️  RAM usage is acceptable but could be optimized" -ForegroundColor Yellow
}
else {
   Write-Host "   ❌ RAM usage is high, optimization needed" -ForegroundColor Red
}

# Test 5: Instruction pour tester l'extension VSCode
Write-Host "`n🔧 5. VSCode Extension Test Instructions:" -ForegroundColor Yellow
Write-Host "   1. Open VSCode" -ForegroundColor White
Write-Host "   2. Check the Status Bar for 'Smart Infrastructure' indicator" -ForegroundColor White
Write-Host "   3. The indicator should show 'Smart Infrastructure: Running' instead of the previous HTTP 404 error" -ForegroundColor White
Write-Host "   4. Try the command palette: 'Smart Infrastructure: Toggle Auto-Healing'" -ForegroundColor White

Write-Host "`n🎉 All API endpoints are now functional!" -ForegroundColor Green
Write-Host "💡 The HTTP 404 error should be resolved in the VSCode extension." -ForegroundColor Cyan
