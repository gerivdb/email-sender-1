#!/usr/bin/env pwsh
# 🔍 Script de Validation de l'Écosystème des Managers
# Version: 1.0.0
# Date: 7 juin 2025

param(
   [switch]$Quick,
   [switch]$Full,
   [string]$Manager = ""
)

$ErrorActionPreference = "Stop"

# Configuration
$MANAGERS = @(
   "git-workflow-manager",
   "dependency-manager", 
   "security-manager",
   "storage-manager",
   "email-manager",
   "notification-manager",
   "integration-manager"
)

$ECOSYSTEM_ROOT = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers"

function Write-ColorOutput {
   param([string]$Message, [string]$Color = "White")
   switch ($Color) {
      "Green" { Write-Host $Message -ForegroundColor Green }
      "Yellow" { Write-Host $Message -ForegroundColor Yellow }
      "Red" { Write-Host $Message -ForegroundColor Red }
      "Blue" { Write-Host $Message -ForegroundColor Blue }
      "Cyan" { Write-Host $Message -ForegroundColor Cyan }
      "Magenta" { Write-Host $Message -ForegroundColor Magenta }
      default { Write-Host $Message }
   }
}

function Test-ManagerStructure {
   param([string]$ManagerName)
    
   Write-ColorOutput "📁 Validation de la structure: $ManagerName" "Blue"
    
   $managerPath = Join-Path $ECOSYSTEM_ROOT $ManagerName
   $results = @()
    
   # Vérifier l'existence du répertoire
   if (-not (Test-Path $managerPath)) {
      $results += @{ Test = "Directory exists"; Status = "❌ FAIL"; Details = "Manager directory not found" }
      return $results
   }
    
   # Vérifier go.mod
   $goModPath = Join-Path $managerPath "go.mod"
   if (Test-Path $goModPath) {
      $results += @{ Test = "go.mod exists"; Status = "✅ PASS"; Details = "Found" }
   }
   else {
      $results += @{ Test = "go.mod exists"; Status = "❌ FAIL"; Details = "Missing go.mod file" }
   }
    
   # Vérifier les fichiers Go
   $goFiles = Get-ChildItem -Path $managerPath -Filter "*.go" -Recurse
   if ($goFiles.Count -gt 0) {
      $results += @{ Test = "Go files exist"; Status = "✅ PASS"; Details = "$($goFiles.Count) files found" }
   }
   else {
      $results += @{ Test = "Go files exist"; Status = "❌ FAIL"; Details = "No Go files found" }
   }
    
   # Vérifier les tests
   $testFiles = Get-ChildItem -Path $managerPath -Filter "*_test.go" -Recurse
   if ($testFiles.Count -gt 0) {
      $results += @{ Test = "Test files exist"; Status = "✅ PASS"; Details = "$($testFiles.Count) test files" }
   }
   else {
      $results += @{ Test = "Test files exist"; Status = "⚠️ WARN"; Details = "No test files found" }
   }
    
   return $results
}

function Test-ManagerCompilation {
   param([string]$ManagerName)
    
   Write-ColorOutput "🔨 Test de compilation: $ManagerName" "Blue"
    
   $managerPath = Join-Path $ECOSYSTEM_ROOT $ManagerName
   $results = @()
    
   if (-not (Test-Path $managerPath)) {
      $results += @{ Test = "Compilation"; Status = "❌ FAIL"; Details = "Manager not found" }
      return $results
   }
    
   Push-Location $managerPath
   try {
      # Test de compilation
      $buildOutput = go build -v ./... 2>&1
      if ($LASTEXITCODE -eq 0) {
         $results += @{ Test = "Build compilation"; Status = "✅ PASS"; Details = "Compiled successfully" }
      }
      else {
         $results += @{ Test = "Build compilation"; Status = "❌ FAIL"; Details = "Build failed: $buildOutput" }
      }
        
      # Test go mod tidy
      go mod tidy 2>&1 | Out-Null
      if ($LASTEXITCODE -eq 0) {
         $results += @{ Test = "go mod tidy"; Status = "✅ PASS"; Details = "Dependencies clean" }
      }
      else {
         $results += @{ Test = "go mod tidy"; Status = "⚠️ WARN"; Details = "Module issues detected" }
      }
        
   }
   catch {
      $results += @{ Test = "Build compilation"; Status = "❌ FAIL"; Details = "Exception: $($_.Exception.Message)" }
   }
   finally {
      Pop-Location
   }
    
   return $results
}

