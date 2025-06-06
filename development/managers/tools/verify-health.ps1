# Script de vérification de santé du projet après réorganisation
# filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\tools\verify-health.ps1

$ErrorActionPreference = "Stop"

Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host "Vérification de la santé après réorganisation" -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor Cyan

# Vérifier que nous sommes dans le bon répertoire
$toolsDir = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\tools"
$currentDir = Get-Location
if ($currentDir.Path -ne $toolsDir) {
   Set-Location $toolsDir
   Write-Host "Répertoire de travail modifié: $toolsDir" -ForegroundColor Yellow
}

# Vérifier la structure des dossiers
Write-Host "`n1. Vérification de la structure de dossiers:" -ForegroundColor Cyan
$requiredFolders = @(
   "cmd\manager-toolkit",
   "core\registry",
   "core\toolkit",
   "docs",
   "internal\test",
   "legacy",
   "operations\analysis",
   "operations\correction",
   "operations\migration",
   "operations\validation",
   "testdata"
)

$foldersOk = $true
foreach ($folder in $requiredFolders) {
   $fullPath = Join-Path $toolsDir $folder
   if (Test-Path $fullPath -PathType Container) {
      Write-Host "  ✅ $folder" -ForegroundColor Green
   }
   else {
      Write-Host "  ❌ $folder (manquant)" -ForegroundColor Red
      $foldersOk = $false
   }
}

# Vérifier go.mod
Write-Host "`n2. Vérification de go.mod:" -ForegroundColor Cyan
if (Test-Path ".\go.mod") {
   Write-Host "  ✅ go.mod existe" -ForegroundColor Green
   $goModContent = Get-Content ".\go.mod" -Raw
   if ($goModContent -match "module github.com/email-sender/tools") {
      Write-Host "  ✅ Module correctement configuré" -ForegroundColor Green
   }
   else {
      Write-Host "  ❌ Module mal configuré dans go.mod" -ForegroundColor Red
   }
}
else {
   Write-Host "  ❌ go.mod manquant" -ForegroundColor Red
}

# Vérification du build
Write-Host "`n3. Vérification de la compilation:" -ForegroundColor Cyan
$buildOutput = Invoke-Expression "go build -v ./cmd/manager-toolkit" 2>&1
if ($LASTEXITCODE -eq 0) {
   Write-Host "  ✅ Compilation réussie" -ForegroundColor Green
   
   # Vérification de l'exécutable généré
   $exePath = Join-Path $toolsDir "manager-toolkit.exe"
   if (Test-Path $exePath) {
      Write-Host "  ✅ Exécutable généré avec succès: $exePath" -ForegroundColor Green
      
      # Vérifier la taille et la date de création de l'exécutable
      $exeInfo = Get-Item $exePath
      $exeSize = [math]::Round($exeInfo.Length / 1MB, 2)
      Write-Host "    - Taille: $exeSize MB" -ForegroundColor Gray
      Write-Host "    - Date de création: $($exeInfo.CreationTime)" -ForegroundColor Gray
      
      # Tenter d'exécuter en mode test pour vérifier son fonctionnement de base
      try {
         $testResult = Invoke-Expression "$exePath --version" 2>&1
         if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ L'exécutable fonctionne correctement" -ForegroundColor Green
            Write-Host "    - Version: $testResult" -ForegroundColor Gray
         }
         else {
            Write-Host "  ⚠️ L'exécutable a généré une erreur lors de l'exécution" -ForegroundColor Yellow
            Write-Host $testResult -ForegroundColor Gray
         }
      }
      catch {
         Write-Host "  ⚠️ Impossible de tester l'exécution: $_" -ForegroundColor Yellow
      }
   }
   else {
      Write-Host "  ⚠️ L'exécutable n'a pas été généré à l'emplacement attendu" -ForegroundColor Yellow
   }
}
else {
   Write-Host "  ❌ Erreurs de compilation:" -ForegroundColor Red
   Write-Host $buildOutput -ForegroundColor Gray
}

