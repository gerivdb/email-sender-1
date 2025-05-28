#!/usr/bin/env pwsh
# Test script for the error resolution pipeline using real errors from 2025-05-28-errors.md

param(
    [string]$ErrorFile = "..\..\2025-05-28-errors.md",
    [string]$TargetPath = "..\..\..",
    [switch]$DryRun = $true,
    [switch]$Verbose = $false
)

Write-Host "🚀 Testing Error Resolution Pipeline with Real Data" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Vérifier l'existence du fichier d'erreurs
if (-not (Test-Path $ErrorFile)) {
    Write-Error "Error file not found: $ErrorFile"
    exit 1
}

# Vérifier la compilation du pipeline
Write-Host "📦 Building pipeline..." -ForegroundColor Yellow
$buildResult = & go build -o pipeline.exe ./cmd/pipeline 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build pipeline: $buildResult"
    exit 1
}

Write-Host "✅ Pipeline built successfully" -ForegroundColor Green

# Vérifier la version
Write-Host "🔍 Checking pipeline version..." -ForegroundColor Yellow
$versionResult = & ./pipeline.exe --version 2>&1
Write-Host "Version: $versionResult" -ForegroundColor Cyan

# Analyser les erreurs du fichier MD
Write-Host "📊 Analyzing errors from $ErrorFile..." -ForegroundColor Yellow
$errorContent = Get-Content $ErrorFile -Raw
$errorLines = $errorContent -split "`n" | Where-Object { $_ -match "^\[?\{" }
$totalErrors = $errorLines.Count
Write-Host "Found $totalErrors errors to process" -ForegroundColor Cyan

# Créer un fichier temporaire avec les erreurs JSON
$tempErrorFile = "temp-errors.json"
$jsonArray = "[$($errorLines -join ',')]"
$jsonArray | Out-File -FilePath $tempErrorFile -Encoding UTF8

Write-Host "💾 Created temporary error file: $tempErrorFile" -ForegroundColor Yellow

# Configuration pour le test
$testConfig = @{
    target_path = $TargetPath
    error_reports = @($tempErrorFile)
    output_dir = "./test-output"
    metrics_port = 8080
    processing_mode = "batch"
    enable_metrics = $true
    log_level = if ($Verbose) { "debug" } else { "info" }
    detector = @{
        enabled = $true
        patterns = @("unused_variables", "circular_dependencies", "type_mismatches", "syntax_errors")
        timeout = "60s"
    }
    resolver = @{
        enabled = $true
        dry_run = $DryRun.IsPresent
        safety_level = "safe"
        backup_enabled = $true
    }
} | ConvertTo-Json -Depth 5

$configFile = "test-config.json"
$testConfig | Out-File -FilePath $configFile -Encoding UTF8

Write-Host "📋 Created test configuration: $configFile" -ForegroundColor Yellow

# Exécuter le pipeline
Write-Host "🔄 Running pipeline..." -ForegroundColor Yellow
$pipelineArgs = @(
    "--config", $configFile
    "--target", $TargetPath
)

if ($DryRun) {
    $pipelineArgs += "--dry-run"
}

if ($Verbose) {
    $pipelineArgs += "--verbose"
}

Write-Host "Command: ./pipeline.exe $($pipelineArgs -join ' ')" -ForegroundColor Cyan

$startTime = Get-Date
$pipelineResult = & ./pipeline.exe @pipelineArgs 2>&1
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "⏱️  Pipeline execution completed in $($duration.TotalSeconds) seconds" -ForegroundColor Green

# Afficher les résultats
Write-Host "`n📈 Pipeline Results:" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host $pipelineResult

# Analyser les résultats de sortie si disponible
$outputDir = "./test-output"
if (Test-Path $outputDir) {
    Write-Host "`n📂 Output files:" -ForegroundColor Yellow
    Get-ChildItem $outputDir -Recurse | ForEach-Object {
        Write-Host "  - $($_.FullName)" -ForegroundColor Cyan
    }
    
    # Chercher les fichiers de résultats JSON
    $resultFiles = Get-ChildItem $outputDir -Filter "*.json" -Recurse
    foreach ($resultFile in $resultFiles) {
        Write-Host "`n📄 Results from $($resultFile.Name):" -ForegroundColor Yellow
        $results = Get-Content $resultFile.FullName | ConvertFrom-Json
        if ($results.summary) {
            Write-Host "  - Total errors: $($results.summary.total_errors)" -ForegroundColor Cyan
            Write-Host "  - Errors fixed: $($results.summary.errors_fixed)" -ForegroundColor Cyan
            Write-Host "  - Success rate: $($results.summary.fix_success_rate)%" -ForegroundColor Cyan
            Write-Host "  - Safe fixes: $($results.summary.safe_fixes_applied)" -ForegroundColor Cyan
            Write-Host "  - Manual review: $($results.summary.manual_review_required)" -ForegroundColor Cyan
        }
    }
}

# Nettoyer les fichiers temporaires
Write-Host "`n🧹 Cleaning up..." -ForegroundColor Yellow
Remove-Item $tempErrorFile -ErrorAction SilentlyContinue
Remove-Item $configFile -ErrorAction SilentlyContinue

Write-Host "✅ Test completed successfully!" -ForegroundColor Green

# Afficher les métriques si disponibles
if ($testConfig.enable_metrics) {
    Write-Host "`n📊 Metrics available at: http://localhost:8080/metrics" -ForegroundColor Yellow
    Write-Host "You can view them with: curl http://localhost:8080/metrics" -ForegroundColor Cyan
}