function Test-ManagerTests {
   param([string]$ManagerName)
    
   Write-ColorOutput "🧪 Test d'exécution: $ManagerName" "Blue"
    
   $managerPath = Join-Path $ECOSYSTEM_ROOT $ManagerName
   $results = @()
    
   if (-not (Test-Path $managerPath)) {
      $results += @{ Test = "Tests execution"; Status = "❌ FAIL"; Details = "Manager not found" }
      return $results
   }
    
   Push-Location $managerPath
   try {
      # Vérifier s'il y a des tests
      $testFiles = Get-ChildItem -Filter "*_test.go" -Recurse
      if ($testFiles.Count -eq 0) {
         $results += @{ Test = "Tests execution"; Status = "⚠️ SKIP"; Details = "No test files found" }
         return $results
      }
        
      # Exécuter les tests
      $testOutput = go test -v ./... 2>&1
      if ($LASTEXITCODE -eq 0) {
         $passCount = ($testOutput | Select-String "PASS:" | Measure-Object).Count
         $results += @{ Test = "Tests execution"; Status = "✅ PASS"; Details = "$passCount tests passed" }
      }
      else {
         $failCount = ($testOutput | Select-String "FAIL:" | Measure-Object).Count
         $results += @{ Test = "Tests execution"; Status = "❌ FAIL"; Details = "$failCount tests failed" }
      }
        
   }
   catch {
      $results += @{ Test = "Tests execution"; Status = "❌ FAIL"; Details = "Exception: $($_.Exception.Message)" }
   }
   finally {
      Pop-Location
   }
    
   return $results
}

function Test-EcosystemIntegrity {
   Write-ColorOutput "🌐 Test d'intégrité de l'écosystème" "Cyan"
    
   $results = @()
    
   # Vérifier la structure des interfaces
   $interfacesPath = Join-Path $ECOSYSTEM_ROOT "interfaces"
   if (Test-Path $interfacesPath) {
      $results += @{ Test = "Interfaces directory"; Status = "✅ PASS"; Details = "Found" }
        
      # Vérifier go.mod des interfaces
      $interfacesGoMod = Join-Path $interfacesPath "go.mod"
      if (Test-Path $interfacesGoMod) {
         $results += @{ Test = "Interfaces go.mod"; Status = "✅ PASS"; Details = "Found" }
      }
      else {
         $results += @{ Test = "Interfaces go.mod"; Status = "❌ FAIL"; Details = "Missing" }
      }
   }
   else {
      $results += @{ Test = "Interfaces directory"; Status = "❌ FAIL"; Details = "Missing interfaces directory" }
   }
    
   # Vérifier les fichiers de documentation
   $docs = @("README-ECOSYSTEM.md", "ROADMAP.md", "CONFIG.md")
   foreach ($doc in $docs) {
      $docPath = Join-Path $ECOSYSTEM_ROOT $doc
      if (Test-Path $docPath) {
         $results += @{ Test = "Documentation: $doc"; Status = "✅ PASS"; Details = "Found" }
      }
      else {
         $results += @{ Test = "Documentation: $doc"; Status = "⚠️ WARN"; Details = "Missing" }
      }
   }
    
   # Vérifier le script de gestion
   $scriptPath = Join-Path $ECOSYSTEM_ROOT "manager-ecosystem.ps1"
   if (Test-Path $scriptPath) {
      $results += @{ Test = "Management script"; Status = "✅ PASS"; Details = "Found" }
   }
   else {
      $results += @{ Test = "Management script"; Status = "❌ FAIL"; Details = "Missing manager-ecosystem.ps1" }
   }
    
   return $results
}

function Show-Results {
   param([array]$Results, [string]$Title)
    
   Write-ColorOutput "`n📊 Résultats: $Title" "Cyan"
   Write-ColorOutput "=" * 60 "Cyan"
    
   $passCount = 0
   $failCount = 0
   $warnCount = 0
   $skipCount = 0
    
   foreach ($result in $Results) {
      $status = $result.Status
      $test = $result.Test.PadRight(30)
      $details = $result.Details
        
      switch -Regex ($status) {
         "✅.*PASS" { 
            Write-ColorOutput "$test $status - $details" "Green"
            $passCount++
         }
         "❌.*FAIL" { 
            Write-ColorOutput "$test $status - $details" "Red"
            $failCount++
         }
         "⚠️.*WARN" { 
            Write-ColorOutput "$test $status - $details" "Yellow"
            $warnCount++
         }
         "⚠️.*SKIP" { 
            Write-ColorOutput "$test $status - $details" "Blue"
            $skipCount++
         }
      }
   }
    
   Write-ColorOutput "`n📈 Résumé:" "Yellow"
   Write-ColorOutput "  ✅ Réussis: $passCount" "Green"
   Write-ColorOutput "  ❌ Échecs: $failCount" "Red"
   Write-ColorOutput "  ⚠️ Avertissements: $warnCount" "Yellow"
   Write-ColorOutput "  ⚠️ Ignorés: $skipCount" "Blue"
    
   return @{
      Pass = $passCount
      Fail = $failCount
      Warn = $warnCount
      Skip = $skipCount
   }
}

