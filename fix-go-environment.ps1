#!/usr/bin/env pwsh

# Fix Go Environment Script
# Resolves Go toolchain issues by setting proper environment variables

Write-Host "🔧 Fixing Go Environment..." -ForegroundColor Yellow

# Get the proper Go installation path
$properGoRoot = "$env:USERPROFILE\sdk\go1.23.9"
$properGoPath = "$env:USERPROFILE\go"

Write-Host "   Setting GOROOT to: $properGoRoot" -ForegroundColor Cyan

# Set environment variables for current session
$env:GOROOT = $properGoRoot
$env:GOPATH = $properGoPath
$env:PATH = "$properGoRoot\bin;$env:PATH"

# Verify the settings
Write-Host "`n📋 Verifying Go Environment..." -ForegroundColor Yellow
Write-Host "   GOROOT: $(go env GOROOT)" -ForegroundColor Green
Write-Host "   GOPATH: $(go env GOPATH)" -ForegroundColor Green
Write-Host "   Go Version: $(go version)" -ForegroundColor Green

# Test build to ensure it works
Write-Host "`n🧪 Testing CLI Build..." -ForegroundColor Yellow
Push-Location "cmd\roadmap-cli"
try {
   go build -o roadmap-cli.exe
   if ($LASTEXITCODE -eq 0) {
      Write-Host "   ✅ CLI builds successfully with fixed environment" -ForegroundColor Green
   }
   else {
      Write-Host "   ❌ CLI build failed" -ForegroundColor Red
   }
}
finally {
   Pop-Location
}

Write-Host "`n🎯 To permanently fix VS Code environment:" -ForegroundColor Yellow
Write-Host "   1. Open VS Code Settings (Ctrl+,)" -ForegroundColor Cyan
Write-Host "   2. Search for 'go.goroot'" -ForegroundColor Cyan
Write-Host "   3. Set go.goroot to: $properGoRoot" -ForegroundColor Cyan
Write-Host "   4. Restart VS Code" -ForegroundColor Cyan

Write-Host "`n✅ Go environment fix complete!" -ForegroundColor Green
