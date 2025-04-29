<#
.SYNOPSIS
    Script de test basique pour le gestionnaire intégré.

.DESCRIPTION
    Ce script permet de tester le bon fonctionnement du gestionnaire intégré de manière basique.
#>

# Définir les chemins
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\integrated-manager.ps1"

# Vérifier que le gestionnaire intégré existe
if (-not (Test-Path -Path $integratedManagerPath)) {
    Write-Error "Le gestionnaire intégré est introuvable : $integratedManagerPath"
    exit 1
}

# Afficher l'en-tête
Write-Host "Test basique du gestionnaire intégré" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Tester l'existence des fichiers référencés
$modeManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager\mode-manager.ps1"
$roadmapManagerPath = Join-Path -Path $projectRoot -ChildPath "projet\roadmaps\scripts\RoadmapManager.ps1"
$configPath = Join-Path -Path $projectRoot -ChildPath "development\config\unified-config.json"

Write-Host "Test 1: Vérification des fichiers référencés" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Yellow
Write-Host "Mode Manager: $modeManagerPath" -ForegroundColor Gray
Write-Host "Roadmap Manager: $roadmapManagerPath" -ForegroundColor Gray
Write-Host "Configuration: $configPath" -ForegroundColor Gray
Write-Host ""

$modeManagerExists = Test-Path -Path $modeManagerPath
$roadmapManagerExists = Test-Path -Path $roadmapManagerPath
$configExists = Test-Path -Path $configPath

if ($modeManagerExists) {
    Write-Host "Mode Manager: OK" -ForegroundColor Green
} else {
    Write-Host "Mode Manager: ÉCHEC - Fichier introuvable" -ForegroundColor Red
}

if ($roadmapManagerExists) {
    Write-Host "Roadmap Manager: OK" -ForegroundColor Green
} else {
    Write-Host "Roadmap Manager: ÉCHEC - Fichier introuvable" -ForegroundColor Red
}

if ($configExists) {
    Write-Host "Configuration: OK" -ForegroundColor Green
} else {
    Write-Host "Configuration: ÉCHEC - Fichier introuvable" -ForegroundColor Red
}

Write-Host ""

# Tester l'exécution du gestionnaire intégré
Write-Host "Test 2: Exécution du gestionnaire intégré" -ForegroundColor Yellow
Write-Host "-------------------------------------" -ForegroundColor Yellow
Write-Host "Commande: $integratedManagerPath" -ForegroundColor Gray
Write-Host ""

try {
    $output = & $integratedManagerPath 2>&1
    Write-Host "Sortie:" -ForegroundColor Gray
    Write-Host $output
    Write-Host "Résultat: OK" -ForegroundColor Green
} catch {
    Write-Host "Résultat: ÉCHEC - $_" -ForegroundColor Red
}

Write-Host ""

# Afficher le résumé
Write-Host "Résumé des tests" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan
Write-Host "Le gestionnaire intégré a été testé." -ForegroundColor Green
Write-Host "Chemin du gestionnaire intégré: $integratedManagerPath" -ForegroundColor Gray
