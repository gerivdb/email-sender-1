# Test-APIServer.ps1
# Script pour tester et diagnostiquer l'API Server

Write-Host "🔍 Testing API Server..." -ForegroundColor Cyan

# 1. Vérifier que l'exécutable existe
if (-not (Test-Path ".\api-server.exe")) {
   Write-Host "❌ api-server.exe not found" -ForegroundColor Red
   exit 1
}

Write-Host "✅ API Server executable found" -ForegroundColor Green

# 2. Tenter de démarrer l'API Server avec timeout
Write-Host "🚀 Starting API Server..." -ForegroundColor Yellow

$apiProcess = Start-Process -FilePath ".\api-server.exe" -PassThru -RedirectStandardOutput "api-output.log" -RedirectStandardError "api-error-new.log"

# 3. Attendre 5 secondes pour que le serveur démarre
Start-Sleep -Seconds 5

# 4. Vérifier si le processus est toujours en vie
if ($apiProcess.HasExited) {
   Write-Host "❌ API Server crashed immediately" -ForegroundColor Red
   Write-Host "Exit code: $($apiProcess.ExitCode)" -ForegroundColor Red
    
   # Afficher les erreurs
   if (Test-Path "api-error-new.log") {
      Write-Host "`n🚨 Error log:" -ForegroundColor Red
      Get-Content "api-error-new.log"
   }
    
   if (Test-Path "api-output.log") {
      Write-Host "`n📋 Output log:" -ForegroundColor Yellow
      Get-Content "api-output.log"
   }
    
   exit 1
}

Write-Host "✅ API Server process is running (PID: $($apiProcess.Id))" -ForegroundColor Green

# 5. Tester les ports
$ports = @(8080, 8081, 8082)
$foundPort = $null

foreach ($port in $ports) {
   try {
      $connection = Test-NetConnection -ComputerName "localhost" -Port $port -WarningAction SilentlyContinue
      if ($connection.TcpTestSucceeded) {
         Write-Host "✅ API Server listening on port $port" -ForegroundColor Green
         $foundPort = $port
         break
      }
   }
   catch {
      # Continue to next port
   }
}

if (-not $foundPort) {
   Write-Host "⚠️ No API Server found on standard ports" -ForegroundColor Yellow
    
   # Vérifier sur quels ports le processus écoute
   $netstat = netstat -ano | findstr $apiProcess.Id
   if ($netstat) {
      Write-Host "📋 Ports used by API Server process:" -ForegroundColor Cyan
      $netstat
   }
}
else {
   # 6. Tester les endpoints
   $endpoints = @(
      "http://localhost:$foundPort/health",
      "http://localhost:$foundPort/status",
      "http://localhost:$foundPort/"
   )
    
   foreach ($endpoint in $endpoints) {
      try {
         $response = Invoke-RestMethod -Uri $endpoint -TimeoutSec 3 -ErrorAction Stop
         Write-Host "✅ $endpoint : OK" -ForegroundColor Green
         Write-Host "   Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
      }
      catch {
         Write-Host "❌ $endpoint : $($_.Exception.Message)" -ForegroundColor Red
      }
   }
}

# 7. Laisser tourner 10 secondes puis arrêter
Write-Host "`n⏱️ Monitoring for 10 seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

if (-not $apiProcess.HasExited) {
   Write-Host "🛑 Stopping API Server..." -ForegroundColor Yellow
   Stop-Process -Id $apiProcess.Id -Force
   Write-Host "✅ API Server stopped" -ForegroundColor Green
}
else {
   Write-Host "❌ API Server crashed during monitoring" -ForegroundColor Red
   Write-Host "Exit code: $($apiProcess.ExitCode)" -ForegroundColor Red
}

Write-Host "`n🏁 API Server test completed" -ForegroundColor Cyan
