# Script pour configurer le remote et pousser vers GitHub
# Date: 8 juin 2025

# Configurer le répertoire
Set-Location "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

Write-Host "=== CONFIGURATION DU REMOTE GITHUB ===" -ForegroundColor Cyan
Write-Host "Objectif: Push vers https://github.com/gerivdb/email-sender-1/tree/manager/powershell-optimization" -ForegroundColor Yellow

# 1. Vérifier l'état actuel
Write-Host "`n1. État actuel:" -ForegroundColor Green
git status

# 2. Configurer le remote correct
Write-Host "`n2. Configuration du remote:" -ForegroundColor Green
git remote -v
git remote remove origin
git remote add origin https://github.com/gerivdb/email-sender-1.git
git remote -v

# 3. Configurer la branche correcte
Write-Host "`n3. Configuration de la branche:" -ForegroundColor Green
git branch -m manager/powershell-optimization

# 4. Pousser vers GitHub avec force
Write-Host "`n4. Push des changements:" -ForegroundColor Green
git push -u origin manager/powershell-optimization --force

# 5. Vérifier l'état final
Write-Host "`n5. État final:" -ForegroundColor Green
git status

Write-Host "`nOpération terminée. Vérifiez https://github.com/gerivdb/email-sender-1/tree/manager/powershell-optimization" -ForegroundColor Cyan
