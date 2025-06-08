#!/usr/bin/env pwsh
# Script final d'optimisation pour EMAIL_SENDER_1
# Utilisation: .\complete-optimization.ps1

$ErrorActionPreference = "Stop"

Write-Host "🚀 OPTIMISATION FINALE - EMAIL_SENDER_1" -ForegroundColor Green
Write-Host "Lancement des méthodes time-saving..." -ForegroundColor Cyan

$ProjectRoot = $PWD

# Application des méthodes time-saving pour Phase 3
Write-Host "`n🔧 Application de Fail-Fast Validation (Phase 3)..." -ForegroundColor Yellow
& pwsh -ExecutionPolicy Bypass -File "$ProjectRoot\tools\apply-time-saving-methods.ps1" -Phase "3" -Method "fail-fast"

Write-Host "`n🎭 Application de Mock-First Strategy..." -ForegroundColor Yellow  
& pwsh -ExecutionPolicy Bypass -File "$ProjectRoot\tools\apply-time-saving-methods.ps1" -Phase "3" -Method "mock-first"

Write-Host "`n📋 Application de Contract-First Development..." -ForegroundColor Yellow
& pwsh -ExecutionPolicy Bypass -File "$ProjectRoot\tools\apply-time-saving-methods.ps1" -Phase "3" -Method "contract-first"

Write-Host "`n📊 Application de Metrics-Driven Development..." -ForegroundColor Yellow
& pwsh -ExecutionPolicy Bypass -File "$ProjectRoot\tools\apply-time-saving-methods.ps1" -Phase "3" -Method "metrics-driven"

Write-Host "`n🔄 Application de Pipeline-as-Code..." -ForegroundColor Yellow
& pwsh -ExecutionPolicy Bypass -File "$ProjectRoot\tools\apply-time-saving-methods.ps1" -Phase "3" -Method "pipeline-as-code"

Write-Host "`n✅ OPTIMISATION TERMINÉE!" -ForegroundColor Green
Write-Host "Le projet EMAIL_SENDER_1 est optimisé pour la Phase 1.1+" -ForegroundColor Cyan
