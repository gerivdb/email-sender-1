# 🔍 Validation Réelle du Projet v64
# Script de diagnostic et validation complète

param(
   [Parameter()]
   [switch]$Fix = $false,
    
   [Parameter()]
   [switch]$DetailedLog = $false,
    
   [Parameter()]
   [switch]$SkipTests = $false
)

$ErrorActionPreference = "Stop"

# Configuration
$ProjectRoot = $PSScriptRoot
$LogFile = Join-Path $ProjectRoot "validation_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
   param(
      [string]$Message,
      [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
      [string]$Level = "INFO"
   )
    
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [$Level] $Message"
    
   # Couleurs selon le niveau
   $color = switch ($Level) {
      "ERROR" { "Red" }
      "WARN" { "Yellow" }
      "SUCCESS" { "Green" }
      default { "White" }
   }
    
   Write-Host $logEntry -ForegroundColor $color
   Add-Content -Path $LogFile -Value $logEntry
}

function Test-GoEnvironment {
   Write-Log "=== VALIDATION ENVIRONNEMENT GO ===" "INFO"
    
   # Test 1: Go version
   try {
      $goVersion = go version
      Write-Log "Go Version: $goVersion" "SUCCESS"
        
      if ($goVersion -match 'go(\d+\.\d+)') {
         $version = [version]$matches[1]
         if ($version -lt [version]"1.21") {
            Write-Log "Go version trop ancienne (requis: 1.21+)" "ERROR"
            return $false
         }
      }
   }
   catch {
      Write-Log "Go n'est pas installé ou accessible" "ERROR"
      return $false
   }
    
   # Test 2: Go modules
   if (Test-Path "go.mod") {
      Write-Log "Fichier go.mod trouvé" "SUCCESS"
   }
   else {
      Write-Log "Fichier go.mod manquant" "ERROR"
      return $false
   }
    
   # Test 3: Go workspace
   if (Test-Path "go.work") {
      Write-Log "Go workspace détecté" "INFO"
   }
    
   return $true
}

function Test-ProjectStructure {
   Write-Log "=== VALIDATION STRUCTURE PROJET ===" "INFO"
    
   $requiredDirs = @(
      "pkg",
      "cmd", 
      "internal",
      "tests",
      "scripts"
   )
    
   $missingDirs = @()
   foreach ($dir in $requiredDirs) {
      if (Test-Path $dir) {
         Write-Log "Répertoire trouvé: $dir" "SUCCESS"
      }
      else {
         Write-Log "Répertoire manquant: $dir" "WARN"
         $missingDirs += $dir
      }
   }
    
   # Vérification fichiers critiques
   $criticalFiles = @(
      "go.mod",
      "go.sum",
      "README.md"
   )
    
   foreach ($file in $criticalFiles) {
      if (Test-Path $file) {
         Write-Log "Fichier critique trouvé: $file" "SUCCESS"
      }
      else {
         Write-Log "Fichier critique manquant: $file" "ERROR"
      }
   }
    
   return $missingDirs.Count -eq 0
}

function Repair-Dependencies {
   Write-Log "=== RÉPARATION DÉPENDANCES ===" "INFO"
    
   try {
      # Nettoyage go.mod
      Write-Log "Nettoyage go.mod..." "INFO"
      $result = go mod tidy 2>&1
      if ($LASTEXITCODE -eq 0) {
         Write-Log "go mod tidy: SUCCESS" "SUCCESS"
      }
      else {
         Write-Log "go mod tidy: ÉCHEC - $result" "ERROR"
      }
        
      # Vérification modules
      Write-Log "Vérification intégrité modules..." "INFO"
      $result = go mod verify 2>&1
      if ($LASTEXITCODE -eq 0) {
         Write-Log "go mod verify: SUCCESS" "SUCCESS"
      }
      else {
         Write-Log "go mod verify: ÉCHEC - $result" "WARN"
      }
        
      # Téléchargement dépendances
      Write-Log "Téléchargement dépendances..." "INFO"
      $result = go mod download 2>&1
      if ($LASTEXITCODE -eq 0) {
         Write-Log "go mod download: SUCCESS" "SUCCESS"
      }
      else {
         Write-Log "go mod download: ÉCHEC - $result" "ERROR"
      }
        
   }
   catch {
      Write-Log "Erreur lors de la réparation: $($_.Exception.Message)" "ERROR"
      return $false
   }
    
   return $true
}

