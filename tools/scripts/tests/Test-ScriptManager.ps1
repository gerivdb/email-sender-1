<#
.SYNOPSIS
    Teste le ScriptManager pour vérifier qu'il fonctionne correctement.
.DESCRIPTION
    Ce script teste le ScriptManager pour vérifier qu'il fonctionne correctement
    et qu'il intègre toutes les fonctionnalités des phases précédentes.
.EXAMPLE
    .\Test-ScriptManager.ps1
    Teste le ScriptManager sur tous les scripts du dossier "scripts".
#>

# Vérifier si le ScriptManager existe
$ScriptManagerPath = "scripts\manager\ScriptManager.ps1"
if (-not (Test-Path -Path $ScriptManagerPath)) {
    Write-Host "Le ScriptManager n'existe pas: $ScriptManagerPath" -ForegroundColor Red
    exit 1
}

Write-Host "Le ScriptManager existe: $ScriptManagerPath" -ForegroundColor Green

# Tester la fonctionnalité d'inventaire
Write-Host "Test de la fonctionnalité d'inventaire..." -ForegroundColor Cyan
try {
    & $ScriptManagerPath -Action inventory -Path "scripts\maintenance"
    $InventoryPath = "scripts\manager\data\inventory.json"
    if (Test-Path -Path $InventoryPath) {
        Write-Host "Test d'inventaire réussi" -ForegroundColor Green
    } else {
        Write-Host "Le fichier d'inventaire n'a pas été généré: $InventoryPath" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Erreur lors du test d'inventaire: $_" -ForegroundColor Red
    exit 1
}

# Tester la fonctionnalité d'analyse
Write-Host "Test de la fonctionnalité d'analyse..." -ForegroundColor Cyan
try {
    & $ScriptManagerPath -Action analyze -Path "scripts\maintenance"
    $AnalysisPath = "scripts\manager\data\analysis.json"
    if (Test-Path -Path $AnalysisPath) {
        Write-Host "Test d'analyse réussi" -ForegroundColor Green
    } else {
        Write-Host "Le fichier d'analyse n'a pas été généré: $AnalysisPath" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Erreur lors du test d'analyse: $_" -ForegroundColor Red
    exit 1
}

# Tester la fonctionnalité de documentation
Write-Host "Test de la fonctionnalité de documentation..." -ForegroundColor Cyan
try {
    & $ScriptManagerPath -Action document -Path "scripts\maintenance" -Format Markdown
    $DocumentationPath = "scripts\manager\docs\script_documentation.markdown"
    if (Test-Path -Path $DocumentationPath) {
        Write-Host "Test de documentation réussi" -ForegroundColor Green
    } else {
        Write-Host "Le fichier de documentation n'a pas été généré: $DocumentationPath" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Erreur lors du test de documentation: $_" -ForegroundColor Red
    exit 1
}

# Tester la fonctionnalité de tableau de bord
Write-Host "Test de la fonctionnalité de tableau de bord..." -ForegroundColor Cyan
try {
    & $ScriptManagerPath -Action dashboard
    Write-Host "Test de tableau de bord réussi" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors du test de tableau de bord: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Tous les tests ont réussi! Le ScriptManager fonctionne correctement." -ForegroundColor Green
exit 0
