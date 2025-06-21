# Phase 4 Monitoring Dashboard Test Script
# Script PowerShell pour tester le système de métriques et dashboard temps réel

param(
   [string]$Port = "8080",
   [string]$TestDuration = "60", # Durée en secondes
   [switch]$StartDashboard,
   [switch]$RunMetricsTest,
   [switch]$GenerateTestData,
   [switch]$Verbose
)

Write-Host "🚀 PHASE 4: MÉTRIQUES & MONITORING - Test Suite" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# Configuration
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$DashboardURL = "http://localhost:$Port"
$MetricsAPIURL = "$DashboardURL/api/metrics"
$StreamURL = "$DashboardURL/api/stream"
$HealthURL = "$DashboardURL/health"

function Write-TestHeader {
   param([string]$Title)
   Write-Host ""
   Write-Host "🔍 $Title" -ForegroundColor Cyan
   Write-Host ("=" * 50) -ForegroundColor Cyan
}

function Test-DashboardHealth {
   Write-TestHeader "Test de Santé du Dashboard"
    
   try {
      $response = Invoke-RestMethod -Uri $HealthURL -Method Get -TimeoutSec 5
        
      if ($response.status -eq "healthy") {
         Write-Host "✅ Dashboard is healthy" -ForegroundColor Green
         Write-Host "   Status: $($response.status)" -ForegroundColor Gray
         Write-Host "   Clients connectés: $($response.clients)" -ForegroundColor Gray
         Write-Host "   Timestamp: $($response.timestamp)" -ForegroundColor Gray
         return $true
      }
      else {
         Write-Host "⚠️  Dashboard status: $($response.status)" -ForegroundColor Yellow
         return $false
      }
   }
   catch {
      Write-Host "❌ Dashboard health check failed: $_" -ForegroundColor Red
      return $false
   }
}

function Test-MetricsAPI {
   Write-TestHeader "Test de l'API Métriques"
    
   try {
      $response = Invoke-RestMethod -Uri $MetricsAPIURL -Method Get -TimeoutSec 10
        
      Write-Host "✅ Metrics API is accessible" -ForegroundColor Green
        
      # Vérifier la structure de la réponse
      if ($response.statistics) {
         Write-Host "📊 Statistics found:" -ForegroundColor Blue
         Write-Host "   Total queries: $($response.statistics.total_queries)" -ForegroundColor Gray
         Write-Host "   AST queries: $($response.statistics.ast_queries)" -ForegroundColor Gray
         Write-Host "   RAG queries: $($response.statistics.rag_queries)" -ForegroundColor Gray
         Write-Host "   Hybrid queries: $($response.statistics.hybrid_queries)" -ForegroundColor Gray
      }
        
      if ($response.summary) {
         Write-Host "📋 Summary found:" -ForegroundColor Blue
         Write-Host "   Performance data: $(if($response.summary.performance) {'✅'} else {'❌'})" -ForegroundColor Gray
         Write-Host "   Optimization data: $(if($response.summary.optimization) {'✅'} else {'❌'})" -ForegroundColor Gray
         Write-Host "   Reliability data: $(if($response.summary.reliability) {'✅'} else {'❌'})" -ForegroundColor Gray
      }
        
      return $true
   }
   catch {
      Write-Host "❌ Metrics API test failed: $_" -ForegroundColor Red
      return $false
   }
}

function Test-StreamConnection {
   Write-TestHeader "Test de Connexion Stream"
    
   try {
      Write-Host "🔗 Testing Server-Sent Events connection..." -ForegroundColor Yellow
        
      # Test simple de connexion (sans parser le SSE complet)
      $webClient = New-Object System.Net.WebClient
      $webClient.Headers.Add("Accept", "text/event-stream")
      $webClient.Headers.Add("Cache-Control", "no-cache")
        
      $response = $webClient.DownloadString($StreamURL)
        
      Write-Host "✅ Stream connection successful" -ForegroundColor Green
      Write-Host "   Response received: $(($response.Length) bytes)" -ForegroundColor Gray
        
      return $true
   }
   catch {
      Write-Host "❌ Stream connection test failed: $_" -ForegroundColor Red
      return $false
   }
   finally {
      if ($webClient) {
         $webClient.Dispose()
      }
   }
}

