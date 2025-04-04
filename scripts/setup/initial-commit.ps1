# Script pour effectuer le premier commit et push vers GitHub

Write-Host "=== Premier commit et push vers GitHub ===" -ForegroundColor Cyan

# Vérifier si Git est installé
$gitVersion = git --version 2>$null
if (-not $gitVersion) {
    Write-Host "❌ Git n'est pas installé ou n'est pas accessible" -ForegroundColor Red
    Write-Host "Veuillez installer Git depuis https://git-scm.com/downloads"
    exit 1
}

# Vérifier si le dépôt Git est initialisé
if (-not (Test-Path ".git")) {
    Write-Host "❌ Le dépôt Git n'est pas initialisé" -ForegroundColor Red
    Write-Host "Veuillez exécuter le script configure-git.ps1 d'abord"
    exit 1
}

# Vérifier si un remote est configuré
$remoteExists = git remote -v | Select-String -Pattern "origin"
if (-not $remoteExists) {
    Write-Host "❌ Aucun remote GitHub n'est configuré" -ForegroundColor Red
    Write-Host "Veuillez exécuter le script configure-git.ps1 d'abord"
    exit 1
}

# Ajouter tous les fichiers au staging
Write-Host "Ajout de tous les fichiers au staging..." -ForegroundColor Yellow
git add .
Write-Host "✅ Tous les fichiers ajoutés au staging" -ForegroundColor Green

# Créer le premier commit
$commitMessage = "Initial commit - Configuration du projet Email Sender 1"

Write-Host "Création du premier commit..." -ForegroundColor Yellow
git commit -m $commitMessage
Write-Host "✅ Premier commit créé" -ForegroundColor Green

# Pousser les changements vers GitHub
Write-Host "Poussée des changements vers GitHub..." -ForegroundColor Yellow
Write-Host "Note: Vous devrez peut-être entrer vos identifiants GitHub" -ForegroundColor Yellow

$branchName = git rev-parse --abbrev-ref HEAD
git push -u origin $branchName

Write-Host "`n=== Premier commit et push terminés ===" -ForegroundColor Cyan
Write-Host "Votre code est maintenant sur GitHub !" -ForegroundColor Green
