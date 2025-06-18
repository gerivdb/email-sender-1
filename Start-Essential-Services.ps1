# Start-Essential-Services.ps1
# Script pour démarrer les services essentiels et résoudre l'erreur API Server

Write-Host "🚀 Starting Essential Services for EMAIL_SENDER_1" -ForegroundColor Green

# 1. Vérifier et réparer les dépendances Go
Write-Host "`n📦 Step 1: Checking Go dependencies..." -ForegroundColor Cyan
try {
   go mod tidy
   Write-Host "✅ Go dependencies updated" -ForegroundColor Green
}
catch {
   Write-Host "❌ Failed to update Go dependencies: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Arrêter les processus Go existants (tests en cours)
Write-Host "`n🛑 Step 2: Stopping existing Go test processes..." -ForegroundColor Cyan
$goProcesses = Get-Process -Name "go" -ErrorAction SilentlyContinue
foreach ($proc in $goProcesses) {
   try {
      Write-Host "Stopping Go process (PID: $($proc.Id))" -ForegroundColor Yellow
      Stop-Process -Id $proc.Id -Force
   }
   catch {
      Write-Host "Could not stop process $($proc.Id)" -ForegroundColor Yellow
   }
}

# 3. Démarrer l'API Server
Write-Host "`n🚀 Step 3: Starting API Server..." -ForegroundColor Cyan
$apiPath = "cmd\infrastructure-api-server\main.go"

if (Test-Path $apiPath) {
   Write-Host "Found API Server at: $apiPath" -ForegroundColor Green
    
   # Démarrer en arrière-plan
   try {
      $process = Start-Process -FilePath "go" -ArgumentList "run", $apiPath -PassThru -NoNewWindow
      Write-Host "✅ API Server started (PID: $($process.Id))" -ForegroundColor Green
        
      # Attendre 5 secondes puis tester
      Start-Sleep -Seconds 5
        
      # Test de connexion
      try {
         $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 5
         Write-Host "✅ API Server is responding on port 8080" -ForegroundColor Green
         Write-Host "Health response: $response" -ForegroundColor Gray
      }
      catch {
         Write-Host "⚠️ API Server started but not responding on port 8080" -ForegroundColor Yellow
         Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
            
         # Essayer d'autres ports
         $testPorts = @(8081, 8082, 8083)
         foreach ($port in $testPorts) {
            try {
               $response = Invoke-RestMethod -Uri "http://localhost:$port/health" -TimeoutSec 3
               Write-Host "✅ API Server responding on port $port" -ForegroundColor Green
               break
            }
            catch {
               Write-Host "❌ Port $port not responding" -ForegroundColor Red
            }
         }
      }
   }
   catch {
      Write-Host "❌ Failed to start API Server: $($_.Exception.Message)" -ForegroundColor Red
   }
}
else {
   Write-Host "❌ API Server not found at: $apiPath" -ForegroundColor Red
}

# 4. Vérifier les autres services
Write-Host "`n🔍 Step 4: Checking other services..." -ForegroundColor Cyan

$services = @(
   @{ Name = "Qdrant"; Port = 6333; Url = "http://localhost:6333/health" },
   @{ Name = "PostgreSQL"; Port = 5432; Url = $null },
   @{ Name = "Redis"; Port = 6379; Url = $null }
)

foreach ($service in $services) {
   try {
      $connection = Test-NetConnection -ComputerName "localhost" -Port $service.Port -WarningAction SilentlyContinue
      if ($connection.TcpTestSucceeded) {
         Write-Host "✅ $($service.Name) (port $($service.Port)) is running" -ForegroundColor Green
            
         if ($service.Url) {
            try {
               $response = Invoke-RestMethod -Uri $service.Url -TimeoutSec 3
               Write-Host "  └─ Health check: OK" -ForegroundColor Green
            }
            catch {
               Write-Host "  └─ Health check: Failed" -ForegroundColor Yellow
            }
         }
      }
      else {
         Write-Host "❌ $($service.Name) (port $($service.Port)) is not running" -ForegroundColor Red
      }
   }
   catch {
      Write-Host "❌ Error checking $($service.Name): $($_.Exception.Message)" -ForegroundColor Red
   }
}

# 5. Résumé final
Write-Host "`n📋 Final Status:" -ForegroundColor Cyan
Write-Host "Run this script to check API Server status:" -ForegroundColor Gray
Write-Host "  .\Emergency-Diagnostic-v2.ps1 -RunDiagnostic" -ForegroundColor Gray

Write-Host "`n🎯 Next steps if API Server still fails:" -ForegroundColor Cyan
Write-Host "  1. Check logs in api-error.log" -ForegroundColor Gray
Write-Host "  2. Verify Go version: go version" -ForegroundColor Gray
Write-Host "  3. Check if port 8080 is free: netstat -an | findstr 8080" -ForegroundColor Gray
Write-Host "  4. Try manual start: cd cmd\infrastructure-api-server && go run main.go" -ForegroundColor Gray
