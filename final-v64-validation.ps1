#!/usr/bin/env pwsh
# final-v64-validation.ps1
# Validation finale complète du Plan de Développement v64

param(
   [switch]$Verbose = $false,
   [switch]$Full = $false,
   [string]$OutputPath = "V64_FINAL_VALIDATION_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
)

$ErrorActionPreference = "Continue"

Write-Host "=== VALIDATION FINALE PLAN V64 ===" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray

# Structure de résultats
$results = @{
   timestamp       = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffK"
   plan            = "v64"
   validation_type = "final"
   environment     = @{
      os                 = $env:OS
      go_version         = ""
      powershell_version = $PSVersionTable.PSVersion.ToString()
      workspace          = (Get-Location).Path
   }
   tests           = @()
   summary         = @{
      total_tests  = 0
      passed       = 0
      failed       = 0
      warnings     = 0
      success_rate = 0
   }
   recommendations = @()
}

function Add-TestResult {
   param(
      [string]$Name,
      [string]$Category,
      [string]$Status,
      [string]$Message,
      [array]$Details = @(),
      [string]$Criticality = "medium",
      [int]$Duration = 0
   )
    
   $test = @{
      name        = $Name
      category    = $Category
      status      = $Status
      message     = $Message
      details     = $Details
      criticality = $Criticality
      duration    = $Duration
      timestamp   = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffK"
   }
    
   $results.tests += $test
   $results.summary.total_tests++
    
   if ($Status -eq "PASS") {
      $results.summary.passed++
      Write-Host "✅ $Name" -ForegroundColor Green
   }
   elseif ($Status -eq "FAIL") {
      $results.summary.failed++
      Write-Host "❌ $Name" -ForegroundColor Red
   }
   else {
      $results.summary.warnings++
      Write-Host "⚠️ $Name" -ForegroundColor Yellow
   }
    
   if ($Verbose) {
      Write-Host "   $Message" -ForegroundColor Gray
      foreach ($detail in $Details) {
         Write-Host "   - $detail" -ForegroundColor DarkGray
      }
   }
}

# Test 1: Environnement Go
Write-Host "`n🔧 TESTS ENVIRONNEMENT" -ForegroundColor Yellow
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
   $goVersion = go version 2>$null
   if ($goVersion) {
      $results.environment.go_version = $goVersion
      Add-TestResult -Name "Go Environment" -Category "environment" -Status "PASS" -Message "Go installed: $goVersion" -Duration $stopwatch.ElapsedMilliseconds
   }
   else {
      Add-TestResult -Name "Go Environment" -Category "environment" -Status "FAIL" -Message "Go not found or not in PATH" -Criticality "high" -Duration $stopwatch.ElapsedMilliseconds
   }
}
catch {
   Add-TestResult -Name "Go Environment" -Category "environment" -Status "FAIL" -Message "Error checking Go: $($_.Exception.Message)" -Criticality "high" -Duration $stopwatch.ElapsedMilliseconds
}

# Test 2: Structure de base
$stopwatch.Restart()
$requiredPaths = @(
   "go.mod",
   "go.work",
   "pkg",
   "cmd",
   "projet/roadmaps/plans/consolidated/plan-dev-v64-correlation-avec-manager-go-existant.md"
)

$missingPaths = @()
$foundPaths = @()

foreach ($path in $requiredPaths) {
   if (Test-Path $path) {
      $foundPaths += $path
   }
   else {
      $missingPaths += $path
   }
}

if ($missingPaths.Count -eq 0) {
   Add-TestResult -Name "Project Structure" -Category "structure" -Status "PASS" -Message "All required paths found" -Details $foundPaths -Duration $stopwatch.ElapsedMilliseconds
}
else {
   Add-TestResult -Name "Project Structure" -Category "structure" -Status "FAIL" -Message "Missing required paths: $($missingPaths.Count)" -Details ("Missing: " + ($missingPaths -join ", ")) -Criticality "high" -Duration $stopwatch.ElapsedMilliseconds
}

# Test 3: Fichiers Go critiques du plan v64
$stopwatch.Restart()
$v64CriticalFiles = @(
   "pkg/config/deployment.go",
   "pkg/monitoring/prometheus_metrics.go",
   "pkg/logging/elk_exporter.go",
   "pkg/tracing/otel_tracing.go",
   "pkg/apigateway/oauth_jwt_auth.go",
   "pkg/tenant/rbac.go",
   "pkg/security/crypto_utils.go",
   "pkg/replication/replicator.go",
   "pkg/loadbalancer/failover.go",
   "pkg/orchestrator/job_orchestrator.go"
)

$foundV64Files = @()
$missingV64Files = @()

