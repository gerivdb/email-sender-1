#!/usr/bin/env pwsh

Write-Host "Testing roadmap-cli TUI views..." -ForegroundColor Green

# Test 1: List view (default)
Write-Host "`n=== Testing List View ===" -ForegroundColor Yellow
"q" | .\roadmap-cli.exe view

# Test 2: Timeline view  
Write-Host "`n=== Testing Timeline View ===" -ForegroundColor Yellow
"v`nq" | .\roadmap-cli.exe view

# Test 3: Kanban view
Write-Host "`n=== Testing Kanban View ===" -ForegroundColor Yellow  
"v`nv`nq" | .\roadmap-cli.exe view

Write-Host "`nAll tests completed!" -ForegroundColor Green
