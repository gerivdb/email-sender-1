# Test script for Manager Toolkit
Write-Host "=== Testing Manager Toolkit Tools ===" -ForegroundColor Green

# Change to tools directory
Set-Location "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\tools"

# Test compilation
Write-Host "1. Testing compilation..." -ForegroundColor Yellow
$buildResult = & go build . 2>&1
if ($LASTEXITCODE -eq 0) {
   Write-Host "✅ Compilation successful" -ForegroundColor Green
}
else {
   Write-Host "❌ Compilation failed:" -ForegroundColor Red
   Write-Host $buildResult
   exit 1
}

# Test NewStructValidator function
Write-Host "2. Testing NewStructValidator function..." -ForegroundColor Yellow
$testResult = & go run test_run.go struct_validator.go manager_toolkit.go toolkit_core.go 2>&1
Write-Host $testResult

# Test specific test functions
Write-Host "3. Running unit tests..." -ForegroundColor Yellow
$testResult = & go test -run TestNewStructValidator -v 2>&1
Write-Host $testResult

Write-Host "=== Test Complete ===" -ForegroundColor Green
