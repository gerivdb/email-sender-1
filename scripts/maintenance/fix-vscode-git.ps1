# Script pour résoudre les problèmes de suivi Git dans VS Code

Write-Host "=== Résolution des problèmes de suivi Git dans VS Code ===" -ForegroundColor Cyan

# Vérifier l'état Git
Write-Host "Vérification de l'état Git..." -ForegroundColor Yellow
git status
Write-Host "✓ État Git vérifié" -ForegroundColor Green

# Nettoyer le cache Git
Write-Host "Nettoyage du cache Git..." -ForegroundColor Yellow
git add --renormalize .
Write-Host "✓ Cache Git nettoyé" -ForegroundColor Green

# Vérifier s'il y a des changements après renormalisation
$changes = git status --porcelain
if ($changes) {
    Write-Host "Des changements ont été détectés après renormalisation:" -ForegroundColor Yellow
    Write-Host $changes

    $commitChanges = Read-Host "Voulez-vous commiter ces changements? (O/N)"
    if ($commitChanges -eq "O" -or $commitChanges -eq "o") {
        git commit -m "Fix: Normalisation des fins de ligne"
        git push
        Write-Host "✓ Changements commités et poussés" -ForegroundColor Green
    }
} else {
    Write-Host "✓ Aucun changement détecté après renormalisation" -ForegroundColor Green
}

# Nettoyer les fichiers ignorés
Write-Host "Nettoyage des fichiers ignorés..." -ForegroundColor Yellow
git clean -fX
Write-Host "✓ Fichiers ignorés nettoyés" -ForegroundColor Green

# Réinitialiser VS Code Git
Write-Host "Réinitialisation du suivi Git dans VS Code..." -ForegroundColor Yellow
Write-Host "Pour terminer la réinitialisation, veuillez:"
Write-Host "1. Fermer VS Code"
Write-Host "2. Supprimer le dossier .vscode dans votre projet (s'il existe)"
Write-Host "3. Rouvrir VS Code"

Write-Host "`n=== Résolution des problèmes de suivi Git dans VS Code terminée ===" -ForegroundColor Cyan
