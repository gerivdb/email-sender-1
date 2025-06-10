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
   if ($metrics.status -eq "running") {
      Write-Host "✅ Metrics OK - Status: $($metrics.status)" -ForegroundColor Green
   }
   else {
      throw "Metrics check failed"
   }
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
   if ($response -eq "Commit intercepted and routed successfully") {
      Write-Host "✅ Feature commit intercepté avec succès" -ForegroundColor Green
   }
   else {
      throw "Feature commit failed: $response"
   }
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
         message   = "fix: resolve null pointer exception in validator"
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
   if ($response -eq "Commit intercepted and routed successfully") {
      Write-Host "✅ Fix commit intercepté avec succès" -ForegroundColor Green
   }
   else {
      throw "Fix commit failed: $response"
   }
}
catch {
   Write-Host "❌ Fix commit échoué: $_" -ForegroundColor Red
   exit 1
}
message   = "feat: add user profile management"
timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
author    = @{
   name  = "Dev Team"
   email = "dev@example.com"
}
added     = @("profile.go", "user_manager.go")
modified  = @("main.go")
}
)
repository = @{
   name      = "test-repo"
   full_name = "user/test-repo"
}
ref        = "refs/heads/main"
} | ConvertTo-Json -Depth 5

try {
   $response = Invoke-RestMethod -Uri "$ServerUrl/hooks/pre-commit" -Method POST -Body $featurePayload -ContentType "application/json"
   Write-Host "✅ Feature commit traité: $response" -ForegroundColor Green
}
catch {
   Write-Host "❌ Feature commit échoué: $_" -ForegroundColor Red
   exit 1
}

# Test 4: Critical Fix Commit
Write-Host "`n[TEST 4] Critical Fix Commit..." -ForegroundColor Yellow
$fixPayload = @{
   commits    = @(
      @{
         id        = "critical456"
         message   = "fix: urgent security vulnerability in authentication"
         timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
         author    = @{
            name  = "Security Team"
            email = "security@example.com"
         }
         modified  = @("auth.go", "security.go")
      }
   )
   repository = @{
      name      = "test-repo"
      full_name = "user/test-repo"
   }
   ref        = "refs/heads/main"
} | ConvertTo-Json -Depth 5

try {
   $response = Invoke-RestMethod -Uri "$ServerUrl/hooks/pre-commit" -Method POST -Body $fixPayload -ContentType "application/json"
   Write-Host "✅ Critical fix traité: $response" -ForegroundColor Green
}
catch {
   Write-Host "❌ Critical fix échoué: $_" -ForegroundColor Red
   exit 1
}

# Test 5: Documentation Commit
Write-Host "`n[TEST 5] Documentation Commit..." -ForegroundColor Yellow
$docsPayload = @{
   commits    = @(
      @{
         id        = "docs789"
         message   = "docs: update API documentation"
         timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
         author    = @{
            name  = "Doc Team"
            email = "docs@example.com"
         }
         modified  = @("README.md", "docs/api.md")
      }
   )
   repository = @{
      name      = "test-repo"
      full_name = "user/test-repo"
   }
   ref        = "refs/heads/main"
} | ConvertTo-Json -Depth 5

try {
   $response = Invoke-RestMethod -Uri "$ServerUrl/hooks/pre-commit" -Method POST -Body $docsPayload -ContentType "application/json"
   Write-Host "✅ Documentation commit traité: $response" -ForegroundColor Green
}
catch {
   Write-Host "❌ Documentation commit échoué: $_" -ForegroundColor Red
   exit 1
}

# Test 6: Post-commit Hook
Write-Host "`n[TEST 6] Post-commit Hook..." -ForegroundColor Yellow
try {
   $response = Invoke-RestMethod -Uri "$ServerUrl/hooks/post-commit" -Method POST -Body $featurePayload -ContentType "application/json"
   Write-Host "✅ Post-commit traité: $response" -ForegroundColor Green
}
catch {
   Write-Host "❌ Post-commit échoué: $_" -ForegroundColor Red
   exit 1
}

# Test 7: Invalid Payload
Write-Host "`n[TEST 7] Invalid Payload (should fail gracefully)..." -ForegroundColor Yellow
$invalidPayload = '{"invalid": "payload"}'
try {
   $response = Invoke-RestMethod -Uri "$ServerUrl/hooks/pre-commit" -Method POST -Body $invalidPayload -ContentType "application/json" -ErrorAction SilentlyContinue
   Write-Host "❌ Invalid payload accepté (ne devrait pas arriver)" -ForegroundColor Red
}
catch {
   if ($_.Exception.Response.StatusCode -eq 400) {
      Write-Host "✅ Invalid payload rejeté correctement (400 Bad Request)" -ForegroundColor Green
   }
   else {
      Write-Host "❌ Invalid payload - erreur inattendue: $_" -ForegroundColor Red
      exit 1
   }
}

Write-Host "`n=== TOUS LES TESTS SONT PASSÉS AVEC SUCCÈS ===" -ForegroundColor Green -BackgroundColor Black
Write-Host "Le Commit Interceptor fonctionne parfaitement ! 🎉" -ForegroundColor Cyan

# Vérification finale des métriques
Write-Host "`n[FINAL] Métriques finales..." -ForegroundColor Yellow
try {
   $finalMetrics = Invoke-RestMethod -Uri "$ServerUrl/metrics" -Method GET
   Write-Host "Status: $($finalMetrics.status)" -ForegroundColor Cyan
   Write-Host "Commits traités: $($finalMetrics.commits_processed)" -ForegroundColor Cyan
}
catch {
   Write-Host "Warning: Impossible de récupérer les métriques finales" -ForegroundColor Yellow
}

Write-Host "`nTests d'intégration terminés avec succès !" -ForegroundColor Green