function Test-Build {
   Write-Log "=== TEST COMPILATION ===" "INFO"
    
   try {
      # Build global
      Write-Log "Compilation globale..." "INFO"
      $buildResult = go build ./... 2>&1
        
      if ($LASTEXITCODE -eq 0) {
         Write-Log "Build global: SUCCESS" "SUCCESS"
         return $true
      }
      else {
         Write-Log "Build global: ÉCHEC" "ERROR"
         Write-Log "Erreurs de build: $buildResult" "ERROR"
            
         # Test build par package pour diagnostiquer
         Write-Log "Diagnostic build par package..." "INFO"
            
         $packages = @("./pkg/...", "./cmd/...", "./internal/...")
         foreach ($pkg in $packages) {
            if (Test-Path $pkg.Replace('./', '').Replace('/...', '')) {
               $pkgResult = go build $pkg 2>&1
               if ($LASTEXITCODE -eq 0) {
                  Write-Log "Build ${pkg}: SUCCESS" "SUCCESS"
               }
               else {
                  Write-Log "Build ${pkg}: ÉCHEC - $pkgResult" "ERROR"
               }
            }
         }
            
         return $false
      }
   }
   catch {
      Write-Log "Erreur compilation: $($_.Exception.Message)" "ERROR"
      return $false
   }
}

function Test-UnitTests {
   Write-Log "=== EXÉCUTION TESTS UNITAIRES ===" "INFO"
    
   if ($SkipTests) {
      Write-Log "Tests ignorés (SkipTests activé)" "WARN"
      return $true
   }
    
   try {
      # Test avec couverture
      $coverageFile = "coverage_validation.out"
      Write-Log "Lancement tests avec couverture..." "INFO"
        
      $testResult = go test -v -race -coverprofile=$coverageFile ./... 2>&1
        
      if ($LASTEXITCODE -eq 0) {
         Write-Log "Tests unitaires: SUCCESS" "SUCCESS"
            
         # Génération rapport couverture
         if (Test-Path $coverageFile) {
            $coverageHtml = "coverage_validation.html"
            go tool cover -html=$coverageFile -o $coverageHtml
                
            # Analyse couverture
            $coverageText = go tool cover -func=$coverageFile 2>&1
            if ($coverageText -match 'total:.*?(\d+\.\d+)%') {
               $coverage = [double]$matches[1]
               Write-Log "Couverture globale: $coverage%" "INFO"
                    
               if ($coverage -ge 80) {
                  Write-Log "Excellente couverture (≥80%)" "SUCCESS"
               }
               elseif ($coverage -ge 60) {
                  Write-Log "Couverture acceptable (≥60%)" "WARN"
               }
               else {
                  Write-Log "Couverture insuffisante (<60%)" "WARN"
               }
            }
                
            Write-Log "Rapport HTML généré: $coverageHtml" "INFO"
         }
            
         return $true
      }
      else {
         Write-Log "Tests unitaires: ÉCHEC" "ERROR"
         Write-Log "Erreurs tests: $testResult" "ERROR"
         return $false
      }
        
   }
   catch {
      Write-Log "Erreur tests: $($_.Exception.Message)" "ERROR"
      return $false
   }
}

function Test-Integration {
   Write-Log "=== TEST INTÉGRATION ===" "INFO"
    
   # Vérification présence tests d'intégration
   $integrationDirs = @("tests/integration", "tests/e2e", "tests/system")
   $hasIntegrationTests = $false
    
   foreach ($dir in $integrationDirs) {
      if (Test-Path $dir) {
         $testFiles = Get-ChildItem -Path $dir -Filter "*_test.go" -Recurse
         if ($testFiles.Count -gt 0) {
            Write-Log "Tests d'intégration trouvés dans: $dir ($($testFiles.Count) fichiers)" "SUCCESS"
            $hasIntegrationTests = $true
         }
      }
   }
    
   if (-not $hasIntegrationTests) {
      Write-Log "Aucun test d'intégration trouvé" "WARN"
      return $true  # Non bloquant
   }
    
   # Exécution tests d'intégration si présents
   try {
      foreach ($dir in $integrationDirs) {
         if (Test-Path $dir) {
            $result = go test -v "./$dir/..." 2>&1
            if ($LASTEXITCODE -eq 0) {
               Write-Log "Tests intégration ${dir}: SUCCESS" "SUCCESS"
            }
            else {
               Write-Log "Tests intégration ${dir}: ÉCHEC - $result" "WARN"
            }
         }
      }
   }
   catch {
      Write-Log "Erreur tests intégration: $($_.Exception.Message)" "WARN"
   }
    
   return $true
}

