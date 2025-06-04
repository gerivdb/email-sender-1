# Script de nettoyage de l'environnement Go
Write-Host "[CLEAN] Nettoyage de l'environnement Go..." -ForegroundColor Cyan

# Arret des processus Go
Write-Host "[PROC] Arret des processus Go..."
Get-Process | Where-Object { 
   $_.ProcessName -like '*go*' -or 
   $_.ProcessName -like '*gopls*' -or 
   $_.ProcessName -like '*dlv*' -or 
   $_.ProcessName -like '*gocode*'
} | ForEach-Object {
   try {
      $_ | Stop-Process -Force -ErrorAction SilentlyContinue
      Write-Host "  ✅ Arrêté: $($_.ProcessName)" -ForegroundColor Green
   }
   catch {
      Write-Host "  ⚠️ Impossible d'arrêter: $($_.ProcessName)" -ForegroundColor Yellow
   }
}

# Sauvegarde des fichiers importants
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = ".\backup\$timestamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Write-Host "[SAVE] Sauvegarde des fichiers importants..."
@("go.mod", "go.sum") | ForEach-Object {
   if (Test-Path $_) {
      Copy-Item $_ "$backupDir\$_"
      Write-Host "  ✅ Sauvegardé: $_" -ForegroundColor Green
   }
}

# Suppression des fichiers de cache
Write-Host "[CACHE] Suppression des fichiers de cache..."
$cacheLocations = @(
   "$env:LOCALAPPDATA\go-build",
   "$env:USERPROFILE\go\pkg\mod"
)

foreach ($location in $cacheLocations) {
   if (Test-Path $location) {
      try {
         Remove-Item -Path $location -Recurse -Force -ErrorAction Stop
         Write-Host "  ✅ Supprimé: $location" -ForegroundColor Green
      }
      catch {
         Write-Host "  ⚠️ Erreur lors de la suppression de $location" -ForegroundColor Yellow
      }
   }
}

# Suppression des fichiers go.sum
if (Test-Path "go.sum") {
   Remove-Item "go.sum" -Force
   Write-Host "  ✅ Supprimé: go.sum" -ForegroundColor Green
}

# Réinitialisation des modules
Write-Host "[MOD] Réinitialisation des modules..."
$env:GO111MODULE = "on"
go mod tidy

Write-Host "`n[DONE] Nettoyage terminé" -ForegroundColor Cyan
