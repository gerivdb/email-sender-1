# Script de lancement rapide pour la gestion de la roadmap
# Ce script permet de lancer rapidement le gestionnaire de roadmap

# Chemin du script principal
$scriptPath = "Roadmap\scripts\RoadmapManager.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Host "Le script principal n'existe pas: $scriptPath" -ForegroundColor Red
    Write-Host "Veuillez vérifier le chemin du script." -ForegroundColor Yellow
    exit 1
}

# Afficher un message d'information
Write-Host "Lancement du gestionnaire de roadmap..." -ForegroundColor Cyan
Write-Host "Chemin du script: $scriptPath" -ForegroundColor Cyan
Write-Host ""

# Exécuter le script principal
& $scriptPath

# Afficher un message de fin
Write-Host ""
Write-Host "Exécution terminée." -ForegroundColor Green
