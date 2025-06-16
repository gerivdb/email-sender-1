#!/usr/bin/env pwsh
# FMOUA Phase 1 Final Status Script
# Quick validation that Phase 1 is complete and ready

Write-Host "🎯 FMOUA Phase 1: Core Framework - Final Status Check" -ForegroundColor Cyan

# Test core components
Write-Host "`n🧪 Testing Core Framework..." -ForegroundColor Yellow
$testOutput = go test ./pkg/fmoua/core ./pkg/fmoua/types ./pkg/fmoua/interfaces -short -v 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ ALL TESTS PASSED" -ForegroundColor Green
    
    # Count tests
    $passedTests = ($testOutput | Select-String "--- PASS:").Count
    $skippedTests = ($testOutput | Select-String "--- SKIP:").Count
    
    Write-Host "   📊 Tests Passed: $passedTests" -ForegroundColor Green
    if ($skippedTests -gt 0) {
        Write-Host "   ⏭️  Tests Skipped: $skippedTests (advanced scenarios)" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ TESTS FAILED" -ForegroundColor Red
    Write-Host $testOutput
    exit 1
}

# Check coverage
Write-Host "`n📈 Coverage Analysis..." -ForegroundColor Yellow
$coverageInfo = $testOutput | Select-String "coverage: .* of statements"
if ($coverageInfo) {
    $coverage = $coverageInfo | ForEach-Object { $_.ToString() }
    Write-Host "   📊 $coverage" -ForegroundColor Green
}

# Verify file structure
Write-Host "`n📁 Core Files Verification..." -ForegroundColor Yellow
$coreFiles = @(
    "pkg/fmoua/core/config.go",
    "pkg/fmoua/core/orchestrator.go", 
    "pkg/fmoua/types/config.go",
    "pkg/fmoua/interfaces/interfaces.go"
)

$allFilesExist = $true
foreach ($file in $coreFiles) {
    if (Test-Path $file) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file MISSING" -ForegroundColor Red
        $allFilesExist = $false
    }
}

Write-Host "`n🎉 PHASE 1 STATUS: " -NoNewline -ForegroundColor Cyan
if ($allFilesExist -and $LASTEXITCODE -eq 0) {
    Write-Host "COMPLETE ✅" -ForegroundColor Green
    Write-Host "Ready for Phase 2: Manager Integration and AI Enhancement" -ForegroundColor Yellow
} else {
    Write-Host "INCOMPLETE ❌" -ForegroundColor Red
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Review Phase 1 completion report: PHASE1_COMPLETION_REPORT.md" -ForegroundColor White
Write-Host "   2. Begin Phase 2 planning and implementation" -ForegroundColor White
Write-Host "   3. Continue with manager integration features" -ForegroundColor White
