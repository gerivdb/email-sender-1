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
      Write-Host "✅ ${dir} ($count fichiers .go)" -ForegroundColor Green
   }
   else {
      Write-Host "⚠️ ${dir} manquant" -ForegroundColor Yellow
   }
}

# 4. Test compilation simple
Write-Host "`n4. TEST COMPILATION:" -ForegroundColor Yellow

Write-Host "Compilation package config..." -ForegroundColor White
try {
   $null = go build ./pkg/config 2>&1
   if ($LASTEXITCODE -eq 0) {
      Write-Host "✅ pkg/config OK" -ForegroundColor Green
   }
   else {
      Write-Host "❌ pkg/config ÉCHEC" -ForegroundColor Red
   }
}
catch {
   Write-Host "❌ pkg/config ERREUR" -ForegroundColor Red
}

Write-Host "Compilation package managers..." -ForegroundColor White
try {
   $null = go build ./pkg/managers 2>&1
   if ($LASTEXITCODE -eq 0) {
      Write-Host "✅ pkg/managers OK" -ForegroundColor Green
   }
   else {
      Write-Host "❌ pkg/managers ÉCHEC" -ForegroundColor Red
   }
}
catch {
   Write-Host "❌ pkg/managers ERREUR" -ForegroundColor Red
}

# 5. Test simple sans timeout
Write-Host "`n5. TESTS RAPIDES:" -ForegroundColor Yellow

# Test un package simple
Write-Host "Test pkg/config..." -ForegroundColor White
try {
   $testResult = go test ./pkg/config -timeout=5s 2>&1 | Out-String
   if ($testResult -like "*PASS*" -or $testResult -like "*ok*") {
      Write-Host "✅ pkg/config tests OK" -ForegroundColor Green
   }
   elseif ($testResult -like "*no test files*") {
      Write-Host "ℹ️ pkg/config pas de tests" -ForegroundColor Cyan
   }
   else {
      Write-Host "❌ pkg/config tests ÉCHEC" -ForegroundColor Red
   }
}
catch {
   Write-Host "⚠️ pkg/config test ERREUR" -ForegroundColor Yellow
}

# 6. Vérification fichiers clés plan v64
Write-Host "`n6. LIVRABLES PLAN V64:" -ForegroundColor Yellow

$keyFiles = @(
   "pkg/monitoring/prometheus_metrics.go",
   "pkg/logging/elk_exporter.go",
   "pkg/tracing/otel_tracing.go",
   "pkg/apigateway/oauth_jwt_auth.go",
   "pkg/security/crypto_utils.go",
   "pkg/tenant/rbac.go",
   "pkg/replication/replicator.go",
   "deployment/helm/",
   "tests/chaos/",
   "analytics/"
)

$foundFiles = 0
$totalFiles = $keyFiles.Count

foreach ($file in $keyFiles) {
   if (Test-Path $file) {
      Write-Host "✅ $file" -ForegroundColor Green
      $foundFiles++
   }
   else {
      Write-Host "❌ $file manquant" -ForegroundColor Red
   }
}

# 7. Calcul score et résumé
Write-Host "`n=== RÉSUMÉ VALIDATION ===" -ForegroundColor Cyan
$completionPercentage = [math]::Round(($foundFiles / $totalFiles) * 100, 1)

Write-Host "Date validation: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host "Répertoire: $PWD" -ForegroundColor White
Write-Host "Livrables Plan v64: ${foundFiles}/${totalFiles} (${completionPercentage}%)" -ForegroundColor White

if ($completionPercentage -ge 90) {
   Write-Host "`n🎉 EXCELLENT! Plan v64 quasi-complet" -ForegroundColor Green
}
elseif ($completionPercentage -ge 70) {
   Write-Host "`n✅ BON! Plan v64 bien avancé" -ForegroundColor Green
}
elseif ($completionPercentage -ge 50) {
   Write-Host "`n⚠️ MOYEN. Plan v64 en cours" -ForegroundColor Yellow
}
else {
   Write-Host "`n❌ FAIBLE. Plan v64 à développer" -ForegroundColor Red
}

Write-Host "`n🎯 VALIDATION TERMINÉE!" -ForegroundColor Cyan
