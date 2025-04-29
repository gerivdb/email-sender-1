<#
.SYNOPSIS
    Script de test basique pour le gestionnaire intÃ©grÃ©.

.DESCRIPTION
    Ce script permet de tester le bon fonctionnement du gestionnaire intÃ©grÃ© de maniÃ¨re basique.
#>

# DÃ©finir les chemins
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\integrated-manager.ps1"

# VÃ©rifier que le gestionnaire intÃ©grÃ© existe
if (-not (Test-Path -Path $integratedManagerPath)) {
    Write-Error "Le gestionnaire intÃ©grÃ© est introuvable : $integratedManagerPath"
    exit 1
}

# Afficher l'en-tÃªte
Write-Host "Test basique du gestionnaire intÃ©grÃ©" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Tester l'existence des fichiers rÃ©fÃ©rencÃ©s
$modeManagerPath = Join-Path -Path $projectRoot -ChildPath "development\\scripts\\mode-manager\mode-manager.ps1"
$roadmap-managerPath = Join-Path -Path $projectRoot -ChildPath "projet\roadmaps\scripts\roadmap-manager.ps1"
$configPath = Join-Path -Path $projectRoot -ChildPath "development\config\unified-config.json"

Write-Host "Test 1: VÃ©rification des fichiers rÃ©fÃ©rencÃ©s" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Yellow
Write-Host "Mode Manager: $modeManagerPath" -ForegroundColor Gray
Write-Host "Roadmap Manager: $roadmap-managerPath" -ForegroundColor Gray
Write-Host "Configuration: $configPath" -ForegroundColor Gray
Write-Host ""

$modeManagerExists = Test-Path -Path $modeManagerPath
$roadmap-managerExists = Test-Path -Path $roadmap-managerPath
$configExists = Test-Path -Path $configPath

if ($modeManagerExists) {
    Write-Host "Mode Manager: OK" -ForegroundColor Green
} else {
    Write-Host "Mode Manager: Ã‰CHEC - Fichier introuvable" -ForegroundColor Red
}

if ($roadmap-managerExists) {
    Write-Host "Roadmap Manager: OK" -ForegroundColor Green
} else {
    Write-Host "Roadmap Manager: Ã‰CHEC - Fichier introuvable" -ForegroundColor Red
}

if ($configExists) {
    Write-Host "Configuration: OK" -ForegroundColor Green
} else {
    Write-Host "Configuration: Ã‰CHEC - Fichier introuvable" -ForegroundColor Red
}

Write-Host ""

# Tester l'exÃ©cution du gestionnaire intÃ©grÃ©
Write-Host "Test 2: ExÃ©cution du gestionnaire intÃ©grÃ©" -ForegroundColor Yellow
Write-Host "-------------------------------------" -ForegroundColor Yellow
Write-Host "Commande: $integratedManagerPath" -ForegroundColor Gray
Write-Host ""

try {
    $output = & $integratedManagerPath 2>&1
    Write-Host "Sortie:" -ForegroundColor Gray
    Write-Host $output
    Write-Host "RÃ©sultat: OK" -ForegroundColor Green
} catch {
    Write-Host "RÃ©sultat: Ã‰CHEC - $_" -ForegroundColor Red
}

Write-Host ""

# Afficher le rÃ©sumÃ©
Write-Host "RÃ©sumÃ© des tests" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan
Write-Host "Le gestionnaire intÃ©grÃ© a Ã©tÃ© testÃ©." -ForegroundColor Green
Write-Host "Chemin du gestionnaire intÃ©grÃ©: $integratedManagerPath" -ForegroundColor Gray