foreach ($file in $v64CriticalFiles) {
   if (Test-Path $file) {
      $foundV64Files += $file
   }
   else {
      $missingV64Files += $file
   }
}

$v64Completion = [math]::Round(($foundV64Files.Count / $v64CriticalFiles.Count) * 100, 2)

if ($v64Completion -ge 80) {
   Add-TestResult -Name "V64 Critical Files" -Category "implementation" -Status "PASS" -Message "V64 implementation: $v64Completion% complete ($($foundV64Files.Count)/$($v64CriticalFiles.Count))" -Details $foundV64Files -Duration $stopwatch.ElapsedMilliseconds
}
else {
   Add-TestResult -Name "V64 Critical Files" -Category "implementation" -Status "FAIL" -Message "V64 implementation incomplete: $v64Completion% ($($foundV64Files.Count)/$($v64CriticalFiles.Count))" -Details $missingV64Files -Criticality "high" -Duration $stopwatch.ElapsedMilliseconds
}

# Test 4: Go Module Tidy
Write-Host "`n🔨 TESTS BUILD & COMPILATION" -ForegroundColor Yellow
$stopwatch.Restart()

try {
   $tidyOutput = go mod tidy 2>&1
   $tidyExitCode = $LASTEXITCODE
   if ($tidyExitCode -eq 0) {
      Add-TestResult -Name "Go Mod Tidy" -Category "build" -Status "PASS" -Message "go mod tidy successful" -Duration $stopwatch.ElapsedMilliseconds
   }
   else {
      Add-TestResult -Name "Go Mod Tidy" -Category "build" -Status "FAIL" -Message "go mod tidy failed (exit code: $tidyExitCode)" -Details @($tidyOutput) -Criticality "high" -Duration $stopwatch.ElapsedMilliseconds
   }
}
catch {
   Add-TestResult -Name "Go Mod Tidy" -Category "build" -Status "FAIL" -Message "Error running go mod tidy: $($_.Exception.Message)" -Criticality "high" -Duration $stopwatch.ElapsedMilliseconds
}

# Test 5: Build sélectif des packages critiques
$stopwatch.Restart()
$buildablePackages = @("./pkg/config", "./pkg/monitoring", "./pkg/logging")
$buildResults = @()

foreach ($package in $buildablePackages) {
   if (Test-Path $package) {
      try {
         $buildOutput = go build $package 2>&1
         $buildExitCode = $LASTEXITCODE
         if ($buildExitCode -eq 0) {
            $buildResults += "✅ $package: OK"
         }
         else {
            $buildResults += "❌ $package: Failed ($buildExitCode)"
         }
      }
      catch {
         $buildResults += "❌ $package: Error ($($_.Exception.Message))"
      }
   }
   else {
      $buildResults += "⚠️ $package: Not found"
   }
}

$buildSuccessCount = ($buildResults | Where-Object { $_ -like "✅*" }).Count
$buildSuccessRate = [math]::Round(($buildSuccessCount / $buildablePackages.Count) * 100, 2)

if ($buildSuccessRate -ge 60) {
   Add-TestResult -Name "Package Build Test" -Category "build" -Status "PASS" -Message "Build success rate: $buildSuccessRate% ($buildSuccessCount/$($buildablePackages.Count))" -Details $buildResults -Duration $stopwatch.ElapsedMilliseconds
}
else {
   Add-TestResult -Name "Package Build Test" -Category "build" -Status "FAIL" -Message "Build success rate too low: $buildSuccessRate%" -Details $buildResults -Criticality "medium" -Duration $stopwatch.ElapsedMilliseconds
}

# Test 6: Documentation et rapports
Write-Host "`n📋 TESTS DOCUMENTATION" -ForegroundColor Yellow
$stopwatch.Restart()

$docFiles = @(
   "PLAN_V64_FINAL_VALIDATION_REPORT.md",
   "V64_REAL_VALIDATION_REPORT.md",
   "validation_final.json"
)

$foundDocs = @()
$missingDocs = @()

foreach ($doc in $docFiles) {
   if (Test-Path $doc) {
      $foundDocs += $doc
   }
   else {
      $missingDocs += $doc
   }
}

if ($missingDocs.Count -eq 0) {
   Add-TestResult -Name "Documentation Complete" -Category "documentation" -Status "PASS" -Message "All documentation files found" -Details $foundDocs -Duration $stopwatch.ElapsedMilliseconds
}
else {
   Add-TestResult -Name "Documentation Complete" -Category "documentation" -Status "WARN" -Message "Some documentation missing" -Details $missingDocs -Duration $stopwatch.ElapsedMilliseconds
}

