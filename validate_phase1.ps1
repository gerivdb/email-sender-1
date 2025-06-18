#!/usr/bin/env pwsh
# Phase 1 FMOUA Validation Script
# Validates completion of Phase 1: Core Framework requirements

Write-Host "=== FMOUA Phase 1 Validation ===" -ForegroundColor Cyan
Write-Host "Validating Core Framework implementation..." -ForegroundColor Yellow

# Check if Go is available
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
   Write-Host "❌ Go not found in PATH" -ForegroundColor Red
   exit 1
}

# Navigate to project root
Push-Location $PSScriptRoot

Write-Host "`n📦 Building FMOUA packages..." -ForegroundColor Yellow
$buildResult = go build ./pkg/fmoua/...
if ($LASTEXITCODE -ne 0) {
   Write-Host "❌ Build failed" -ForegroundColor Red
   Pop-Location
   exit 1
}
Write-Host "✅ Build successful" -ForegroundColor Green

Write-Host "`n🧪 Running core tests with coverage..." -ForegroundColor Yellow
$testResult = go test -v ./pkg/fmoua/core ./pkg/fmoua/types ./pkg/fmoua/interfaces -coverprofile=phase1_validation.out
if ($LASTEXITCODE -ne 0) {
   Write-Host "❌ Core tests failed" -ForegroundColor Red
   Pop-Location
   exit 1
}
Write-Host "✅ Core tests passed" -ForegroundColor Green

Write-Host "`n📊 Coverage Analysis..." -ForegroundColor Yellow
$coverageOutput = go tool cover -func=phase1_validation.out

# Parse coverage for core components
$coreCoverage = @{}
$coverageOutput | ForEach-Object {
   if ($_ -match "pkg/fmoua/(core|types|interfaces)/(\w+)\.go:(\w+)\s+(\d+\.\d+)%") {
      $package = $matches[1]
      $file = $matches[2]
      $function = $matches[3]
      $percentage = [float]$matches[4]
        
      if (-not $coreCoverage.ContainsKey($package)) {
         $coreCoverage[$package] = @{}
      }
      if (-not $coreCoverage[$package].ContainsKey($file)) {
         $coreCoverage[$package][$file] = @()
      }
      $coreCoverage[$package][$file] += @{Function = $function; Coverage = $percentage }
   }
}

# Display coverage results
Write-Host "`n📈 Coverage Results:" -ForegroundColor Cyan
$totalCoverage = 0
$totalFunctions = 0

foreach ($package in $coreCoverage.Keys) {
   Write-Host "  📦 $package package:" -ForegroundColor White
   foreach ($file in $coreCoverage[$package].Keys) {
      $fileCoverage = ($coreCoverage[$package][$file] | Measure-Object -Property Coverage -Average).Average
      Write-Host "    📄 $file.go: $($fileCoverage)%" -ForegroundColor $(if ($fileCoverage -ge 80) { "Green" } else { "Yellow" })
        
      $totalCoverage += $fileCoverage * $coreCoverage[$package][$file].Count
      $totalFunctions += $coreCoverage[$package][$file].Count
   }
}

$averageCoverage = $totalCoverage / $totalFunctions
Write-Host "`n🎯 Overall Core Coverage: $($averageCoverage.ToString("F1"))%" -ForegroundColor $(if ($averageCoverage -ge 80) { "Green" } else { "Yellow" })

Write-Host "`n🔍 Phase 1 Requirements Check:" -ForegroundColor Cyan

# Check file existence
$requiredFiles = @(
   "pkg/fmoua/core/config.go",
   "pkg/fmoua/core/orchestrator.go",
   "pkg/fmoua/types/config.go",
   "pkg/fmoua/interfaces/interfaces.go"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
   if (Test-Path $file) {
      Write-Host "  ✅ $file exists" -ForegroundColor Green
   }
   else {
      Write-Host "  ❌ $file missing" -ForegroundColor Red
      $missingFiles += $file
   }
}

# Check test files
$requiredTestFiles = @(
   "pkg/fmoua/core/config_test.go",
   "pkg/fmoua/core/orchestrator_test.go",
   "pkg/fmoua/types/config_test.go",
   "pkg/fmoua/interfaces/interfaces_test.go"
)

foreach ($file in $requiredTestFiles) {
   if (Test-Path $file) {
      Write-Host "  ✅ $file exists" -ForegroundColor Green
   }
   else {
      Write-Host "  ⚠️ $file missing" -ForegroundColor Yellow
   }
}

Write-Host "`n📋 Phase 1 Compliance Summary:" -ForegroundColor Cyan
Write-Host "  • Configuration YAML: $(if (Test-Path 'pkg/fmoua/core/config.go') { '✅' } else { '❌' })" -ForegroundColor White
Write-Host "  • Types & Interfaces: $(if ((Test-Path 'pkg/fmoua/types/config.go') -and (Test-Path 'pkg/fmoua/interfaces/interfaces.go')) { '✅' } else { '❌' })" -ForegroundColor White
Write-Host "  • MaintenanceOrchestrator: $(if (Test-Path 'pkg/fmoua/core/orchestrator.go') { '✅' } else { '❌' })" -ForegroundColor White
Write-Host "  • Test Coverage >80%: $(if ($averageCoverage -ge 80) { '✅' } else { '❌' })" -ForegroundColor White

if ($missingFiles.Count -eq 0 -and $averageCoverage -ge 80) {
   Write-Host "`n🎉 Phase 1 COMPLETE! All requirements satisfied." -ForegroundColor Green
   $exitCode = 0
}
else {
   Write-Host "`n⚠️ Phase 1 INCOMPLETE. Review requirements above." -ForegroundColor Yellow
   $exitCode = 1
}

Pop-Location
exit $exitCode