function Validate-Manager {
   param([string]$ManagerName)
    
   Write-ColorOutput "`n🔍 Validation du manager: $ManagerName" "Magenta"
   Write-ColorOutput "=" * 60 "Magenta"
    
   $allResults = @()
    
   # Tests de structure
   $structureResults = Test-ManagerStructure $ManagerName
   $allResults += $structureResults
    
   # Tests de compilation
   $compilationResults = Test-ManagerCompilation $ManagerName
   $allResults += $compilationResults
    
   # Tests d'exécution
   if (-not $Quick) {
      $testResults = Test-ManagerTests $ManagerName
      $allResults += $testResults
   }
    
   # Afficher les résultats
   $summary = Show-Results $allResults $ManagerName
    
   return $summary
}

function Validate-Ecosystem {
   Write-ColorOutput "🏗️ Validation de l'Écosystème des Managers" "Cyan"
   Write-ColorOutput "=" * 60 "Cyan"
   Write-ColorOutput "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Blue"
   Write-ColorOutput "Mode: $(if($Quick) { 'Quick' } else { 'Full' })" "Blue"
    
   $globalSummary = @{
      Pass = 0
      Fail = 0
      Warn = 0
      Skip = 0
   }
    
   # Test d'intégrité de l'écosystème
   $ecosystemResults = Test-EcosystemIntegrity
   $ecosystemSummary = Show-Results $ecosystemResults "Intégrité de l'Écosystème"
    
   $globalSummary.Pass += $ecosystemSummary.Pass
   $globalSummary.Fail += $ecosystemSummary.Fail
   $globalSummary.Warn += $ecosystemSummary.Warn
   $globalSummary.Skip += $ecosystemSummary.Skip
    
   # Tests des managers individuels
   foreach ($manager in $MANAGERS) {
      if ($Manager -and $manager -ne $Manager) {
         continue
      }
        
      $managerSummary = Validate-Manager $manager
        
      $globalSummary.Pass += $managerSummary.Pass
      $globalSummary.Fail += $managerSummary.Fail
      $globalSummary.Warn += $managerSummary.Warn
      $globalSummary.Skip += $managerSummary.Skip
   }
    
   # Résumé global
   Write-ColorOutput "`n🎯 RÉSUMÉ GLOBAL DE LA VALIDATION" "Cyan"
   Write-ColorOutput "=" * 60 "Cyan"
    
   $total = $globalSummary.Pass + $globalSummary.Fail + $globalSummary.Warn + $globalSummary.Skip
   $successRate = if ($total -gt 0) { [math]::Round(($globalSummary.Pass / $total) * 100, 1) } else { 0 }
    
   Write-ColorOutput "  📊 Tests totaux: $total" "Blue"
   Write-ColorOutput "  ✅ Réussis: $($globalSummary.Pass)" "Green"
   Write-ColorOutput "  ❌ Échecs: $($globalSummary.Fail)" "Red" 
   Write-ColorOutput "  ⚠️ Avertissements: $($globalSummary.Warn)" "Yellow"
   Write-ColorOutput "  ⚠️ Ignorés: $($globalSummary.Skip)" "Blue"
   Write-ColorOutput "  📈 Taux de réussite: $successRate%" $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })
    
   # Status final
   if ($globalSummary.Fail -eq 0) {
      Write-ColorOutput "`n🎉 VALIDATION RÉUSSIE! L'écosystème est opérationnel." "Green"
      exit 0
   }
   else {
      Write-ColorOutput "`n⚠️ VALIDATION ÉCHOUÉE! Des problèmes ont été détectés." "Red"
      exit 1
   }
}

# Point d'entrée principal
if ($Manager) {
   Validate-Manager $Manager
}
else {
   Validate-Ecosystem
}