# Test 7: Git Status
$stopwatch.Restart()
try {
   $gitBranch = git branch --show-current 2>$null
   $gitStatus = git status --porcelain 2>$null
    
   if ($gitBranch) {
      if ($gitStatus) {
         Add-TestResult -Name "Git Repository" -Category "vcs" -Status "WARN" -Message "On branch '$gitBranch' with uncommitted changes" -Details @("Uncommitted files: $($gitStatus.Count)") -Duration $stopwatch.ElapsedMilliseconds
      }
      else {
         Add-TestResult -Name "Git Repository" -Category "vcs" -Status "PASS" -Message "On branch '$gitBranch', clean working directory" -Duration $stopwatch.ElapsedMilliseconds
      }
   }
   else {
      Add-TestResult -Name "Git Repository" -Category "vcs" -Status "WARN" -Message "Not in a Git repository or Git not available" -Duration $stopwatch.ElapsedMilliseconds
   }
}
catch {
   Add-TestResult -Name "Git Repository" -Category "vcs" -Status "WARN" -Message "Error checking Git status: $($_.Exception.Message)" -Duration $stopwatch.ElapsedMilliseconds
}

# Calcul des statistiques finales
$results.summary.success_rate = [math]::Round(($results.summary.passed / $results.summary.total_tests) * 100, 2)

# Recommandations basées sur les résultats
if ($results.summary.success_rate -ge 90) {
   $results.recommendations += "✅ Plan v64: VALIDATION RÉUSSIE - Prêt pour finalisation"
}
elseif ($results.summary.success_rate -ge 70) {
   $results.recommendations += "⚠️ Plan v64: VALIDATION PARTIELLE - Corrections mineures nécessaires"
   $results.recommendations += "🔧 Corriger les échecs de build et tests manquants"
}
else {
   $results.recommendations += "❌ Plan v64: VALIDATION ÉCHOUÉE - Corrections majeures requises"
   $results.recommendations += "🔧 Réviser l'implémentation et l'environnement de développement"
}

# Tests spécifiques si demandé
if ($Full) {
   Write-Host "`n🧪 TESTS ÉTENDUS" -ForegroundColor Yellow
    
   # Compte des fichiers Go
   $stopwatch.Restart()
   try {
      $goFiles = Get-ChildItem -Recurse -Filter "*.go" | Measure-Object
      Add-TestResult -Name "Go Files Count" -Category "metrics" -Status "PASS" -Message "Found $($goFiles.Count) Go files in project" -Duration $stopwatch.ElapsedMilliseconds
   }
   catch {
      Add-TestResult -Name "Go Files Count" -Category "metrics" -Status "WARN" -Message "Could not count Go files" -Duration $stopwatch.ElapsedMilliseconds
   }
    
   # Vérification des dépendances
   $stopwatch.Restart()
   try {
      $modCheck = go list -m all 2>$null
      if ($modCheck) {
         $depCount = ($modCheck | Measure-Object).Count
         Add-TestResult -Name "Dependencies Check" -Category "dependencies" -Status "PASS" -Message "Found $depCount dependencies" -Duration $stopwatch.ElapsedMilliseconds
      }
      else {
         Add-TestResult -Name "Dependencies Check" -Category "dependencies" -Status "WARN" -Message "Could not list dependencies" -Duration $stopwatch.ElapsedMilliseconds
      }
   }
   catch {
      Add-TestResult -Name "Dependencies Check" -Category "dependencies" -Status "WARN" -Message "Error checking dependencies: $($_.Exception.Message)" -Duration $stopwatch.ElapsedMilliseconds
   }
}

# Affichage du résumé final
Write-Host "`n📊 RÉSUMÉ FINAL" -ForegroundColor Cyan
Write-Host "Tests totaux: $($results.summary.total_tests)" -ForegroundColor White
Write-Host "Réussis: $($results.summary.passed)" -ForegroundColor Green
Write-Host "Échoués: $($results.summary.failed)" -ForegroundColor Red
Write-Host "Avertissements: $($results.summary.warnings)" -ForegroundColor Yellow
Write-Host "Taux de réussite: $($results.summary.success_rate)%" -ForegroundColor $(if ($results.summary.success_rate -ge 80) { "Green" } elseif ($results.summary.success_rate -ge 60) { "Yellow" } else { "Red" })

Write-Host "`n🎯 RECOMMANDATIONS:" -ForegroundColor Cyan
foreach ($rec in $results.recommendations) {
   Write-Host "  $rec" -ForegroundColor White
}

# Sauvegarde des résultats
try {
   $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
   Write-Host "`n💾 Résultats sauvegardés: $OutputPath" -ForegroundColor Green
}
catch {
   Write-Host "`n❌ Erreur sauvegarde: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== VALIDATION TERMINÉE ===" -ForegroundColor Cyan

# Code de sortie basé sur les résultats
if ($results.summary.success_rate -ge 80) {
   exit 0
}
else {
   exit 1
}