# Vérification des fichiers de documentation
Write-Host "`n4. Vérification des fichiers de documentation:" -ForegroundColor Cyan
$docFiles = @(
   "docs\README.md",
   "docs\TOOLS_ECOSYSTEM_DOCUMENTATION.md", 
   "docs\TOOLS_ECOSYSTEM_DOCUMENTATION_V3.md"
)

foreach ($doc in $docFiles) {
   $fullPath = Join-Path $toolsDir $doc
   if (Test-Path $fullPath) {
      Write-Host "  ✅ $doc" -ForegroundColor Green
        
      # Vérifier les références absolues dans les fichiers markdown
      $content = Get-Content $fullPath -Raw
      if ($content -match "development/managers/tools/[^/]") {
         Write-Host "    ⚠️ Références à l'ancienne structure détectées" -ForegroundColor Yellow
      }
   }
   else {
      Write-Host "  ❌ $doc (manquant)" -ForegroundColor Red
   }
}

# Vérification des imports dans les fichiers Go
Write-Host "`n5. Vérification des imports dans les fichiers Go:" -ForegroundColor Cyan
$badImports = @()
$goFiles = Get-ChildItem -Path $toolsDir -Filter "*.go" -Recurse

foreach ($file in $goFiles) {
   $content = Get-Content $file.FullName -Raw
    
   # Vérifier les imports qui ne suivent pas la nouvelle structure
   if ($content -match 'import\s+\([^)]*"github\.com/email-sender/tools"[^)]*\)' -or 
      $content -match 'import\s+"github\.com/email-sender/tools"') {
      $badImports += $file.FullName
   }
}

if ($badImports.Count -eq 0) {
   Write-Host "  ✅ Tous les imports sont à jour" -ForegroundColor Green
}
else {
   Write-Host "  ⚠️ Fichiers avec imports potentiellement incorrects: $($badImports.Count)" -ForegroundColor Yellow
   foreach ($file in $badImports) {
      Write-Host "    - $file" -ForegroundColor Yellow
   }
}

# Vérification des tests unitaires
Write-Host "`n6. Vérification des tests unitaires:" -ForegroundColor Cyan
try {
   $testOutput = Invoke-Expression "go test ./..." 2>&1
   if ($LASTEXITCODE -eq 0) {
      Write-Host "  ✅ Tous les tests fonctionnent" -ForegroundColor Green
   }
   else {
      Write-Host "  ⚠️ Certains tests ont échoué" -ForegroundColor Yellow
      Write-Host $testOutput -ForegroundColor Gray
   }
}
catch {
   Write-Host "  ⚠️ Erreur lors de l'exécution des tests: $_" -ForegroundColor Yellow
}

# Vérification de la cohérence des scripts
Write-Host "`n7. Vérification des scripts d'assistance:" -ForegroundColor Cyan
$scripts = @("build.ps1", "run.ps1", "update-packages.ps1", "update-imports.ps1", "migrate-config.ps1")
$scriptsOk = $true

foreach ($script in $scripts) {
   $scriptPath = Join-Path $toolsDir $script
   if (Test-Path $scriptPath) {
      Write-Host "  ✅ $script" -ForegroundColor Green
        
      # Vérifier le contenu pour les références à l'ancienne structure
      $content = Get-Content $scriptPath -Raw
      if ($content -match "tools/[^/]" -and -not $content.Contains("github.com/email-sender/tools")) {
         Write-Host "    ⚠️ Références potentiellement obsolètes détectées" -ForegroundColor Yellow
         $scriptsOk = $false
      }
   }
   else {
      Write-Host "  ❌ $script (manquant)" -ForegroundColor Red
      $scriptsOk = $false
   }
}

# Rapport final
Write-Host "`nRapport de santé:" -ForegroundColor Cyan
if ($foldersOk -and $LASTEXITCODE -eq 0 -and $badImports.Count -eq 0 -and $scriptsOk) {
   Write-Host "✅ Le projet semble correctement réorganisé!" -ForegroundColor Green
}
else {
   Write-Host "⚠️ Certains problèmes ont été détectés, voir les détails ci-dessus." -ForegroundColor Yellow
}