function New-ValidationReport {
   Write-Log "=== GÉNÉRATION RAPPORT VALIDATION ===" "INFO"
    
   $reportFile = "V64_VALIDATION_REPORT_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    
   $report = @"
# 🔍 Rapport de Validation v64 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## 📊 Résumé Exécutif

**Projet** : EMAIL_SENDER_1 - Plan v64  
**Date de validation** : $(Get-Date -Format 'yyyy-MM-dd')  
**Environnement** : $(hostname) - Windows

## 🎯 Résultats de Validation

### ✅ Environnement Go
- **Version Go** : $(go version)
- **Modules Go** : $(if (Test-Path 'go.mod') { '✅ Configurés' } else { '❌ Manquants' })
- **Workspace** : $(if (Test-Path 'go.work') { '✅ Détecté' } else { 'ℹ️ Absent' })

### 🏗️ Structure Projet
- **Répertoires core** : $(if ((Test-Path 'pkg') -and (Test-Path 'cmd')) { '✅ Présents' } else { '⚠️ Incomplets' })
- **Tests** : $(if (Test-Path 'tests') { '✅ Répertoire présent' } else { '⚠️ Manquant' })
- **Documentation** : $(if (Test-Path 'README.md') { '✅ README présent' } else { '❌ README manquant' })

### 🔧 Compilation
- **Build global** : 
- **Dépendances** : 
- **Modules tiers** : 

### 🧪 Tests
- **Tests unitaires** : 
- **Couverture** : 
- **Tests intégration** : 

## 📁 Fichiers Générés

- **Log détaillé** : ``$LogFile``
- **Couverture tests** : ``coverage_validation.out`` / ``coverage_validation.html``
- **Ce rapport** : ``$reportFile``

## 🔮 Recommandations

### Prochaines Étapes
1. Corriger les erreurs de compilation identifiées
2. Améliorer la couverture de tests (objectif: 80%+)
3. Ajouter tests d'intégration manquants
4. Mettre à jour la documentation

### Actions Immédiates
- [ ] Résoudre dépendances manquantes
- [ ] Exécuter ``go mod tidy`` si nécessaire
- [ ] Vérifier imports et chemins relatifs
- [ ] Tester build après corrections

---

**Validation effectuée par** : validate-project-v64.ps1  
**Version script** : 1.0  
**Contact** : Équipe développement
"@

   Set-Content -Path $reportFile -Value $report -Encoding UTF8
   Write-Log "Rapport généré: $reportFile" "SUCCESS"
    
   return $reportFile
}

# ============================================
# EXÉCUTION PRINCIPALE
# ============================================

try {
   Write-Log "🚀 DÉMARRAGE VALIDATION PROJET V64" "INFO"
   Write-Log "Projet: $ProjectRoot" "INFO"
   Write-Log "Log: $LogFile" "INFO"
    
   $validationSuccess = $true
    
   # 1. Validation environnement
   if (-not (Test-GoEnvironment)) {
      $validationSuccess = $false
      Write-Log "❌ Validation environnement échouée" "ERROR"
   }
    
   # 2. Validation structure
   if (-not (Test-ProjectStructure)) {
      Write-Log "⚠️ Structure projet incomplète" "WARN"
   }
    
   # 3. Réparation dépendances si demandé
   if ($Fix) {
      Write-Log "🔧 Mode réparation activé" "INFO"
      if (-not (Repair-Dependencies)) {
         $validationSuccess = $false
         Write-Log "❌ Échec réparation dépendances" "ERROR"
      }
   }
    
   # 4. Test compilation
   if (-not (Test-Build)) {
      $validationSuccess = $false
      Write-Log "❌ Échec compilation" "ERROR"
   }
    
   # 5. Tests unitaires
   if (-not (Test-UnitTests)) {
      $validationSuccess = $false
      Write-Log "❌ Échec tests unitaires" "ERROR"
   }
    
   # 6. Tests intégration
   Test-Integration  # Non bloquant
    
   # 7. Génération rapport    $reportFile = New-ValidationReport
    
   # Résumé final
   Write-Log "============================================" "INFO"
   if ($validationSuccess) {
      Write-Log "🎉 VALIDATION PROJET V64: SUCCÈS" "SUCCESS"
      Write-Log "Tous les composants critiques sont fonctionnels" "SUCCESS"
   }
   else {
      Write-Log "❌ VALIDATION PROJET V64: ÉCHEC" "ERROR"
      Write-Log "Des problèmes critiques nécessitent correction" "ERROR"
   }
    
   Write-Log "📄 Rapport détaillé: $reportFile" "INFO"
   Write-Log "📋 Log complet: $LogFile" "INFO"
   Write-Log "============================================" "INFO"
    
   # Code de sortie
   if ($validationSuccess) {
      exit 0
   }
   else {
      exit 1
   }
    
}
catch {
   Write-Log "💥 ERREUR CRITIQUE: $($_.Exception.Message)" "ERROR"
   Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
   exit 2
}
