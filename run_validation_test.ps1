# PowerShell script to run validation tests
Set-Location "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
Write-Host "Running Go validation tests..." -ForegroundColor Green

# Test compilation first
Write-Host "Testing compilation..." -ForegroundColor Yellow
go build -v ./tests/test_runners/

if ($LASTEXITCODE -eq 0) {
   Write-Host "Compilation successful!" -ForegroundColor Green
    
   # Run the specific validation test
   Write-Host "Running validation tests..." -ForegroundColor Yellow
   go test ./tests/test_runners/ -v -run TestValidationPhase1_1
    
   if ($LASTEXITCODE -eq 0) {
      Write-Host "Tests completed successfully!" -ForegroundColor Green
   }
   else {
      Write-Host "Tests failed with exit code: $LASTEXITCODE" -ForegroundColor Red
   }
}
else {
   Write-Host "Compilation failed with exit code: $LASTEXITCODE" -ForegroundColor Red
}
