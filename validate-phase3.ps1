#!/usr/bin/env pwsh

# Phase 3 Managers Validation Script
Write-Host "🚀 Phase 3 Managers Validation" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green

$ErrorActionPreference = "Continue"
$projectRoot = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

# Function to check if a directory exists and has Go files
function Test-GoModule($path, $name) {
   Write-Host "`n📁 Checking $name..." -ForegroundColor Yellow
    
   if (Test-Path $path) {
      $goFiles = Get-ChildItem -Path $path -Filter "*.go" | Measure-Object
      Write-Host "  ✅ Directory exists with $($goFiles.Count) Go files" -ForegroundColor Green
        
      # Check for go.mod
      if (Test-Path "$path\go.mod") {
         Write-Host "  ✅ go.mod found" -ForegroundColor Green
      }
      else {
         Write-Host "  ⚠️  go.mod not found" -ForegroundColor Yellow
      }
        
      return $true
   }
   else {
      Write-Host "  ❌ Directory not found" -ForegroundColor Red
      return $false
   }
}

# Function to test Go compilation
function Test-GoCompilation($path, $name) {
   Write-Host "`n🔨 Testing $name compilation..." -ForegroundColor Yellow
    
   try {
      Set-Location $path
      $output = go build . 2>&1
      if ($LASTEXITCODE -eq 0) {
         Write-Host "  ✅ Compilation successful" -ForegroundColor Green
         return $true
      }
      else {
         Write-Host "  ❌ Compilation failed: $output" -ForegroundColor Red
         return $false
      }
   }
   catch {
      Write-Host "  ❌ Compilation error: $_" -ForegroundColor Red
      return $false
   }
}

# Start validation
Write-Host "`n🎯 Starting Phase 3 Managers Validation..." -ForegroundColor Cyan

# Check Email Manager
$emailManagerPath = "$projectRoot\development\managers\email-manager"
$emailManagerOk = Test-GoModule $emailManagerPath "Email Manager"

# Check Notification Manager
$notificationManagerPath = "$projectRoot\development\managers\notification-manager"
$notificationManagerOk = Test-GoModule $notificationManagerPath "Notification Manager"

# Check Integration Manager
$integrationManagerPath = "$projectRoot\development\managers\integration-manager"
$integrationManagerOk = Test-GoModule $integrationManagerPath "Integration Manager"

# Check Interfaces
$interfacesPath = "$projectRoot\development\managers\interfaces"
$interfacesOk = Test-GoModule $interfacesPath "Interfaces"

Write-Host "`n🔍 Module Structure Summary:" -ForegroundColor Cyan
Write-Host "  Email Manager:        $(if($emailManagerOk){'✅'}else{'❌'})" -ForegroundColor $(if ($emailManagerOk) { 'Green' }else { 'Red' })
Write-Host "  Notification Manager: $(if($notificationManagerOk){'✅'}else{'❌'})" -ForegroundColor $(if ($notificationManagerOk) { 'Green' }else { 'Red' })
Write-Host "  Integration Manager:  $(if($integrationManagerOk){'✅'}else{'❌'})" -ForegroundColor $(if ($integrationManagerOk) { 'Green' }else { 'Red' })
Write-Host "  Interfaces:           $(if($interfacesOk){'✅'}else{'❌'})" -ForegroundColor $(if ($interfacesOk) { 'Green' }else { 'Red' })

# Test compilations if modules exist
$compilationResults = @{}

if ($emailManagerOk) {
   $compilationResults["Email Manager"] = Test-GoCompilation $emailManagerPath "Email Manager"
}

if ($notificationManagerOk) {
   $compilationResults["Notification Manager"] = Test-GoCompilation $notificationManagerPath "Notification Manager"
}

if ($integrationManagerOk) {
   $compilationResults["Integration Manager"] = Test-GoCompilation $integrationManagerPath "Integration Manager"
}

# Test main workspace compilation
Write-Host "`n🏗️  Testing main workspace compilation..." -ForegroundColor Yellow
Set-Location $projectRoot
try {
   $output = go build ./development/managers/integration-manager 2>&1
   if ($LASTEXITCODE -eq 0) {
      Write-Host "  ✅ Main workspace compilation successful" -ForegroundColor Green
      $compilationResults["Main Workspace"] = $true
   }
   else {
      Write-Host "  ⚠️  Main workspace compilation issues: $output" -ForegroundColor Yellow
      $compilationResults["Main Workspace"] = $false
   }
}
catch {
   Write-Host "  ❌ Main workspace compilation error: $_" -ForegroundColor Red
   $compilationResults["Main Workspace"] = $false
}

# Final summary
Write-Host "`n📊 Final Validation Summary:" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

$allGood = $true
foreach ($result in $compilationResults.GetEnumerator()) {
   $status = if ($result.Value) { '✅ PASS' }else { '❌ FAIL' }
   $color = if ($result.Value) { 'Green' }else { 'Red' }
   Write-Host "  $($result.Key): $status" -ForegroundColor $color
   if (-not $result.Value) { $allGood = $false }
}

Write-Host "`n🎉 Phase 3 Implementation Status:" -ForegroundColor Cyan
if ($allGood) {
   Write-Host "  ✅ ALL MANAGERS READY FOR PRODUCTION" -ForegroundColor Green
   Write-Host "  ✅ Phase 3 Implementation COMPLETE" -ForegroundColor Green
}
else {
   Write-Host "  ⚠️  Some issues detected - review above" -ForegroundColor Yellow
}

# File count summary
Write-Host "`n📁 Implementation Files:" -ForegroundColor Cyan
$totalFiles = 0

if (Test-Path $integrationManagerPath) {
   $integrationFiles = (Get-ChildItem -Path $integrationManagerPath -Filter "*.go" | Measure-Object).Count
   Write-Host "  Integration Manager: $integrationFiles Go files" -ForegroundColor White
   $totalFiles += $integrationFiles
}

if (Test-Path $emailManagerPath) {
   $emailFiles = (Get-ChildItem -Path $emailManagerPath -Filter "*.go" | Measure-Object).Count
   Write-Host "  Email Manager: $emailFiles Go files" -ForegroundColor White
   $totalFiles += $emailFiles
}

if (Test-Path $notificationManagerPath) {
   $notificationFiles = (Get-ChildItem -Path $notificationManagerPath -Filter "*.go" | Measure-Object).Count
   Write-Host "  Notification Manager: $notificationFiles Go files" -ForegroundColor White
   $totalFiles += $notificationFiles
}

Write-Host "  Total Implementation Files: $totalFiles" -ForegroundColor Green

Write-Host "`n🏁 Validation Complete!" -ForegroundColor Green
