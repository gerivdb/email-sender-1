# 🚀 Quick Validation Script v64
Write-Host "=== VALIDATION RAPIDE PROJET V64 ===" -ForegroundColor Cyan

# 1. Test Go version
Write-Host "`n1. VERSION GO:" -ForegroundColor Yellow
go version

# 2. Test go.mod
Write-Host "`n2. MODULES GO:" -ForegroundColor Yellow
if (Test-Path "go.mod") {
   Write-Host "✅ go.mod trouvé" -ForegroundColor Green
}
else {
   Write-Host "❌ go.mod manquant" -ForegroundColor Red
}

# 3. Test structure
Write-Host "`n3. STRUCTURE PROJET:" -ForegroundColor Yellow
$dirs = @("pkg", "cmd", "internal", "tests")
foreach ($dir in $dirs) {
   if (Test-Path $dir) {
      $count = (Get-ChildItem $dir -Recurse -Filter "*.go" | Measure-Object).Count
      Write-Host "✅ $dir ($count fichiers .go)" -ForegroundColor Green
   }
   else {
      Write-Host "⚠️  $dir manquant" -ForegroundColor Yellow
   }
}

# 4. Test compilation simple
Write-Host "`n4. TEST COMPILATION:" -ForegroundColor Yellow
Write-Host "Compilation package config..." -ForegroundColor White
$result = go build ./pkg/config 2>&1
if ($LASTEXITCODE -eq 0) {
   Write-Host "✅ pkg/config: OK" -ForegroundColor Green
}
else {
   Write-Host "❌ pkg/config: ÉCHEC" -ForegroundColor Red
   Write-Host $result -ForegroundColor Red
}

Write-Host "Compilation package managers..." -ForegroundColor White
$result = go build ./pkg/managers 2>&1
if ($LASTEXITCODE -eq 0) {
   Write-Host "✅ pkg/managers: OK" -ForegroundColor Green
}
else {
   Write-Host "❌ pkg/managers: ÉCHEC" -ForegroundColor Red
   Write-Host $result -ForegroundColor Red
}

# 5. Test quelques tests unitaires
Write-Host "`n5. TESTS UNITAIRES (échantillon):" -ForegroundColor Yellow

# Test avec timeout court pour éviter les blocages
$testDirs = @("./pkg/config", "./pkg/converters", "./internal/...")
foreach ($testDir in $testDirs) {
   if (Test-Path $testDir.Replace("./", "").Replace("/...", "")) {
      Write-Host "Test $testDir..." -ForegroundColor White
      $job = Start-Job -ScriptBlock { 
         param($dir)
         Set-Location $using:PWD
         go test $dir -timeout=10s 2>&1
      } -ArgumentList $testDir
        
      if (Wait-Job $job -Timeout 15) {
         $result = Receive-Job $job
         if ($result -match "PASS" -or $result -match "ok") {
            Write-Host "✅ $testDir: PASS" -ForegroundColor Green
         }
         elseif ($result -match "no test files") {
            Write-Host "ℹ️  $testDir: Pas de tests" -ForegroundColor Cyan
         }
         else {
            Write-Host "❌ $testDir: FAIL" -ForegroundColor Red
            if ($result) { Write-Host $result -ForegroundColor Red }
         }
      }
      else {
         Write-Host "⏱️  $testDir: TIMEOUT" -ForegroundColor Yellow
         Stop-Job $job
      }
      Remove-Job $job -Force
   }
}

# 6. Couverture rapide
Write-Host "`n6. COUVERTURE TESTS:" -ForegroundColor Yellow
$job = Start-Job -ScriptBlock {
   Set-Location $using:PWD
   go test ./pkg/config -coverprofile=quick_coverage.out 2>&1
}

if (Wait-Job $job -Timeout 20) {
   $result = Receive-Job $job
   if (Test-Path "quick_coverage.out") {
      $coverage = go tool cover -func=quick_coverage.out 2>&1 | Select-String "total:"
      if ($coverage) {
         Write-Host "✅ Couverture: $coverage" -ForegroundColor Green
      }
      Remove-Item "quick_coverage.out" -ErrorAction SilentlyContinue
   }
}
else {
   Write-Host "⏱️  Test couverture: TIMEOUT" -ForegroundColor Yellow
   Stop-Job $job
}
Remove-Job $job -Force

# 7. Résumé final
Write-Host "`n=== RÉSUMÉ VALIDATION ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)" -ForegroundColor White
Write-Host "Répertoire: $PWD" -ForegroundColor White

# Vérification fichiers clés créés selon plan v64
$keyFiles = @(
   "pkg/monitoring/prometheus_metrics.go",
   "pkg/logging/elk_exporter.go", 
   "pkg/tracing/otel_tracing.go",
   "pkg/apigateway/oauth_jwt_auth.go",
   "pkg/security/crypto_utils.go"
)

Write-Host "`n📁 LIVRABLES PLAN V64:" -ForegroundColor Yellow
foreach ($file in $keyFiles) {
   if (Test-Path $file) {
      Write-Host "✅ $file" -ForegroundColor Green
   }
   else {
      Write-Host "❌ $file" -ForegroundColor Red
   }
}

Write-Host "`n🎯 VALIDATION TERMINÉE!" -ForegroundColor Green
Write-Host "Consultez les résultats ci-dessus pour l'état du projet v64." -ForegroundColor White
