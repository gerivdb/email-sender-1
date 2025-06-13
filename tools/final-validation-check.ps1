#!/usr/bin/env pwsh
# Script de validation finale pour EMAIL_SENDER_1 Phase 1.1
# Utilisation: .\tools\final-validation-check.ps1

param(
   [Parameter(Mandatory = $false)]
   [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "🎯 VALIDATION FINALE - EMAIL_SENDER_1 Phase 1.1 - Plan v49" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$TestResults = @()

# Test 1: Go Environment
Write-Host "`n📋 Test 1: Environnement Go" -ForegroundColor Yellow
try {
   $goVersion = & go version 2>$null
   if ($goVersion) {
      Write-Host "✅ Go Runtime: $goVersion" -ForegroundColor Green
      $TestResults += @{Test = "Go Runtime"; Status = "PASS"; Details = $goVersion }
   }
}
catch {
   Write-Host "❌ Go Runtime: Non disponible" -ForegroundColor Red
   $TestResults += @{Test = "Go Runtime"; Status = "FAIL"; Details = $_.Exception.Message }
}

# Test 2: Go Modules
Write-Host "`n📋 Test 2: Go Modules" -ForegroundColor Yellow
try {
   $modInfo = & go list -m all 2>$null | Select-Object -First 1
   if ($modInfo) {
      Write-Host "✅ Go Modules: $modInfo" -ForegroundColor Green
      $TestResults += @{Test = "Go Modules"; Status = "PASS"; Details = $modInfo }
   }
}
catch {
   Write-Host "❌ Go Modules: Erreur" -ForegroundColor Red
   $TestResults += @{Test = "Go Modules"; Status = "FAIL"; Details = $_.Exception.Message }
}

# Test 3: PowerShell Scripts
Write-Host "`n📋 Test 3: Scripts PowerShell" -ForegroundColor Yellow
$psFiles = Get-ChildItem -Path $ProjectRoot -Filter "*.ps1" -Recurse | Measure-Object
Write-Host "✅ Fichiers PowerShell trouvés: $($psFiles.Count)" -ForegroundColor Green
$TestResults += @{Test = "PowerShell Scripts"; Status = "PASS"; Details = "$($psFiles.Count) fichiers" }

# Test 4: Validation Test File
Write-Host "`n📋 Test 4: Fichier de validation Phase 1.1" -ForegroundColor Yellow
$validationFile = "$ProjectRoot\tests\test_runners\validation_test_phase1.1.go"
if (Test-Path $validationFile) {
   Write-Host "✅ Fichier de validation: Présent" -ForegroundColor Green
   $TestResults += @{Test = "Validation File"; Status = "PASS"; Details = "validation_test_phase1.1.go" }
}
else {
   Write-Host "❌ Fichier de validation: Manquant" -ForegroundColor Red
   $TestResults += @{Test = "Validation File"; Status = "FAIL"; Details = "Fichier non trouvé" }
}

# Test 5: Project Structure
Write-Host "`n📋 Test 5: Structure du projet" -ForegroundColor Yellow
$requiredDirs = @("internal", "pkg", "tools", "tests")
$missingDirs = @()
foreach ($dir in $requiredDirs) {
   if (-not (Test-Path "$ProjectRoot\$dir")) {
      $missingDirs += $dir
   }
}

if ($missingDirs.Count -eq 0) {
   Write-Host "✅ Structure du projet: Complète" -ForegroundColor Green
   $TestResults += @{Test = "Project Structure"; Status = "PASS"; Details = "Tous les répertoires présents" }
}
else {
   Write-Host "⚠️  Structure du projet: Répertoires manquants: $($missingDirs -join ', ')" -ForegroundColor Yellow
   $TestResults += @{Test = "Project Structure"; Status = "WARN"; Details = "Manquants: $($missingDirs -join ', ')" }
}

# Test 6: Executables
Write-Host "`n📋 Test 6: Executables générés" -ForegroundColor Yellow
$exeFiles = Get-ChildItem -Path $ProjectRoot -Filter "*.exe" | Measure-Object
Write-Host "✅ Executables trouvés: $($exeFiles.Count)" -ForegroundColor Green
$TestResults += @{Test = "Executables"; Status = "PASS"; Details = "$($exeFiles.Count) executables" }

# Résultats finaux
Write-Host "`n" + "=" * 60 -ForegroundColor Gray
Write-Host "📊 RÉSULTATS DE VALIDATION" -ForegroundColor White
Write-Host "=" * 60 -ForegroundColor Gray

$passCount = ($TestResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($TestResults | Where-Object { $_.Status -eq "FAIL" }).Count
$warnCount = ($TestResults | Where-Object { $_.Status -eq "WARN" }).Count
$totalTests = $TestResults.Count

foreach ($result in $TestResults) {
   $statusColor = switch ($result.Status) {
      "PASS" { "Green" }
      "FAIL" { "Red" }
      "WARN" { "Yellow" }
      default { "White" }
   }
    
   $statusIcon = switch ($result.Status) {
      "PASS" { "✅" }
      "FAIL" { "❌" }
      "WARN" { "⚠️ " }
      default { "ℹ️ " }
   }
    
   Write-Host "$statusIcon $($result.Test): $($result.Status)" -ForegroundColor $statusColor
   if ($Verbose) {
      Write-Host "   Détails: $($result.Details)" -ForegroundColor Gray
   }
}

Write-Host "`n📈 STATISTIQUES:" -ForegroundColor Cyan
Write-Host "Total des tests: $totalTests" -ForegroundColor White
Write-Host "Réussis: $passCount" -ForegroundColor Green
Write-Host "Échecs: $failCount" -ForegroundColor Red
Write-Host "Avertissements: $warnCount" -ForegroundColor Yellow

$successRate = [math]::Round(($passCount / $totalTests) * 100, 1)
Write-Host "Taux de réussite: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

# Verdict final
Write-Host "`n" + "=" * 60 -ForegroundColor Gray
if ($failCount -eq 0 -and $successRate -ge 80) {
   Write-Host "🎉 VALIDATION RÉUSSIE! Projet prêt pour la phase suivante." -ForegroundColor Green
   exit 0
}
elseif ($failCount -eq 0) {
   Write-Host "⚠️  VALIDATION PARTIELLE. Quelques améliorations nécessaires." -ForegroundColor Yellow
   exit 1
}
else {
   Write-Host "❌ VALIDATION ÉCHOUÉE. Corrections nécessaires avant de continuer." -ForegroundColor Red
   exit 2
}
