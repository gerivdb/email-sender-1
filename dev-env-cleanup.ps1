# Script de nettoyage complet de l'environnement Go
# Usage: .\dev-env-cleanup.ps1

Write-Host "🧹 Nettoyage complet de l'environnement Go..." -ForegroundColor Yellow

# Arrêt du serveur de langage Go
Write-Host "🔄 Arrêt du serveur de langage Go..." -ForegroundColor Blue
taskkill /F /IM gopls.exe 2>$null
Start-Sleep -Seconds 2

# Nettoyage des caches Go
Write-Host "🗑️ Nettoyage des caches Go..." -ForegroundColor Blue
go clean -cache -modcache -i
go clean -testcache

# Suppression des fichiers de test temporaires
Write-Host "🗂️ Suppression des fichiers de test temporaires..." -ForegroundColor Blue
$testFiles = @(
   "debug_*.go",
   "test_*.go", 
   "*_test_debug.go",
   "cache_logic_simulation.go",
   "cache_verification.go",
   "comprehensive_cache_test.go",
   "end_to_end_integration_test.go",
   "qdrant_test_types.go",
   "validation_test.go",
   "qdrant_validation_test.go"
)

foreach ($pattern in $testFiles) {
   Remove-Item $pattern -Force -ErrorAction SilentlyContinue
}

# Suppression de go.sum pour régénération
Write-Host "📋 Suppression de go.sum pour régénération..." -ForegroundColor Blue
Remove-Item "go.sum" -Force -ErrorAction SilentlyContinue

# Reconstruction des dépendances
Write-Host "📦 Reconstruction des dépendances..." -ForegroundColor Blue
go mod tidy
go mod download

# Vérification de l'état
Write-Host "✅ Vérification de l'état..." -ForegroundColor Blue
go mod verify

Write-Host "🎉 Nettoyage terminé! Redémarrez VS Code pour des résultats optimaux." -ForegroundColor Green