function Start-HybridMetricsTest {
   Write-TestHeader "Test du Système de Métriques Hybrides"
    
   Write-Host "🧪 Running hybrid metrics tests..." -ForegroundColor Yellow
    
   try {
      $testArgs = @(
         "test"
         "./tests/monitoring"
         "-v"
         "-run=TestHybridMetricsCollector"
      )
        
      Write-Host "🏃‍♂️ Executing: go $($testArgs -join ' ')" -ForegroundColor Gray
      $result = & go @testArgs 2>&1
        
      if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ Hybrid metrics tests passed" -ForegroundColor Green
            
         # Analyser les résultats
         $passedTests = ($result | Select-String "PASS:").Count
         $failedTests = ($result | Select-String "FAIL:").Count
            
         Write-Host "📊 Test Results:" -ForegroundColor Blue
         Write-Host "   ✅ Passed: $passedTests" -ForegroundColor Green
         Write-Host "   ❌ Failed: $failedTests" -ForegroundColor Red
            
         if ($Verbose) {
            Write-Host "📝 Detailed output:" -ForegroundColor Gray
            $result | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
         }
            
         return $true
      }
      else {
         Write-Host "❌ Hybrid metrics tests failed" -ForegroundColor Red
         $result | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
         return $false
      }
   }
   catch {
      Write-Host "❌ Error running metrics tests: $_" -ForegroundColor Red
      return $false
   }
}

function Start-DashboardDemo {
   Write-TestHeader "Démarrage du Dashboard de Démonstration"
    
   Write-Host "🌐 Starting dashboard server..." -ForegroundColor Yellow
   Write-Host "   URL: $DashboardURL" -ForegroundColor Gray
   Write-Host "   Port: $Port" -ForegroundColor Gray
    
   try {
      # Compiler et démarrer le dashboard
      $buildArgs = @(
         "run"
         "./cmd/dashboard-demo"
         "-port=$Port"
      )
        
      Write-Host "🔨 Building and starting dashboard..." -ForegroundColor Yellow
      Write-Host "🏃‍♂️ Executing: go $($buildArgs -join ' ')" -ForegroundColor Gray
        
      # Démarrer en arrière-plan
      $process = Start-Process -FilePath "go" -ArgumentList $buildArgs -NoNewWindow -PassThru
        
      # Attendre un peu que le serveur démarre
      Start-Sleep -Seconds 3
        
      # Tester la connexion
      if (Test-DashboardHealth) {
         Write-Host "✅ Dashboard started successfully" -ForegroundColor Green
         Write-Host "🌐 Access dashboard at: $DashboardURL" -ForegroundColor Cyan
         Write-Host "📊 Metrics API at: $MetricsAPIURL" -ForegroundColor Cyan
         Write-Host "🔄 Stream API at: $StreamURL" -ForegroundColor Cyan
            
         Write-Host ""
         Write-Host "💡 Dashboard will run for $TestDuration seconds..." -ForegroundColor Yellow
         Write-Host "   Press Ctrl+C to stop early" -ForegroundColor Gray
            
         Start-Sleep -Seconds $TestDuration
            
         # Arrêter le processus
         if (!$process.HasExited) {
            $process.Kill()
            Write-Host "🛑 Dashboard stopped" -ForegroundColor Yellow
         }
            
         return $true
      }
      else {
         Write-Host "❌ Dashboard failed to start properly" -ForegroundColor Red
         if (!$process.HasExited) {
            $process.Kill()
         }
         return $false
      }
   }
   catch {
      Write-Host "❌ Error starting dashboard: $_" -ForegroundColor Red
      return $false
   }
}

