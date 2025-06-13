# Script pour ajouter et committer les changements restants
# Date: 8 juin 2025

Set-Location "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

Write-Host "===== COMMIT DES FICHIERS RESTANTS =====" -ForegroundColor Cyan

Write-Host "`nStatut actuel:" -ForegroundColor Yellow
git status

Write-Host "`nAjout de tous les fichiers modifiés..." -ForegroundColor Green
git add .

Write-Host "`nCréation du commit..." -ForegroundColor Green
$commitMessage = Read-Host "Entrez le message de commit (ou appuyez sur Entrée pour utiliser la valeur par défaut 'fix: ajout des fichiers restants')"

if ([string]::IsNullOrWhiteSpace($commitMessage)) {
   $commitMessage = "fix: ajout des fichiers restants"
}

git commit -m "$commitMessage"

Write-Host "`nPush vers GitHub..." -ForegroundColor Green
git push origin manager/powershell-optimization

Write-Host "`n===== OPÉRATION TERMINÉE =====" -ForegroundColor Cyan
Write-Host "Vérifiez: https://github.com/gerivdb/email-sender-1/tree/manager/powershell-optimization" -ForegroundColor Yellow
Pause
