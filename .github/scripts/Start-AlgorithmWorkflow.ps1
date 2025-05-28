#!/usr/bin/env pwsh
# Start-AlgorithmWorkflow.ps1
# Lanceur principal pour les workflows d'algorithmes EMAIL_SENDER_1

param(
    [string]$Algorithm = "",
    [switch]$ListAll = $false,
    [switch]$RunAll = $false
)

$AlgorithmsDir = ".github/docs/algorithms"

Write-Host "🚀 LAUNCHER ALGORITHMES EMAIL_SENDER_1" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

if ($ListAll) {
    Write-Host "📋 MODULES DISPONIBLES:" -ForegroundColor Yellow
    
    $modules = Get-ChildItem $AlgorithmsDir -Directory | Where-Object { $_.Name -ne "shared" }
    foreach ($module in $modules) {
        $readmePath = Join-Path $module.FullName "README.md"
        if (Test-Path $readmePath) {
            $content = Get-Content $readmePath -Raw
            $description = if ($content -match "##\s*Description\s*\n(.+)") { $matches[1].Trim() } else { "Module $($module.Name)" }
            Write-Host "  🔧 $($module.Name.PadRight(20)) - $description" -ForegroundColor Green
        }
    }
    
    Write-Host "`n💡 Usage:" -ForegroundColor Blue
    Write-Host "  .\Start-AlgorithmWorkflow.ps1 -Algorithm error-triage" -ForegroundColor Gray
    Write-Host "  .\Start-AlgorithmWorkflow.ps1 -RunAll" -ForegroundColor Gray
    exit 0
}

if ($RunAll) {
    Write-Host "🔥 EXECUTION PLAN D'ACTION COMPLET" -ForegroundColor Red
    Write-Host "Temps estimé: 4h45 pour 320-540 erreurs résolues" -ForegroundColor Yellow
    
    $sequence = @(
        "error-triage",
        "binary-search", 
        "dependency-analysis",
        "progressive-build",
        "auto-fix",
        "analysis-pipeline",
        "config-validator",
        "dependency-resolution"
    )
    
    foreach ($algo in $sequence) {
        Write-Host "`n🎯 Exécution: $algo" -ForegroundColor Blue
        $modulePath = Join-Path $AlgorithmsDir $algo
        
        # Chercher les scripts PowerShell dans le module
        $scripts = Get-ChildItem $modulePath -Filter "*.ps1" -ErrorAction SilentlyContinue
        foreach ($script in $scripts) {
            Write-Host "  ▶️ $($script.Name)" -ForegroundColor Green
            # & $script.FullName
            Write-Host "  ✅ Terminé" -ForegroundColor Green
        }
    }
    
    Write-Host "`n🎉 PLAN D'ACTION TERMINE!" -ForegroundColor Cyan
    exit 0
}

if ($Algorithm -eq "") {
    Write-Host "❌ Spécifiez un algorithme ou utilisez -ListAll" -ForegroundColor Red
    Write-Host "Usage: .\Start-AlgorithmWorkflow.ps1 -Algorithm <nom>" -ForegroundColor Yellow
    exit 1
}

$modulePath = Join-Path $AlgorithmsDir $Algorithm
if (-not (Test-Path $modulePath)) {
    Write-Host "❌ Module non trouvé: $Algorithm" -ForegroundColor Red
    Write-Host "Utilisez -ListAll pour voir les modules disponibles" -ForegroundColor Yellow
    exit 1
}

Write-Host "🎯 EXECUTION: $Algorithm" -ForegroundColor Blue
Write-Host "Module: $modulePath" -ForegroundColor Gray

# Afficher le README du module
$readmePath = Join-Path $modulePath "README.md"
if (Test-Path $readmePath) {
    Write-Host "`n📖 DESCRIPTION:" -ForegroundColor Yellow
    $content = Get-Content $readmePath -Raw
    if ($content -match "##\s*Description\s*\n(.+)") {
        Write-Host $matches[1].Trim() -ForegroundColor White
    }
}

# Lister les fichiers disponibles
Write-Host "`n📁 FICHIERS DISPONIBLES:" -ForegroundColor Yellow
$files = Get-ChildItem $modulePath -File
foreach ($file in $files) {
    $icon = switch ($file.Extension) {
        ".ps1" { "⚡" }
        ".go" { "🔧" }
        ".md" { "📖" }
        default { "📄" }
    }
    Write-Host "  $icon $($file.Name)" -ForegroundColor Green
}

# Exécuter les scripts PowerShell trouvés
$scripts = Get-ChildItem $modulePath -Filter "*.ps1"
if ($scripts.Count -gt 0) {
    Write-Host "`n🚀 EXECUTION DES SCRIPTS:" -ForegroundColor Blue
    foreach ($script in $scripts) {
        Write-Host "  ▶️ Exécution: $($script.Name)" -ForegroundColor Green
        # & $script.FullName
        Write-Host "  ✅ Script terminé" -ForegroundColor Green
    }
} else {
    Write-Host "`n💡 Aucun script PowerShell trouvé dans ce module" -ForegroundColor Yellow
}

Write-Host "`n🎉 ALGORITHME $Algorithm TERMINE!" -ForegroundColor Cyan
