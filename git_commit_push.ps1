# Script pour commiter et pousser les changements
Set-Location D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1

# Ajouter tous les fichiers modifiés
Write-Host "Ajout des fichiers modifiés..." -ForegroundColor Cyan
git add .

# Commiter les changements
Write-Host "Commit des changements..." -ForegroundColor Cyan
git commit -m "Correction des problèmes dans les scripts PowerShell"

# Pousser les changements
Write-Host "Push des changements..." -ForegroundColor Cyan
git push --no-verify

# Afficher le statut
Write-Host "Statut Git final:" -ForegroundColor Cyan
git status
