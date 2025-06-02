# Run-FixAllErrors.ps1 - Script to fix all errors
param (
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
)

Write-Host "🔧 EMAIL_SENDER_1 - Script de correction des 123 erreurs" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

Push-Location $ProjectRoot

try {
    Write-Host "`n📦 Exécution du correcteur d'erreurs principal..." -ForegroundColor Yellow
    go run fix_all_errors.go
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Le correcteur principal a échoué. Tentative avec des correcteurs individuels..." -ForegroundColor Red
        
        # Run individual fixers
        Write-Host "`n🔧 1/5 Correction des conflits de packages..." -ForegroundColor Yellow
        go run fix_multiple_main.go
        
        Write-Host "`n🔧 2/5 Correction des imports non utilisés..." -ForegroundColor Yellow 
        go run fix_imports.go
        
        Write-Host "`n🔧 3/5 Correction des erreurs PowerShell..." -ForegroundColor Yellow
        # Replace PowerShell verbs
        $psFiles = Get-ChildItem -Path $ProjectRoot -Filter "*.ps1" -Recurse
        foreach ($file in $psFiles) {
            $content = Get-Content $file.FullName -Raw
            
            $content = $content -replace "Generate-ComponentRecommendations", "New-ComponentRecommendations"
            $content = $content -replace "Generate-FixActions", "New-FixActions" 
            $content = $content -replace "Generate-DependencyReport", "New-DependencyReport"
            $content = $content -replace "Analyze-CircularDependencies", "Test-CircularDependencies"
            
            Set-Content -Path $file.FullName -Value $content
        }
        
        Write-Host "`n🔧 4/5 Correction des variables non utilisées..." -ForegroundColor Yellow
        go run error_fixer_625.go
        
        Write-Host "`n🔧 5/5 Nettoyage des dépendances..." -ForegroundColor Yellow
        go mod tidy
    }
    
    # Final validation
    Write-Host "`n✅ Validation finale..." -ForegroundColor Green
    $buildOutput = & go build -o temp_build.exe 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n🎉 SUCCÈS! Toutes les erreurs ont été corrigées." -ForegroundColor Green
        
        # Clean up temp build
        if (Test-Path "temp_build.exe") {
            Remove-Item "temp_build.exe" -Force
        }
    } else {
        Write-Host "`n⚠️ Il reste encore des erreurs à corriger:" -ForegroundColor Yellow
        $buildOutput | ForEach-Object { Write-Host "   $_" }
    }
    
} finally {
    Pop-Location
}

Write-Host "`n📋 Rapport complet disponible dans: all_errors_fix_report.json" -ForegroundColor Cyan