function Generate-TestMetricsData {
   Write-TestHeader "Génération de Données de Test"
    
   Write-Host "📊 Generating test metrics data..." -ForegroundColor Yellow
    
   # Créer un script de génération de données
   $testDataScript = @"
package main

import (
    "context"
    "fmt"
    "math/rand"
    "time"

    "go.uber.org/zap"
    "github.com/contextual-memory-manager/internal/monitoring"
)

func main() {
    logger, _ := zap.NewProduction()
    collector := monitoring.NewHybridMetricsCollector(logger)
    
    modes := []string{"ast", "rag", "hybrid", "parallel"}
    
    fmt.Println("Generating test data for 30 seconds...")
    
    for i := 0; i < 1000; i++ {
        mode := modes[rand.Intn(len(modes))]
        duration := time.Duration(rand.Intn(500)+50) * time.Millisecond
        success := rand.Float64() > 0.1 // 90% success rate
        quality := rand.Float64()*0.4 + 0.6 // 0.6-1.0
        
        collector.RecordQuery(mode, duration, success, quality)
        
        // Simuler des hits de cache
        if rand.Float64() > 0.3 {
            collector.RecordCacheHit(mode, rand.Float64() > 0.2) // 80% hit rate
        }
        
        // Simuler l'utilisation mémoire
        if i % 10 == 0 {
            collector.RecordMemoryUsage(mode, int64(rand.Intn(10)*1024*1024))
        }
        
        time.Sleep(30 * time.Millisecond)
    }
    
    stats := collector.GetStatistics()
    fmt.Printf("Generated %d total queries\n", stats.TotalQueries)
}
"@

   $testDataPath = "$ProjectRoot/cmd/test-data-generator/main.go"
   $testDataScript | Out-File -FilePath $testDataPath -Encoding UTF8
    
   try {
      Write-Host "🏃‍♂️ Running test data generator..." -ForegroundColor Gray
      & go run $testDataPath
        
      Write-Host "✅ Test data generation completed" -ForegroundColor Green
      return $true
   }
   catch {
      Write-Host "❌ Error generating test data: $_" -ForegroundColor Red
      return $false
   }
   finally {
      # Nettoyer
      if (Test-Path $testDataPath) {
         Remove-Item $testDataPath -Force
      }
   }
}

function Run-ComprehensiveTest {
   Write-TestHeader "Test Complet du Système de Monitoring"
    
   $allTestsPassed = $true
    
   # 1. Tests des métriques
   if ($RunMetricsTest -or $true) {
      Write-Host "1️⃣ Testing metrics system..." -ForegroundColor Yellow
      $allTestsPassed = $allTestsPassed -and (Start-HybridMetricsTest)
   }
    
   # 2. Génération de données de test
   if ($GenerateTestData -or $true) {
      Write-Host "2️⃣ Generating test data..." -ForegroundColor Yellow
      $allTestsPassed = $allTestsPassed -and (Generate-TestMetricsData)
   }
    
   # 3. Test du dashboard
   if ($StartDashboard -or $true) {
      Write-Host "3️⃣ Testing dashboard..." -ForegroundColor Yellow
      $allTestsPassed = $allTestsPassed -and (Start-DashboardDemo)
   }
    
   return $allTestsPassed
}

# Exécution principale
$startTime = Get-Date

try {
   # Vérifier les prérequis
   Write-Host "🔧 Checking prerequisites..." -ForegroundColor Gray
    
   if (!(Get-Command go -ErrorAction SilentlyContinue)) {
      Write-Host "❌ Go is not installed or not in PATH" -ForegroundColor Red
      exit 1
   }
    
   # Exécuter selon les paramètres
   $success = $false
    
   if ($StartDashboard) {
      $success = Start-DashboardDemo
   }
   elseif ($RunMetricsTest) {
      $success = Start-HybridMetricsTest
   }
   elseif ($GenerateTestData) {
      $success = Generate-TestMetricsData
   }
   else {
      # Test complet par défaut
      $success = Run-ComprehensiveTest
   }
    
   $endTime = Get-Date
   $duration = $endTime - $startTime
    
   Write-Host ""
   Write-Host "🏁 PHASE 4 Monitoring Test Complete!" -ForegroundColor Green
   Write-Host "⏱️  Total execution time: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
    
   if ($success) {
      Write-Host "✅ All tests passed successfully!" -ForegroundColor Green
      Write-Host ""
      Write-Host "🌐 Dashboard URL: $DashboardURL" -ForegroundColor Cyan
      Write-Host "📊 Metrics API: $MetricsAPIURL" -ForegroundColor Cyan
      Write-Host "🔄 Stream API: $StreamURL" -ForegroundColor Cyan
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
