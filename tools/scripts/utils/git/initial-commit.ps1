# Script pour effectuer le premier commit et push vers GitHub

Write-Host "=== Premier commit et push vers GitHub ===" -ForegroundColor Cyan

# VÃ©rifier si Git est installÃ©
$gitVersion = git --version 2>$null
if (-not $gitVersion) {
    Write-Host "âŒ Git n'est pas installÃ© ou n'est pas accessible" -ForegroundColor Red
    Write-Host "Veuillez installer Git depuis https://git-scm.com/downloads"
    exit 1
}

# VÃ©rifier si le dÃ©pÃ´t Git est initialisÃ©
if (-not (Test-Path ".git")) {
    Write-Host "âŒ Le dÃ©pÃ´t Git n'est pas initialisÃ©" -ForegroundColor Red
    Write-Host "Veuillez exÃ©cuter le script configure-git.ps1 d'abord"
    exit 1
}

# VÃ©rifier si un remote est configurÃ©
$remoteExists = git remote -v | Select-String -Pattern "origin"
if (-not $remoteExists) {
    Write-Host "âŒ Aucun remote GitHub n'est configurÃ©" -ForegroundColor Red
    Write-Host "Veuillez exÃ©cuter le script configure-git.ps1 d'abord"
    exit 1
}

# Ajouter tous les fichiers au staging
Write-Host "Ajout de tous les fichiers au staging..." -ForegroundColor Yellow
git add .
Write-Host "âœ… Tous les fichiers ajoutÃ©s au staging" -ForegroundColor Green

# CrÃ©er le premier commit
$commitMessage = "Initial commit - Configuration du projet Email Sender 1"

Write-Host "CrÃ©ation du premier commit..." -ForegroundColor Yellow
git commit -m $commitMessage
Write-Host "âœ… Premier commit crÃ©Ã©" -ForegroundColor Green

# Pousser les changements vers GitHub
Write-Host "PoussÃ©e des changements vers GitHub..." -ForegroundColor Yellow
Write-Host "Note: Vous devrez peut-Ãªtre entrer vos identifiants GitHub" -ForegroundColor Yellow

$branchName = git rev-parse --abbrev-ref HEAD
git push -u origin $branchName

Write-Host "`n=== Premier commit et push terminÃ©s ===" -ForegroundColor Cyan
Write-Host "Votre code est maintenant sur GitHub !" -ForegroundColor Green
