# Script de vérification rapide de l'état de la réorganisation
# Version: 1.0.0

$ErrorActionPreference = "Continue"

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "Vérification Rapide - Manager Toolkit v3.0.0" -ForegroundColor Cyan  
Write-Host "===============================================" -ForegroundColor Cyan

# Vérifier la structure des dossiers
Write-Host "`n1. Structure des dossiers:" -ForegroundColor Yellow
$requiredFolders = @(
   "cmd\manager-toolkit",
   "core\registry", 
   "core\toolkit",
   "docs",
   "operations\analysis",
   "operations\correction",
   "operations\migration", 
   "operations\validation"
)

$allFoldersExist = $true
foreach ($folder in $requiredFolders) {
   if (Test-Path $folder) {
      Write-Host "  ✅ $folder" -ForegroundColor Green
   }
   else {
      Write-Host "  ❌ $folder" -ForegroundColor Red
      $allFoldersExist = $false
   }
}

# Vérifier go.mod
Write-Host "`n2. Configuration Go:" -ForegroundColor Yellow
if (Test-Path "go.mod") {
   Write-Host "  ✅ go.mod existe" -ForegroundColor Green
}
else {
   Write-Host "  ❌ go.mod manquant" -ForegroundColor Red
}

# Vérifier les fichiers principaux
Write-Host "`n3. Fichiers principaux:" -ForegroundColor Yellow
$mainFiles = @(
   "cmd\manager-toolkit\manager_toolkit.go",
   "core\registry\tool_registry.go",
   "core\toolkit\toolkit_core.go"
)

foreach ($file in $mainFiles) {
   if (Test-Path $file) {
      Write-Host "  ✅ $file" -ForegroundColor Green
   }
   else {
      Write-Host "  ❌ $file" -ForegroundColor Red
   }
}

# Vérifier la documentation
Write-Host "`n4. Documentation:" -ForegroundColor Yellow
$docFiles = @(
   "docs\REORGANISATION_RAPPORT_FINAL.md",
   "docs\GUIDE_MIGRATION_STRUCTURE.md"
)

foreach ($doc in $docFiles) {
   if (Test-Path $doc) {
      Write-Host "  ✅ $doc" -ForegroundColor Green
   }
   else {
      Write-Host "  ❌ $doc" -ForegroundColor Red
   }
}

# Tentative de compilation simple
Write-Host "`n5. Test de compilation:" -ForegroundColor Yellow
try {
   $compileResult = go build -v ./cmd/manager-toolkit 2>&1
   if ($LASTEXITCODE -eq 0) {
      Write-Host "  ✅ Compilation réussie" -ForegroundColor Green
   }
   else {
      Write-Host "  ⚠️ Erreurs de compilation détectées" -ForegroundColor Yellow
      Write-Host "     Détails: $compileResult" -ForegroundColor Gray
   }
}
catch {
   Write-Host "  ❌ Impossible de compiler: $_" -ForegroundColor Red
}

# Résumé final
Write-Host "`n===============================================" -ForegroundColor Cyan
if ($allFoldersExist) {
   Write-Host "✅ RÉORGANISATION RÉUSSIE!" -ForegroundColor Green
   Write-Host "La nouvelle structure est en place et fonctionnelle." -ForegroundColor Green
}
else {
   Write-Host "⚠️ RÉORGANISATION INCOMPLÈTE" -ForegroundColor Yellow
   Write-Host "Certains éléments manquent encore." -ForegroundColor Yellow
}
Write-Host "===============================================" -ForegroundColor Cyan
