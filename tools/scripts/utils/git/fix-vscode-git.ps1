# Script pour rÃ©soudre les problÃ¨mes de suivi Git dans VS Code

Write-Host "=== RÃ©solution des problÃ¨mes de suivi Git dans VS Code ===" -ForegroundColor Cyan

# VÃ©rifier l'Ã©tat Git
Write-Host "VÃ©rification de l'Ã©tat Git..." -ForegroundColor Yellow
git status
Write-Host "âœ“ Ã‰tat Git vÃ©rifiÃ©" -ForegroundColor Green

# Nettoyer le cache Git
Write-Host "Nettoyage du cache Git..." -ForegroundColor Yellow
git add --renormalize .
Write-Host "âœ“ Cache Git nettoyÃ©" -ForegroundColor Green

# VÃ©rifier s'il y a des changements aprÃ¨s renormalisation
$changes = git status --porcelain
if ($changes) {
    Write-Host "Des changements ont Ã©tÃ© dÃ©tectÃ©s aprÃ¨s renormalisation:" -ForegroundColor Yellow
    Write-Host $changes

    $commitChanges = Read-Host "Voulez-vous commiter ces changements? (O/N)"
    if ($commitChanges -eq "O" -or $commitChanges -eq "o") {
        git commit -m "Fix: Normalisation des fins de ligne"
        git push
        Write-Host "âœ“ Changements commitÃ©s et poussÃ©s" -ForegroundColor Green
    }
} else {
    Write-Host "âœ“ Aucun changement dÃ©tectÃ© aprÃ¨s renormalisation" -ForegroundColor Green
}

# Nettoyer les fichiers ignorÃ©s
Write-Host "Nettoyage des fichiers ignorÃ©s..." -ForegroundColor Yellow
git clean -fX
Write-Host "âœ“ Fichiers ignorÃ©s nettoyÃ©s" -ForegroundColor Green

# RÃ©initialiser VS Code Git
Write-Host "RÃ©initialisation du suivi Git dans VS Code..." -ForegroundColor Yellow
Write-Host "Pour terminer la rÃ©initialisation, veuillez:"
Write-Host "1. Fermer VS Code"
Write-Host "2. Supprimer le dossier .vscode dans votre projet (s'il existe)"
Write-Host "3. Rouvrir VS Code"

Write-Host "`n=== RÃ©solution des problÃ¨mes de suivi Git dans VS Code terminÃ©e ===" -ForegroundColor Cyan
