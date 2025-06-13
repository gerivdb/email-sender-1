# PowerShell script to run validation tests and check status
$ErrorActionPreference = "Continue"

Write-Host "🧪 JULES BOT VALIDATION TEST RUNNER" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Set working directory
$projectRoot = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
Set-Location $projectRoot

Write-Host "📍 Working directory: $projectRoot" -ForegroundColor Yellow
Write-Host ""

# Test 1: Basic Go functionality
Write-Host "1️⃣ Testing basic Go functionality..." -ForegroundColor Green
try {
   $output = & go version 2>&1
   Write-Host "✅ Go version: $output" -ForegroundColor Green
}
catch {
   Write-Host "❌ Go not working: $_" -ForegroundColor Red
   exit 1
}

# Test 2: Module status
Write-Host ""
Write-Host "2️⃣ Checking module status..." -ForegroundColor Green
try {
   & go mod tidy
   Write-Host "✅ Module tidy successful" -ForegroundColor Green
}
catch {
   Write-Host "❌ Module tidy failed: $_" -ForegroundColor Red
}

# Test 3: Basic compilation
Write-Host ""
Write-Host "3️⃣ Testing basic compilation..." -ForegroundColor Green
$basicTestContent = @"
package main
import "fmt"
func main() { fmt.Println("Basic test successful!") }
"@

$basicTestContent | Out-File -FilePath "basic_test_temp.go" -Encoding UTF8

try {
   $result = & go run basic_test_temp.go 2>&1
   Write-Host "✅ Basic compilation: $result" -ForegroundColor Green
}
catch {
   Write-Host "❌ Basic compilation failed: $_" -ForegroundColor Red
}
finally {
   Remove-Item "basic_test_temp.go" -Force -ErrorAction SilentlyContinue
}

# Test 4: Tools module check
Write-Host ""
Write-Host "4️⃣ Checking tools module..." -ForegroundColor Green
$toolsPath = "$projectRoot\development\managers\tools"
if (Test-Path $toolsPath) {
   Write-Host "✅ Tools directory exists" -ForegroundColor Green
   Set-Location $toolsPath
   try {
      & go mod tidy
      & go build ./...
      Write-Host "✅ Tools module builds successfully" -ForegroundColor Green
   }
   catch {
      Write-Host "❌ Tools module build failed: $_" -ForegroundColor Red
   }
   Set-Location $projectRoot
}
else {
   Write-Host "❌ Tools directory not found" -ForegroundColor Red
}

# Test 5: Validation tests
Write-Host ""
Write-Host "5️⃣ Running validation tests..." -ForegroundColor Green
$validationPath = "$projectRoot\tests\validation"
if (Test-Path $validationPath) {
   Set-Location $validationPath
   try {
      & go mod tidy
      $testResult = & go test -v 2>&1
      Write-Host "Test output: $testResult" -ForegroundColor Cyan
      if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ Validation tests passed!" -ForegroundColor Green
      }
      else {
         Write-Host "❌ Validation tests failed with exit code: $LASTEXITCODE" -ForegroundColor Red
      }
   }
   catch {
      Write-Host "❌ Validation test execution failed: $_" -ForegroundColor Red
   }
   Set-Location $projectRoot
}
else {
   Write-Host "❌ Validation test directory not found" -ForegroundColor Red
}

# Test 6: Test runners
Write-Host ""
Write-Host "6️⃣ Checking test runners..." -ForegroundColor Green
$testRunnersPath = "$projectRoot\tests\test_runners"
if (Test-Path $testRunnersPath) {
   Set-Location $testRunnersPath
   try {
      & go mod tidy
      $testResult = & go test -v 2>&1
      Write-Host "Test runners output: $testResult" -ForegroundColor Cyan
      if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ Test runners passed!" -ForegroundColor Green
      }
      else {
         Write-Host "❌ Test runners failed with exit code: $LASTEXITCODE" -ForegroundColor Red
      }
   }
   catch {
      Write-Host "❌ Test runners execution failed: $_" -ForegroundColor Red
   }
   Set-Location $projectRoot
}
else {
   Write-Host "❌ Test runners directory not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 VALIDATION COMPLETE" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host "Check the output above for detailed results." -ForegroundColor Yellow
