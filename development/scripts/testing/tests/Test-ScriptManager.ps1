<#
.SYNOPSIS
    Teste le ScriptManager pour vÃ©rifier qu'il fonctionne correctement.
.DESCRIPTION
    Ce script teste le ScriptManager pour vÃ©rifier qu'il fonctionne correctement
    et qu'il intÃ¨gre toutes les fonctionnalitÃ©s des phases prÃ©cÃ©dentes.
.EXAMPLE
    .\Test-ScriptManager.ps1
    Teste le ScriptManager sur tous les scripts du dossier "scripts".
#>

# VÃ©rifier si le ScriptManager existe
$ScriptManagerPath = "scripts\\mode-manager\ScriptManager.ps1"
if (-not (Test-Path -Path $ScriptManagerPath)) {
    Write-Host "Le ScriptManager n'existe pas: $ScriptManagerPath" -ForegroundColor Red
    exit 1
}

Write-Host "Le ScriptManager existe: $ScriptManagerPath" -ForegroundColor Green

# Tester la fonctionnalitÃ© d'inventaire
Write-Host "Test de la fonctionnalitÃ© d'inventaire..." -ForegroundColor Cyan
try {
    & $ScriptManagerPath -Action inventory -Path "scripts\maintenance"
    $InventoryPath = "scripts\\mode-manager\data\inventory.json"
    if (Test-Path -Path $InventoryPath) {
        Write-Host "Test d'inventaire rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "Le fichier d'inventaire n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $InventoryPath" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Erreur lors du test d'inventaire: $_" -ForegroundColor Red
    exit 1
}

# Tester la fonctionnalitÃ© d'analyse
Write-Host "Test de la fonctionnalitÃ© d'analyse..." -ForegroundColor Cyan
try {
    & $ScriptManagerPath -Action analyze -Path "scripts\maintenance"
    $AnalysisPath = "scripts\\mode-manager\data\analysis.json"
    if (Test-Path -Path $AnalysisPath) {
        Write-Host "Test d'analyse rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "Le fichier d'analyse n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $AnalysisPath" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Erreur lors du test d'analyse: $_" -ForegroundColor Red
    exit 1
}

# Tester la fonctionnalitÃ© de documentation
Write-Host "Test de la fonctionnalitÃ© de documentation..." -ForegroundColor Cyan
try {
    & $ScriptManagerPath -Action document -Path "scripts\maintenance" -Format Markdown
    $DocumentationPath = "scripts\\mode-manager\docs\script_documentation.markdown"
    if (Test-Path -Path $DocumentationPath) {
        Write-Host "Test de documentation rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "Le fichier de documentation n'a pas Ã©tÃ© gÃ©nÃ©rÃ©: $DocumentationPath" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Erreur lors du test de documentation: $_" -ForegroundColor Red
    exit 1
}

# Tester la fonctionnalitÃ© de tableau de bord
Write-Host "Test de la fonctionnalitÃ© de tableau de bord..." -ForegroundColor Cyan
try {
    & $ScriptManagerPath -Action dashboard
    Write-Host "Test de tableau de bord rÃ©ussi" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors du test de tableau de bord: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Tous les tests ont rÃ©ussi! Le ScriptManager fonctionne correctement." -ForegroundColor Green
exit 0

