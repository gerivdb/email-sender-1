#!/usr/bin/env pwsh
# integration-tests.ps1 - Tests d'intégration pour le Commit Interceptor

param(
   [string]$ServerUrl = "http://localhost:8080",
   [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== TESTS D'INTÉGRATION COMMIT INTERCEPTOR ===" -ForegroundColor Green
Write-Host "URL du serveur: $ServerUrl" -ForegroundColor Cyan

# Test 1: Health Check
Write-Host "`n[TEST 1] Health Check..." -ForegroundColor Yellow
try {
   $response = Invoke-RestMethod -Uri "$ServerUrl/health" -Method GET
   if ($response -eq "OK") {
      Write-Host "✅ Health check réussi" -ForegroundColor Green
   }
   else {
      throw "Health check failed: $response"
   }
}
catch {
   Write-Host "❌ Health check échoué: $_" -ForegroundColor Red
   exit 1
}

# Test 2: Metrics
Write-Host "`n[TEST 2] Metrics..." -ForegroundColor Yellow
try {
   $metrics = Invoke-RestMethod -Uri "$ServerUrl/metrics" -Method GET
   Write-Host "✅ Metrics OK - Status: $($metrics.status)" -ForegroundColor Green
}
catch {
   Write-Host "❌ Metrics échoué: $_" -ForegroundColor Red
   exit 1
}

# Test 3: Feature Commit (Security)
Write-Host "`n[TEST 3] Feature Commit (Authentication)..." -ForegroundColor Yellow
$featurePayload = @{
   commits    = @(
      @{
         id        = "feat123"
         message   = "feat: add user authentication system"
         timestamp = "2025-06-10T15:00:00Z"
         author    = @{
            name  = "Test User"
            email = "test@example.com"
         }
         added     = @("src/auth.go")
         removed   = @()
         modified  = @("src/main.go")
      }
   )
   repository = @{
      name      = "test-repo"
      full_name = "user/test-repo"
   }
   ref        = "refs/heads/main"
} | ConvertTo-Json -Depth 5

try {
   $response = Invoke-RestMethod -Uri "$ServerUrl/hooks/pre-commit" -Method POST -ContentType "application/json" -Body $featurePayload
   Write-Host "✅ Feature commit intercepté: $response" -ForegroundColor Green
}
catch {
   Write-Host "❌ Feature commit échoué: $_" -ForegroundColor Red
   exit 1
}

# Test 4: Fix Commit
Write-Host "`n[TEST 4] Fix Commit..." -ForegroundColor Yellow
$fixPayload = @{
   commits    = @(
      @{
         id        = "fix456"
         message   = "fix: resolve null pointer exception"
         timestamp = "2025-06-10T15:05:00Z"
         author    = @{
            name  = "Test User"
            email = "test@example.com"
         }
         added     = @()
         removed   = @()
         modified  = @("src/validator.go")
      }
   )
   repository = @{
      name      = "test-repo"
      full_name = "user/test-repo"
   }
   ref        = "refs/heads/main"
} | ConvertTo-Json -Depth 5

try {
   $response = Invoke-RestMethod -Uri "$ServerUrl/hooks/pre-commit" -Method POST -ContentType "application/json" -Body $fixPayload
   Write-Host "✅ Fix commit intercepté: $response" -ForegroundColor Green
}
catch {
   Write-Host "❌ Fix commit échoué: $_" -ForegroundColor Red
   exit 1
}

# Test 5: Docs Commit  
Write-Host "`n[TEST 5] Documentation Commit..." -ForegroundColor Yellow
$docsPayload = @{
   commits    = @(
      @{
         id        = "docs789"
         message   = "docs: update API documentation"
         timestamp = "2025-06-10T15:10:00Z"
         author    = @{
            name  = "Test User"
            email = "test@example.com"
         }
         added     = @("docs/api.md")
         removed   = @()
         modified  = @("README.md")
      }
   )
   repository = @{
      name      = "test-repo"  
      full_name = "user/test-repo"
   }
   ref        = "refs/heads/main"
} | ConvertTo-Json -Depth 5

try {
   $response = Invoke-RestMethod -Uri "$ServerUrl/hooks/pre-commit" -Method POST -ContentType "application/json" -Body $docsPayload
   Write-Host "✅ Docs commit intercepté: $response" -ForegroundColor Green
}
catch {
   Write-Host "❌ Docs commit échoué: $_" -ForegroundColor Red
   exit 1
}

# Test 6: Refactor Commit (High Impact)
Write-Host "`n[TEST 6] Refactor Commit (High Impact)..." -ForegroundColor Yellow
$refactorPayload = @{
   commits    = @(
      @{
         id        = "refactor012"
         message   = "refactor: restructure database connection pool"
         timestamp = "2025-06-10T15:15:00Z"
         author    = @{
            name  = "Test User"
            email = "test@example.com"
         }
         added     = @("src/db/pool_manager.go")
         removed   = @("src/db/old_connection.go")
         modified  = @("src/db/connection.go", "src/db/config.go", "src/main.go", "tests/db_test.go")
      }
   )
   repository = @{
      name      = "test-repo"
      full_name = "user/test-repo"
   }
   ref        = "refs/heads/main"
} | ConvertTo-Json -Depth 5

try {
   $response = Invoke-RestMethod -Uri "$ServerUrl/hooks/pre-commit" -Method POST -ContentType "application/json" -Body $refactorPayload
   Write-Host "✅ Refactor commit intercepté: $response" -ForegroundColor Green
}
catch {
   Write-Host "❌ Refactor commit échoué: $_" -ForegroundColor Red
   exit 1
}

Write-Host "`n=== TOUS LES TESTS RÉUSSIS ✅ ===" -ForegroundColor Green
Write-Host "Le Commit Interceptor fonctionne parfaitement !" -ForegroundColor Cyan
