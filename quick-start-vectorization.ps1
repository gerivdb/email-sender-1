#!/usr/bin/env pwsh
# Quick Start Guide for Go Vector Migration Tools
# This script helps you get started with the Go native vectorization tools

Write-Host "🚀 Go Vector Migration Tools - Quick Start" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Check if Makefile exists
if (!(Test-Path "Makefile")) {
   Write-Host "❌ Makefile not found. Please run this script from the project root." -ForegroundColor Red
   exit 1
}

# Create necessary directories
Write-Host "📁 Creating necessary directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "bin" | Out-Null
New-Item -ItemType Directory -Force -Path "reports" | Out-Null
New-Item -ItemType Directory -Force -Path "backups" | Out-Null

Write-Host "✅ Directories created successfully" -ForegroundColor Green

# Build the tools
Write-Host "🔨 Building vector migration tools..." -ForegroundColor Yellow
try {
   & make vector-tools
   Write-Host "✅ Vector tools built successfully" -ForegroundColor Green
}
catch {
   Write-Host "❌ Failed to build vector tools: $_" -ForegroundColor Red
   exit 1
}

# Check if Qdrant is running
Write-Host "🔍 Checking Qdrant connection..." -ForegroundColor Yellow
try {
   $response = Invoke-WebRequest -Uri "http://localhost:6333/health" -TimeoutSec 5 -ErrorAction SilentlyContinue
   if ($response.StatusCode -eq 200) {
      Write-Host "✅ Qdrant is running and accessible" -ForegroundColor Green
   }
   else {
      Write-Host "⚠️  Qdrant may not be running (status: $($response.StatusCode))" -ForegroundColor Yellow
   }
}
catch {
   Write-Host "⚠️  Qdrant not accessible. Please ensure Qdrant is running on localhost:6333" -ForegroundColor Yellow
   Write-Host "   Start Qdrant with: docker run -p 6333:6333 qdrant/qdrant" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🎯 Available Commands:" -ForegroundColor Blue
Write-Host "=====================" -ForegroundColor Blue
Write-Host ""

Write-Host "📦 Build commands:" -ForegroundColor White
Write-Host "  make vector-tools        # Build all vector tools" -ForegroundColor Cyan
Write-Host "  make vector-migrate      # Build migration tool only" -ForegroundColor Cyan
Write-Host "  make vector-benchmark    # Build benchmark tool only" -ForegroundColor Cyan
Write-Host ""

Write-Host "🧪 Test commands:" -ForegroundColor White
Write-Host "  make vector-test         # Run vector package tests" -ForegroundColor Cyan
Write-Host "  go test ./pkg/vectorization/... -v" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚡ Migration commands:" -ForegroundColor White
Write-Host "  # Create collection" -ForegroundColor Gray
Write-Host "  ./bin/vector-migration -action migrate-collection -collection tasks_v1" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Vectorize markdown files" -ForegroundColor Gray
Write-Host "  ./bin/vector-migration -action vectorize -input ./roadmaps -collection tasks_v1 -verbose" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Validate vectorization" -ForegroundColor Gray
Write-Host "  ./bin/vector-migration -action validate -input ./roadmaps -collection tasks_v1 -output reports/validation.json" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Check consistency" -ForegroundColor Gray
Write-Host "  ./bin/vector-migration -action check -collection tasks_v1" -ForegroundColor Cyan
Write-Host ""

Write-Host "📊 Benchmark commands:" -ForegroundColor White
Write-Host "  # Basic benchmark" -ForegroundColor Gray
Write-Host "  ./bin/vector-benchmark -vectors 1000 -iterations 100" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Comprehensive benchmark with report" -ForegroundColor Gray
Write-Host "  ./bin/vector-benchmark -vectors 5000 -iterations 50 -parallel 4 -output reports/benchmark.json" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔧 Makefile shortcuts:" -ForegroundColor White
Write-Host "  make vector-run-migration    # Quick migration run" -ForegroundColor Cyan
Write-Host "  make vector-run-validation   # Quick validation run" -ForegroundColor Cyan
Write-Host "  make vector-run-benchmark    # Quick benchmark run" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Configuration:" -ForegroundColor White
Write-Host "  Config file: config/vector.json" -ForegroundColor Cyan
Write-Host "  Edit this file to customize Qdrant connection, collection names, etc." -ForegroundColor Gray
Write-Host ""

Write-Host "📚 Help:" -ForegroundColor White
Write-Host "  ./bin/vector-migration -action help     # Show migration tool help" -ForegroundColor Cyan
Write-Host "  ./bin/vector-benchmark -help            # Show benchmark tool help" -ForegroundColor Cyan
Write-Host ""

Write-Host "🎉 Ready to go! Start with creating a collection:" -ForegroundColor Green
Write-Host "   ./bin/vector-migration -action migrate-collection -collection my_test_collection" -ForegroundColor White

# Optional: Run a quick test
$response = Read-Host "`n❓ Would you like to run a quick test? (y/N)"
if ($response -eq "y" -or $response -eq "Y") {
   Write-Host "`n🧪 Running quick test..." -ForegroundColor Yellow
    
   try {
      # Test vector generation
      Write-Host "Testing vector generation..." -ForegroundColor Gray
      & go test ./pkg/vectorization -run TestGenerateTestVectors -v
        
      Write-Host "✅ Quick test completed successfully!" -ForegroundColor Green
   }
   catch {
      Write-Host "❌ Quick test failed: $_" -ForegroundColor Red
   }
}

Write-Host "`n🔗 Related Documentation:" -ForegroundColor Blue
Write-Host "  - audit-vectorization-v56.md    # Migration audit results" -ForegroundColor Cyan
Write-Host "  - plan-dev-v56.md               # Migration plan and specifications" -ForegroundColor Cyan
Write-Host "  - README-UnixCommands.md        # Unix commands support in PowerShell" -ForegroundColor Cyan

Write-Host "`n✨ Happy vectorizing! ✨" -ForegroundColor Green
