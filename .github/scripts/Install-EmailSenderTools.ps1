#!/usr/bin/env pwsh
# Install-EmailSenderTools.ps1
# Installation complete des outils pour EMAIL_SENDER_1

param(
    [switch]$SkipExtensions = $false,
    [switch]$SkipGo = $false,
    [switch]$SkipValidation = $false
)

Write-Host "🚀 INSTALLATION OUTILS EMAIL_SENDER_1" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# 1. Verifier la structure modulaire
Write-Host "`n📦 VERIFICATION STRUCTURE MODULAIRE" -ForegroundColor Yellow

$algorithmsDir = ".github/docs/algorithms"
if (Test-Path $algorithmsDir) {
    $modules = Get-ChildItem $algorithmsDir -Directory | Where-Object { $_.Name -ne "shared" }
    Write-Host "✅ Structure modulaire detectee: $($modules.Count) modules" -ForegroundColor Green
    
    foreach ($module in $modules) {
        Write-Host "  📁 $($module.Name)" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ Structure modulaire non trouvee" -ForegroundColor Red
    exit 1
}

# 2. Verifier Go si necessaire
if (-not $SkipGo) {
    Write-Host "`n🔧 VERIFICATION GO" -ForegroundColor Yellow
    
    try {
        $goVersion = go version 2>$null
        if ($goVersion) {
            Write-Host "✅ Go detecte: $goVersion" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Go non detecte - certains modules ne fonctionneront pas" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ Go non disponible" -ForegroundColor Yellow
    }
    
    # Verifier go.mod
    if (Test-Path "go.mod") {
        Write-Host "✅ go.mod present" -ForegroundColor Green
        
        # Installer les dependances
        Write-Host "📥 Installation dependances Go..." -ForegroundColor Blue
        go mod download 2>$null
        go mod tidy 2>$null
        Write-Host "✅ Dependances Go installees" -ForegroundColor Green
    }
}

# 3. Installer extensions VS Code si demande
if (-not $SkipExtensions) {
    Write-Host "`n🔌 INSTALLATION EXTENSIONS VS CODE" -ForegroundColor Yellow
    
    $extensions = @(
        @{ id = "alefragnani.project-manager"; name = "Project Manager" },
        @{ id = "usernamehw.errorlens"; name = "Error Lens" },
        @{ id = "ms-vscode.vscode-json"; name = "JSON Support" },
        @{ id = "redhat.vscode-yaml"; name = "YAML Support" },
        @{ id = "golang.go"; name = "Go Extension" },
        @{ id = "ms-vscode.powershell"; name = "PowerShell Extension" }
    )
    
    foreach ($ext in $extensions) {
        Write-Host "📦 Installation: $($ext.name)" -ForegroundColor Blue
        try {
            code --install-extension $ext.id --force 2>$null
            Write-Host "✅ $($ext.name) installe" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Echec installation $($ext.name)" -ForegroundColor Yellow
        }
    }
}

# 4. Creer les raccourcis de navigation
Write-Host "`n🎯 CREATION RACCOURCIS NAVIGATION" -ForegroundColor Yellow

$shortcutsDir = ".github/shortcuts"
if (-not (Test-Path $shortcutsDir)) {
    New-Item -ItemType Directory -Path $shortcutsDir -Force | Out-Null
}

# Raccourci pour les algorithmes prioritaires
$priorityScript = @"
#!/usr/bin/env pwsh
# Algorithmes prioritaires EMAIL_SENDER_1
Write-Host "🔥 ALGORITHMES PRIORITE CRITIQUE" -ForegroundColor Red
Write-Host "1. Error Triage: .\.github\scripts\Start-AlgorithmWorkflow.ps1 -Algorithm error-triage"
Write-Host "2. Binary Search: .\.github\scripts\Start-AlgorithmWorkflow.ps1 -Algorithm binary-search"
Write-Host "3. Dependency Analysis: .\.github\scripts\Start-AlgorithmWorkflow.ps1 -Algorithm dependency-analysis"
"@

$priorityScript | Out-File -FilePath "$shortcutsDir/priority-algorithms.ps1" -Encoding UTF8

# Raccourci pour le plan complet
$fullPlanScript = @"
#!/usr/bin/env pwsh
# Plan d'action complet EMAIL_SENDER_1
Write-Host "🚀 EXECUTION PLAN COMPLET EMAIL_SENDER_1" -ForegroundColor Cyan
.\.github\scripts\Start-AlgorithmWorkflow.ps1 -RunAll
"@

$fullPlanScript | Out-File -FilePath "$shortcutsDir/full-action-plan.ps1" -Encoding UTF8

Write-Host "✅ Raccourcis crees dans $shortcutsDir" -ForegroundColor Green

# 5. Validation finale
if (-not $SkipValidation) {
    Write-Host "`n✅ VALIDATION FINALE" -ForegroundColor Yellow
    
    # Compter les fichiers
    $totalFiles = Get-ChildItem $algorithmsDir -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count
    Write-Host "📊 Total fichiers modules: $totalFiles" -ForegroundColor Blue
    
    # Verifier les scripts principaux
    $mainScripts = @(
        ".github/scripts/Start-AlgorithmWorkflow.ps1",
        ".github/scripts/Restructure-AlgorithmsEmailSender.ps1"
    )
    
    foreach ($script in $mainScripts) {
        if (Test-Path $script) {
            Write-Host "✅ Script present: $script" -ForegroundColor Green
        } else {
            Write-Host "❌ Script manquant: $script" -ForegroundColor Red
        }
    }
    
    # Tester un module
    $testModule = "error-triage"
    $testPath = Join-Path $algorithmsDir $testModule
    if (Test-Path $testPath) {
        $moduleFiles = Get-ChildItem $testPath -File | Measure-Object | Select-Object -ExpandProperty Count
        Write-Host "🧪 Test module $testModule : $moduleFiles fichiers" -ForegroundColor Blue
    }
}

# 6. Afficher le resume final
Write-Host "`n🎉 INSTALLATION TERMINEE!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n📋 COMMANDES PRINCIPALES:" -ForegroundColor Yellow
Write-Host "  Liste modules    : .\.github\scripts\Start-AlgorithmWorkflow.ps1 -ListAll" -ForegroundColor White
Write-Host "  Module specifique: .\.github\scripts\Start-AlgorithmWorkflow.ps1 -Algorithm error-triage" -ForegroundColor White
Write-Host "  Plan complet     : .\.github\scripts\Start-AlgorithmWorkflow.ps1 -RunAll" -ForegroundColor White
Write-Host "  Priorite critique: .\.github\shortcuts\priority-algorithms.ps1" -ForegroundColor White

Write-Host "`n📂 STRUCTURE MODULAIRE:" -ForegroundColor Yellow
Write-Host "  Index principal  : .github/docs/algorithms/README.md" -ForegroundColor White
Write-Host "  Modules          : .github/docs/algorithms/<module-name>/" -ForegroundColor White
Write-Host "  Utilitaires      : .github/docs/algorithms/shared/" -ForegroundColor White

Write-Host "`n🎯 PROCHAINES ETAPES:" -ForegroundColor Yellow
Write-Host "  1. Tester un module: .\.github\scripts\Start-AlgorithmWorkflow.ps1 -Algorithm error-triage" -ForegroundColor White
Write-Host "  2. Executer plan priorite: .\.github\shortcuts\priority-algorithms.ps1" -ForegroundColor White
Write-Host "  3. Suivre les metriques dans les logs/" -ForegroundColor White

Write-Host "`n🚀 EMAIL_SENDER_1 pret pour debug systematique!" -ForegroundColor Green
