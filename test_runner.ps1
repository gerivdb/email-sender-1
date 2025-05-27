#!/usr/bin/env pwsh

Write-Host "=== EMAIL_SENDER_1 Project Test Runner ===" -ForegroundColor Green

# Change to project directory
Set-Location "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

Write-Host "`n1. Checking Go version..." -ForegroundColor Yellow
go version

Write-Host "`n2. Verifying Go module..." -ForegroundColor Yellow
go mod verify

Write-Host "`n3. Downloading dependencies..." -ForegroundColor Yellow
go mod download

Write-Host "`n4. Building project..." -ForegroundColor Yellow
go build ./...

Write-Host "`n5. Running tests..." -ForegroundColor Yellow
go test ./... -v

Write-Host "`n6. Running tests with coverage..." -ForegroundColor Yellow
go test ./... -cover -coverprofile=coverage.out

Write-Host "`n7. Generating coverage report..." -ForegroundColor Yellow
go tool cover -html=coverage.out -o coverage.html

Write-Host "`nTest execution completed!" -ForegroundColor Green
