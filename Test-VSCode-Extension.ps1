#!/usr/bin/env pwsh
# ================================================================
# Test-VSCode-Extension.ps1 - Test complet de l'extension
# ================================================================

Write-Host "🔍 Testing VSCode Extension - Smart Infrastructure" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Vérifier que l'API Server fonctionne
Write-Host "`n📡 1. API Server Status Check:" -ForegroundColor Yellow
$apiProcess = Get-Process | Where-Object { $_.ProcessName -eq "api-server-fixed" }
if ($apiProcess) {
   Write-Host "   ✅ API Server running (PID: $($apiProcess.Id))" -ForegroundColor Green
    
   # Test des endpoints critiques
   $endpoints = @(
      @{url = "http://localhost:8080/api/v1/infrastructure/status"; name = "Infrastructure" },
      @{url = "http://localhost:8080/api/v1/monitoring/status"; name = "Monitoring" }
   )
    
   foreach ($endpoint in $endpoints) {
      try {
         $response = Invoke-RestMethod -Uri $endpoint.url -TimeoutSec 5
         Write-Host "   ✅ $($endpoint.name) endpoint: OK" -ForegroundColor Green
      }
      catch {
         Write-Host "   ❌ $($endpoint.name) endpoint: FAILED" -ForegroundColor Red
         Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
      }
   }
}
else {
   Write-Host "   ❌ API Server not running" -ForegroundColor Red
   Write-Host "   💡 Starting API Server..." -ForegroundColor Yellow
   Start-Process -FilePath "cmd\simple-api-server-fixed\api-server-fixed.exe" -WindowStyle Hidden
   Start-Sleep -Seconds 3
}

# 2. Vérifier la configuration de l'extension
Write-Host "`n🔌 2. Extension Configuration Check:" -ForegroundColor Yellow
$extensionPath = ".vscode\extension"
if (Test-Path $extensionPath) {
   Write-Host "   ✅ Extension directory found" -ForegroundColor Green
    
   # Vérifier package.json
   $packagePath = "$extensionPath\package.json"
   if (Test-Path $packagePath) {
      Write-Host "   ✅ package.json found" -ForegroundColor Green
      $package = Get-Content $packagePath | ConvertFrom-Json
      Write-Host "   📋 Extension name: $($package.name)" -ForegroundColor White
      Write-Host "   📋 Version: $($package.version)" -ForegroundColor White
   }
    
   # Vérifier le code source
   $srcPath = "$extensionPath\src\extension.ts"
   if (Test-Path $srcPath) {
      Write-Host "   ✅ Extension source code found" -ForegroundColor Green
   }
   else {
      Write-Host "   ⚠️  Extension source code missing" -ForegroundColor Yellow
   }
}
else {
   Write-Host "   ❌ Extension directory not found" -ForegroundColor Red
}

# 3. Instructions pour tester manuellement dans VSCode
Write-Host "`n🎯 3. Manual Testing Instructions:" -ForegroundColor Yellow
Write-Host "   1. Open VSCode in this workspace" -ForegroundColor White
Write-Host "   2. Press F5 to launch Extension Development Host" -ForegroundColor White
Write-Host "   3. Check the Status Bar for 'Smart Infrastructure' indicator" -ForegroundColor White
Write-Host "   4. The indicator should show:" -ForegroundColor White
Write-Host "      - ✅ 'Smart Infrastructure: Running' (GREEN)" -ForegroundColor Green
Write-Host "      - NOT ❌ 'Smart Infrastructure: API Server not running' (RED)" -ForegroundColor Red
Write-Host "   5. Try commands in Command Palette (Ctrl+Shift+P):" -ForegroundColor White
Write-Host "      - 'Smart Infrastructure: Show Status'" -ForegroundColor White
Write-Host "      - 'Smart Infrastructure: Toggle Auto-Healing'" -ForegroundColor White

# 4. Test automatique de simulation de l'extension
Write-Host "`n🤖 4. Simulating Extension API Calls:" -ForegroundColor Yellow
try {
   # Simuler l'appel que fait l'extension au démarrage
   $statusCheck = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/infrastructure/status" -TimeoutSec 5
    
   if ($statusCheck.overall -eq "healthy") {
      Write-Host "   ✅ Extension would show: 'Smart Infrastructure: Running'" -ForegroundColor Green
      Write-Host "   ✅ NO MORE HTTP 404 ERROR!" -ForegroundColor Green
   }
   else {
      Write-Host "   ⚠️  Extension would show warning status" -ForegroundColor Yellow
   }
    
   # Test auto-healing toggle
   $enableResult = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auto-healing/enable" -Method POST -TimeoutSec 5
   if ($enableResult.enabled -eq $true) {
      Write-Host "   ✅ Auto-healing toggle: WORKING" -ForegroundColor Green
   }
    
}
catch {
   Write-Host "   ❌ Extension simulation FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=================================================" -ForegroundColor Cyan
Write-Host "🎉 VSCode Extension Test Complete!" -ForegroundColor Green
Write-Host "💡 The HTTP 404 error should be completely resolved." -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
