# Phase 3 Test Suite - Tests & Validation
# Script PowerShell pour exécuter la suite complète de tests de performance et d'intégration

param(
   [string]$TestType = "all", # all, performance, integration
   [switch]$Verbose,
   [switch]$Coverage,
   [string]$OutputDir = "./test-results"
)

Write-Host "🧪 PHASE 3: TESTS & VALIDATION - Starting Test Suite" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Configuration
$TestDir = "tests"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$TestDataDir = "$ProjectRoot/testdata"

# Créer le répertoire de sortie s'il n'existe pas
if (!(Test-Path $OutputDir)) {
   New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

function Write-TestHeader {
   param([string]$Title)
   Write-Host ""
   Write-Host "🔍 $Title" -ForegroundColor Cyan
   Write-Host ("=" * 50) -ForegroundColor Cyan
}

function Run-PerformanceTests {
   Write-TestHeader "Phase 3.1.1: Tests de Performance Comparative"
    
   Write-Host "⚡ Running AST vs RAG vs Hybrid benchmarks..." -ForegroundColor Yellow
    
   $benchmarkArgs = @(
      "test"
      "-bench=."
      "-benchmem"
      "-run=^$"
      "./tests/hybrid"
   )
    
   if ($Verbose) {
      $benchmarkArgs += "-v"
   }
    
   if ($Coverage) {
      $benchmarkArgs += "-cover"
      $benchmarkArgs += "-coverprofile=$OutputDir/performance_coverage.out"
   }
    
   try {
      Write-Host "🏃‍♂️ Executing: go $($benchmarkArgs -join ' ')" -ForegroundColor Gray
      $result = & go @benchmarkArgs 2>&1
        
      if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ Performance tests completed successfully" -ForegroundColor Green
         $result | Tee-Object -FilePath "$OutputDir/performance_results.txt"
            
         # Analyser les résultats de performance
         $astBench = $result | Select-String "BenchmarkASTSearch"
         $ragBench = $result | Select-String "BenchmarkRAGSearch"
         $hybridBench = $result | Select-String "BenchmarkHybridSearch"
            
         Write-Host ""
         Write-Host "📊 Performance Results Summary:" -ForegroundColor Blue
         if ($astBench) { Write-Host "  🔍 AST Search: $($astBench.Line)" -ForegroundColor White }
         if ($ragBench) { Write-Host "  📚 RAG Search: $($ragBench.Line)" -ForegroundColor White }
         if ($hybridBench) { Write-Host "  🔄 Hybrid Search: $($hybridBench.Line)" -ForegroundColor White }
            
      }
      else {
         Write-Host "❌ Performance tests failed" -ForegroundColor Red
         $result
         return $false
      }
   }
   catch {
      Write-Host "❌ Error running performance tests: $_" -ForegroundColor Red
      return $false
   }
    
   return $true
}

function Run-IntegrationTests {
   Write-TestHeader "Phase 3.1.2: Tests d'Intégration End-to-End"
    
   Write-Host "🔗 Running integration test suite..." -ForegroundColor Yellow
    
   $integrationArgs = @(
      "test"
      "./tests/integration"
      "-run=TestHybridIntegration"
   )
    
   if ($Verbose) {
      $integrationArgs += "-v"
   }
    
   if ($Coverage) {
      $integrationArgs += "-cover"
      $integrationArgs += "-coverprofile=$OutputDir/integration_coverage.out"
   }
    
   try {
      Write-Host "🏃‍♂️ Executing: go $($integrationArgs -join ' ')" -ForegroundColor Gray
      $result = & go @integrationArgs 2>&1
        
      if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ Integration tests completed successfully" -ForegroundColor Green
         $result | Tee-Object -FilePath "$OutputDir/integration_results.txt"
            
         # Analyser les résultats d'intégration
         $passed = ($result | Select-String "PASS").Count
         $failed = ($result | Select-String "FAIL").Count
            
         Write-Host ""
         Write-Host "📊 Integration Results Summary:" -ForegroundColor Blue
         Write-Host "  ✅ Passed: $passed" -ForegroundColor Green
         Write-Host "  ❌ Failed: $failed" -ForegroundColor Red
            
      }
      else {
         Write-Host "❌ Integration tests failed" -ForegroundColor Red
         $result
         return $false
      }
   }
   catch {
      Write-Host "❌ Error running integration tests: $_" -ForegroundColor Red
      return $false
   }
    
   return $true
}

function Run-QualityTests {
   Write-TestHeader "Tests de Qualité et Validation"
    
   Write-Host "🎯 Running quality validation tests..." -ForegroundColor Yellow
    
   $qualityArgs = @(
      "test"
      "./tests/hybrid"
      "-run=TestSearchQualityComparison"
   )
    
   if ($Verbose) {
      $qualityArgs += "-v"
   }
    
   try {
      Write-Host "🏃‍♂️ Executing: go $($qualityArgs -join ' ')" -ForegroundColor Gray
      $result = & go @qualityArgs 2>&1
        
      if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ Quality tests completed successfully" -ForegroundColor Green
         $result | Tee-Object -FilePath "$OutputDir/quality_results.txt"
      }
      else {
         Write-Host "❌ Quality tests failed" -ForegroundColor Red
         $result
         return $false
      }
   }
   catch {
      Write-Host "❌ Error running quality tests: $_" -ForegroundColor Red
      return $false
   }
    
   return $true
}

function Generate-TestReport {
   Write-TestHeader "Génération du Rapport de Test"
    
   $reportFile = "$OutputDir/phase3_test_report.md"
    
   $report = @"
# PHASE 3: TESTS & VALIDATION - Rapport d'Exécution

## 📅 Exécution du $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 🎯 Résumé des Tests

### Phase 3.1.1: Tests de Performance Comparative
- **Status**: $(if (Test-Path "$OutputDir/performance_results.txt") { "✅ COMPLETED" } else { "❌ FAILED" })
- **Fichier de résultats**: performance_results.txt

### Phase 3.1.2: Tests d'Intégration End-to-End  
- **Status**: $(if (Test-Path "$OutputDir/integration_results.txt") { "✅ COMPLETED" } else { "❌ FAILED" })
- **Fichier de résultats**: integration_results.txt

### Tests de Qualité
- **Status**: $(if (Test-Path "$OutputDir/quality_results.txt") { "✅ COMPLETED" } else { "❌ FAILED" })
- **Fichier de résultats**: quality_results.txt

## 📊 Métriques de Performance

"@

   if (Test-Path "$OutputDir/performance_results.txt") {
      $perfResults = Get-Content "$OutputDir/performance_results.txt"
      $report += @"

### Benchmarks
``````
$($perfResults -join "`n")
``````

"@
   }

   $report += @"

## 🔧 Configuration de Test
- **Type de test**: $TestType
- **Mode verbose**: $Verbose
- **Couverture de code**: $Coverage
- **Répertoire de sortie**: $OutputDir

## 📝 Recommandations

1. Analyser les résultats de performance pour identifier les goulots d'étranglement
2. Vérifier que tous les tests d'intégration passent
3. Surveiller la qualité des résultats de recherche
4. Optimiser les modes hybrides selon les métriques

---
*Rapport généré automatiquement par le script de test Phase 3*
"@

   $report | Out-File -FilePath $reportFile -Encoding UTF8
   Write-Host "📝 Rapport généré: $reportFile" -ForegroundColor Green
}

# Exécution principale
$startTime = Get-Date
$allTestsPassed = $true

try {
   # Vérifier les prérequis
   Write-Host "🔧 Checking prerequisites..." -ForegroundColor Gray
    
   if (!(Get-Command go -ErrorAction SilentlyContinue)) {
      Write-Host "❌ Go is not installed or not in PATH" -ForegroundColor Red
      exit 1
   }
    
   if (!(Test-Path $TestDataDir)) {
      Write-Host "⚠️  Test data directory not found, creating..." -ForegroundColor Yellow
      New-Item -ItemType Directory -Path $TestDataDir -Force | Out-Null
   }
    
   # Exécuter les tests selon le type spécifié
   switch ($TestType.ToLower()) {
      "performance" {
         $allTestsPassed = Run-PerformanceTests
      }
      "integration" {
         $allTestsPassed = Run-IntegrationTests
      }
      "quality" {
         $allTestsPassed = Run-QualityTests
      }
      "all" {
         $allTestsPassed = Run-PerformanceTests
         $allTestsPassed = $allTestsPassed -and (Run-IntegrationTests)
         $allTestsPassed = $allTestsPassed -and (Run-QualityTests)
      }
      default {
         Write-Host "❌ Invalid test type: $TestType. Use: all, performance, integration, quality" -ForegroundColor Red
         exit 1
      }
   }
    
   # Générer le rapport
   Generate-TestReport
    
   $endTime = Get-Date
   $duration = $endTime - $startTime
    
   Write-Host ""
   Write-Host "🏁 PHASE 3 Test Suite Complete!" -ForegroundColor Green
   Write-Host "⏱️  Total execution time: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
    
   if ($allTestsPassed) {
      Write-Host "✅ All tests passed successfully!" -ForegroundColor Green
      exit 0
   }
   else {
      Write-Host "❌ Some tests failed. Check the output above." -ForegroundColor Red
      exit 1
   }
}
catch {
   Write-Host "❌ Fatal error during test execution: $_" -ForegroundColor Red
   exit 1
}
